echo "[TASK 0] Disable firewalld"
systemctl disable firewalld; systemctl stop firewalld

echo "[TASK 1] Disable SELinux"
setenforce 0
sed -i --follow-symlinks 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux

echo "[TASK 2] Patch hosts files"
cat >>/etc/hosts<<EOF
172.18.50.50   jenkins-master
172.18.50.55   jenkins-worker
EOF

echo "[TASK 3] Prepare repositories for installation"
yum update -y && yum install -y wget
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key

echo "[TASK 4] Install Java runtime"
yum install -y epel-release java-11-openjdk-devel

echo "[TASK 5] Install Jenkins"
yum install -y jenkins

echo "[TASK 6] Re-enable Services"
systemctl daemon-reload
systemctl start jenkins
sleep 5
systemctl status jenkins
#sleep 10
#cat /var/lib/jenkins/secrets/initialAdminPassword