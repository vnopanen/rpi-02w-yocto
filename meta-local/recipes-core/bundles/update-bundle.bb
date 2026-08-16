DESCRIPTION = "Minimal RAUC update bundle recipe for Raspberry Pi 0 2W"
LICENSE = "MIT"

inherit bundle

RAUC_BUNDLE_FORMAT = "verity"
RAUC_BUNDLE_COMPATIBLE = "raspberrypi0-2w-64"

RAUC_BUNDLE_SLOTS = "rootfs"
RAUC_SLOT_rootfs = "core-image-minimal"
RAUC_SLOT_rootfs[type] = "image"
RAUC_SLOT_rootfs[fstype] = "ext4"

RAUC_KEY_FILE ?= "${LAYERDIR_meta-local}/../keys/ca.key.pem"
RAUC_CERT_FILE ?= "${LAYERDIR_meta-local}/../keys/ca.cert.pem"
