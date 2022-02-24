#!/bin/bash

#username
user_del () {
    #format checking
    if [ -z $1 ]; then
        exit
    fi

    echo "Deleting old user ($1)"
    deluser --remove-home $1
    smbpasswd -x $1
}
#username, uid, gid, pw
user_add () {
    #format checking
    if [ -z $1 ] || [ -z $2 ] || [ -z $3 ] || [[ "$2" =~ ^[0-9]+$ ]] ||  [[ "$3" =~ ^[0-9]+$ ]]; then
        exit
    fi

    echo "Adding new user ($1:$2:$3)"
    #new user already exist?
    if [ ! -z $(getent passwd "$1" | cut -d: -f1) ]; then
        echo "Deleting wrong user ($1)"
        sudo deluser --remove-home $1
    fi
    #Password specified?
    if [ ! -z "$4" ]; then
        (echo "$4"; echo "$4") | (adduser -H -h/home/nas-users/$1 -g "$3" -u "$2" "$1")
        adduser $1 $SMB_USERS_GUID
    else
        echo "New Users must have a password"
    fi
}
#username, pw
smb_add () {
    #format checking
    if [ -z $1 ]; then
        exit
    fi

    #Password exists?
    if [ ! -z "$2" ]; then
        echo "Changing samba password"
        (echo "$2"; echo "$2") | (smbpasswd -a "$1")
    fi
}

#root check
if [ $(id -u) != "0" ]; then
    echo "Not Running as root"
    exit
fi

#Check if config files exist
if [ ! -f "/config/smb.conf" ]; then
    echo "Creating /config/smb.conf"
    cp /etc/samba/custom/smb.conf.template /config/smb.conf
fi
if [ ! -f "/config/smb.users" ]; then
    echo "Creating /config/smb.users"
    cp /etc/samba/custom/smb.users.template /config/smb.users
fi

#reading smb.users
file="/config/smb.users"
lines=$(cat $file | sed '/^\s*#/d;/^\s*$/d')

#checking user removes
log="/etc/samba/custom/smb.users.log"
loglines=$(cat $log | sed '/^\s*#/d;/^\s*$/d')
for logline in $loglines; do
    #looking for user in smb.users
    if [ -z $(grep -n "^$logline:" $file) ]; then
        #user doesnt exit anymore
        user_del $logline
    fi
done

#checking users
for line in $lines; do
    new_user=$(echo "$line" | cut -d':' -f1)
    new_uid=""
    new_gid=""
    new_pw=""
    #checking if line has ':'
    if $(echo "$line" | grep -q ":"); then
        new_uid=$(echo "$line" | cut -d':' -f2)
        new_gid=$(echo "$line" | cut -d':' -f3)
        new_pw=$(echo "$line" | cut -d':' -f4)
    fi

    #debug
    echo "$new_user:$new_uid:$new_gid:$new_pw"

    #check if new_user is valid
    if [ -z "$new_user" ]; then
        continue
    fi

    #Check if user already exists
    if [ -z "$(getent passwd "$new_user" | cut -d: -f1)" ]; then
        #modify existing user

        #replace uid if needed
        if [ ! -z "$new_uid" ] && [[ "$new_uid" =~ ^[0-9]+$ ]]; then
            echo "Replacing UID"
            sed -i -e "s/^$new_user:\([^:]*\):[0-9]*:\([0-9]*\)/samba:\1:$new_uid:\2/" /etc/passwd
        fi

        #replace gid if needed
        if [ ! -z "$new_gid" ] && [[ "$new_gid" =~ ^[0-9]+$ ]]; then
            echo "Replacing GID"
            sed -i -e "s/^$new_user:\([^:]*\):[0-9]*/samba:\1:$new_gid/" /etc/group
            sed -i -e "s/^$new_user:\([^:]*\):\([0-9]*\):[0-9]*/samba:\1:\2:$new_gid/" /etc/passwd
        fi

        #replace password
        if [ ! -z "$new_pw" ]; then
            echo "Replacing Password"
            smb_add $new_user $new_pw
        fi
    else
        #create new user
        #username, uid, gid, pw
        user_add $new_user $new_uid $new_gid $new_pw
        smb_add $new_user $new_pw

        #add to log
        echo "$new_user" >> "$log"
        #remove pw
        if [ "$SMB_USERS_REMOVE_PASSWORD"="1" ]; then
            sed -i -e "s/^$new_user:.*/$new_user:$new_uid:$new_gid/" "file"
        fi
    fi
done