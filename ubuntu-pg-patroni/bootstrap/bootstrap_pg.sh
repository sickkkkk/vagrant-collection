#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
PG_MAJOR_VERSION="16"
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
LOCAL_IP=$(ip addr show | grep -oP 'inet \K172\.18\.50\.\d+')
echo $LOCAL_IP
ETCD_IP="172.18.50.55"
SHORT_HOSTNAME=$(nslookup $LOCAL_IP | awk '/name =/ { print $4 }' | head -n1 | awk -F. '{print $1}')
echo "Hostname is $HOSTNAME"
apt install curl ca-certificates -y
install -d /usr/share/postgresql-common/pgdg
curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
apt-get update -y
# install pg
apt-get install postgresql-$PG_MAJOR_VERSION bzip2 tar build-essential \
    dkms linux-headers-$(uname -r) python3-pip python3-dev libpq-dev pgbackrest -y
systemctl daemon-reload
systemctl start postgresql
systemctl stop postgresql
systemctl status postgresql
systemctl disable postgresql

echo -e "admin\nadmin" | passwd root 
echo "export TERM=xterm" >> /etc/bash.bashrc

#set ru_RU locale:
locale-gen ru_RU
locale-gen ru_RU.UTF-8
update-locale

pip3 install --upgrade pip
pip install "patroni[psycopg3,etcd3]==3.2.2"
ln -s /usr/lib/postgresql/$PG_MAJOR_VERSION/bin/* /usr/sbin/
mkdir -p /data/patroni
chown postgres:postgres -R /data
chmod 700 /data/patroni/

cat >>/etc/systemd/system/patroni.service<<EOF
[Unit]
Description=Patroni Orchestration
After=syslog.target network.target
[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni.yml
KillMode=process
TimeoutSec=30
Restart=no
[Install]
WantedBy=multi-user.targ
EOF

echo "Bootstrapping patroni config for $SHORT_HOSTNAME with $LOCAL_IP. etcd is at: $ETCD_IP"
cat >>/etc/patroni.yml<<EOF
scope: postgres_sandbox
namespace: /db/
name: $SHORT_HOSTNAME
restapi:
  listen: $LOCAL_IP:8008
  connect_address: $LOCAL_IP:8008
etcd:
  host: $ETCD_IP:2379
  protocol: http
  version: "v2"
bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
    use_pg_rewind: true
  initdb:
    - encoding: UTF8
    - data-checksums
    - auth-host: md5
    - locale: ru_RU.utf8
  pg_hba:
    - host replication replicator   127.0.0.1/32 md5
    - host replication replicator   172.18.50.0/24   md5
    - host replication replicator   172.18.50.0/24   md5
    - host all all   0.0.0.0/0   md5
  users:
    admin:
       password: admin
       options:
       - createrole
       - createdb
postgresql:
   listen: $LOCAL_IP:5432
   connect_address: $LOCAL_IP:5432
   data_dir: /data/patroni
   pgpass: /tmp/pgpass
   password_encryption: md5
   parameters:
    archive_command: pgbackrest --stanza=postgres_sandbox archive-push "%p"
    archive_mode: "on"
   authentication:
    replication:
      username: replicator
      password: "qwer1234StrongPassword"
    superuser:
      username: postgres
      password: "${USERPASSWORD}"
      parameters:
      unix_socket_directories: '.'
   create_replica_methods:
      - pgbackrest
      - basebackup
   pgbackrest:
      command: pgbackrest --stanza=postgres_sandbox restore --type=none
      keep_data: True
      no_params: True
   basebackup:
      checkpoint: 'fast'
tags:
   nofailover: false
   noloadbalance: false
   clonefrom: false
   nosync: false
EOF
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
repo1-host=172.18.50.160
repo1-host-user=postgres
log-level-file=warn
log-path=/var/log/pgbackrest
# 'process-max=1' or similar might be used if needed.

[postgres_sandbox]
pg1-database=postgres
pg1-path=/data/patroni
pg1-port=5432
EOF
# update postgres user password in system
echo "postgres:${USERPASSWORD}" | chpasswd
echo "Password updated for postgres user."

systemctl daemon-reload && systemctl start patroni
