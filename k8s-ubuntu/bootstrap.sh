#!/bin/bash

## !IMPORTANT ##
#
## This script is tested only in the generic/ubuntu2204 Vagrant box
## If you use a different version of Ubuntu or a different Ubuntu Vagrant box test this again
#
set -x

echo "[TASK 1] Disable and turn off SWAP"
sed -i '/swap/d' /etc/fstab
swapoff -a

echo "[TASK 2] Stop and Disable firewall"
systemctl disable --now ufw 

echo "[TASK 3] Enable and Load Kernel modules"
cat >>/etc/modules-load.d/containerd.conf<<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

echo "[TASK 4] Add Kernel settings"
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system 

echo "[TASK 5] Install containerd runtime"
apt update -y
apt install containerd -y
systemctl enable containerd 
systemctl start containerd 
mkdir -p /etc/containerd/
containerd config default | sudo tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sed -i 's/sandbox_image \= "registry.k8s.io\/pause:3.8"/sandbox_image \= "registry.k8s.io\/pause:3.9"/g' /etc/containerd/config.toml
systemctl restart containerd

echo "[TASK 6] Install kubeadm from deb"
# apt-transport-https may be a dummy package; if so, you can skip that package
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

echo "[TASK 7] Enable ssh password authentication"
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl reload sshd

echo "[TASK 8] Set root password"
echo -e "kubeadmin\nkubeadmin" | passwd root 
echo "export TERM=xterm" >> /etc/bash.bashrc

echo "[TASK 9] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
172.16.55.50   kmaster.int.ohmylab.io     kmaster
172.16.55.61   kworker01.int.ohmylab.io    kworker01
172.16.55.62   kworker02.int.ohmylab.io    kworker02
EOF