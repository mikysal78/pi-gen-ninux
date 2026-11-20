
#!/bin/bash -e

# Ninux customizations are deliberately isolated in the top-level "ninux" stage.
# The image keeps the distribution's default DHCP configuration.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# SSH configuration is controlled by the main pi-gen config.
if [ "${ENABLE_SSH:-0}" = "1" ]; then

    if [ -z "${PUBKEY_SSH_FIRST_USER:-}" ]; then
        echo "Ninux: ENABLE_SSH=1 ma PUBKEY_SSH_FIRST_USER non è impostata." >&2
        exit 1
    fi

    # Install public key for root.
    install -d -m 700 "${ROOTFS_DIR}/root/.ssh"
    printf '%s\n' "${PUBKEY_SSH_FIRST_USER}" \
        > "${ROOTFS_DIR}/root/.ssh/authorized_keys"
    chmod 600 "${ROOTFS_DIR}/root/.ssh/authorized_keys"
    chown -R 0:0 "${ROOTFS_DIR}/root/.ssh"

    # Install the same public key for the first user.
    if [ -n "${FIRST_USER_NAME:-}" ]; then
        USER_HOME="${ROOTFS_DIR}/home/${FIRST_USER_NAME}"

        if [ ! -d "${USER_HOME}" ]; then
            echo "Ninux: home dell'utente ${FIRST_USER_NAME} non trovata." >&2
            exit 1
        fi

        # Verify that the user exists inside the target image.
        if ! chroot "${ROOTFS_DIR}" id "${FIRST_USER_NAME}" >/dev/null 2>&1; then
            echo "Ninux: utente ${FIRST_USER_NAME} non trovato nel rootfs." >&2
            exit 1
        fi

        install -d -m 700 "${USER_HOME}/.ssh"
        printf '%s\n' "${PUBKEY_SSH_FIRST_USER}" \
            > "${USER_HOME}/.ssh/authorized_keys"
        chmod 600 "${USER_HOME}/.ssh/authorized_keys"

        # Change ownership inside the image, not on the build host.
        chroot "${ROOTFS_DIR}" chown -R \
            "${FIRST_USER_NAME}:${FIRST_USER_NAME}" \
            "/home/${FIRST_USER_NAME}/.ssh"
    else
        echo "Ninux: FIRST_USER_NAME non impostata; chiave installata soltanto per root." >&2
    fi

    # Enable SSH at first boot.
    if [ -e "${ROOTFS_DIR}/lib/systemd/system/ssh.service" ]; then
        SSH_SERVICE="/lib/systemd/system/ssh.service"
    elif [ -e "${ROOTFS_DIR}/usr/lib/systemd/system/ssh.service" ]; then
        SSH_SERVICE="/usr/lib/systemd/system/ssh.service"
    else
        echo "Ninux: ssh.service non trovato nel rootfs." >&2
        exit 1
    fi

    install -d "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants"
    ln -sfn "${SSH_SERVICE}" \
        "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants/ssh.service"

    # Disable SSH password authentication only when explicitly requested.
    if [ "${PUBKEY_ONLY_SSH:-0}" = "1" ]; then
        install -d "${ROOTFS_DIR}/etc/ssh/sshd_config.d"

        cat > "${ROOTFS_DIR}/etc/ssh/sshd_config.d/00-ninux-pubkey-only.conf" <<'EOF'
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
EOF
    fi
fi

# Install the post-installation network configuration utility.
install -D -m 0755 \
    "${SCRIPT_DIR}/files/ninux-configure-network" \
    "${ROOTFS_DIR}/root/ninux-configure-network"

echo "Ninux: configurazione completata."

