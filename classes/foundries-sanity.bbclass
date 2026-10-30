# Copyright (c) 2026 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
# Parse-time checks of the configuration meta-foundries depends on, so a bad
# value stops the build early and names the variable to fix.
#
# Errors: 'sota' missing from DISTRO_FEATURES, an empty variable listed in
# FOUNDRIES_REQUIRED_VARS, FIO_PRODUCTION_MODE defined as anything but "0"/"1".
# Warnings: a variable listed in FOUNDRIES_WARN_IF_UNSET is undefined.
#
# Enabled globally from conf/layer.conf with INHERIT += "foundries-sanity".
# FOUNDRIES_SANITY_SKIP = "1" disables the checks for bring-up builds.

FOUNDRIES_SANITY_SKIP ?= "0"

# Variables that raise an error when empty.
FOUNDRIES_REQUIRED_VARS ?= "SOTA_CLIENT COMPOSE_APP_MANAGER"

# Variables that raise a warning when undefined.
FOUNDRIES_WARN_IF_UNSET ?= "FIO_DEVICE_API FIO_OAUTH_API"

addhandler foundries_sanity_eventhandler
foundries_sanity_eventhandler[eventmask] = "bb.event.ConfigParsed"

python foundries_sanity_eventhandler() {
    d = e.data

    if d.getVar('FOUNDRIES_SANITY_SKIP') == '1':
        bb.warn("foundries-sanity: checks skipped (FOUNDRIES_SANITY_SKIP=1)")
        return

    errors = []

    if 'sota' not in (d.getVar('DISTRO_FEATURES') or '').split():
        errors.append("'sota' is missing from DISTRO_FEATURES. The distro "
                      "configuration must add it.")

    for var in (d.getVar('FOUNDRIES_REQUIRED_VARS') or '').split():
        if not (d.getVar(var) or '').strip():
            errors.append("%s is empty." % var)

    # FIO_PRODUCTION_MODE is optional; a defined value must be a valid switch.
    mode = d.getVar('FIO_PRODUCTION_MODE')
    if mode is not None and mode not in ('0', '1'):
        errors.append("FIO_PRODUCTION_MODE is '%s'; the value must be '0' or '1'." % mode)

    for var in (d.getVar('FOUNDRIES_WARN_IF_UNSET') or '').split():
        if not d.getVar(var):
            bb.warn("foundries-sanity: %s is not defined" % var)

    if errors:
        bb.fatal("foundries-sanity: configuration errors:\n  - %s"
                 % "\n  - ".join(errors))
}
