python () {
    import os
    env_path = os.path.normpath(os.path.join(d.getVar('TOPDIR'), '..', '.env'))
    if os.path.exists(env_path):
        with open(env_path, 'r') as f:
            for line in f:
                if '=' in line:
                    key, val = line.strip().split('=', 1)
                    d.setVar(key, val)
}

configure_wpa_supplicant() {
    cat <<EOF > ${IMAGE_ROOTFS}/etc/wpa_supplicant.conf
ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=0
update_config=1

network={
    ssid="${WIFI_SSID}"
    psk="${WIFI_PSK}"
    key_mgmt=WPA-PSK
 } # leading space so bitbake parses correctly
EOF
    chmod 600 ${IMAGE_ROOTFS}/etc/wpa_supplicant.conf
}
ROOTFS_POSTPROCESS_COMMAND += "configure_wpa_supplicant;"
