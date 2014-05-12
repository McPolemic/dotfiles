#!/bin/bash -e
export DOCKER_HOST=tcp://localdocker:4243
HOSTS=$*

for HOST in $HOSTS
  do docker run --rm purduefed/heartbleed $HOST 2>&1 | grep '^2' | grep -v uint8
done
