#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

### kill check process
for pr in `ps uax | grep check.sh | awk {'print$2'}`
do
kill $pr  > /dev/null 2>&1
done

pwd="/home/router"

# VARS
. $pwd/var.sh

# main script
. $pwd/iptables_default.sh
. $pwd/iptables_func.sh

# routing ==> 2GWs <==

ip route flush table $TBL1
ip route flush table $TBL2
ip route flush cache

while [ -n "`ip rule show | grep -Ev '^(0|32766|32767):'`" ]; do
   ip rule flush
done

ip rule add from all lookup main pref 32766
ip rule add from all lookup default pref 32767

ip route add $P1_NET dev $IF1 src $IP1 table $TBL1 > /dev/null 2>&1
ip route add default via $P1 table $TBL1 > /dev/null 2>&1
ip route add $P2_NET dev $IF2 src $IP2 table $TBL2 > /dev/null 2>&1
ip route add default via $P2 table $TBL2 > /dev/null 2>&1

ip route add $P1_NET dev $IF1 src $IP1 > /dev/null 2>&1
ip route add $P2_NET dev $IF2 src $IP2  > /dev/null 2>&1

ip route replace default scope global \
  nexthop via $P1 dev $IF1 weight $W1 \
  nexthop via $P2 dev $IF2 weight $W2

ip rule add from $IP1 table $TBL1 > /dev/null 2>&1
ip rule add from $IP2 table $TBL2 > /dev/null 2>&1


ip route add $P0_NET dev $IF0 table $TBL1 > /dev/null 2>&1
ip route add $P2_NET dev $IF2 table $TBL1 > /dev/null 2>&1
ip route add 127.0.0.0/8 dev lo table $TBL1 > /dev/null 2>&1
ip route add $P0_NET dev $IF0 table $TBL2 > /dev/null 2>&1
ip route add $P1_NET dev $IF1 table $TBL2 > /dev/null 2>&1
ip route add 127.0.0.0/8 dev lo table $TBL2 > /dev/null 2>&1


# my adds
iptables -A FORWARD  -d 192.168.0.0/24 -j ACCEPT
iptables -A FORWARD  -s 192.168.0.0/24 -j ACCEPT

route add -net 10.2.2.0/27 gw 10.3.2.0 > /dev/null 2>&1
route add -net 192.168.111.0/24 gw 10.1.2.2 > /dev/null 2>&1

#block bad ips or networks with tarpit
tarpit "36.0.0.0/8 118.0.0.0/8"

# Input port for daemons
input_ports "all" "8900:9100"

#shaper your ips or network or iprange
shaper_dev "$IF0" "100mbit"
shaper_dev "$IF1" "100mbit"
shaper_dev "$IF2" "100mbit"

# bypass speed
shaper $IF0 "5" "95mbit"  "6" #down
shaper $IF1  "5" "95mbit"  "6" #up
shaper $IF2  "5" "95mbit"  "6" #up

# port_forwarding
.  $pwd/portforward.sh

# vpn_server
vpn_server_on

# ip mac binding
#mac_ip 10.0.0.2 74:2f:68:52:ac:11

#nat
snat_local $P0_NET  "10.2.2.0/27 192.168.0.0/24 176.105.102.80/29"
snat_bypassport  $P0_NET  $IP2 "49152:65534"
snat $P0_NET $IP1

# if you have terrible problems with some port use this option
### Don`t use when it`s possible!!!
### block info in 'cat  /proc/net/xt_recent/spamer'
#safull_port "port" "time_in_sec"


### ICMP
icmp on

### Pulls
pull "10.1.2" "2" "254" "16mbit" "all" "" "" "" "49152:65534"

### IPs not in PULLS
iptables -A FORWARD -s $P0_NET -j DROP

#save iptables conf
service iptables save


### check
$pwd/check.sh >> $pwd/route.log  &

#/home/router/check.sh &

### check fail2ban
f=`ps uax | grep fail2ban | wc -l`
if [ $f -eq 2 ]; then
service fail2ban restart
fi

