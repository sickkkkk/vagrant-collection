#/!/bin/bash
set -x
export POD_CIDR="10.10.20.0/24"

echo "[TASK 1] Disable and turn off SWAP"
sed -i '/swap/d' /etc/fstab
swapoff -a

# not covered in tutorail dues to ec2 vm origin maybe?
echo "[TASK 2] Stop and Disable firewall"
systemctl disable --now ufw

echo "[TASK 3] Add network specific kernel settings"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

cat >>/etc/sysctl.d/k8s.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

echo "[TASK 4] Install containerd and nerdctl for container runtime control"
#sudo bash 
cd /tmp
apt update -y
apt install containerd -y
systemctl enable containerd
systemctl start containerd
# initialise default config for containerd
mkdir -p /etc/containerd/
containerd config default | sudo tee /etc/containerd/config.toml
# replace cgroup driver with runc
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
# fix sandpox image
sed -i 's/sandbox_image \= "registry.k8s.io\/pause:3.8"/sandbox_image \= "registry.k8s.io\/pause:3.9"/g' /etc/containerd/config.toml
systemctl restart containerd

wget https://github.com/containerd/nerdctl/releases/download/v1.5.0/nerdctl-1.5.0-linux-amd64.tar.gz
tar zxvf nerdctl-1.5.0-linux-amd64.tar.gz 
mv nerdctl /usr/local/bin/
wget https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz
mkdir -p /opt/cni/bin
tar zxvf cni-plugins-linux-amd64-v1.3.0.tgz -C /opt/cni/bin/

touch /etc/cni/net.d/10-bridge.conf

# https://www.cni.dev/plugins/current/main/bridge/
cat >>/etc/cni/net.d/10-bridge.conf<<EOF
{
    "cniVersion": "0.3.1",
    "name": "mynet",
    "type": "bridge",
    "bridge": "mynet0",
    "isDefaultGateway": true,
    "forceAddress": false,
    "ipMasq": true,
    "hairpinMode": true,
    "ipam": {
        "type": "host-local",
        "subnet": "$POD_CIDR"
    }
}
EOF

echo "[TASK 5] Install kubeadm from deb"
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl

sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

kubeadm init --pod-network-cidr=$POD_CIDR

echo "[TASK 6] Install qol tips for kubeadm"
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
echo 'alias k=kubectl' >> ~/.bashrc 
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
echo 'KUBECONFIG=/etc/kubernetes/admin.conf' >> ~/.bashrc
source ~/.bashrc 


#alias nerdctl_stopall="nerdctl -n k8s.io ps -a | grep -v CONTAINER | cut -d ' ' -f 1 | xargs -n1 -i sh -c 'nerdctl -n k8s.io stop {} || true'"
#alias nerdctl_rmall="nerdctl -n k8s.io ps -a | grep -v CONTAINER | cut -d ' ' -f 1 | xargs -n1 -i sh -c 'nerdctl -n k8s.io rm {} || true'"
# etcd
#ETCDCTL_API=3 etcdctl --endpoints https://10.0.2.15:2379 \
#--cacert /etc/kubernetes/pki/etcd/ca.crt \
#--cert /etc/kubernetes/pki/etcd/server.crt \
#--key /etc/kubernetes/pki/etcd/server.key \
#--write-out=table \
#--endpoints=$ENDPOINTS endpoint status
#ETCDCTL_API=3 etcdctl --endpoints https://10.0.2.15:2379 --cacert /etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/etcd/server.crt --key /etc/kubernetes/pki/etcd/server.key get / --prefix --keys-only | grep -v ^$