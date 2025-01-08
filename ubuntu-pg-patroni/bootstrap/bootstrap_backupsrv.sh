#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
USERPASSWORD="B1qaz2wsx3edc"
systemctl disable --now ufw
# local hosts file
cat >>/etc/hosts<<EOF
172.18.50.151   pg1.int.ohmylab.io     pg1
172.18.50.152   pg2.int.ohmylab.io     pg2
172.18.50.153   pg3.int.ohmylab.io     pg3
172.18.50.55    etcd.int.ohmylab.io    etcd
172.18.50.60    haproxy.int.ohmylab.io  haproxy
172.18.50.160    backupsrv.int.ohmylab.io  backupsrv
EOF
# root password
echo -e "admin\nadmin" | passwd root 
echo "export TERM=xterm" >> /etc/bash.bashrc
#set ru_RU locale:
locale-gen ru_RU
locale-gen ru_RU.UTF-8
update-locale
# packages
apt-get update -y
apt-get install bzip2 tar build-essential \
    dkms linux-headers-$(uname -r) python3-pip python3-dev libpq-dev pgbackrest -y
# pgbackrest setup - local repo
mkdir -p /backup/pgbackrestrepo && \
chmod 750 /backup/pgbackrestrepo && \
chown postgres:postgres /backup/pgbackrestrepo
# pgbackrest - log dirs
mkdir -p -m 770 /var/log/pgbackrest && \
chown postgres:postgres /var/log/pgbackrest
# temp dirs permissions
mkdir -p /tmp/pgbackrest
chown -R postgres:postgres /var/log/pgbackrest && \
chown -R postgres:postgres /tmp/pgbackrest && \
chmod 750 /var/log/pgbackrest && \
chmod 700 /tmp/pgbackrest
# pgbackrest - starter config
echo "" > /etc/pgbackrest.conf
cat >>/etc/pgbackrest.conf<<EOF
[global]
repo1-path=/backup/pgbackrestrepo
repo1-retention-full=14
repo1-retention-full-type=time
archive-check=n
process-max=1
log-level-console=info
log-path=/var/log/pgbackrest
log-level-file=debug
start-fast=y
delta=y
compress-level=3

[postgres_sandbox]
pg1-host=172.18.50.151
pg1-host-user=postgres
pg1-database=postgres
pg1-path=/data/patroni
pg1-port=5432

pg2-host=172.18.50.152
pg2-host-user=postgres
pg2-database=postgres
pg2-path=/data/patroni
pg2-port=5432

pg3-host=172.18.50.153
pg3-host-user=postgres
pg3-database=postgres
pg3-path=/data/patroni
pg3-port=5432
EOF
# update postgres user password in system
echo "postgres:${USERPASSWORD}" | chpasswd
echo "Password updated for postgres user."
