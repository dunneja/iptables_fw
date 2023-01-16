#!/bin/bash

echo "-------------------------------------"
echo "IPTables Firewall Script Installation"
echo "-------------------------------------"

echo "Copying firewall.start to systemd"
cp firewall.service /etc/systemd/system/

echo "Making /etc/firewall/ directory"
if [ ! -d /etc/firewall ]; then
  mkdir -p /etc/firewall;
fi

echo "Copying firewall.stop to /etc/firewall/"
cp firewall.stop /etc/firewall/

echo "Copying firewall.sh to /etc/firewall/"
cp firewall.sh /etc/firewall/

echo "Enabling the systemd firewall.service at boot"
systemctl enable firewall
sleep 3

echo "Starting the systemd firewall.service"
systemctl start firewall

echo "Finished installation of IPTables Firewall"

echo "-------------------------------------"
echo "IPTables Logging Config Setup        "
echo "-------------------------------------"

echo "Making /var/log/iptables directory"

if [ ! -d /var/log/iptables ]; then
  mkdir -p /var/log/iptables;
fi

echo "Setting /var/log/iptables ownership"
chown syslog:adm /var/log/iptables

echo "Copying 10-iptables.conf to /etc/rsyslog.d/"
cp 10-iptables.conf /etc/rsyslog.d

echo "Restarting rsyslog.d Service"
systemctl restart rsyslog.service

echo "Finished installation of IPTables Logging"
