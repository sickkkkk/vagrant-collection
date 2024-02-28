#!/bin/bash
set -x

systemctl disable --now ufw 
LOCAL_IP=$(ip addr show | grep -oP 'inet \K172\.[\d.]+')
echo 
#ETCD_IP=$(nslookup etcd | awk '/^Address: / { print $2 }' | tail -n1)
ETCD_IP="172.18.50.55"
SHORT_HOSTNAME=$(nslookup $LOCAL_IP | awk '/name =/ { print $4 }' | head -n1 | awk -F. '{print $1}')
# add pgpro repo
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

echo -e "admin\nadmin" | passwd root 
echo "export TERM=xterm" >> /etc/bash.bashrc

cat >>/etc/hosts<<EOF
172.18.50.151   pg1.int.ohmylab.io     pg1
172.18.50.152   pg2.int.ohmylab.io     pg2
172.18.50.55    etcd.int.ohmylab.io    etcd
172.18.50.60    haproxy.int.ohmylab.io  haproxy
EOF

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