#!/bin/bash


echo 1 > /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv4/ip_dynaddr
echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects
echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects
echo 0 > /proc/sys/net/ipv4/conf/default/rp_filter
echo 0 > /proc/sys/net/ipv4/conf/default/accept_source_route
echo 0 > /proc/sys/net/ipv4/conf/default/send_redirects
echo 1 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses


for vpn in /proc/sys/net/ipv4/conf/*; do echo 0 > $vpn/accept_redirects; echo 0 > $vpn/send_redirects; done

modprobe iptable_nat
modprobe ip_conntrack_ftp
modprobe ip_nat_ftp
modprobe xt_TARPIT

iptables -F
iptables -F -t nat
iptables -F -t filter
iptables -F -t raw
iptables -F -t mangle

iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

iptables -t mangle -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

iptables -A INPUT -m state --state INVALID -j DROP
iptables -A FORWARD -m state --state INVALID -j DROP

iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
iptables -A OUTPUT -p tcp ! --syn -m state --state NEW -j DROP

iptables -A INPUT   -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD  -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -i $IF0 -j ACCEPT
iptables -A FORWARD -i lo -o lo -j ACCEPT
iptables -A FORWARD -i $IF0 -o $IF0 -j ACCEPT
iptables -A INPUT   -p icmp -j ACCEPT
##################FUNCTIONS##################################
function tarpit {
a=`echo $i | awk {'print$1'}`
if [ ! -z $a ]; then
IP="$1"

 for ip in `echo $IP`
                do

iptables -I INPUT 1 -p tcp  -s $ip -j TARPIT
iptables -A FORWARD -p tcp  -s $ip -j TARPIT
iptables -t raw -I PREROUTING -p tcp -s $ip -j NOTRACK
done
fi
 }
function input_ports {
a="all"
    if [  $1 == $a ]; then
iptables -A INPUT -i $IF1  -p tcp -m multiport --dports $2   -j DROP
iptables -A INPUT -i $IF1 -p udp -m multiport --dports $2   -j DROP
iptables -A INPUT -i $IF2  -p tcp -m multiport --dports $2   -j DROP
iptables -A INPUT -i $IF2 -p udp -m multiport --dports $2   -j DROP

iptables -A INPUT -i $IF1  -p tcp  -j ACCEPT
iptables -A INPUT -i $IF1  -p udp  -j ACCEPT
iptables -A INPUT -i $IF2  -p tcp  -j ACCEPT
iptables -A INPUT -i $IF2  -p udp  -j ACCEPT
 else
iptables -A INPUT -i $IF1  -p tcp -m multiport --dports $1   -j ACCEPT
iptables -A INPUT -i $IF1 -p udp -m multiport --dports $1   -j ACCEPT
iptables -A INPUT -i $IF2  -p tcp -m multiport --dports $1   -j ACCEPT
iptables -A INPUT -i $IF2 -p udp -m multiport --dports $1   -j ACCEPT
    fi
 }
function port_forwarding_fake {

iptables -t nat -A PREROUTING -d $2 $6 -p tcp -m tcp --dport $3 -j DNAT --to-destination $4:$5
iptables -t nat -A PREROUTING -d $2 $6 -p udp -m udp --dport $3 -j DNAT --to-destination $4:$5
iptables -I FORWARD 1 -i $1 -o $IF0 -d $4 -p tcp -m tcp --dport $5 -j ACCEPT
iptables -I FORWARD 1 -i $1 -o $IF0 -d $4 -p udp -m udp --dport $5 -j ACCEPT

iptables -A INPUT -p tcp  --dport $3   -j ACCEPT
iptables -A INPUT -p udp  --dport $3   -j ACCEPT
}


function port_forwarding {
iptables -A INPUT -p tcp  --dport $4   -j ACCEPT
iptables -A INPUT -p udp  --dport $4   -j ACCEPT

iptables -t nat -A PREROUTING --dst $2 $5 -p tcp --dport $4 -j DNAT --to-destination $3
iptables -t nat -A PREROUTING --dst $2 $5 -p udp --dport $4 -j DNAT --to-destination $3
iptables -I FORWARD 1 -i $1 -o $IF0 -d $3 -p tcp -m tcp --dport $4 -j ACCEPT
iptables -I FORWARD 1 -i $1 -o $IF0 -d $3 -p udp -m udp --dport $4 -j ACCEPT
}

# Борьба со спамом. Забаненные ip можно посмотреть: /proc/net/xt_recent/spamer
function safull_port {
iptables -I FORWARD 2 -i $3 -p tcp -m tcp --dport $1 --tcp-flags FIN,SYN,RST,ACK SYN \
-m recent --set --name spamer --rsource

iptables -I FORWARD 3 -i $3 -p tcp -m tcp --dport $1 --tcp-flags FIN,SYN,RST,ACK SYN \
-m recent --update --seconds $2 --hitcount 3 --name spamer --rsource -j DROP
}
#Allow vpn_server
function vpn_server_on {
modprobe ip_gre
modprobe ip_nat_pptp
modprobe ip_conntrack_pptp


iptables -A INPUT  -p gre -j ACCEPT
iptables -A INPUT  -m tcp -p tcp --dport 1723 -j ACCEPT
iptables -A INPUT  -m udp -p udp --dport 1723 -j ACCEPT

iptables -A INPUT -i ppp+ -j ACCEPT

iptables -A FORWARD -i ppp+  -j ACCEPT
iptables -A FORWARD -o ppp+  -j ACCEPT
}

############Привязки ip к Мак-адресу########################
function ip_mac {
touch /etc/ethers
ether=`/bin/cat /etc/ethers | /bin/grep $1`
ip_ether=`echo "$1 $2"`
if [ "$ether" = "$ip_ether" ];then
echo
else
echo "$1 $2" >> /etc/ethers
echo "added /etc/ethers"
fi
         arp -f  # /etc/ethers
}


############Привязки Мак-адреса к ip и наоборот (ЖЕСТКАЯ ПРИВЯЗКА)#######
function mac_ip {
iptables -A FORWARD ! -s $1  -m mac  --mac-source $2 -j DROP
ip_mac  $1 $2
}


############Открыть порты все или некоторые#######
function open_port {

PORT="$1"

 for port in `echo $PORT`
                do

aaaa="all"
if [ $port == $aaaa ];then

iptables -A FORWARD -s $2  -j ACCEPT

else

iptables -A FORWARD -s $2  -m tcp -p tcp  --sport $port -j ACCEPT
iptables -A FORWARD -s $2  -m udp -p udp  --dport $port -j ACCEPT

fi
                done

}


###########Закрыть порты#############################
function close_port {
PORTIS="$1"

 for portis in `echo $PORTIS`
                do

iptables -A FORWARD  -s $2  -m tcp -p tcp --dport $portis -j DROP

done
}


function close_ip {
SITE2="$1"
 for site2 in `echo $SITE2`
                do
################ ЗАПРЕТЫ на сайты или ресурсы ###############################
iptables -A FORWARD   -d $site2  -s $2 -j DROP
done
}


################ ЗАПРЕТЫ на сайты или ресурсы ###############################
function close_site {
SITE1="$1"
 for site1 in `echo $SITE1`
                do

iptables -A FORWARD   -d $site1  -s $2 -j REJECT
iptables -A INPUT   -s $site1   -j REJECT
done
}

################# NAT enable #############################
function nat {
#iptables -t nat -A POSTROUTING -s $1 -o $IF1 -j MASQUERADE
#iptables -t nat -A POSTROUTING -s $1 -o $IF2 -j MASQUERADE
#iptables -t nat -A POSTROUTING -s $1  -j MASQUERADE
for ips in `echo $3` ; do
iptables -t nat -A POSTROUTING -s $1 -d $ips -j MASQUERADE
done
iptables -t nat -A POSTROUTING -s $1  -j SNAT --to-source $2
}



################# ICMP enable #############################
function icmp {
ping123=`echo "$1"`
ping321=`echo "on"`
if [ $ping123 == $ping321  ];then
iptables -A FORWARD  -p icmp -j ACCEPT
iptables -A OUTPUT -p icmp -j ACCEPT
fi
}




#############Шейпер#############
function shaper_dev {
tc qdisc del dev $1 root
tc qdisc add dev $1 root handle 1:0 htb default 106
tc class add dev $1 parent 1:0 classid 1:1 htb rate "$2" burst 20k
}

function shaper {
tc class add dev $1 parent 1:1 classid 1:"$2" htb rate "$3" burst 10k prio "$4"
tc qdisc add dev $1 parent 1:"$2" handle "$2": sfq perturb 10
tc filter add dev $1 parent 1:0 protocol ip prio "$4" handle "$2" fw classid 1:"$2"
}


function tariff {
for max in `echo $2`
do
if [ ! -z $1 ]; then
	if [ ! -z $7 ]; then
	iptables -t mangle -A FORWARD -s $max -p tcp   -j MARK --set-mark $1
	iptables -t mangle -A FORWARD -s $max -p udp   -j MARK --set-mark $1
	iptables -t mangle -A POSTROUTING -d $max -p tcp -m multiport ! --sports $7   -j MARK --set-mark $1
	iptables -t mangle -A POSTROUTING -d $max -p udp  -m multiport ! --sports $7   -j MARK --set-mark $1
	else
	iptables -t mangle -A FORWARD -s $max -p tcp   -j MARK --set-mark $1
	iptables -t mangle -A FORWARD -s $max -p udp   -j MARK --set-mark $1
	iptables -t mangle -A POSTROUTING -d $max -p tcp  -j MARK --set-mark $1
	iptables -t mangle -A POSTROUTING -d $max -p udp  -j MARK --set-mark $1
fi
close_ip "$6" "$max"
close_site "$5" "$max"
close_port "$4" "$max"
open_port "$3" "$max"
fi
done
}


function proxy {
iptables -t nat -A PREROUTING -s $1 -p tcp -m multiport --dport $2 -j REDIRECT --to-port $3
iptables -t nat -A PREROUTING -s $1 -p udp -m multiport --dport $2 -j REDIRECT --to-port $3
}




function pull {
COUNTER="$2"
         while [  $COUNTER -le $3 ]; do
             echo  $1.$COUNTER is NATed
	a="$1.$COUNTER"

###
shaper $IF0 "5$COUNTER" $4 2 #down
shaper $IF1 "5$COUNTER" $4 2 #up
shaper $IF2 "5$COUNTER" $4 2 #up
###
#tariff	"tariff" "ip"  "openport" "closeport" "denydomains" "denyips"
tariff "5$COUNTER" 	"$a" 	"$5" 	"$6" 	"$7" 	"$8"  "$9" #minimal 
	let COUNTER=COUNTER+1
	done

if [ ! -z $9 ]; then
iptables -t mangle -A POSTROUTING -d $P0_NET -p tcp -m multiport --sports $9   -j MARK --set-mark 5
iptables -t mangle -A POSTROUTING -d $P0_NET -p udp  -m multiport --sports $9   -j MARK --set-mark 5
fi

}

