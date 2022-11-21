echo "[TASK 0] Declare Variables"
JENKINS_VERSION=2.300

echo "[TASK 1] Stop and Disable firewall"
systemctl disable --now ufw >/dev/null 2>&1

echo "[TASK 2] Fetch and install Jenkins"
apt-get update -y && apt-get install -y openjdk-11-jdk

echo "[TASK 3] Fetch and install Jenkins"
JENKINS_VERSION=2.300
wget http://mirrors.jenkins-ci.org/debian/jenkins_${JENKINS_VERSION}_all.deb
dpkg -i jenkins_${JENKINS_VERSION}_all.deb
apt-get install -fy

echo "[TASK 4] Show Jenkins Default Password"
sleep 10 && cat /var/lib/jenkins/secrets/initialAdminPassword