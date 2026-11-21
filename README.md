# Raspberry Pi OS Ninux

A customized Raspberry Pi OS image for the Ninux community, based on the official [Raspberry Pi pi-gen](https://github.com/RPi-Distro/pi-gen) build system.

The project provides a custom Ninux stage, SSH access configuration, post-installation network configuration and automated image builds through GitHub Actions.

## Features

- Based on Raspberry Pi OS Trixie.
- Custom Ninux stage (`ninux/`).
- SSH server enabled.
- SSH public key installed for both `root` and the first user.
- Default network configuration preserved (DHCP).
- Interactive network configuration utility.
- Local and Docker-based build scripts.
- Automated builds and GitHub Releases.

## Supported hardware

The image is intended primarily for:

- Raspberry Pi 3 Model B
- Raspberry Pi 3 Model B+

Other Raspberry Pi models may work depending on the selected pi-gen configuration.

## Repository structure

```text
.
├── config
├── config.example
├── build.sh
├── build-ninux.sh
├── build-docker-ninux.sh
├── ninux/
│   └── 00-configure-ninux/
├── stage0/
├── stage1/
├── stage2/
└── .github/
    └── workflows/
        └── release.yml
```

The upstream pi-gen build system is kept as the foundation. Ninux-specific customizations are isolated in the `ninux/` stage and the dedicated build scripts.

## Configuration

Create or edit the `config` file in the repository root.

Example:

```bash
IMG_NAME='raspios-ninux'
RELEASE='trixie'
ENABLE_CLOUD_INIT=0

FIRST_USER_NAME='ninux'
FIRST_USER_PASS='CHANGE_THIS_PASSWORD'

STAGE_LIST="stage0 stage1 stage2 ninux"

ENABLE_SSH=1
PUBKEY_ONLY_SSH=0
```

The SSH public key is configured through `PUBKEY_SSH_FIRST_USER`.

**Important:** change the initial user password before deploying the image. Never commit private SSH keys or other secrets.

For a minimal image, adjust `STAGE_LIST` to include only the standard stages required for the selected build, followed by `ninux`.

## Building locally

On a Debian-based build machine, install the dependencies required by pi-gen.

Start the Ninux build with:

```bash
./build-ninux.sh
```

The script runs the official `build.sh` engine while temporarily selecting the Ninux stage as the image export source. Upstream stage files are not permanently modified.

The generated images are placed in:

```text
deploy/
```

## Building with Docker

Docker is required for this method.

Run:

```bash
./build-docker-ninux.sh
```

This uses the Ninux-specific Docker launcher and keeps the upstream `build-docker.sh` unchanged.

## Network configuration

The image retains the default DHCP configuration.

After flashing and booting the Raspberry Pi, configure a static IP address interactively:

```bash
sudo /root/ninux-configure-network
```

To restore DHCP:

```bash
sudo /root/ninux-configure-network --dhcp
```

The utility uses NetworkManager (`nmcli`) and is executed manually after installation. The build does not change the default network configuration.

## Automated builds and releases

GitHub Actions is configured in:

```text
.github/workflows/release.yml
```

There are two supported triggers:

| Trigger | Action |
|---|---|
| Manual `workflow_dispatch` | Builds the image and uploads an artifact |
| Push of a version tag (`v*`) | Builds the image and publishes a GitHub Release |

For example, to publish a new version:

```bash
git tag -a v1.0.1 -m "Ninux v1.0.1"
git push origin v1.0.1
```

The workflow automatically:

1. Checks out the repository.
2. Installs the pi-gen build dependencies.
3. Configures ARM emulation.
4. Builds the Ninux image.
5. Generates SHA256 checksums.
6. Uploads the build artifacts.
7. Publishes a GitHub Release when triggered by a version tag.

Manual builds do not publish a release.

## Download

Released images are available in the repository's [GitHub Releases](https://github.com/mikysal78/pi-gen-ninux/releases).

Each release includes the compressed image and its SHA256 checksum.

## Credits

- [RPi-Distro/pi-gen](https://github.com/RPi-Distro/pi-gen) — Raspberry Pi OS image build system.
- [Ninux](https://www.ninux.org/) — Community wireless network project.

## License

See the upstream pi-gen license and the license notices included in this repository.
