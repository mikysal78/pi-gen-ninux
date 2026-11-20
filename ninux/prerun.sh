#!/bin/bash -e

# Follow the official pi-gen stage pattern: inherit the previous stage rootfs.
if [ ! -d "${ROOTFS_DIR}" ]; then
    copy_previous
fi
