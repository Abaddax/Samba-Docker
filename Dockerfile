#building startup routine
FROM alpine:latest AS build-env

#installing gcc
RUN apk add --no-cache build-base

RUN mkdir /build
#to be removed
COPY startup_routine.c /build/startup_routine.c

RUN gcc -o /build/startup_routine /build/startup_routine.c


#samba image
FROM alpine:latest

#Upgrade and samba install
RUN apk --no-cache upgrade
RUN apk --no-cache add \
	coreutils \
	bash \
	samba \
	samba-common \
	samba-server

#Add samba user	
RUN addgroup \
    -S -g 1000 \
    samba
RUN adduser \
    -S -H -D \
    -h /etc/samba/custom \
    -s /bin/bash \
    -u 1000 \
    -G samba \
    samba

#Create directories
RUN mkdir -p /data /config /logs /etc/samba/custom

#Copy config templates
RUN cp /etc/samba/smb.conf /etc/samba/custom/smb.conf
COPY smb.users /etc/samba/custom/smb.users
RUN chown -R samba:samba /data /config /logs /etc/samba/custom
COPY --chown=root:root smb_redirect.conf /etc/samba/smb.conf

#Making samba work dir accessable for samba-user


#to be removed
COPY --chown=root:root update_current_user.sh /etc/samba/custom/update_current_user.sh
COPY --chown=root:root update_samba_users.sh /etc/samba/custom/update_samba_users.sh

#Copy startup routine
COPY --from=build-env --chown=root:root /build/startup_routine /etc/samba/custom/startup_routine
RUN chmod a=xs /etc/samba/custom/startup_routine

#Copy entrypoint
COPY --chown=root:root entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh


ENV USER samba
ENV SHARE_GID 1002

USER 1000:1000

EXPOSE 445

VOLUME [ "/data" ]
VOLUME [ "/config" ]
VOLUME [ "/logs" ]

ENTRYPOINT [ "/entrypoint.sh" ]