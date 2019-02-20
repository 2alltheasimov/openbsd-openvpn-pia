#!/bin/sh

# (qbittorrent launcher) Another script does the following:
# 1. Checks if qbittorrent is running. If not, launches qbittorrent in GUI mode.
# 2. Change qbittorrent's listening port to forwarded port. 
#Make sure webui is enabled on port 8080 before use and click "bypass authentication for clients on localhost"
#Can add authentication with username and password + cookie. See webui documentation.
#Assumes qbittorrent can be found in PATH

#check with ps if qbittorrent is running. If not, start it, sleep for a couple seconds
ps cax | grep qbittorrent > /dev/null
if [ $? -eq 0 ]; then
  echo "qbittorrent is running."
else
  echo "Starting qbittorrent."
  qbittorrent &
  sleep 5
fi

#check forward port to make sure it's 1-5 digits long:
FORWARDPORT=$(cat /etc/openvpn/forwardport)
echo $FORWARDPORT
if echo "$FORWARDPORT" | grep -Eq ^[0-9]\{1,5\}$ ; then
  echo "Updating qbittorrent listening port."
  # The json is url encoded:
  curl -i -X POST -d "json=%7B%22listen_port%22%3A${FORWARDPORT}%7D" http://localhost:8080/command/setPreferences
else
  echo "qbittorrent listening port not updated."
fi
