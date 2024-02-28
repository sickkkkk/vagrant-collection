set -x

systemctl disable --now ufw 
apt-get update -y && apt-get install etcd -y


echo -e "admin\nadmin" | passwd root 
echo "export TERM=xterm" >> /etc/bash.bashrc

cat >>/etc/hosts<<EOF
172.18.50.151   pg1.int.ohmylab.io     pg1
172.18.50.152   pg2.int.ohmylab.io     pg2
172.18.50.55    etcd.int.ohmylab.io    etcd
172.18.50.60    haproxy.int.ohmylab.io  haproxy
EOF

LOCAL_IP=$(ip addr show | grep -oP 'inet \K172\.[\d.]+')
cat >>/etc/default/etcd<<EOF
ETCD_LISTEN_PEER_URLS  =  "http://$LOCAL_IP:2380,http://$LOCAL_IP:7001"
ETCD_LISTEN_CLIENT_URLS  =  "http://127.0.0.1:2379, http://$LOCAL_IP:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS  =  "http://$LOCAL_IP:2380"
ETCD_INITIAL_CLUSTER  =  "etcd0=http://$LOCAL_IP:2380"
ETCD_ADVERTISE_CLIENT_URLS  =  "http://$LOCAL_IP:2379"
ETCD_INITIAL_CLUSTER_TOKEN  =  "pg1"
ETCD_INITIAL_CLUSTER_STATE  =  "new"
EOF

systemctl enable etcd && systemctl restart etcd && systemctl status etcd