#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
echo "Update hosts file"
cat >>/etc/hosts<<EOF
172.18.50.71    kmaster1.cluster.local    kmaster1
172.18.50.72    kmaster2.cluster.local    kmaster2
172.18.50.61    kworker.cluster.local  kworker
172.18.50.100   haproxy.cluster.local  haproxy
EOF