FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://dockerd-daemon-use-default-system-config-when-none-i.patch;patchdir=src/import \
    file://tarexport-Optimize-image-loading-on-local-host.patch;patchdir=src/import \
    file://daemon.json \
"

do_install:append() {
    install -d ${D}${libdir}/docker
    install -m 0644 ${UNPACKDIR}/daemon.json ${D}${libdir}/docker/daemon.json
}

FILES:${PN} += "${libdir}/docker/daemon.json"
