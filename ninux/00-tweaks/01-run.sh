#!/bin/bash -e

install -v -d					"${ROOTFS_DIR}/etc/wpa_supplicant"
install -v -m 600 files/wpa_supplicant.conf	"${ROOTFS_DIR}/etc/wpa_supplicant/"

install -v -m 744 files/static-ip.sh            "${ROOTFS_DIR}/root/"
install -v -m 744 files/disable-wifi.sh         "${ROOTFS_DIR}/root/"

install -v -m 440 files/010_ninux-nopasswd "${ROOTFS_DIR}/etc/sudoers.d/"

# Append the team keys instead of replacing the file: stage2 already wrote
# PUBKEY_SSH_FIRST_USER there, and sshd_config disables password logins.
install -v -m 0700 -o 1000 -g 1000 -d "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.ssh"
install -v -m 0700 -d "${ROOTFS_DIR}/root/.ssh"
for AUTH_KEYS in "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.ssh/authorized_keys" \
		 "${ROOTFS_DIR}/root/.ssh/authorized_keys"; do
	touch "${AUTH_KEYS}"
	while read -r KEY; do
		if [ -n "${KEY}" ]; then
			grep -qxF "${KEY}" "${AUTH_KEYS}" || echo "${KEY}" >> "${AUTH_KEYS}"
		fi
	done < files/authorized_keys
	chmod 0600 "${AUTH_KEYS}"
done
chown 1000:1000 "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.ssh/authorized_keys"

install -m 600 files/sshd_config "${ROOTFS_DIR}/etc/ssh/sshd_config"

install -m 644 files/bashrc "${ROOTFS_DIR}/etc/bash.bashrc"
install -m 644 files/bashrc "${ROOTFS_DIR}/etc/skel/.bashrc"
# ${FIRST_USER_NAME} was already created in stage1 from the stock skel, so its
# ~/.bashrc would be sourced after /etc/bash.bashrc and reset PS1/aliases.
install -m 644 -o 1000 -g 1000 files/bashrc "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.bashrc"
install -m 644 files/bashrc "${ROOTFS_DIR}/root/.bashrc"
install -m 644 files/system.vimrc "${ROOTFS_DIR}/etc/vim/vimrc"
install -m 755 files/up2date "${ROOTFS_DIR}/usr/local/bin/up2date"
install -m 644 files/motd "${ROOTFS_DIR}/etc/motd"

on_chroot << EOF
	SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_boot_wait 0
EOF

if [ -v WPA_COUNTRY ]; then
	echo "country=${WPA_COUNTRY}" >> "${ROOTFS_DIR}/etc/wpa_supplicant/wpa_supplicant.conf"
fi

if [ -v WPA_ESSID ] && [ -v WPA_PASSWORD ]; then
on_chroot <<EOF
set -o pipefail
wpa_passphrase "${WPA_ESSID}" "${WPA_PASSWORD}" | tee -a "/etc/wpa_supplicant/wpa_supplicant.conf"
EOF
elif [ -v WPA_ESSID ]; then
cat >> "${ROOTFS_DIR}/etc/wpa_supplicant/wpa_supplicant.conf" << EOL

network={
	ssid="${WPA_ESSID}"
	key_mgmt=NONE
}
EOL
fi

# Disable wifi on 5GHz models if WPA_COUNTRY is not set
mkdir -p "${ROOTFS_DIR}/var/lib/systemd/rfkill/"
if [ -n "$WPA_COUNTRY" ]; then
    echo 0 > "${ROOTFS_DIR}/var/lib/systemd/rfkill/platform-3f300000.mmcnr:wlan"
    echo 0 > "${ROOTFS_DIR}/var/lib/systemd/rfkill/platform-fe300000.mmcnr:wlan"
else
    echo 1 > "${ROOTFS_DIR}/var/lib/systemd/rfkill/platform-3f300000.mmcnr:wlan"
    echo 1 > "${ROOTFS_DIR}/var/lib/systemd/rfkill/platform-fe300000.mmcnr:wlan"
fi
