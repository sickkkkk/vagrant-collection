#!/bin/bash
set -x
echo "[TASK 1] Join node to Kubernetes Cluster"
apt install -y sshpass 
sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no kmaster.int.ohmylab.io:/joincluster.sh /joincluster.sh 2>/dev/null
bash /joincluster.sh 
