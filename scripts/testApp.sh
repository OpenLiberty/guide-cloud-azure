#!/bin/bash
set -euxo pipefail
./mvnw -version

# Test app

./mvnw -ntp -q clean package

./mvnw -pl inventory \
    -ntp -Dhttp.keepAlive=false \
    -Dmaven.wagon.http.pool=false \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120 \
    -q clean package liberty:create liberty:install-feature liberty:deploy
./mvnw -pl inventory \
    -ntp liberty:start

./mvnw -pl system \
    -ntp -Dhttp.keepAlive=false \
    -Dmaven.wagon.http.pool=false \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120 \
    -q clean package liberty:create liberty:install-feature liberty:deploy
./mvnw -pl system \
    -ntp liberty:start

sleep 120

curl http://localhost:9080/system/properties
curl http://localhost:9081/inventory/systems/

./mvnw -ntp failsafe:integration-test -Dsystem.ip="localhost" -Dinventory.ip="localhost"
./mvnw -ntp failsafe:verify

./mvnw -pl inventory \
    -ntp liberty:stop

./mvnw -pl system \
    -ntp liberty:stop

# Clear .m2 cache
rm -rf ~/.m2
