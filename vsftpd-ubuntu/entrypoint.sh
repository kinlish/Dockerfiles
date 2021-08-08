#!/bin/bash

# Color
YELLOW='\033[0;33m'
NC='\033[0;00m'

__ANONYMOUS__=anonymous

start() {
  isrunning="$(service vsftpd status | cut -d' ' -f6)"

  if [ "$isrunning" = "not" ]; then
    service vsftpd start
  fi
}

reload() {
  isrunning="$(service vsftpd status | cut -d' ' -f6)"

  if [ "$isrunning" = "running" ]; then
    service vsftpd reload
  fi
}

stop() {
  isrunning="$(service vsftpd status | cut -d' ' -f6)"

  if [ "$isrunning" = "running" ]; then
    service vsftpd stop
  fi
}

quit() {
  stop &
  cmdpid=$!
  wait $cmdpid
  exit $$
}

create_group() {
  groupname="${1:-DEFAULT_GROUP}"

  groupent="$(getent group "$groupname")"
  
  if [ -z "$groupent" ]; then
    addgroup --quiet "$groupname"
  fi
}

create_user() {
  username="${1:-$DEFAULT_USER}"
  
  if [ ! -z "$username" ]; then
    userent="$(getent passwd "$username")"
  
    if [ -z "$userent" ]; then
      groupname="${3:-$DEFAULT_GROUP}"

      create_group "$groupname"

      userdir=$FTP_ROOT/$username
      mkdir -p -m +w $userdir/files/
      useradd -M -d $userdir -G $groupname $username &
      upid=$!
      wait $upid

      chmod a-w $userdir
      chown $username:$groupname $userdir/files/
  
      echo $username:${2:-$DEFAULT_PWD} | chpasswd
    fi
  fi
}

deny_user() {
  if [ -z $(cat /etc/ftpusers | sed -n "/$1/p") ]; then
    echo $1 >> /etc/ftpusers
  fi
}

allow_user() {
  sed -i "/^$1$/d" /etc/ftpusers
}

deny_chroot() {
  sed -i "/^$1$/d" /etc/vsftpd.chroot_list
}

allow_chroot() {
  userent="$(getent passwd "$1")"
  if [ ! -z "$userent" ] && [ -z $(cat /etc/vsftpd.chroot_list | sed -n "/$1/p") ]; then
    echo $1 >> /etc/vsftpd.chroot_list
  fi
}

show_conf() {
  if [ -z "$1" ]; then
    cat << @EOF
VSFTPD SETTINGS 
----------------------------------------------
$(cat /etc/vsftpd.conf)
@EOF
  else
    cat /etc/vsftpd.conf | sed -n -E "/($1)[[:print:]]+/p"
  fi
}

modify_conf() {
  sed -i -E "s/^($1)=[[:print:]]+/\1=$(echo $2 | sed 's/\//\\\//g')/g" /etc/vsftpd.conf
  reload
}

help() {
  cat << @EOF
Support command usage:
===========================================
- start
- reload
- stop
- quit
- create_user @USERNAME [@PASSWORD] [@GROUPNAME]
- deny_user @USERNAME
- allow_user @USERNAME
- deny_chroot @USERNAME
- allow_chroot @USERNAME
- show_conf [@%CONF_KEY%]
- modify_conf @CONFIG_NAME @VALUE
@EOF
}

sed -i "s/\$FTP_ROOT/$(echo $FTP_ROOT | sed 's/\//\\\//g')/g" /etc/vsftpd.conf
IFS="-" read MINPORT MAXPORT <<< $PASV_PORT
modify_conf pasv_min_port $MINPORT
modify_conf pasv_max_port $MAXPORT
modify_conf pasv_address $PASV_ADDRESS

create_user

mkdir -p -m a+w $FTP_ROOT/$__ANONYMOUS__/files
useradd -M -d $FTP_ROOT/$__ANONYMOUS__ -G ftp -s /usr/sbin/nologin $__ANONYMOUS__
chmod a-w $FTP_ROOT/$__ANONYMOUS__
chown $__ANONYMOUS__:$DEFAULT_GROUP $FTP_ROOT/$__ANONYMOUS__/files

start

cat << @EOF 
===========================================
- PASV port range : $MINPORT - $MAXPORT
- FTP directory   : $FTP_ROOT
- Enable anonymous: $(grep -m1 "pasv_enable" /etc/vsftpd.conf | cut -d'=' -f2)
- Allow chroot    : $(grep -m1 "chroot_list_enable" /etc/vsftpd.conf | cut -d'=' -f2)
- Enable SSL      : $(grep -m1 "ssl_enable" /etc/vsftpd.conf | cut -d'=' -f2)

type "help" to get performe command

@EOF

trap quit SIGINT SIGTERM

command=$@

while [ ! "$command" = "quit" ]; do
  if [ -z "$command" ]; then
    read command
    continue
  fi
  $command &
  cmdpid=$!
  wait $cmdpid
  printf "${YELLOW}vsftpd > ${NC}"
  read command
done
