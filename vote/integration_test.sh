#!/bin/bash

cd integration

echo "I: Creating environment to run  integration tests..."

docker-compose build
docker-compose up -d

echo "Waiting for vote app to be ready..."
if ! timeout 60 bash -c 'until curl -s http://localhost:80 > /dev/null 2>&1; do sleep 2; done'; then
  echo "Vote app not ready, aborting"
  docker-compose down
  cd ..
  exit 1
fi

echo "I: Launching Integration Test ..."

docker-compose run --rm integration /test/test.sh

if [ $? -eq 0 ]
then
  echo "---------------------------------------"
  echo "INTEGRATION TESTS PASSED....."
  echo "---------------------------------------"
  docker-compose down
  cd ..
  exit 0
else
  echo "---------------------------------------"
  echo "INTEGRATION TESTS FAILED....."
  echo "---------------------------------------"
  docker-compose down
  cd ..
  exit 1
fi
