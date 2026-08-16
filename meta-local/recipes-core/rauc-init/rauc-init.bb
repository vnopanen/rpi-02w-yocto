SUMMARY = "SysVinit integration for the RAUC update service"
DESCRIPTION = "Starts the RAUC D-Bus service and marks the running slot good after the shared data partition is mounted."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit update-rc.d

SRC_URI = "file://rauc-init"

S = "${UNPACKDIR}"

RDEPENDS:${PN} = "rauc dbus"

INITSCRIPT_NAME = "rauc"
INITSCRIPT_PARAMS = "defaults 99 20"

do_install() {
    install -D -m 0755 ${UNPACKDIR}/rauc-init ${D}${sysconfdir}/init.d/rauc
}
