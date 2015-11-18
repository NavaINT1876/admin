#!/bin/bash

. /home/router/var.sh


# vars
priP=$P1
priIF=$IF1
###
secP=$P2
secIF=$IF2
###

while true; do

x1=`ping -c 3 -s 100 "$priP" -I "$priIF" | grep loss | sed "s/%.*//g" | awk {'print$NF'}`
x2=`ping -c 3 -s 100 "$secP" -I "$secIF" | grep loss | sed "s/%.*//g" | awk {'print$NF'}`

if [ $x1 -lt 50 ]; then
  c=`ip route | grep default | awk {'print$3'}`
	if [ $c  ==  $priP ]; then
	echo "no changed, gw $priP"
	else
	ip route delete default
	ip route add default via $priP
        echo "changed, gw $priP"
	fi
else
	if [ $x2 -lt 50 ]; then
		 c=`ip route | grep default | awk {'print$3'}`
	        if [ $c  ==  $secP ]; then
	        echo "no changed, gw $secP"
		else
		ip route delete default
        	ip route add default via $secP
                echo "changed, gw $secP"
		fi
	else
	echo "All gateways are down"
	fi
fi

sleep 3
done
