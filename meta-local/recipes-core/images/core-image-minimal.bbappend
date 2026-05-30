inject_iwd_config() {
    ENV_FILE="${TOPDIR}/../.env"
    TEMPLATE_FILE="${TOPDIR}/../files/wifi.psk"
    if [ -f "$ENV_FILE" ]; then
        . "$ENV_FILE"
    else
        bbfatal "Credential file .env not found in project root."
    fi
    if [ -z "$WIFI_SSID" ] || [ -z "$WIFI_PASSWORD" ]; then
        bbfatal "WIFI_SSID or WIFI_PASSWORD not defined in .env"
    fi
    install -d ${IMAGE_ROOTFS}/var/lib/iwd
    install -d ${IMAGE_ROOTFS}/etc/iwd
    install -m 644 ${TOPDIR}/../files/main.conf ${IMAGE_ROOTFS}/etc/iwd/main.conf
    sed "s/PLACEHOLDER_PASSWORD/${WIFI_PASSWORD}/g" "$TEMPLATE_FILE" > ${IMAGE_ROOTFS}/var/lib/iwd/"${WIFI_SSID}.psk"
    chmod 600 ${IMAGE_ROOTFS}/var/lib/iwd/"${WIFI_SSID}.psk"
}
ROOTFS_POSTPROCESS_COMMAND += "inject_iwd_config;"
