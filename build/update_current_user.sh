#!/bin/bash

if [ $(id -u) != "0" ]; then
    echo "Not Running as root"
    exit
fi

USER_UID=$1;
USER_GID=$2;

if [ -z "$USER_UID" ] || [ -z "$USER_GID" ]; then
    echo "You need to pass 2 arguments"
    echo "usage: update_current_user UID GUI"
    echo "UID [1000..1999]"
    echo "GID [1000.1999]"
    exit
fi

if [[ ! "$USER_UID" =~ ^[0-9]+$ ]]; then
    echo "UID is not a number"
    exit
else
    if [ "$USER_UID" -gt 1999 ] && [ "$USER_UID" -lt 3000 ]; then
        echo "UID is in blocked range"
        exit
    fi
fi

if [[ ! "$USER_GID" =~ ^[0-9]+$ ]]; then
    echo "GID is not a number"
    exit
else
    if [ "$USER_GID" -gt 1999 ] && [ "$USER_GID" -lt 3000 ]; then
        echo "GID is in blocked range"
        exit
    fi
fi


# Samba has the right uid?
if [ "$USER_UID" != "$(id -u samba)" ]; then
    echo "Replacing samba uid"
    sed -i -e "s/^samba:\([^:]*\):[0-9]*:\([0-9]*\)/samba:\1:${USER_UID}:\2/" /etc/passwd
fi

# Samba has the right gid?
if [ "$USER_GID" != "$(id -g samba)" ]; then
    echo "Replacing samba gid"
    sed -i -e "s/^samba:\([^:]*\):[0-9]*/samba:\1:${USER_GID}/" /etc/group
    sed -i -e "s/^samba:\([^:]*\):\([0-9]*\):[0-9]*/samba:\1:\2:${USER_GID}/" /etc/passwd
fi
