#!/bin/bash
ETCD_VERSION="v3.3.25"
ETCD_ARCH="linux-arm64"
ETCD_TARBALL="etcd-${ETCD_VERSION}-${ETCD_ARCH}.tar.gz"
ETCD_URL="https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/${ETCD_TARBALL}"
LOCAL_IP="172.18.50.55"
systemctl disable --now ufw 
apt-get update -y
echo "Downloading etcd ${ETCD_VERSION}..."
wget ${ETCD_URL}
echo "Extracting ${ETCD_TARBALL}..."
tar -xvf ${ETCD_TARBALL}
mv etcd-${ETCD_VERSION}-${ETCD_ARCH}/etcd /usr/local/bin/
mv etcd-${ETCD_VERSION}-${ETCD_ARCH}/etcdctl /usr/local/bin/
# Clean up
echo "Cleaning up..."
rm -rf ${ETCD_TARBALL} etcd-${ETCD_VERSION}-${ETCD_ARCH}
# Verify installation
echo "etcd installation completed successfully."
echo -e "admin\nadmin" | passwd root 
echo "export TERM=xterm" >> /etc/bash.bashrc
cat >>/etc/hosts<<EOF
172.18.50.151   pg1.int.ohmylab.io     pg1
172.18.50.152   pg2.int.ohmylab.io     pg2
172.18.50.55    etcd.int.ohmylab.io    etcd
172.18.50.60    haproxy.int.ohmylab.io  haproxy
EOF
touch /etc/default/etcd.conf.yml
cat >>/etc/default/etcd.conf.yml<<EOF
name: etcd0
data-dir: /var/lib/etcd
listen-peer-urls: "http://$LOCAL_IP:2380,http://$LOCAL_IP:7001"
listen-client-urls: "http://127.0.0.1:2379,http://$LOCAL_IP:2379"
initial-advertise-peer-urls: "http://$LOCAL_IP:2380"
initial-cluster: "etcd0=http://$LOCAL_IP:2380"
advertise-client-urls: "http://$LOCAL_IP:2379"
initial-cluster-token: "pg1"
initial-cluster-state: "new"
EOF

cat >>/etc/systemd/system/etcd.service<<EOF
[Unit]
Description=etcd
Documentation=https://github.com/etcd-io/etcd
After=network.target

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd --config-file /etc/default/etcd.conf.yml
Restart=always
RestartSec=10s
LimitNOFILE=40000

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload && \
systemctl enable etcd && \
systemctl start etcd && \
systemctl status etcd

etcd --version
etcdctl -version