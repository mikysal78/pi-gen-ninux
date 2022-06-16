#!/bin/bash
clear
echo "IP Address CIDR (es: 10.27.22.5/24):"
read CIDR

echo "hostname" > /etc/dhcpcd.conf
echo "clientid" >> /etc/dhcpcd.conf
echo "persistent" >> /etc/dhcpcd.conf
echo "option rapid_commit" >> /etc/dhcpcd.conf
echo "option domain_name_servers, domain_name, domain_search, host_name" >> /etc/dhcpcd.conf
echo "option classless_static_routes" >> /etc/dhcpcd.conf
echo "option ntp_servers" >> /etc/dhcpcd.conf
echo "option interface_mtu" >> /etc/dhcpcd.conf
echo "require dhcp_server_identifier" >> /etc/dhcpcd.conf
echo "slaac private" >> /etc/dhcpcd.conf
echo " " >> /etc/dhcpcd.conf
echo "interface eth0" >> /etc/dhcpcd.conf
echo "static ip_address="$CIDR >> /etc/dhcpcd.conf
ip route | grep default | awk '{print "static routers="$3}' >> /etc/dhcpcd.conf
awk '/nameserver/{dns=dns" "$2} END {sub(/^ */,"",dns); print "static domain_name_servers="dns}' < /etc/resolv.conf >> /etc/dhcpcd.conf
