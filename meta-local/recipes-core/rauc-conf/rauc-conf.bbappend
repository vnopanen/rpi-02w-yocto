FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://system.conf \
    file://ca.cert.pem \
"

RAUC_KEYRING_FILE = "ca.cert.pem"

python __anonymous() {
    import os

    cert_file = d.expand("${THISDIR}/files/ca.cert.pem")
    if not os.path.isfile(cert_file):
        bb.fatal("RAUC certificate is missing: %s" % cert_file)
}
