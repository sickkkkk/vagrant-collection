#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
echo "Update hosts file"
cat >>/etc/hosts<<EOF
172.18.50.50    ansible-master.cluster.local    ansible-master
172.18.50.55    kmaster.cluster.local   kmaster
172.18.50.61    kworker.cluster.local   kworker
EOF

mkdir -p /home/vagrant/.ssh
echo $(cat /home/vagrant/vagrant-key/vagrant-bootstrap-key.pub) >> /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

echo 'eval $(ssh-agent -s) > /dev/null' >> /home/vagrant/.bashrc
echo 'ssh-add /home/vagrant/vagrant-key/vagrant-bootstrap-key > /dev/null 2>&1' >> /home/vagrant/.bashrc

sudo -u vagrant curl https://bootstrap.pypa.io/get-pip.py -o /home/vagrant/get-pip.py
sudo -u vagrant python3 get-pip.py --user
sudo -u vagrant python3 -m pip install --user ansible
echo 'export PATH="$PATH:/home/vagrant/.local/bin"' >> /home/vagrant/.bashrc
sudo -u vagrant bash -l -c "/vagrant/scripts/ssh-add-inventory.sh"