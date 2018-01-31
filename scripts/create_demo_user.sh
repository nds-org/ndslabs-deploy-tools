#!/bin/bash
apiserver=$(kubectl get pod | grep -Eow 'ndslabs\-apiserver\-\w*')
adminpassword=$(kubectl exec $apiserver cat password.txt)
echo $apiserver
echo $adminpassword
kubectl cp scripts/account-register.json $apiserver:account-register.json
echo "-----------Creating Shell in API Server for MANUAL STEP ---------------"
echo "Login as admin with password: $adminpassword"
echo "    ndslabsctl login admin"
echo "and import default account as"
echo "    ndslabsctl add account -f account-register.json"
kubectl -it exec $apiserver bash
