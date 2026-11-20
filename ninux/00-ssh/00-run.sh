#!/bin/bash -e
# Install pi-gen's configured first-user SSH key for root as well.
# pi-gen stage2 installs PUBKEY_SSH_FIRST_USER for FIRST_USER_NAME itself.

: "${ROOTFS_DIR:?ROOTFS_DIR is not set by pi-gen}"

KEY="${PUBKEY_SSH_FIRST_USER:-}"
if [ -z "$KEY" ]; then
  echo "ninux: PUBKEY_SSH_FIRST_USER is empty; skipping root authorized_keys"
  exit 0
fi

# Keep authorized_keys to exactly one public-key line; reject accidental multiline input.
if [[ "$KEY" == *$'\n'* || "$KEY" == *$'\r'* ]]; then
  echo "PUBKEY_SSH_FIRST_USER must contain one SSH public key on a single line" >&2
  exit 1
fi

read -r KEY_TYPE KEY_DATA _ <<< "$KEY"
case "$KEY_TYPE" in
  ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|sk-ssh-ed25519@openssh.com|sk-ecdsa-sha2-nistp256@openssh.com)
    ;;
  *)
    echo "Unsupported or invalid SSH public-key type: ${KEY_TYPE:-<empty>}" >&2
    exit 1
    ;;
esac
if [ -z "$KEY_DATA" ] || ! printf '%s' "$KEY_DATA" | base64 -d >/dev/null 2>&1; then
  echo "PUBKEY_SSH_FIRST_USER does not look like a valid SSH public key" >&2
  exit 1
fi

install -d -m 0700 "$ROOTFS_DIR/root/.ssh"
printf '%s\n' "$KEY" > "$ROOTFS_DIR/root/.ssh/authorized_keys"
chmod 0600 "$ROOTFS_DIR/root/.ssh/authorized_keys"
chown 0:0 "$ROOTFS_DIR/root/.ssh" "$ROOTFS_DIR/root/.ssh/authorized_keys"

echo "ninux: installed PUBKEY_SSH_FIRST_USER for root (pi-gen installs it for FIRST_USER_NAME in stage2)"
