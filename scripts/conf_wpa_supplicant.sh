#!/usr/bin/env bash
set -e

SD_DEVICE="${1:-/dev/mmcblk0}"
ENV_FILE="${2:-$HOME/rpi-02w-yocto.env}"

SSID=""
PSK=""
ALREADY_MOUNTED=false
MOUNT_DIR=""

cleanup() {
    if [ "$ALREADY_MOUNTED" = false ] && [ -n "$MOUNT_DIR" ] && [ -d "$MOUNT_DIR" ]; then
        umount "$MOUNT_DIR"
        rmdir "$MOUNT_DIR"
    fi
}
trap cleanup EXIT

if [ -f "$ENV_FILE" ]; then
    echo "Reading configuration from $ENV_FILE..."
    # shellcheck source=/dev/null
    source "$ENV_FILE"
fi

if [ -z "$SSID" ] || [ -z "$PSK" ]; then
    echo "NOTE: SSID or PSK not found in $ENV_FILE."

    if [ -z "$SSID" ]; then
        read -rp "Enter SSID: " SSID
    fi

    if [ -z "$PSK" ]; then
        printf "Enter PSK: "

        while IFS= read -r -s -n1 char; do
            # Check for Enter (newline) or EOF
            if [[ -z $char || $char == $'\n' ]]; then
                printf '\n'
                break
            fi

            # Handle Backspace (DEL or BS)
            if [[ $char == $'\x7f' || $char == $'\x08' ]]; then
                if [[ -n $PSK ]]; then
                    PSK=${PSK%?}
                    printf '\b \b'
                fi
            else
                PSK+="$char"
                printf '*'
            fi
        done
    fi
fi

if [ -z "$SSID" ] || [ -z "$PSK" ]; then
    echo "WARN: SSID or PSK was not provided. Skipping..."
    exit 0
fi

if [[ "$SD_DEVICE" =~ mmcblk ]]; then
    ROOTFS_PART="${SD_DEVICE}p2"
else
    ROOTFS_PART="${SD_DEVICE}2"
fi

if [ ! -b "$ROOTFS_PART" ]; then
    echo "Error: Rootfs partition $ROOTFS_PART does not exist."
    echo "Please ensure the image was flashed correctly and the device path is accurate."
    exit 1
fi

EXISTING_MOUNT=$(findmnt -n -o TARGET "$ROOTFS_PART" 2>/dev/null || true)
if [ -n "$EXISTING_MOUNT" ]; then
    MOUNT_DIR="$EXISTING_MOUNT"
    ALREADY_MOUNTED=true
else
    MOUNT_DIR=$(mktemp -d)
    mount "$ROOTFS_PART" "$MOUNT_DIR"
fi

TARGET_CONF="$MOUNT_DIR/etc/wpa_supplicant.conf"
if [ ! -f "$TARGET_CONF" ]; then
    echo "Error: $TARGET_CONF not found on rootfs."
    exit 1
fi

# Verify DUMMY placeholders exist before replacing
if ! grep -q "DUMMY_SSID" "$TARGET_CONF" || ! grep -q "DUMMY_PSK" "$TARGET_CONF"; then
    echo "Error: DUMMY_SSID or DUMMY_PSK placeholders not found in $TARGET_CONF."
    exit 1
fi

# Escape special characters for sed (handling & and |)
SAFE_SSID=$(printf '%s\n' "$SSID" | sed 's/[&|]/\\&/g')
SAFE_PSK=$(printf '%s\n' "$PSK" | sed 's/[&|]/\\&/g')

# Replace placeholders only
sed -i "s|DUMMY_SSID|$SAFE_SSID|g; s|DUMMY_PSK|$SAFE_PSK|g" "$TARGET_CONF"

echo "$TARGET_CONF configured."
