#!/bin/bash
node_count=$(kubectl get node | grep -v NAME | grep k8s-node | wc -l)
echo $node_count

# For Single Node Cluster we make the master a compute node
if [ $node_count == 0 ]; then
  nodename=$(kubectl get nodes | grep -v NAME | grep k8s-master | awk '{print $1}')
  kubectl label nodes $nodename ndslabs-role-compute=true
fi
