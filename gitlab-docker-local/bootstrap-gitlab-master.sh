echo "[TASK 1] Stop and Disable firewall"
systemctl disable --now ufw >/dev/null 2>&1

echo "[TASK 2] Fetch and install Docker"
sudo apt-get update -y
sudo apt-get install ca-certificates curl gnupg lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

sudo usermod -aG docker vagrant

echo "[TASK 3] Run Gitlab CI container"
export GITLAB_HOME=/srv/gitlab
sudo docker run --detach \
  --hostname gitlab.ohmylab.lab \
  --publish 443:443 --publish 80:80 --publish 2233:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/config:/etc/gitlab \
  --volume $GITLAB_HOME/logs:/var/log/gitlab \
  --volume $GITLAB_HOME/data:/var/opt/gitlab \
  --shm-size 256m \
  gitlab/gitlab-ee:latest

echo "[TASK 4] wait till gitlab image comes up and fetch admin password"
while ! nc -z localhost 80; do   
  sleep 0.1 # wait for 1/10 of the second before check again
done
echo "Gitlab Started"
sudo docker exec gitlab grep 'Password:' /etc/gitlab/initial_root_password >> /home/vagrant/admintoken