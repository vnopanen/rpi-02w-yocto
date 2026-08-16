FILESEXTRAPATHS:prepend := "${LAYERDIR_meta-local}/../keys:${THISDIR}/files:"

SRC_URI:append = " \
    file://system.conf \
    file://ca.cert.pem \
"

RAUC_KEYRING_FILE = "ca.cert.pem"
