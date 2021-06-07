#!/bin/bash
set -euxo pipefail

# Test app

mvn -q clean package

cd inventory
mvn -Dhttp.keepAlive=false \
    -Dmaven.wagon.http.pool=false \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120 \
    -q clean package liberty:create liberty:install-feature liberty:deploy
mvn liberty:start

cd ../system
mvn -Dhttp.keepAlive=false \
    -Dmaven.wagon.http.pool=false \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120 \
    -q clean package liberty:create liberty:install-feature liberty:deploy
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

# Clear .m2 cache
rm -rf ~/.m2
