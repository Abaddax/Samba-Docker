#!/bin/bash

#root check
if [ $(id -u) != "0" ]; then
    echo "Not Running as root"
    exit
fi

USER_UID=$1;
USER_GID=$2;

#checking parameters
if [ -z "$USER_UID" ] || [ -z "$USER_GID" ]; then
    echo "You need to pass 2 arguments"
    echo "usage: update_current_user UID GUI"
    exit
fi

#Checking UID format
if [[ ! "$USER_UID" =~ ^[0-9]+$ ]]; then
    echo "UID is not a number"
    exit
fi

#Checking GID format
if [[ ! "$USER_GID" =~ ^[0-9]+$ ]]; then
    echo "GID is not a number"
    exit
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
