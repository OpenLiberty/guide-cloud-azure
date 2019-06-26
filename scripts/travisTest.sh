#!/bin/bash
set -euxo pipefail

##############################################################################
##
##  Travis CI test script
##
##############################################################################

printf "\nmvn -q package\n"
mvn -q package


docker build -t system system/.
docker build -t inventory inventory/.

printf "\replacing containers in kubernetes.yaml\n"
cat kubernetes.yaml | sed 's/guideregistry.azurecr.io\/system/system/g' | sed 's/guideregistry.azurecr.io\/inventory/inventory/g' > kubernetes.yaml

printf "\nkubectl apply -f kubernetes.yaml\n"
kubectl apply -f kubernetes.yaml

printf "\nsleep 120\n"
sleep 120

printf "\nkubectl get pods\n"
kubectl get pods




printf "\nminikube ip\n"
echo `minikube ip`

printf "\ncurl http://`minikube ip`:9080/system/properties\n"
curl http://`minikube ip`:9080/system/properties

printf "\ncurl http://`minikube ip`:9081/inventory/systems/system-service\n"
curl http://`minikube ip`:9081/inventory/systems/system-service


mvn verify -Ddockerfile.skip=true -Dsystem.ip=`minikube ip` -Dinventory.ip=`minikube ip`




printf "\nkubectl logs $(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep system)\n"
kubectl logs $(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep system)

printf "\nkubectl logs $(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep inventory)\n" 
kubectl logs $(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep inventory)