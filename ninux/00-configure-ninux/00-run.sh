#!/bin/bash -e

# Ninux customizations are deliberately isolated in the top-level "ninux" stage.
# The image keeps the distribution's default DHCP configuration.

PUBKEY_SSH_FIRST_USER='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMuoHflKC6z/hH9l5qqinpQ5gNgmFI+r9c8Xu3kHnN9s mikysal78@gmail.com'

install -d -m 700 "${ROOTFS_DIR}/root/.ssh"
printf '%s\n' "$PUBKEY_SSH_FIRST_USER" > "${ROOTFS_DIR}/root/.ssh/authorized_keys"
chmod 600 "${ROOTFS_DIR}/root/.ssh/authorized_keys"

if [ -n "${FIRST_USER_NAME:-}" ]; then
    USER_HOME="${ROOTFS_DIR}/home/${FIRST_USER_NAME}"
    if [ ! -d "$USER_HOME" ]; then
        echo "Ninux: home dell'utente ${FIRST_USER_NAME} non trovata: ${USER_HOME}" >&2
        exit 1
    fi
    install -d -m 700 "${USER_HOME}/.ssh"
    printf '%s\n' "$PUBKEY_SSH_FIRST_USER" > "${USER_HOME}/.ssh/authorized_keys"
    chmod 600 "${USER_HOME}/.ssh/authorized_keys"
    chown -R "${FIRST_USER_NAME}:${FIRST_USER_NAME}" "${USER_HOME}/.ssh"
else
    echo 'Ninux: FIRST_USER_NAME non è impostata; chiave installata soltanto per root.' >&2
fi

install -D -m 0755 files/ninux-configure-network \
    "${ROOTFS_DIR}/root/ninux-configure-network"

# Enable SSH for the first boot; do not change the network configuration.
if [ -d "${ROOTFS_DIR}/etc" ]; then
    install -d "${ROOTFS_DIR}/etc/ssh"
    install -d "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants"
    if [ -e "${ROOTFS_DIR}/lib/systemd/system/ssh.service" ]; then
        ln -sfn /lib/systemd/system/ssh.service \
            "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants/ssh.service"
    elif [ -e "${ROOTFS_DIR}/usr/lib/systemd/system/ssh.service" ]; then
        ln -sfn /usr/lib/systemd/system/ssh.service \
            "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants/ssh.service"
    fi
fi
