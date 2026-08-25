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

RAUC_KEY_FILE ?= "${LAYERDIR_meta-local}/../keys/ca.key.pem"
RAUC_CERT_FILE ?= "${LAYERDIR_meta-local}/../keys/ca.cert.pem"

python __anonymous() {
    import os

    for variable in ("RAUC_KEY_FILE", "RAUC_CERT_FILE"):
        file_path = d.expand(d.getVar(variable) or "")
        if not os.path.isfile(file_path):
            bb.fatal("%s is missing: %s" % (variable, file_path or "<unset>"))
}
