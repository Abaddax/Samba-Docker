# Samba
		
Samba docker container (rootless)
		
# Purpose
		
This project is a simple docker container that allows you to create SMB-network-shares (via samba). It's meant for use in private networks.
I create this project for my own usage on a Raspberry Pi 4 (Raspberry Pi OS Lite 64 Bit) and that's also the only platform I tested this.


# How to build
		
Download this project and navigate into the folder containing the Dockerfile
		
    docker build -t samba:0.1 .

# How to use
		
## General
		
Before you create a container make sure you have at least 2 folders you can map to the container-volumes `/data` and `/config`.
It it recommended to also have a folder for `/logs`.
		
* `/data` is meant to contain the NAS-Folders you want to shares
* `/config` contains `smb.conf` and `smb.users`
* `/logs` will contain samba log files
		
Make sure the user `1000:1000` has access to them, otherwise change the container-user with the `--user` option.
		
## Configuration
		
The `/config` volume contains two files `smb.conf` and `smb.users`.
* `smb.conf` is the normal (slightly modified) samba config file, for more information use [this](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html).
* `smb.users` is a custom file that contains all samba users (users that have access to samba shares). It is used to automatically create the needed samba users or remove unneeded samba users. By default the passwords (plain text) will be removed after the container starts, to disable this behaviour use the `SMB_USERS_REMOVE_PASSWORD=0` environment variable.
		
## Creating a container using docker run
    docker run -d -p 445:4455 --name samba --user 1000:1000 --restart=unless-stopped -v ./data:/data -v ./config:/config -v ./logs:/logs samba:0.1
		
## Create a container with compose file
    version: "3"
    services:
        server:
            image: samba:0.1
            user: "1000:1000"
            container_name: samba
            restart: unless-stopped
            volumes:
                - ./data:/data
                - ./config:/config
                - ./logs:/logs
            ports:
                - "445:4455"
