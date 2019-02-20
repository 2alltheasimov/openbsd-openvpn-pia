#!/bin/sh
# The openvpn down script does the following:
# 1. Changes DNS servers back (see resolv.conf change scripts)
# 2. Change the pf rules back

undo_change_DNS()
{
  mv /etc/resolv.conf /etc/resolv_ovpn_conf
  mv /etc/resolv_conf.orig /etc/resolv.conf
  echo "DNS changed to:"
  echo $(cat /etc/resolv.conf)
} 

undo_change_firewall_settings()
{
  #This part is specific to openbsd pf. You will have to rewrite it for Linux
  #Add the piaopenvpnsetup anchor rules back in, which contains rules necessary for setup of the VPN, but not necessary after connection is established.
  pfctl -f /etc/pf.conf 
  
  #Flush anchor containing the rule for port forwarding.
  pfctl -a piaportforward -F rules
}

undo_change_DNS
undo_change_firewall_settings
