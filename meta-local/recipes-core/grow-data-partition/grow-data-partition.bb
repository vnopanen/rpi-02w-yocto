SUMMARY = "Grow the data partition on first boot"
DESCRIPTION = "Resize the fourth Raspberry Pi partition and its ext4 filesystem to use trailing device space."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit update-rc.d

SRC_URI = "file://grow-data-partition"

S = "${UNPACKDIR}"

RDEPENDS:${PN} = "parted e2fsprogs-resize2fs"

INITSCRIPT_NAME = "grow-data-partition"
INITSCRIPT_PARAMS = "defaults 98 20"

do_install() {
    install -D -m 0755 ${UNPACKDIR}/grow-data-partition \
        ${D}${sysconfdir}/init.d/grow-data-partition
}
