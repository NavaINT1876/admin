#!/bin/bash

# port_forwarding  #	for source add "-s X.X.X.X" to the end of config line

#servicedesk
port_forwarding_fake  $IF1 $IP1  80  10.1.2.7 8765 ""
port_forwarding_fake  $IF2 $IP2  80  10.1.2.7 8765 ""
#icinga based via nagios3
port_forwarding_fake  $IF1 $IP1  82  10.1.2.13 80 ""
port_forwarding_fake  $IF2 $IP2  82  10.1.2.13 80 ""
#rdp
port_forwarding $IF1 $IP1 10.1.2.129 3389 ""
port_forwarding $IF2 $IP2 10.1.2.129 3389 ""

port_forwarding_fake $IF1 $IP1 1234 10.1.2.109 3389 ""
port_forwarding_fake $IF2 $IP2 1234 10.1.2.109 3389 ""

port_forwarding_fake $IF1 $IP1 1212 10.1.2.156 3389 ""
port_forwarding_fake $IF2 $IP2 1212 10.1.2.156 3389 ""
