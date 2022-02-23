#!/bin/bash

#Create smbd dirs if not existing
mkdir -p \
	/var/cache/samba \
	/var/lib/samba \
	/var/run/samba
#Change smbd dirs owner to samba
chown -R samba:samba /var/cache/samba
chown -R samba:samba /var/lib/samba
chown -R samba:samba /var/run/samba

echo "Giving samba access to"
echo "/var/cache/samba"
echo "/var/lib/samba"
echo "/var/run/samba"

	
#smbd -iF -d 3
	