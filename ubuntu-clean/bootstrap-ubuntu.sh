echo "[TASK 1] Stop and Disable firewall"
systemctl disable --now ufw >/dev/null 2>&1

echo "[TASK 2] Fetch and install Jenkins"
apt-get update -y