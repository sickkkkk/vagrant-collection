#!/bin/bash
curl -sfL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash -
# set-up bootstrap config
mkdir -p /etc/rancher/rke2/
cat >>/etc/rancher/rke2/config.yaml<<EOF
advertise-address: "172.18.50.55"
node-name: "kmaster.cluster.local"
etcd-snapshot-schedule-cron: "0 */5 * * *"
etcd-snapshot-retention: "10"
cluster-cidr: 10.100.0.0/16
service-cidr: 10.110.0.0/16
cluster-dns: 10.110.0.10
node-ip: "172.18.50.55"
tls-san:
  - "kmaster.cluster.local"
  - "172.18.50.55"
  - "kmaster"
node-taint:
  - "CriticalAddonsOnly=true:NoExecute"
kubelet-arg:
  - seccomp-default=true
  - pod-max-pids=2048
cni: none
disable-kube-proxy: true
disable:
  - rke2-canal
  - rke2-kube-proxy
protect-kernel-defaults: true
EOF
# install latest rke2
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=server bash -
systemctl enable --now rke2-server.service
# set-up tools
ln -s $(find /var/lib/rancher/rke2/data/ -name kubectl) /usr/local/bin/kubectl
echo "export KUBECONFIG=/etc/rancher/rke2/rke2.yaml PATH=$PATH:/usr/local/bin/:/var/lib/rancher/rke2/bin/" >> ~/.bashrc
source ~/.bashrc
kubectl get node

# cilium
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

cat >>cilium.yml<<EOF
cluster:
  name: default
  id: 0
version: 1.15.4
operator:
  prometheus:
    enabled: false
  dashboards:
    enabled: false
EOF

cilium install -f cilium.yml
# update cm
kubectl patch configmap cilium-config -n kube-system --type='merge' -p '{"data":{"ipam":"kubernetes"}}'
kubectl -n kube-system rollout restart deployment cilium-operator
kubectl -n kube-system rollout restart ds cilium

# install k9s
wget https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_linux_arm64.deb
sudo dpkg -i k9s_linux_arm64.deb
# possibly remove taints? coredns not being scheduled
kubectl taint node kmaster.cluster.local CriticalAddonsOnly-
kubectl taint nodes kmaster.cluster.local node.cloudprovider.kubernetes.io/uninitialized-

# cert-manager

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.crds.yaml
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.yaml

# rancher
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
kubectl create namespace cattle-system
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.cluster.local \
  --set bootstrapPassword=yYM9b3YcaHgX \
  --set replicas=1
  #--set ingress.tls.source=letsEncrypt \
  #--set letsEncrypt.email=info@example.org \
  #--set letsEncrypt.ingress.class=nginx

### Worker node
mkdir -p /etc/rancher/rke2/
cat >> /etc/rancher/rke2/config.yaml<<EOF
server: https://172.18.50.55:9345
token: K109361b244f370a528db90d810688e5a5e49c9e3c08dcd7926e499b568e1f5542d::server:baa3fab33c6dadf57fa03790aec93009 #which one?
node-name: kworker.cluster.local
EOF
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=agent bash -
systemctl enable --now rke2-agent.service
# run as binary (alternatively)
rke2 agent --server https://172.18.50.55:9345 --token K109361b244f370a528db90d810688e5a5e49c9e3c08dcd7926e499b568e1f5542d::server:baa3fab33c6dadf57fa03790aec93009
kubectl label node kworker.cluster.local node-role.kubernetes.io/worker=