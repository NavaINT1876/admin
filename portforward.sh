#!/bin/bash

# port_forwarding  #	for source add "-s X.X.X.X" to the end of config line


#port_forwarding_fake  $wanip  11941	 192.168.0.10 11941
#port_forwarding_fake  $wanip  25 	 192.168.0.10 25
#port_forwarding_fake  $wanip  443	 192.168.0.10 443

#port_forwarding $wanip 10.1.2.140 25
#port_forwarding $wanip 10.1.2.140 143
#port_forwarding $wanip 10.1.2.140 587
#port_forwarding $wanip 10.1.2.140 443
#port_forwarding $wanip 10.1.2.140 80

#kerio
#port_forwarding $wanip 10.1.2.141 4090
#icinga based via nagios3
#port_forwarding_fake  $wanip  82  10.1.2.13 80
#rdp
#port_forwarding $wanip 10.1.2.129 3389
#port_forwarding_fake  $wanip  1234  10.1.2.35 3389

#servicedesk
port_forwarding_fake  $IF1 $IP1  80  10.1.2.7 8765
port_forwarding_fake  $IF2 $IP2  80  10.1.2.7 8765
#icinga based via nagios3
port_forwarding_fake  $IF1 $IP1  82  10.1.2.13 80
port_forwarding_fake  $IF2 $IP2  82  10.1.2.13 80
#rdp
port_forwarding $IF1 $IP1 10.1.2.129 3389
port_forwarding $IF2 $IP2 10.1.2.129 3389

port_forwarding_fake $IF1 $IP1 1234 10.1.2.109 3389
port_forwarding_fake $IF2 $IP2 1234 10.1.2.109 3389

port_forwarding_fake $IF1 $IP1 1212 10.1.2.156 3389
port_forwarding_fake $IF2 $IP2 1212 10.1.2.156 3389
