#!/bin/bash
set -euxo pipefail

##############################################################################
##
##  Travis CI test script
##
##############################################################################

mvn -q clean package

cd inventory
mvn -q clean package liberty:create liberty:install-feature liberty:deploy
mvn liberty:start

cd ../system
mvn -q clean package liberty:create liberty:install-feature liberty:deploy
mvn liberty:start

cd ..

sleep 20

curl http://localhost:9080/system/properties
curl http://localhost:9081/inventory/systems

mvn failsafe:integration-test -Dsystem.ip="localhost" -Dinventory.ip="localhost"
mvn failsafe:verify

cd inventory
mvn liberty:stop

cd ../system
mvn liberty:stop

cd ..

##############################################################################
##
##  Test docker
##
##############################################################################

docker pull openliberty/open-liberty:kernel-java8-openj9-ubi

docker build -t system:1.0-SNAPSHOT system/.
docker build -t inventory:1.0-SNAPSHOT inventory/.

sed -i 's/\[registry-server\]\///g' kubernetes.yaml
sed -i 's/targetPort: 9080/targetPort: 9080\n    nodePort: 31000/g' kubernetes.yaml
sed -i 's/targetPort: 9081/targetPort: 9081\n    nodePort: 32000/g' kubernetes.yaml

kubectl apply -f kubernetes.yaml

sleep 120

kubectl get pods

kubectl get service/system-service
kubectl get service/inventory-service
echo `minikube ip`

curl http://`minikube ip`:31000/system/properties
curl http://`minikube ip`:32000/inventory/systems/system-service

cd system
mvn failsafe:integration-test -Dsystem.ip=`minikube ip` -Dsystem.http.port=31000
mvn failsafe:verify

cd ../inventory
mvn failsafe:integration-test -Dsystem.ip=system-service -Dinventory.ip=`minikube ip` -Dinventory.http.port=32000 
mvn failsafe:verify

kubectl logs $(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep system)
kubectl logs $(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep inventory)
