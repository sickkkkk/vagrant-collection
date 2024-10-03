#!/bin/bash
INVENTORY_FILE="../../ansible/inventory.yml"
KEY_FILE_PATH="../../vagrant-key/vagrant-bootstrap-key.pub"
REMOTE_USER="vagrant"
KNOWN_HOSTS_FILE=~/.ssh/known_hosts
if [[ ! -f "$INVENTORY_FILE" || ! -f "$KEY_FILE_PATH" ]]
then
    echo "Nor keyfile nor inventory found. Aborting"
    exit 1
fi
if ! command -v jq &> /dev/null
then
    echo "jq is required but not installed. Please install jq and retry."
    exit 1
fi
HOSTS=$(ansible-inventory -i "$INVENTORY_FILE" --list | jq -r '._meta.hostvars | to_entries[] | .value.ansible_host')
echo "$HOSTS" | while IFS= read -r host; do
    echo "Adding identity $REMOTE_USER@$host"
    ssh-copy-id -i "$KEY_FILE_PATH" "$REMOTE_USER@$host"
    echo "Adding host key for $host to known_hosts"
    ssh-keyscan -t ed25519 "$host" >> "$KNOWN_HOSTS_FILE" 2>/dev/null
done
