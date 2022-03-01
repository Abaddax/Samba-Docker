#building startup routine
FROM alpine:latest AS build-env

#installing gcc
RUN apk add --no-cache build-base

RUN mkdir /build

COPY build/startup_routine.c /build/startup_routine.c
RUN gcc -o /build/startup_routine /build/startup_routine.c


#samba image
FROM alpine:latest

EXPOSE 4455

#Upgrade and samba install
RUN apk --no-cache upgrade && \
    apk --no-cache add \
	    coreutils \
        util-linux \
	    bash \
	    samba \
	    samba-common \
	    samba-server

#Add samba user
RUN addgroup \
        -S -g 1000 \
        samba && \
    adduser \
        -S -H -D \
        -h /etc/samba/custom \
        -s /bin/bash \
        -u 1000 \
        -G samba \
        samba

#Create directories
RUN mkdir -p /data /config /logs /etc/samba/custom && \
    chown -R samba:samba /data /config /logs

VOLUME [ "/data" ]
VOLUME [ "/config" ]
VOLUME [ "/logs" ]


#Copy config templates
COPY --chown=root:root  config/smb.users    /etc/samba/custom/smb.users
COPY --chown=root:root  config/smb.conf     /etc/samba/custom/smb.conf
RUN chmod 400 /etc/samba/custom/smb.users && \
    chmod 400 /etc/samba/custom/smb.conf


#Making smbd workdir accessable to samba
RUN mkdir -p /var/cache/samba /var/lib/samba /var/run/samba && \
    chown -R samba:samba /var/cache/samba && \
    chown -R samba:samba /var/lib/samba && \
    chown -R samba:samba /var/run/samba

#Copy startup routine
COPY --from=build-env --chown=root:root /build/startup_routine /startup_routine
COPY --chown=root:root build/update_current_user.sh /etc/samba/custom/update_current_user.sh
COPY --chown=root:root build/update_samba_dirs.sh /etc/samba/custom/update_samba_dirs.sh
COPY --chown=root:root build/update_samba_users.sh /etc/samba/custom/update_samba_users.sh
RUN chmod a=xs startup_routine && \
    chmod 400 /etc/samba/custom/update_current_user.sh && \
    chmod 400 /etc/samba/custom/update_samba_dirs.sh && \
    chmod 400 /etc/samba/custom/update_samba_users.sh

#Copy entrypoint
COPY --chown=root:root entrypoint.sh /entrypoint.sh
RUN chmod 555 /entrypoint.sh

USER 1000:1000

ENV SMB_USERS_REMOVE_PASSWORD 1

ENTRYPOINT [ "/entrypoint.sh" ]