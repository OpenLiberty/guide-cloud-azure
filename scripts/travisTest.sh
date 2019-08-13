#!/bin/bash
set -euxo pipefail

##############################################################################
##
##  Travis CI test script
##
##############################################################################

mvn -q package

docker build -t system:test system/.
docker build -t inventory:test inventory/.

kubectl apply -f ../scripts/test.yaml

sleep 120

kubectl get pods

echo `minikube ip`

GUIDE_IP=`minikube ip`
GUIDE_SYSTEM_PORT=`kubectl get service system-service -o jsonpath="{.spec.ports[0].nodePort}"`
GUIDE_INVENTORY_PORT=`kubectl get service inventory-service -o jsonpath="{.spec.ports[0].nodePort}"`

curl http://$GUIDE_IP:$GUIDE_SYSTEM_PORT/system/properties

curl http://$GUIDE_IP:$GUIDE_INVENTORY_PORT/inventory/systems/system-service

mvn verify -Ddockerfile.skip=true -Dsystem.ip=`minikube ip` -Dinventory.ip=`minikube ip`

kubectl logs $(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep system)

kubectl logs $(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep inventory)