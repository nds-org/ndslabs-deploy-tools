#!/bin/bash
apiserver=$(kubectl get pod | grep -Eow 'ndslabs\-apiserver\-\w*')
adminpassword=$(kubectl exec $apiserver cat password.txt)
echo $apiserver
echo $adminpassword
kubectl cp scripts/account-register.json $apiserver:account-register.json
kubectl exec $apiserver -- bash -c "ndslabsctl login admin -p $adminpassword && ndslabsctl add account -f account-register.json"
grep password scripts/account-register.json
