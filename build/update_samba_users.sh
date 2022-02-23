#!/bin/bash

#username
user_del () {
    echo "Deleting old user ($1)"
    deluser --remove-home $1
    smbpasswd -x $1
}
#username, id, pw
user_add () {
    echo "Adding new user ($1:$2:$3)"
	#new user already exist?
    if [ ! -z $(getent passwd "$1" | cut -d: -f1) ]; then
        echo "Deleting wrong user ($1)"
        sudo deluser --remove-home $1
    fi
    #Password exists?
    if [ ! -z "$3" ]; then
       (echo "$3"; echo "$3") | (adduser -H -h/home/nas-users/$1 -g "" -u "$2" "$1")
       adduser $1 nas-drive-access
    else
        echo "New Users must have a password"
    fi
}
#username, pw
smb_add () {
    #Password exists?
    if [ ! -z "$2" ]; then
        echo "Changing samba password"
        (echo "$2"; echo "$2") | (smbpasswd -a "$1")
    fi
}


if [ $(id -u) != "0" ]; then
    echo "Not Running as root"
    exit
fi

#Check if config files exist
if [ ! -f "/config/smb.conf" ]; then
    echo "Creating /config/smb.conf"
    cp /etc/samba/custom/smb.conf /config/smb.conf
fi
if [ ! -f "/config/smb.users" ]; then
    echo "Creating /config/smb.users"
    cp /etc/samba/custom/smb.users /config/smb.users
fi

#reading smb.users
file="/config/smb.users"
lines=$(cat $file | sed '/^\s*#/d;/^\s*$/d')

userid=1999

#Check usercount
user_count=$(cat $file | sed '/^\s*#/d;/^\s*$/d' | wc -l)
last_user=$(cut -d: -f3 /etc/passwd | tail -1)
user_diff=$(($last_user-1999-$user_count))

#Removing unneeded users
if [ $user_diff -gt 0 ]; then
    echo "$user_diff"
    uid=$last_user
    while [ $uid -ge $((2000+$user_count)) ]; do
        user=$(getent passwd "$uid" | cut -d: -f1)
        user_del "$user"
        uid=$((uid - 1))
    done
fi


for line in $lines; do
    #Increase UserID
    userid=$((userid + 1))
	#reading user:pw
    new_user=$(echo "$line" | cut -d':' -f1)
    new_pw=""
    if $(echo "$line" | grep -q ":"); then
        new_pw=$(echo "$line" | cut -d':' -f2)
    fi

    #Debug
    echo "\nuser:$new_user"

    #Check if an user already exists
    old_user=$(getent passwd "$userid" | cut -d: -f1)
    #user exists?
    if [ ! -z "$old_user" ]; then
        echo "Old user found"
        #right user?
        if [ "$old_user" != "$new_user" ]; then
            #delete old user and create new     user
            user_del $old_user
            user_add $new_user $userid $new_pw
        fi
    else
        user_add $new_user $userid $new_pw
    fi

    #Changing samba password
    smb_add $new_user $new_pw

done
