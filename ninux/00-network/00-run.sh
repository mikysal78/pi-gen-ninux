#!/bin/bash -e
# pi-gen host-side stage script: writes network config into ROOTFS_DIR.

: "${ROOTFS_DIR:?ROOTFS_DIR is not set by pi-gen}"

IFACE="${NINUX_NET_IFACE:-eth0}"
MODE="${NINUX_NET_MODE:-static}"
ADDRESS="${NINUX_NET_ADDRESS:-10.27.22.50/24}"
GATEWAY="${NINUX_NET_GATEWAY:-10.27.22.1}"
DNS="${NINUX_NET_DNS:-1.1.1.1 8.8.8.8}"

case "$IFACE" in
  ''|*[!a-zA-Z0-9_.:-]*) echo "Invalid NINUX_NET_IFACE: $IFACE" >&2; exit 1 ;;
esac
case "$MODE" in
  static|dhcp) ;;
  *) echo "NINUX_NET_MODE must be 'static' or 'dhcp' (got '$MODE')" >&2; exit 1 ;;
esac

python3 - "$MODE" "$ADDRESS" "$GATEWAY" "$DNS" <<'PY'
import ipaddress, sys
mode, address, gateway, dns = sys.argv[1:]
if mode == "static":
    iface = ipaddress.ip_interface(address)
    gw = ipaddress.ip_address(gateway)
    if iface.version != 4 or gw.version != 4 or gw not in iface.network:
        raise SystemExit("Invalid static IPv4 address/gateway combination")
for server in dns.split():
    if ipaddress.ip_address(server).version != 4:
        raise SystemExit(f"DNS server must be IPv4: {server}")
PY

mkdir -p "$ROOTFS_DIR/etc/network/interfaces.d" \
         "$ROOTFS_DIR/etc/resolvconf/resolv.conf.d" \
         "$ROOTFS_DIR/etc/systemd/network" \
         "$ROOTFS_DIR/etc/NetworkManager/conf.d" \
         "$ROOTFS_DIR/etc/cloud/cloud.cfg.d"

if [ -e "$ROOTFS_DIR/etc/network/interfaces" ] && [ ! -e "$ROOTFS_DIR/etc/network/interfaces.pre-ninux" ]; then
  cp -a "$ROOTFS_DIR/etc/network/interfaces" "$ROOTFS_DIR/etc/network/interfaces.pre-ninux"
fi
cat > "$ROOTFS_DIR/etc/network/interfaces" <<'EOF_INTERFACES'
# Managed by pi-gen ninux.
auto lo
iface lo inet loopback

source-directory /etc/network/interfaces.d
EOF_INTERFACES

if [ "$MODE" = "static" ]; then
  PREFIX="${ADDRESS#*/}"
  IP="${ADDRESS%/*}"
  NETMASK="$(python3 - "$PREFIX" <<'PY'
import ipaddress, sys
print(ipaddress.IPv4Network('0.0.0.0/' + sys.argv[1]).netmask)
PY
)"
  cat > "$ROOTFS_DIR/etc/network/interfaces.d/$IFACE" <<EOF_IFACE
# Managed by pi-gen ninux.
auto $IFACE
iface $IFACE inet static
    address $IP
    netmask $NETMASK
    gateway $GATEWAY
    dns-nameservers $DNS
EOF_IFACE
else
  cat > "$ROOTFS_DIR/etc/network/interfaces.d/$IFACE" <<EOF_IFACE
# Managed by pi-gen ninux.
auto $IFACE
iface $IFACE inet dhcp
EOF_IFACE
fi

printf '%s\n' "$DNS" | tr ' ' '\n' | sed '/^$/d; s/^/nameserver /' > "$ROOTFS_DIR/etc/resolvconf/resolv.conf.d/head"

# Prevent cloud-init from replacing ifupdown configuration on first boot.
cat > "$ROOTFS_DIR/etc/cloud/cloud.cfg.d/99-ninux-disable-network-config.cfg" <<'EOF_CLOUD'
network: {config: disabled}
EOF_CLOUD

# Keep NetworkManager available for Wi-Fi/other devices, but exclude this interface.
cat > "$ROOTFS_DIR/etc/NetworkManager/conf.d/90-ninux-ifupdown.conf" <<EOF_NM
[keyfile]
unmanaged-devices=interface-name:$IFACE
EOF_NM

# If dhcpcd is installed by a later stage, it must not take over this interface.
mkdir -p "$ROOTFS_DIR/etc"
if [ ! -f "$ROOTFS_DIR/etc/dhcpcd.conf" ]; then
  : > "$ROOTFS_DIR/etc/dhcpcd.conf"
fi
if ! grep -Eq "^[[:space:]]*denyinterfaces[[:space:]].*\\b${IFACE}\\b" "$ROOTFS_DIR/etc/dhcpcd.conf"; then
  printf '\n# Managed by pi-gen ninux\ndenyinterfaces %s\n' "$IFACE" >> "$ROOTFS_DIR/etc/dhcpcd.conf"
fi

# systemd-networkd must ignore this link if it is installed/enabled later.
cat > "$ROOTFS_DIR/etc/systemd/network/00-ninux-${IFACE}-unmanaged.network" <<EOF_NETWORKD
[Match]
Name=$IFACE

[Link]
Unmanaged=yes
EOF_NETWORKD

# Enable ifupdown networking in the target rootfs.
mkdir -p "$ROOTFS_DIR/etc/systemd/system/multi-user.target.wants"
if [ -e "$ROOTFS_DIR/usr/lib/systemd/system/networking.service" ]; then
  ln -sf /usr/lib/systemd/system/networking.service \
    "$ROOTFS_DIR/etc/systemd/system/multi-user.target.wants/networking.service"
elif [ -e "$ROOTFS_DIR/lib/systemd/system/networking.service" ]; then
  ln -sf /lib/systemd/system/networking.service \
    "$ROOTFS_DIR/etc/systemd/system/multi-user.target.wants/networking.service"
fi

echo "ninux: configured $IFACE mode=$MODE address=$ADDRESS gateway=$GATEWAY DNS='$DNS'"
