#!/usr/bin/env bash
#Ubuntu Server iptables firewall script v1.0.

#Set Variables.
iptables=/sbin/iptables
iptablessave=/sbin/iptables-save
uplink="eth0"
internal="127.0.0.1"
external="192.168.0.100"

#iptables rules.
echo -e "\e[32m*\e[0m IPTABLES Firewall Script:"
echo -e "\e[32m*\e[0m Flushing all chains, rules and setting all policies to ACCEPT..."
$iptables -F
$iptables -t nat -F
$iptables -t mangle -F
$iptables -X
$iptables -P FORWARD ACCEPT
$iptables -P INPUT   ACCEPT
$iptables -P OUTPUT  ACCEPT
echo -e "\e[32m*\e[0m Creating allowed connections chain for lo interface aswell as established & related connections..."
$iptables -N allowed-connections
$iptables -F allowed-connections
$iptables -A allowed-connections -i lo -j ACCEPT
$iptables -A allowed-connections -i $uplink -m state --state ESTABLISHED,RELATED -j ACCEPT
echo -e "\e[32m*\e[0m Creating incoming ssh traffic chain..."
$iptables -N allow-ssh-traffic
$iptables -F allow-ssh-traffic
$iptables -I allow-ssh-traffic 1 -p tcp -i $uplink -m tcp --dport 22 -m state --state NEW -m recent --set --name SSH --rsource
$iptables -I allow-ssh-traffic 2 -p tcp -i $uplink -m tcp --dport 22 -m recent --rcheck --seconds 60 --hitcount 4 --rttl --name SSH --rsource -j REJECT --reject-with tcp-reset
$iptables -I allow-ssh-traffic 3 -p tcp -i $uplink -m tcp --dport 22 -m recent --rcheck --seconds 60 --hitcount 3 --rttl --name SSH --rsource -j LOG --log-prefix "IPTABLES:BLOCKED-CONN: "
$iptables -I allow-ssh-traffic 4 -p tcp -i $uplink -m tcp --dport 22 -m recent --update --seconds 60 --hitcount 3 --rttl --name SSH --rsource -j REJECT --reject-with tcp-reset
$iptables -A allow-ssh-traffic -p tcp -i $uplink -m tcp --dport 22 -j LOG --log-prefix "IPTABLES:ALLOWED-SSH: "
$iptables -A allow-ssh-traffic -p tcp -i $uplink -m tcp --dport 22 -j ACCEPT
echo -e "\e[32m*\e[0m Creating incoming http traffic chain..."
$iptables -N allow-http-traffic
$iptables -F allow-http-traffic
$iptables -I allow-http-traffic 1 -p tcp -i $uplink --dport 80 -m state --state NEW -m recent --update --seconds 10 --hitcount 5 -j LOG --log-prefix "IPTABLES:BLOCKED-CONN: "
$iptables -I allow-http-traffic 2 -p tcp -i $uplink --dport 80 -m state --state NEW -m recent --update --seconds 10 --hitcount 5 -j DROP
$iptables -A allow-http-traffic -p tcp -i $uplink --dport 80 -m tcp -j LOG --log-prefix "IPTABLES:ALLOWED-HTTP: "
$iptables -A allow-http-traffic -p tcp -i $uplink --dport 80 -m tcp -j ACCEPT
echo -e "\e[32m*\e[0m Creating incoming https traffic chain..."
$iptables -N allow-https-traffic
$iptables -F allow-https-traffic
$iptables -I allow-https-traffic 1 -p tcp -i $uplink --dport 443 -m state --state NEW -m recent --update --seconds 10 --hitcount 5 -j LOG --log-prefix "IPTABLES:BLOCKED-CONN: "
$iptables -I allow-https-traffic 2 -p tcp -i $uplink --dport 443 -m state --state NEW -m recent --update --seconds 10 --hitcount 5 -j DROP
$iptables -A allow-https-traffic -p tcp -i $uplink --dport 443 -m tcp -j LOG --log-prefix "IPTABLES:ALLOWED-HTTPS: "
$iptables -A allow-https-traffic -p tcp -i $uplink --dport 443 -m tcp -j ACCEPT
echo -e "\e[32m*\e[0m Creating blocked connections chain and setting drop & log rules..."
$iptables -N blocked-connections
$iptables -F blocked-connections
$iptables -A blocked-connections -i $uplink -m conntrack --ctstate INVALID -j LOG --log-prefix "IPTABLES:BLOCKED-CONN: "
$iptables -A blocked-connections -i $uplink -m conntrack --ctstate INVALID -j DROP
echo -e "\e[32m*\e[0m Applying new chains to INPUT..."
$iptables -A INPUT -j allowed-connections
$iptables -A INPUT -j allow-ssh-traffic
$iptables -A INPUT -j allow-http-traffic
$iptables -A INPUT -j allow-https-traffic
$iptables -A INPUT -j blocked-connections
echo -e "\e[32m*\e[0m Setting DROP rules & log conditions for INPUT chain..."
$iptables -P INPUT DROP
$iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "IPTABLES:BLOCKED-CONN: "
$iptables -A INPUT -p tcp -i $uplink -j REJECT --reject-with tcp-reset
$iptables -A INPUT -p udp -i $uplink -j REJECT --reject-with icmp-port-unreachable
$iptables -A INPUT -i $uplink -m state --state INVALID -j DROP
echo -e "\e[32m*\e[0m Setting DROP rules for the MANGLE table..."
$iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
echo -e "\e[32m*\e[0m Setting default DROP condition & Applying logging for FORWARD chain..."
$iptables -P FORWARD DROP
$iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "IPTABLES:BLOCKED-CONN: "
$iptables -A FORWARD -m state --state INVALID -j DROP
echo -e "\e[32m*\e[0m Setting ACCEPT condition for OUTPUT chain..."
$iptables -P OUTPUT ACCEPT
echo -e "\e[32m*\e[0m Saving iptables..."
$iptablessave > /etc/firewall/firewall.rules
