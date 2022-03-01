#!/bin/bash

#username
user_del () {
    #format checking
    if [ -z $1 ]; then
        echo "ERROR: user_del invalid arg"
        exit
    fi

    echo "- Deleting old user ($1)"
    deluser --remove-home $1
    smbpasswd -x $1

    #removing group
    if [ ! $(getent group $1 | cut -d: -f4 | grep -q ",") ]; then
        delgroup $1
    fi
}
#username, uid, gid, pw
user_add () {
    #format checking
    if [ -z $1 ] || [ -z $2 ] || [ -z $3 ] || [[ "$2" =~ "^[0-9]+$" ]] ||  [[ "$3" =~ "^[0-9]+$" ]]; then
        echo "ERROR: user_add invalid arg"
        exit
    fi

    #Password specified?
    if [ ! -z "$4" ]; then
        echo "($1:$2:$3)"
        addgroup -g "$3" "$1"
        gname="$(getent group "$3" | cut -d: -f1)"
        adduser -H -D -h "/home/$1" -g "" -G "$gname" -u "$2" "$1"
        #adduser $1 $SMB_USERS_GUID
        (echo "$4"; echo "$4") | (smbpasswd -a "$1")
        echo "- $1 added"
    else
        echo "WARNING: New users must have a password, user $1 not added"
    fi
}
#username, pw
user_update () {
    #format checking
    if [ -z $1 ]; then
        echo "ERROR: user_update invalid arg"
        exit
    fi

    #Password exists?
    if [ ! -z "$2" ]; then
        echo "- Changing user ($1) password"
        (echo "$2"; echo "$2") | (smbpasswd -a "$1")
    fi
}

echo "Updating samba users...
"
#root check
if [ $(id -u) != "0" ]; then
    echo "ERROR: Not running as root"
    exit
fi

#Check if config files exist
if [ ! -f "/config/smb.conf" ]; then
    echo "- Creating /config/smb.conf"
    cp /etc/samba/custom/smb.conf /config/smb.conf
    chown samba:samba /config/smb.conf
    chmod 660 /config/smb.conf
fi
if [ ! -f "/config/smb.users" ]; then
    echo "- Creating /config/smb.users"
    cp /etc/samba/custom/smb.users /config/smb.users
    chown samba:samba /config/smb.users
    chmod 660 /config/smb.users
fi

#reading smb.users
file="/config/smb.users"
lines=$(cat $file | sed '/^\s*#/d;/^\s*$/d')

#checking user removes
log="/etc/samba/custom/smb.users.log"
if [ ! -f "$log" ]; then
    touch "$log"
    chown root:root "$log" 
    chmod 600 "$log"
fi
loglines=$(cat $log | sed '/^\s*#/d;/^\s*$/d')
#removing unneeded users
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

    echo "--------------------------"

    #debug
    #echo "$new_user:$new_uid:$new_gid:$new_pw"

    #check if new_user is valid
    if [ -z "$new_user" ]; then
        echo "WARNING: username not specified, ignoring"
        continue
    fi

    #Check if user already exists
    if [ ! -z "$(getent passwd "$new_user" | cut -d: -f1)" ]; then
        #modify existing user
        echo "- Modifying user ($new_user)"

        #replace uid if needed
        if [ ! -z "$new_uid" ] && [[ "$new_uid" =~ ^[0-9]+$ ]]; then
            echo "- Replacing UID"
            sed -i -e "s/^$new_user:\([^:]*\):[0-9]*:\([0-9]*\)/$new_user:\1:$new_uid:\2/" /etc/passwd
        fi

        #replace gid if needed
        if [ ! -z "$new_gid" ] && [[ "$new_gid" =~ ^[0-9]+$ ]]; then
            echo "- Replacing GID"
            sed -i -e "s/^$new_user:\([^:]*\):[0-9]*/$new_user:\1:$new_gid/" /etc/group
            sed -i -e "s/^$new_user:\([^:]*\):\([0-9]*\):[0-9]*/$new_user:\1:\2:$new_gid/" /etc/passwd
        fi

        #replace password
        if [ ! -z "$new_pw" ]; then
            user_update $new_user $new_pw
        fi
    else
        #create new user
        echo "- Creating user ($new_user)"

        user_add $new_user $new_uid $new_gid $new_pw

        #add to smb.users.log
        echo "$new_user" >> "$log"

        #remove pw from smb.users
        if [ "$SMB_USERS_REMOVE_PASSWORD" = "1" ]; then
            echo "- Removing password from smb.users"
            sed -i -e "s/^$new_user:.*/$new_user:$new_uid:$new_gid/" "$file"
        fi
    fi
done

echo "--------------------------"
echo "OK"