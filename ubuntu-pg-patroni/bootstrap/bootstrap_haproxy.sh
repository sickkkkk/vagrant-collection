#!/bin/bash
set -x
export DEBIAN_FRONTEND=noninteractive
systemctl disable --now ufw 
apt-get update -y
apt -y install haproxy

echo "[TASK 2] Set root password"
echo -e "admin\nadmin" | passwd root 
echo "export TERM=xterm" >> /etc/bash.bashrc

cat >>/etc/hosts<<EOF
172.18.50.151   pg1.int.ohmylab.io     pg1
172.18.50.152   pg2.int.ohmylab.io     pg2
172.18.50.153   pg3.int.ohmylab.io     pg3
172.18.50.55    etcd.int.ohmylab.io    etcd
172.18.50.60    haproxy.int.ohmylab.io  haproxy
172.18.50.160    backupsrv.int.ohmylab.io  backupsrv
EOF

cat >>/etc/haproxy/haproxy.cfg<<EOF
global
      maxconn 100
defaults
      log global
      mode tcp
      retries 10
      timeout client 30m
      timeout connect 4s
      timeout server 30m
      timeout   check   5s
listen stats
      mode http
      bind *:7000
      stats enable
      stats uri /
listen postgres
      bind *:5432
      mode tcp
      option httpchk GET /health
      http-check expect status 200
      default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
      server pg1 172.18.50.151:5432 maxconn 100   check   port 8008
      server pg2 172.18.50.152:5432 maxconn 100   check   port 8008
      server pg3 172.18.50.153:5432 maxconn 100   check   port 8008
      log global
EOF

systemctl restart haproxy