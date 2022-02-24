#!/bin/bash

GREEN="\033[0;32m"
NC="\033[0m"

echo -e "$GREEN[ Running startup routine ]$NC"
/etc/samba/custom/startup_routine $(id -u) $(id -g)
echo -e "done\n"

echo -e "$GREEN[ Starting samba ]$NC"
echo "User:$(id -u)"
smbd -DF --no-process-group --configfile /config/smb.conf -l /logs/ -d 3
echo -e "done\n";

exec "$@"