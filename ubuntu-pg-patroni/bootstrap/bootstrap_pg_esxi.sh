#!/bin/bash
LOCAL_IP=$(ip addr show | grep -oP 'inet \K10\.[\d.]+')
ETCD_IP="10.17.9.72"
echo "Local ip is: $LOCAL_IP. ETCD is at: $ETCD_IP"
SHORT_HOSTNAME=$(nslookup $LOCAL_IP | awk '/name =/ { print $4 }' | head -n1 | awk -F. '{print $1}')
echo "Hostname is: $SHORT_HOSTNAME"
NET_CIDR="10.17.0.0/16"

wget -q -O /tmp/repo-add.sh https://repo.postgrespro.ru/1c-15/keys/pgpro-repo-add.sh
chmod +x /tmp/repo-add.sh
bash -c "/tmp/repo-add.sh"
apt-get update -y
# install pg1c
apt-get install postgrespro-1c-15 bzip2 tar build-essential \
    dkms linux-headers-$(uname -r) python3-pip python3-dev libpq-dev -y
systemctl daemon-reload
systemctl start postgrespro-1c-15
systemctl stop postgrespro-1c-15
systemctl status postgrespro-1c-15
systemctl disable postgrespro-1c-15

#set ru_RU locale:
locale-gen ru_RU
locale-gen ru_RU.UTF-8
update-locale
# update pip; install patroni
pip3 install --upgrade pip
pip install patroni[psycopg3,etcd3]

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
scope: postgres
namespace: /db/
name: $SHORT_HOSTNAME
restapi:
  listen: $LOCAL_IP:8008
  connect_address: $LOCAL_IP:8008
etcd:
  host: $ETCD_IP:2379
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
    - host replication replicator   $NET_CIDR   md5
    - host replication replicator   $NET_CIDR   md5
    - host all all   $NET_CIDR   md5
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
   authentication:
    replication:
      username: replicator
      password: "qwer1234StrongPassword"
    superuser:
      username: postgres
      password: "B1qaz2wsx3edc"
      parameters:
      unix_socket_directories: '.'
tags:
   nofailover: false
   noloadbalance: false
   clonefrom: false
   nosync: false
EOF
echo
systemctl daemon-reload && systemctl start patroni