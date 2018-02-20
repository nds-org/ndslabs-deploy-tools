#!/bin/bash
echo ${1}/api/healthz
until $(curl -k --output /dev/null --silent --fail -X GET ${1}/api/healthz); do
  echo "Trying again in ${2} seconds..."
  sleep ${2}s # wait before checking again
  kubectl get pod
  API_SERVER=$(kubectl get pod | grep -Eow 'ndslabs\-apiserver\-\w*')
  kubectl logs $API_SERVER
done
$ECHO 'Labs Workbench API server successfully started!'
kubectl get pod
