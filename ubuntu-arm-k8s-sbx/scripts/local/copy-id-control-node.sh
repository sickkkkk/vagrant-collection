#!/bin/bash
KEY_FILE_PATH="../../vagrant-key/vagrant-bootstrap-key.pub" #key path to local file
for host in kmaster1.cluster.local kmaster2.cluster.local kworker.cluster.local; do
    echo "Adding identity to $host"
    ssh-copy-id -i $KEY_FILE_PATH vagrant@$host
done