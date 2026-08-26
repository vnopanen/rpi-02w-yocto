SUMMARY = "RAUC update bundle for Raspberry Pi 0 2W"
DESCRIPTION = "Minimal RAUC update bundle recipe for Raspberry Pi 0 2W"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit bundle

RAUC_BUNDLE_FORMAT = "verity"
RAUC_BUNDLE_COMPATIBLE = "raspberrypi0-2w-64"

RAUC_BUNDLE_SLOTS = "rootfs"
RAUC_SLOT_rootfs = "core-image-minimal"
RAUC_SLOT_rootfs[type] = "image"
RAUC_SLOT_rootfs[fstype] = "ext4"

RAUC_KEY_FILE ?= "${TOPDIR}/../keys/ca.key.pem"
RAUC_CERT_FILE ?= "${TOPDIR}/../keys/ca.cert.pem"

do_bundle:prepend() {
    if [ -z "${RAUC_KEY_FILE}" ] || [ ! -f "${RAUC_KEY_FILE}" ]; then
        bbfatal "RAUC_KEY_FILE is missing: ${RAUC_KEY_FILE}"
    fi

    if [ -z "${RAUC_CERT_FILE}" ] || [ ! -f "${RAUC_CERT_FILE}" ]; then
        bbfatal "RAUC_CERT_FILE is missing: ${RAUC_CERT_FILE}"
    fi
}
