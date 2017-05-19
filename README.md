# NDS Labs Workbench Deploy Tools
This repository contains a set of [Ansible](https://www.ansible.com/) scripts to deploy [Kubernetes](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/) and the [Labs Workbench](https://github.com/nds-org/ndslabs) onto an OpenStack cluster

If you don't have access to an OpenStack cluster, there are [plenty of ways to run Kubernetes](https://kubernetes.io/docs/setup/pick-right-solution/)!

# Prerequisites
* [Docker](https://www.docker.com/get-docker)

# Build Docker Image
```bash
docker build -t ndslabs/deploy-tools .
```

# Run Docker Image
```bash
docker run -it -v /home/core/private:/root/SAVED_AND_SENSITIVE_VOLUME ndslabs/deploy-tools bash 
```

NOTE: You should remember to map some volume to `/root/SAVED_AND_SENSITIVE_VOLUME` containing your `*-openrc.sh` file. This directory is where the ansible output gets stored. This includes SSH private keys, generated TLS certificates, and Ansible's own fact cache. If you forget to map this directory, its contents **WILL BE LOST FOREVER**.

# Provide Your OpenStack Credentials
The first thing you need to do is to `source` the openrc file of the project you wish to deploy to in OpenStack

NOTE: this file can be retrieved for any OpenStack project which you can access by following the insturctions [here](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux_OpenStack_Platform/4/html/End_User_Guide/cli_openrc.html).

Assuming you've passed your the openrc.sh files with `-v`, as recommended above:
```bash
source /root/SAVED_AND_SENSITIVE_VOLUME/OpenStackProjectName-openrc.sh
```

# Prepare Your Site
Some parameters, such as the available flavors (sizes) and images for the deployed OpenStack instances, are properties of the particular installation of OpenStack or the projects to which you are allowed to deploy. We refer to each installation of OpenStack as a "site", and similarly store their variables under `/root/inventory/site_vars`, where each file is named after the site that it represents.

To set up a new site, you can simply copy an existing site and change the names of the images and flavors accordingly.

## Obtain a CoreOS Image
[Download](https://coreos.com/os/docs/latest/booting-on-openstack.html) the newest stable cloud image of CoreOS for OpenStack and [import](https://docs.openstack.org/user-guide/dashboard-manage-images.html) it into your project.

Currently supported CoreOS version: **1235.6**

NOTE: While newer versions of CoreOS *should* work, due to CoreOS and Docker versions being tied together later versions may not be supported immediately.

## Choosing a Flavor
Set the site_vars named `flavor_small` / `flavor_medium` / `flavor_large` to flavors that already exist in your OpenStack project, or create new flavors that match these.

# Compose Your Inventory
Make a copy of the existing example or minimal inventory located in `/root/inventory` and edit it to your liking:
```bash
cp inventory/minimal-ncsa inventory/my-cluster
vi inventory/my-cluster
```

* The top section pertains to **Cluster Variables** - here you can override any group_vars (NOTE: site_vars cannot yet be overridden)
* The middle section defines **Servers**, where we choose the names and quantities for each type of node
* The last section defines **Groups**, which groups the node types that we declared above into several larger groups

## About Group Variables
Some parameters are different based on the type of node being provisioned - Ansible calls these "groups". The group-specific values can be found under `/root/inventory/group_vars`, where each file is named after the group it represents.

NOTE: these groups can be nested / hierarchical.
**NOTE**: Raw images should be preferred at OpenStack sites where Ceph is used for the backing volumes, as it will significanlty decrease the time needed to provision and start your cluster.

# Ansible Playbooks
After adjusting the inventory/site parameters to your liking, run the three Ansible playbooks to bring up a Labs Workbench cluster:
```bash
ansible-playbook -i inventory/my-cluster playbooks/openstack-provision.yml && \
ansible-playbook -i inventory/my-cluster playbooks/k8s-install.yml && \
ansible-playbook -i inventory/my-cluster playbooks/ndslabs-k8s-install.yml
```

These commands can be run one at a time, or all at once for provisioning in a single command:
```bash
ansible-playbook -i inventory/my-cluster playbooks/openstack-provision.yml playbooks/k8s-install.yml playbooks/ndslabs-k8s-install.yml
```

## About Playbooks
Each playbook takes care of a small portion of the installation process:
* `playbooks/openstack-provision.yml`: Provision OpenStack volumes and instances with chosen flavor / image
* `playbooks/k8s-install.yml`: Download and install Kubernetes binaries onto each node
* `playbooks/ndslabs-k8s-install.yml`: Deploy our Kubernetes YAML files to start up services necessary to run Labs Workbench

## About Node Labels
After running all three playbooks, you should be left with a working cluster.

Labels recognized by the cluster are as follows:
* *glfs* server nodes must be labelled with `ndslabs-role-glfs=true` for the GLFS server to run there
* *compute* nodes must be labelled with `ndslabs-role-compute=true` for the Workbench API server to schedule services there
* *loadbal* nodes must be labelled to know where a public IP is available can run the ingress/loadbalance
* *lma* nodes must be labelled to know where dedicated resources are set aside to run logging/monitoring/alerts
