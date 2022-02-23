#!/bin/bash

/etc/samba/custom/startup_routine

echo "Done Updating"

echo "Starting Samba"

smbd -DF --no-process-group --configfile /config/smb.conf -l /logs/ -d 3

echo "Entrypoint ended";

exec "/bin/bash"