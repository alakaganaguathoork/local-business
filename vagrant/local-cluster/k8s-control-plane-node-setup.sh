#!/bin/bash

HOME="/home/vagrant"

# Init a cluster
kubeadm init \
                    --cri-socket unix:///var/run/cri-dockerd.sock \
                    --apiserver-advertise-address 172.16.8.10 \
                    --pod-network-cidr 172.16.8.0/24

# Generate kubectl config file
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown vagrant:vagrant $HOME/.kube/config

# produce "root:root" ownership
#sudo chown "$(id -u)":"$(id -g)" $HOME/.kube/config

# Apply CNI
# kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Allow scheduling on the master node
# UPD: needed for single-node clusters 
# kubectl taint nodes --all node-role.kubernetes.io/master-

# Save the join command to add worker nodes
mkdir -p $HOME/shared/scripts
touch $HOME/shared/scripts/join_command.sh

tee $HOME/shared/scripts/join_command.sh <<EOF
#!/bin/bash

set -e

$(kubeadm token create --print-join-command) --cri-socket unix:///var/run/cri-dockerd.sock
EOF

chmod +x $HOME/shared/scripts/join_command.sh
