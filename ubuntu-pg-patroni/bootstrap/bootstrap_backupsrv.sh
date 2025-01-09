#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export USERPASSWORD=""
export AWS_ACCESS_KEY_ID=""
export AWS_ACCESS_KEY=""
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
apt install curl ca-certificates -y
install -d /usr/share/postgresql-common/pgdg
curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
apt-get update -y
# install pg
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
repo2-type=s3
repo2-path=/pgbackrestrepo
repo2-s3-bucket=pgbackrest-rpwsdkeq6rbmpwlo
repo2-s3-region=eu-central-1
repo2-s3-endpoint=s3.eu-central-1.amazonaws.com
repo2-s3-verify-tls=y
repo2-s3-key=${AWS_ACCESS_KEY_ID}
repo2-s3-key-secret=${AWS_ACCESS_KEY}
repo2-retention-full=14
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
