#!/bin/bash

#Change smbd dirs owner to samba
chown -R root:samba /var/cache/samba
chown -R root:samba /var/lib/samba
chown -R root:samba /var/run/samba

echo "Giving samba access to"
echo "/var/cache/samba"
echo "/var/lib/samba"
echo "/var/run/samba"