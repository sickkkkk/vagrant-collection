#!/bin/bash
set -x
echo "[TASK 1] Pull required containers"
sudo kubeadm config images pull 

echo "[TASK 2] Initialize Kubernetes Cluster"
sudo kubeadm init --apiserver-advertise-address=172.16.55.50 --pod-network-cidr=192.168.0.0/16 >> /root/kubeinit.log

echo "[TASK 3] Deploy Calico network"
sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml 

echo "[TASK 4] Generate and save cluster join command to /joincluster.sh"
sudo kubeadm token create --print-join-command > /joincluster.sh