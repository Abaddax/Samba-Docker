#!/bin/bash

echo "Updating smbd workdir access..."

#Change volume dirs owner to samba
chown -R samba:samba /data
chown -R samba:samba /config
chown -R samba:samba /logs
chmod -R 770 /data
echo "- Changing owner of volumes"

#Change smbd dirs owner to samba
chown -R samba:samba /var/cache/samba
chown -R samba:samba /var/lib/samba
chown -R samba:samba /var/run/samba
echo "- Giving access to worksdirs"

echo "OK"