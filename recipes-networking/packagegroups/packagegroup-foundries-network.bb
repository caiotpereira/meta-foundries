SUMMARY = "Foundries.io networking components"
LICENSE = "MIT"

inherit packagegroup

RDEPENDS:${PN} = "\
    networkmanager \
    networkmanager-nmcli \
    wireless-regdb-static \
"
