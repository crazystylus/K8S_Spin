#!/bin/bash
## Handle SELinux ##
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

systemctl disable firewalld && systemctl stop firewalld
## INSTALLING DOCKER RUNTIME ##
curl "https://get.docker.com/" | bash
mkdir /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
printf "\nUseDNS no\n" >> /etc/ssh/sshd_config
mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker

## INSTALLING KUBELET, KUBECTL, KUBEADM

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

yum install -y kubelet kubeadm kubectl rsync wget
systemctl start docker && systemctl enable docker
systemctl start kubelet && systemctl enable kubelet

