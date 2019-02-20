# openbsd-openvpn-pia
helpful scripts for unix + openvpn + PIA + qbittorrent
Developed by pulling from multiple sources.

More details here: https://mitrocketscience.blogspot.com/2019/02/openbsd-openvpn-and-bittorrent-client.html

OpenVPN up helper script:
Called with "route-up /full/path/to/openvpn_up_helper.sh" in the .ovpn configuration file.
Calls the openvpn up script. 

OpenVPN up script:
1. Waits until connection is established. (while loop with wait)
2. Once established, change DNS (see resolv.conf change scripts. there are equivalents for linux and windows)
3. Query the PIA server for a forwarded port, which gets output to a file
4. Change firewall settings (pf)

qbittorrent launcher script:
1. Checks if qbittorrent is running. If not, launches qbittorrent in GUI mode.
2. Change qbittorrent's listening port to forwarded port. 
 
OpenVPN down script:
1. Changes DNS servers back (see resolv.conf change scripts)
2. Change the pf rules back

