#!/bin/bash

HOME=/home/vagrant
PACKAGE_FILE="./utils/required-packages.txt"
ARCH="$(dpkg --print-architecture)"
K8S_VERSION="1.32"
CRI_DOCKERD_VERSION="0.3.16"
CRI_DOCKERD_TAR_NAME="cri-dockerd-$CRI_DOCKERD_VERSION.$ARCH.tgz"


install_system_packages() {
  # Update packages list
  sudo apt update
  sudo apt upgrade -y
  
  while read -r package; do
        # Skip empty lines and comments
        [[ -z "$package" || "$package" =~ ^# ]] && continue

        if dpkg -s "$package" >/dev/null 2>&1; then
            echo "[ INFO ] Package '$package' is already installed. Skipping..."
        else
            echo "[ INFO ] Installing package '$package'..."
            sudo apt install -y "$package"
        fi
    done < $PACKAGE_FILE
}

install_docker() {
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
              -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo \
    "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update
  sudo apt install -y docker-ce \
                      docker-ce-cli \
                      containerd.io \
                      docker-buildx-plugin \
                      docker-compose-plugin

  #Manage Docker as a non-root user
  getent group docker || sudo groupadd docker
  sudo usermod -aG docker "$USER"
  sudo newgrp docker

  # Restart Docker with new settings
  sudo systemctl enable --now docker.service
  sudo systemctl enable --now containerd.service
  sudo systemctl daemon-reload
  sudo systemctl restart docker.service
  sudo systemctl status docker.service
}

install_cri_dockerd() {
  # (to use docker as CRI)
  wget https://github.com/Mirantis/cri-dockerd/releases/download/v$CRI_DOCKERD_VERSION/"$CRI_DOCKERD_TAR_NAME"
  tar xvf "$CRI_DOCKERD_TAR_NAME"
  sudo chown root:root cri-dockerd/cri-dockerd
  sudo mv cri-dockerd/cri-dockerd /usr/bin/
  rm "$CRI_DOCKERD_TAR_NAME"
  rm -r cri-dockerd

  # Copy config files
  cat $HOME/configs/docker/cri-docker.service | sudo tee /etc/systemd/system/cri-docker.service > /dev/null
  cat $HOME/configs/docker/cri-docker.socket | sudo tee /etc/systemd/system/cri-docker.socket > /dev/null

  sudo systemctl daemon-reload
  sudo systemctl start cri-docker
  sudo systemctl enable --now cri-docker.service cri-docker.socket
  sudo systemctl status cri-docker.service
}

install_system_packages
install_docker
install_cri_dockerd

# Install k8s components 
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/deb/Release.key | \
sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/deb/ /" | \
sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet \
                    kubeadm \
                    kubectl
sudo apt-mark hold kubelet \
                    kubeadm \
                    kubectl

# Disable swap
sudo swapoff -a
# (makes swapoff setting persistent)
sudo sed -i '/ swap / s/^/#/' /etc/fstab 

# Check if a required port opened (for kubectl to interact)
#nc 127.0.0.1 6443 -zv -w 2

# Enable required modules
sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Configure k8s network setup
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables=1 
net.bridge.bridge-nf-call-iptables=1
net.ipv4.ip_forward=1
EOF
 
#  Restart networking settings
sudo sysctl --system
#sudo sysctl -p /etc/sysctl.d/kubernetes.conf

#Enable and start kubelet
sudo systemctl enable --now kubelet
sudo systemctl start kubelet.service
