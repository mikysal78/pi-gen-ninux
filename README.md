# Ninux stage for the official RPi-Distro/pi-gen

This overlay adds a real top-level pi-gen stage named **`stage1-ninux`** to a
clean clone of the official `RPi-Distro/pi-gen` repository.

It is deliberately placed between `stage1` and `stage2`: the stage inherits
the previous root filesystem using the same `copy_previous` pattern as the
official stages. This ensures its network configuration is carried into the
Lite image exported from stage2 and all later images.

## Contents

```text
stage1-ninux/
├── prerun.sh
└── 00-network/
    ├── 00-packages
    └── 00-run.sh
```

## What it does

- Installs `ifupdown` and `resolvconf` into the target image.
- Configures the selected interface in `/etc/network/interfaces` and
  `/etc/network/interfaces.d/<interface>`.
- Supports static IPv4 and DHCP modes.
- Leaves NetworkManager available for other interfaces, while marking the
  selected interface unmanaged by NetworkManager.
- Adds a `denyinterfaces` rule for dhcpcd, if it is present now or installed
  by a later stage.
- Adds a systemd-networkd `Unmanaged=yes` match for the selected interface.
- Disables cloud-init network reconfiguration in the target image.
- Enables the SSH server when `ENABLE_SSH=1` is set in the config.
- Uses pi-gen's `PUBKEY_SSH_FIRST_USER` setting for the normal first user and
  installs the same public key in `/root/.ssh/authorized_keys` with secure
  ownership and permissions.

## Install

Clone the official repository and copy the `stage1-ninux/` directory into its
root, alongside `stage0/`, `stage1/`, `stage2/`, etc. Append the contents of
`config-snippet.sh` to the existing `config` file (do not replace the rest of
your configuration).

The default `STAGE_LIST='stage*'` automatically discovers `stage1-ninux` and
runs it after `stage1`, before `stage2`. If you set `STAGE_LIST` explicitly,
include `stage1-ninux` between `stage1` and `stage2`.

For a 64-bit build, use the official `arm64` branch. The official `master`
branch builds 32-bit images.

## Configuration defaults

- Interface: `eth0`
- Mode: `static`
- Address: `10.27.22.50/24`
- Gateway: `10.27.22.1`
- DNS: `1.1.1.1 8.8.8.8`
- SSH server: enabled (`ENABLE_SSH=1`)
- SSH public key: configured in `config-snippet.sh` and installed for both the first user and root

**Important:** change the static address for each Raspberry Pi. Do not deploy
multiple devices with the same IP. To use DHCP instead, set
`NINUX_NET_MODE='dhcp'` in `config`. The supplied public key is already configured in `config-snippet.sh` as
`PUBKEY_SSH_FIRST_USER` and exported so the custom stage can read it. pi-gen
installs it for `FIRST_USER_NAME`; this Ninux stage installs the same key for
root. Replace that value only if you later want to rotate the key.
The default `PUBKEY_ONLY_SSH=0` leaves password authentication available. Set
it to `1` only after verifying that the public key works, to disable SSH
password authentication.

`ENABLE_CLOUD_INIT=0` is required so pi-gen does not install/configure its
optional cloud-init and Netplan network setup.

## Build

Run the normal official pi-gen build command from the repository root:

```bash
sudo ./build.sh
```

This overlay has been checked with `bash -n` and its static/DHCP configuration
generation has been exercised against a temporary root filesystem. A complete
pi-gen image build and boot test have not yet been performed.
