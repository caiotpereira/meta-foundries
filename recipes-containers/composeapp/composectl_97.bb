DESCRIPTION = "A CLI utility to manage compose apps"
HOMEPAGE = "https://github.com/foundriesio/composeapp"
SECTION = "devel"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://src/${GO_IMPORT}/LICENSE;md5=504a5c2455c8bb2fc5b7667833ab1a68"

GO_IMPORT = "github.com/foundriesio/composeapp"
GO_IMPORT_PROTO ?= "https"

PV = "97+git"
BRANCH ?= "lmp-97"
SRCREV = "0af6d7702713f36848ae569dc7a6c7f05f1d2abe"

SRC_URI = "git://${GO_IMPORT};protocol=${GO_IMPORT_PROTO};branch=${BRANCH};destsuffix=${GO_SRCURI_DESTSUFFIX}"

inherit go-mod

RDEPENDS:${PN}-dev = "make"
GO_INSTALL = "${GO_IMPORT}/cmd/composectl"

COMPOSE_APP_STORE_ROOT ?= "/var/sota/reset-apps"
COMPOSE_APP_COMPOSE_ROOT ?= "/var/sota/compose-apps"

GO_EXTRA_LDFLAGS = "\
    -X '${GO_IMPORT}/cmd/composectl/cmd.storeRoot=${COMPOSE_APP_STORE_ROOT}' \
    -X '${GO_IMPORT}/cmd/composectl/cmd.composeRoot=${COMPOSE_APP_COMPOSE_ROOT}' \
    -X '${GO_IMPORT}/cmd/composectl/cmd.commit=${SRCREV}' \
"

do_install:append() {
    cd ${D}${bindir}
    ln -sf composectl aklite-apps
}

PACKAGES =+ "${PN}-aklite-apps"

FILES:${PN} = "${bindir}/composectl"
FILES:${PN}-aklite-apps = "${bindir}/aklite-apps"

RDEPENDS:${PN}-aklite-apps = "${PN}"
