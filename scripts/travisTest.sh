#!/bin/bash
set -euxo pipefail

##############################################################################
##
##  Travis CI test script
##
##############################################################################

printf "\nmvn -q package\n"
mvn -q package

docker build -t system:test system/.
docker build -t inventory:test inventory/.

printf "\nkubectl apply -f kubernetes.yaml\n"
kubectl apply -f ../scripts/kubernetes.yaml

printf "\nsleep 120\n"
sleep 120

printf "\nkubectl get pods\n"
kubectl get pods

printf "\nminikube ip\n"
echo `minikube ip`

GUIDE_IP=`minikube ip`
GUIDE_SYSTEM_PORT=`kubectl get service system-service -o jsonpath="{.spec.ports[0].nodePort}"`
GUIDE_INVENTORY_PORT=`kubectl get service inventory-service -o jsonpath="{.spec.ports[0].nodePort}"`

printf "\nMinikube IP: $GUIDE_IP\n"
printf "\nSystem Port: $GUIDE_SYSTEM_PORT\n"
printf "\nInventory Port: $GUIDE_INVENTORY_PORT\n"

printf "\ncurl http://$GUIDE_IP:$GUIDE_SYSTEM_PORT/system/properties\n"
curl http://$GUIDE_IP:$GUIDE_SYSTEM_PORT/system/properties

printf "\ncurl http://$GUIDE_IP:$GUIDE_INVENTORY_PORT/inventory/systems/system-service\n"
curl http://$GUIDE_IP:$GUIDE_INVENTORY_PORT/inventory/systems/system-service

mvn verify -Ddockerfile.skip=true -Dsystem.ip=`minikube ip` -Dinventory.ip=`minikube ip`

printf "\nkubectl logs $(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep system)\n"
kubectl logs $(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep system)

printf "\nkubectl logs $(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep inventory)\n" 
kubectl logs $(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep inventory)