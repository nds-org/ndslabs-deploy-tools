# NDS Labs Workbench Deploy Tools
This repository contains a set of tools that will deploy workbench onto one or
more nodes. The tools are all coordinated by `Make` so you can execute the steps
you need for your particular setup.

## Available Deployment Steps
| Step | Description | Make Target |
| ------ | ----------- | ----------- |
| Terraform | Provision VMs on cloud provider using Terraform | `terraform` |
| Verify VMs | Use the Ansible Ping command to make sure that the hosts have been provisioned correctly and are accessible | `ping` |
| Install Kubernetes | Use `Kubespray` to install Kubernetes in the cluster | `kubernetes` |
| NDS Workbench | Deploy the NDS Workbench on the provisioned Kubernetes Cluster | `workbench` |
| Destroy Workbench | Delete all of the services and pods associated with workbench | `workbench-down` |
| Demo Account | Create a demo account with a known password. This is not currently complete since it requires a change to `ndslabsctl` to allow for the admin password to be passed in from command line. Currently it creates a shell in the api server pod and displays instructions on how to install the demo user | `demo-login` |
| Label Worker Nodes | The API Server only starts services on nodes that are labeled. This runs a script to label appropriate nodes as eligible | `label-workers` |
| Destroy VMs | Use Terraform to destroy the cluster and release the VMs | `clean`

## Terraform
Execute this step to use terraform to allocate and commission VMs to host
your kubernetes cluster. Before running this step you need to create a
`tfvars` file that specifies the cluster you would like to create. The contents
of this file are specified in the [Kubespray Terraform README](https://github.com/kubernetes-incubator/kubespray/tree/master/contrib/terraform/openstack).

You also need to set environment variables to your Openstack credentials also
shown in the README.

To run the make command you need to provide names for the `tfvars` file to use
and the `tfstate` to store the results.

```bash
% make TFVARS=sdsc-single-note.tfvars TFSTATE=sdsc-single-note.tfstate kubernetes
```

Once complete, you can verify your stack with a ping command run on each of the
provisioned hosts. Ansible will communicate with hosts that have an external
IP directly. Other hosts will be contacted via the bastion host.

This command depends on the `tfstate` file from the terraform build to resolve
the inventory

Try this command:
```bash
% make TFSTATE=sdsc-single-note.tfstate ping
```

## Kubespray Deploy Kubernetes
Next step is to install kubernetes on the cluster. Before executing this step
you should customize `k8s-cluster.yml` in the repo's root directory. One setting
of particular note is `calico_mtu` which should be set to the value which is
appropriate for the Openstack you are deploying to. You may also edit settings
in `all.yml` which control cluster-wide settings for the ansible deploy.

Once you are satisfied with the settings, you can request the kubspray deploy
with:

Try this command:
```bash
% make TFSTATE=sdsc-single-note.tfstate kubernetes
```

After Kubernetes is deployed you will still need to follow the instructions in
the [README](https://github.com/kubernetes-incubator/kubespray/tree/master/contrib/terraform/openstack) to add the new cluster to your kubectl config.

## Deploy Workbench
You must first edit the `config.yml` file in the repo's root directory to set
values for your workbench.

The value for `workbench.domain` is particularly important.

Deploy workbench with the command:

```bash
% make workbench
```

## Create a Demo Account
In order to work with your workbench you need to log into it. The account
approval workflow can be vexing in a development environment. You can bypass
this by forcing a demo account into your registry. You can create a demo account
with the command:

```bash
% make demo-login
```

This will copy the account specification file from
`scripts/account-register.json` into the api server's pod and then launch
a bash shell in that pod and prompt you to login as admin using ndsctl and
execute the command to add that user to the registry. This manual step is needed
until [NDS-1172](https://opensource.ncsa.illinois.edu/jira/browse/NDS-1172) is
complete.

## Label Compute Nodes
The API Server needs to know which nodes can run services. Execute:

```bash
% make label-workers
```
For now this script only works for single node deployments. It will label the
master node as a worker. Eventually, this script will label the kubernetes
worker nodes only.
