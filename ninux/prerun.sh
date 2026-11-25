#!/bin/bash -e

# Keep the previous pi-gen rootfs and add only Ninux customizations.
if [ ! -d "${ROOTFS_DIR}" ]; then
    copy_previous
fi
