#!/bin/bash
set -e

if [ "$(id -u)" != "0" ]; then
	echo "Run this script as root" >&2
	exit 1
fi

clear
echo "IP Address CIDR (es: 10.27.22.5/24):"
read -r CIDR

if ! [[ "${CIDR}" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]]; then
	echo "Invalid CIDR: '${CIDR}' (expected a.b.c.d/nn), nothing changed" >&2
	exit 1
fi

ROUTERS="$(ip route show default | awk 'NR==1 {print $3}')"
if [ -z "${ROUTERS}" ]; then
	echo "No default route found, gateway not configured" >&2
fi

DNS="$(awk '/^nameserver/ {dns=dns" "$2} END {sub(/^ */,"",dns); print dns}' /etc/resolv.conf)"

if [ -f /etc/dhcpcd.conf ]; then
	cp -f /etc/dhcpcd.conf /etc/dhcpcd.conf.bak
fi

{
	echo "hostname"
	echo "clientid"
	echo "persistent"
	echo "option rapid_commit"
	echo "option domain_name_servers, domain_name, domain_search, host_name"
	echo "option classless_static_routes"
	echo "option ntp_servers"
	echo "option interface_mtu"
	echo "require dhcp_server_identifier"
	echo "slaac private"
	echo " "
	echo "interface eth0"
	echo "static ip_address=${CIDR}"
	if [ -n "${ROUTERS}" ]; then echo "static routers=${ROUTERS}"; fi
	if [ -n "${DNS}" ]; then echo "static domain_name_servers=${DNS}"; fi
} > /etc/dhcpcd.conf

echo "Written /etc/dhcpcd.conf (backup: /etc/dhcpcd.conf.bak), reboot to apply"
