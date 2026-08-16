SUMMARY = "Minimal MCP (Model Context Protocol) Diagnostic Server"
DESCRIPTION = "Lightweight C-based MCP server running JSON-RPC 2.0 over stdio for remote runtime diagnostics."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://yocto-mcp.c;subdir=sources \
           file://Makefile;subdir=sources"

S = "${UNPACKDIR}/sources"

do_compile() {
    oe_runmake -C ${S}
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/yocto-mcp ${D}${bindir}/yocto-mcp
}

FILES:${PN} = "${bindir}/yocto-mcp"
