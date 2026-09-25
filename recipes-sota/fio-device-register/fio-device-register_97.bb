SUMMARY = "Linux microPlatform OSF OTA+ device registration tool"
HOMEPAGE = "https://github.com/foundriesio/lmp-device-register"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://COPYING.MIT;md5=838c366f69b72c5df05c96dff79b35f2"

DEPENDS = "boost curl glib-2.0 openssl"

SRCREV = "d8f39a6d95e20f5b64881ae014381682aa1c7aad"
PV = "97+git"

SRC_URI = "git://github.com/foundriesio/lmp-device-register.git;protocol=https;branch=main"

FIO_DEVICE_API ?= "https://api.foundries.io/ota/devices/"
FIO_OAUTH_API ?= "https://app.foundries.io/oauth"

PACKAGECONFIG ?= "${@bb.utils.contains('COMPOSE_APP_MANAGER', 'composectl', 'composeapp', '', d)} pkcs11"
PACKAGECONFIG[composeapp] = "-DDOCKER_COMPOSE_APP=ON,-DDOCKER_COMPOSE_APP=OFF,"
PACKAGECONFIG[production] = "-DPRODUCTION=ON,-DPRODUCTION=OFF,"
PACKAGECONFIG[pkcs11]     = "-DDISABLE_PKCS11=OFF,-DDISABLE_PKCS11=ON,libp11"

inherit cmake pkgconfig

RDEPENDS:${PN} += "${@d.getVar('SOTA_CLIENT') or ''}"

EXTRA_OECMAKE += "\
    -DGIT_COMMIT=${SRCREV} \
    -DHARDWARE_ID=${MACHINE} \
    -DDEVICE_API=${FIO_DEVICE_API} \
    -DOAUTH_API=${FIO_OAUTH_API} \
"

# Upstream falls back to "aktualizr-lite" while the define is absent.
EXTRA_OECMAKE += "${@'-DSOTA_CLIENT=' + d.getVar('SOTA_CLIENT') if d.getVar('SOTA_CLIENT') else ''}"

do_install:append() {
    mv ${D}${bindir}/lmp-device-register ${D}${bindir}/fio-device-register
}
