#!/bin/bash -e
# Copyright (c) 2024 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: MIT

if [ -z $1 ] || [ -z $2 ] ; then
    echo "The REPO_DIR or WORK_DIR is empty and it needs to point to the corresponding directories."
    echo "Please run it with:"
    echo " $0 REPO_DIR WORK_DIR"
    exit 1
fi

REPO_DIR="$1"
WORK_DIR="$2"

_is_dir(){
    test -d "$1" && return
    echo "The '$1' is not a directory."
    exit 1
}

_is_dir "$REPO_DIR"
_is_dir "$WORK_DIR"

# Creates a temporary build directory to run the yocto-check-layer
# script to avoid a contaminated environment.
BUILDDIR="$(mktemp -p $WORK_DIR -d -t build-yocto-check-layer-XXXX)"
source $WORK_DIR/openembedded-core/oe-init-build-env $BUILDDIR
# Layer conformance parses without a sota distro; the builds run the checks.
echo 'FOUNDRIES_SANITY_SKIP = "1"' >> conf/local.conf
git -c advice.detachedHead=false -c init.defaultBranch=main clone --quiet --shared $REPO_DIR meta-foundries

# Yocto Project layer checking tool
CMD="yocto-check-layer"
# Layer to check
CMD="$CMD meta-foundries"
# Disable auto layer discovery
CMD="$CMD --no-auto"
# Layers to process for dependencies. meta-foundries pulls the OTA client
# from meta-updater (sota), which in turn wants meta-python and
# meta-filesystems, so make them all available alongside core.
CMD="$CMD --dependency $WORK_DIR/openembedded-core/meta"
CMD="$CMD $WORK_DIR/meta-openembedded/meta-oe"
CMD="$CMD $WORK_DIR/meta-openembedded/meta-python"
CMD="$CMD $WORK_DIR/meta-openembedded/meta-filesystems"
CMD="$CMD $WORK_DIR/meta-openembedded/meta-networking"
CMD="$CMD $WORK_DIR/meta-updater"
CMD="$CMD --additional-layers $WORK_DIR/meta-virtualization"
# Disable automatic testing of dependencies
CMD="$CMD --no-auto-dependency"
# Set machines to all machines defined in this layer, if any. meta-foundries is
# a software layer and normally ships no conf/machine/, so only pass --machines
# when machine configs actually exist.
if [ -d meta-foundries/conf/machine ]; then
    MACHINES="$(find meta-foundries/conf/machine/ -maxdepth 1 -name '*.conf' -exec basename {} .conf \;)"
    if [ -n "$MACHINES" ]; then
        CMD="$CMD --machines $(echo $MACHINES)"
    fi
fi

exec $CMD
