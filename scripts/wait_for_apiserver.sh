#!/bin/bash -x
echo ${1}/api/healthz
until $(curl -k --output /dev/null --silent --fail --header "Host: www.${2}" -X GET ${1}/api/healthz); do
  echo "Trying again in ${3} seconds..."
  sleep ${3}s # wait before checking again
  kubectl get pod
done
echo 'Labs Workbench API server successfully started!'
kubectl get pod
