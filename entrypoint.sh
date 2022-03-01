#!/bin/bash

GREEN="\033[0;32m"
NC="\033[0m"

echo -e "$GREEN[ Running startup routine ]$NC"
/startup_routine $(id -u) $(id -g)
echo -e "\n"

echo -e "$GREEN[ Starting samba ]$NC"
echo "User:$(id -u)"
echo "Running..."
smbd -DF --no-process-group --configfile /config/smb.conf -l /logs/ -d 3 -p 4455
echo -e "\n";

#exec "$@"

echo "Closing (if unexpected, read /logs/log.smbd for more information)"