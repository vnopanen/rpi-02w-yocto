FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://authorized_keys \
    file://dropbear.default \
"

do_install:append() {
    install -d -m 0700 ${D}${ROOT_HOME}/.ssh
    install -m 0600 ${UNPACKDIR}/authorized_keys ${D}${ROOT_HOME}/.ssh/authorized_keys
    install -m 0644 ${UNPACKDIR}/dropbear.default ${D}${sysconfdir}/default/dropbear
}

FILES:${PN} += "${ROOT_HOME}/.ssh ${ROOT_HOME}/.ssh/authorized_keys"

