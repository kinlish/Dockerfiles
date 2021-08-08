FROM kinlish/ubuntu-u

WORKDIR /usr/local/bin/

ENV LANG=C.UTF-8 \
    DEFAULT_GROUP=ftp \
    DEFAULT_USER=admin \
    DEFAULT_PWD=password \
    PASV_ADDRESS=192.168.1.100 \
    PASV_PORT=55550-55555 \
    FTP_ROOT=/var/ftp

ADD entrypoint.sh .

RUN apt install -y vsftpd && \
    touch /etc/vsftpd.chroot_list && mkdir -p $FTP_ROOT && chown nobody:nogroup $FTP_ROOT && \
    echo "vsftpd: ALL" >> /etc/hosts.allow && \
    chmod +x ./entrypoint.sh

ADD vsftpd.conf /etc/

EXPOSE 20 21 $PASV_PORT

ENTRYPOINT ["./entrypoint.sh"]

CMD ["start"]