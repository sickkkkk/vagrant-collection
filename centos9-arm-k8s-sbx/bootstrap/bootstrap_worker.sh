#!/bin/bash
set -x
echo "Disable and turn off SWAP"
sed -i '/swap/d' /etc/fstab
swapoff -a

echo "Disable firewalld"
systemctl disable firewalld && systemctl stop firewalld

echo "Disable SELinux"
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

echo "Update hosts file"
cat >>/etc/hosts<<EOF
172.18.50.55    master.cluster.local    master
172.18.50.61    worker01.cluster.local  worker01
172.18.50.62    worker02.cluster.local  worker02
EOF