#!/usr/bin/env bash
set -euo pipefail
NODES=( "172.18.50.160" )
if [ "$(whoami)" != "postgres" ]; then
  echo "Error: please run this script as the 'postgres' user."
  echo "       e.g. 'sudo -u postgres -i' then run './setup-postgres-ssh.sh'"
  exit 1
fi
SSH_DIR="$HOME/.ssh"
PRIVATE_KEY="$SSH_DIR/id_rsa"
PUBLIC_KEY="$PRIVATE_KEY.pub"
if [ ! -f "$PRIVATE_KEY" ]; then
  echo "No SSH key found for postgres at '$PRIVATE_KEY'. Generating a new key pair..."
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
  ssh-keygen -t rsa -b 4096 -N "" -f "$PRIVATE_KEY"
  chmod 600 "$PRIVATE_KEY"
  chmod 644 "$PUBLIC_KEY"
  echo "Key pair created: $PRIVATE_KEY, $PUBLIC_KEY"
else
  echo "SSH key already exists: $PRIVATE_KEY"
fi
for node in "${NODES[@]}"; do
  echo
  echo ">>> Installing key on 'postgres@${node}' using ssh-copy-id..."
  ssh-copy-id -i "$PUBLIC_KEY" "postgres@${node}"
done
echo
echo ">>> Done!"