#!/bin/bash
set -euxo pipefail

# Set up Minikube

curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x kubectl
sudo ln -s $(pwd)/kubectl /usr/local/bin/kubectl
wget https://github.com/kubernetes/minikube/releases/download/v0.28.2/minikube-linux-amd64 -q -O minikube
chmod +x minikube

sudo apt-get update -y
sudo apt-get install -y conntrack

sudo minikube start --vm-driver=none --bootstrapper=kubeadm

# Test app

mvn -q clean package

cd inventory
mvn -q clean package liberty:create liberty:install-feature liberty:deploy
mvn liberty:start

cd ../system
mvn -q clean package liberty:create liberty:install-feature liberty:deploy
mvn liberty:start

cd ..

sleep 120

curl http://localhost:9080/system/properties
curl http://localhost:9081/inventory/systems/

mvn failsafe:integration-test -Dsystem.ip="localhost" -Dinventory.ip="localhost"
mvn failsafe:verify

cd inventory
mvn liberty:stop

cd ../system
mvn liberty:stop