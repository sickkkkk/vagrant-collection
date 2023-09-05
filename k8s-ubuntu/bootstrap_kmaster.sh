#!/bin/bash
set -x
echo "[TASK 1] Pull required containers"
sudo kubeadm config images pull 

echo "[TASK 2] Initialize Kubernetes Cluster"
sudo kubeadm init --apiserver-advertise-address=172.16.55.50 --pod-network-cidr=192.168.0.0/16

echo "[TASK 3] Deploy Calico network"
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo "[TASK 4] Generate and save cluster join command to /joincluster.sh"
sudo kubeadm token create --print-join-command > /joincluster.sh

echo "[TASK 5] Install qol tips for kubeadm"
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
echo 'alias k=kubectl' >> ~/.bashrc 
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
echo 'KUBECONFIG=/etc/kubernetes/admin.conf' >> ~/.bashrc
source ~/.bashrc