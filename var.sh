#!/bin/bash


#PWD
pwd="/home/router"
 
# LAN interface
IF0="em1"
 
# WAN interface 1
IF1="em2"
 
# WAN interface 2
IF2="eth1"
 
IP1="94.153.193.173"
IP2="176.105.102.82"
 
# gateway 1
P1="94.153.193.169"
# gateway 2
P2="176.105.102.81"
 
# LAN netmask
P0_NET="10.1.2.0/24"
# WAN1 netmask
P1_NET="94.153.193.168/29"
# WAN2 netmask
P2_NET="176.105.102.80/29"
 
 
TBL1="101"
TBL2="102"

# Realtive weight of channels bandwidth
W1="254"
W2="1"

transnet="192.168.0.0/24 10.2.2.0/27"
