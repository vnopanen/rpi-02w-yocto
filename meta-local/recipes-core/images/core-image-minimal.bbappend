python () {
    import os
    env_path = os.path.normpath(os.path.join(d.getVar('TOPDIR'), '..', '.env'))
    if os.path.exists(env_path):
        with open(env_path, 'r') as f:
            for line in f:
                if '=' in line:
                    key, val = line.strip().split('=', 1)
                    val = val.strip().strip('\'"')
                    d.setVar(key, val)
}

configure_wpa_supplicant() {
    cat <<EOF > ${IMAGE_ROOTFS}/etc/wpa_supplicant.conf
ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=0
update_config=1

network={
    ssid="${WIFI_SSID}"
    psk=${WIFI_PSK}
    key_mgmt=WPA-PSK
 } # leading space so bitbake parses correctly
EOF
    chmod 600 ${IMAGE_ROOTFS}/etc/wpa_supplicant.conf
}

configure_network_interfaces() {
    install -d ${IMAGE_ROOTFS}/etc/network/
    cat <<EOF > ${IMAGE_ROOTFS}/etc/network/interfaces
auto lo
iface lo inet loopback

auto wlan0
iface wlan0 inet dhcp
    wpa-conf /etc/wpa_supplicant.conf
EOF
}

ROOTFS_POSTPROCESS_COMMAND += "configure_wpa_supplicant; configure_network_interfaces;"

configure_rauc_mounts() {
    install -d ${IMAGE_ROOTFS}/boot ${IMAGE_ROOTFS}/data
    touch ${IMAGE_ROOTFS}/etc/fstab

    if ! grep -qE '^[^#]*[[:space:]]/boot[[:space:]]' ${IMAGE_ROOTFS}/etc/fstab; then
        echo 'LABEL=boot /boot vfat defaults 0 0' >> ${IMAGE_ROOTFS}/etc/fstab
    fi

    if ! grep -qE '^[^#]*[[:space:]]/data[[:space:]]' ${IMAGE_ROOTFS}/etc/fstab; then
        echo 'LABEL=data /data ext4 defaults 0 2' >> ${IMAGE_ROOTFS}/etc/fstab
    fi
}

ROOTFS_POSTPROCESS_COMMAND += "configure_rauc_mounts;"
