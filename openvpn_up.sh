#!/bin/sh
# This script pulls from multiple sources, including the port_forwarding.sh PIA script.
# This script is called by openvpn during start up. 
# What this script does:
# 1. Waits until connection is established. (while loop with wait)
# 2. Once established, change DNS (see resolv.conf change scripts. there are equivalents for linux and windows)
# 3. Query the PIA server for a forwarded port, which gets output to a file
# 4. Change firewall settings (pf)
#
# (qbittorrent launcher) Another script does the following:
# 1. Checks if qbittorrent is running. If not, launches qbittorrent in GUI mode.
# 2. Change qbittorrent's listening port to forwarded port. 
# 
# The openvpn down script does the following:
# 1. Changes DNS servers back (see resolv.conf change scripts)
# 2. Change the pf rules back

# gateway changes and unchanges are handled by openvpn's "redirect-gateway def1" function automatically.


check_physical_if( )
{
  #Check extif is up or not. if not, exit
  if ifconfig $EXTIF | grep -q 'active'; then
    echo "Interface $EXTIF is active"
  else
    echo "Interface $EXTIF is not active. Check connection. Exiting OpenVPN up script."
    exit 2
  fi
}

wait_for_connection( )
{
  #This function causes the up script to sleep until a VPN connection is established
  echo 'waiting for openvpn connection to establish...'
  local counter1=0
  while ! ifconfig $VPNIF | grep -q 'active' # if false: then iterate, if true: done/skip. 
  do
    if [ $counter1 -gt 11 ]; then
      echo "It has been more than 120s since start of attempts to connect, so port forwarding is now unavailable. Check OpenVPN logs for details. Exiting up script."
      exit 3
    fi
    sleep 10
    counter1=$(expr $counter1 + 1)
  done
  echo "Interface $VPNIF is active."
}

change_DNS( )
{
  mv /etc/resolv.conf /etc/resolv_conf.orig 
  mv /etc/resolv_ovpn_conf /etc/resolv.conf
  echo "DNS changed to:"
  echo $(cat /etc/resolv.conf)
}

port_forward_assignment( )
{
  #This function checks for existence of a client_id, creates a new one if it doesn't exist,
  #requests a forwarded port, trims the output to the forwarded port, 
  #If want a new port, simply delete pia_client_id.
  
  echo 'Loading port forward assignment information...'
  if [ ! -f $VPNPATH/pia_client_id ]; then
    if [ "$(uname)" == "Linux" ]; then
      head -n 100 /dev/urandom | sha256sum | tr -d " -" > $VPNPATH/pia_client_id
    fi
    if [ "$(uname)" == "Darwin" ]; then
      head -n 100 /dev/urandom | shasum -a 256 | tr -d " -" > $VPNPATH/pia_client_id
    fi
    if [ "$(uname)" == "OpenBSD" ]; then
      head -n 100 /dev/urandom | sha256 | tr -d " -" > $VPNPATH/pia_client_id
    fi
  fi
  client_id=$(cat $VPNPATH/pia_client_id)
  json=$(curl --interface $VPNIF "http://209.222.18.222:2000/?client_id=$client_id" 2>/dev/null)
  echo $json
  FORWARDPORT=$(echo $json | grep -oE [0-9]\{1,5\} )
  echo $FORWARDPORT > $VPNPATH/forwardport
  if [ "$FORWARDPORT" == "" ]; then
    echo "Port forwarding is already activated on this connection, has expired, or you are not connected to a PIA region that supports port forwarding"
    echo "OpenVPN up script will continue, but port forwarding will not be activated."
    PORTFLAG=1
  fi
}

change_firewall_settings( )
{
  #This part is specific to openbsd pf. You will have to rewrite it for Linux depending on flavor
  
  #Flush the piaopenvpnsetup anchor, which contains rules necessary for setup of the VPN, but not necessary after connection is established.
  pfctl -a piaopenvpnsetup -F rules
  
  if [ $PORTFLAG -eq 0 ]; then
    #Add rule for port forwarding. Since the port number has to change, this is done by writing an anchor text file and loading it.
    echo "pass in on $VPNIF proto { tcp udp } from any to $VPNIF port $FORWARDPORT" > /etc/anchor-piaportforward
    pfctl -a piaportforward -f /etc/anchor-piaportforward
    echo "Set port forwarding pf rule."
  fi
}

EXITCODE=0
PROGRAM=`basename $0`
VERSION=2.2
EXTIF="msk0"
VPNIF="tun0"
VPNPATH="/etc/openvpn/"
PORTFLAG=0 


check_physical_if
wait_for_connection
change_DNS
port_forward_assignment
change_firewall_settings

exit 0
