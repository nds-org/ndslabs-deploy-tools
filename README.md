# NDSLabs deploy tools
Tooling and support for deploying NDSLabs-style Kubernetes developer systems and production clusters based on CoreOS in private clouds.
Tested primarily on openstack - but usable in other environments.

# Tools:
  * Openstack clients: nova, heat, glance, keystone 
  * Ansible, ansible libraries, playbooks to deploy cluster systems in openstack, kubernetes, and ndslabs PaaS on kubernetes.

# Important information
  * OpenStack:  You need an openstack "rc" API file
  * SAVED_AND_SENSITIVE_VOLUME, mapped at /root/SAVED_AND_SENSITIVE_VOLUME is used to save provisioned system information, keys, etc. for copying for safe storage.  If you don't provide a volume mount ( -v /my-path:/root/SAVED_AND_SENSITIVE_VOLUME ) and destroy the container, you may lose sensitive information

# Startup:
  * Create a named container:  docker create --name deploy-test-cluster --it ndslabs/deploy-tools
  * Add your your openstack rc file to the volume mount, if it is not in a mapped volume, and source it: . <my-rc>.sh
  * Test that the OpenStack API's are directly accessible: nova credentials
  * Ansible playbooks used by NDSLabs are in ${HOME} and are available as examples and to copy/modify

# Playbooks - under playbooks
There are 3 layers of install:   1.systems, 2.kubernetes, and 3.ndslabs
  * openstack-provision.yml, openstack-delete.yml - Render/delete the OpenStack resources (except keys and secgroups)
  * k8s-install.yml, k8s-delete.yml - install/delete kubernetes onto the systems
  * ndslabs-k8s-install.yml - deploy the ndslabs PaaS on top of kubernetes

# Inventory/group_vars:
  * The inventory file has 3 sections: names, groups, variables
  * Names are grouped, where groups can override variables such as flavors or storage sizes.
  * Roles are assigned and parameterized via groups, with common variable values under group_vars and typical user-specified variables in the inventory-file in-line.   Ansible variables specified in multiple places will receive the most-recently encountered value.


# OpenStack resources 
  * The playbooks will create new resources, such as keys, security-groups, and volumes
  * Many resources are only saved at creation-time to avoid overwriting - keys/volumes/security-groups.
  * Failures in multi-step plays may occur for various reasons such as over resource-limits, network-errors, etc.
  * Failures may result in a resource not being saved.  
  * Recovering varies by resource type, typically the system involved can be removed by hand using the nova cli or horizon and the full playbook re-run safely, the previously provisioned systems should be skipped.

# Create a Cluster:
  * Copy the inventory/example and adjust naming and resources to your needs.   Typically the numbers of various groups, flavor, image, key_name, etc.    
  * run ansible-playbook -i inventory/mycluster playbooks/kubernetes-infrastructure.yml
  * Save and/or safeguard anything saved in SAVED_AND_SENSITIVE_VOLUME

# Group/roles/args summary for Infrastructure:
  * openstack-system: Provisioned in OpenStack (inventory_host)
  * openstack-securitygroup-open:   provision security-group and rules for fully-open in-cluster ingress SW loadbalancers
  * openstack-key:   Provision/save key in OpenStack (key_name)
  * openstack-glfs:   Openstack volume provisionuing for glfs nodes (vol_size, vol_name, mount_path, service_name)
  * coreos_mount: Mount the glfs brick in coreos(block_dev, mount_path)
  * format-mount-glfs:  Format and mount the brick (block_dev, mount_path)
# Group/roles/args for workshop setups
  * docker-pull-images:  pre-pull images to system once up
  * with-saved-account: provision a login on the system, set a random password, save user/passwd/IP info
  * coreos-ndslabs-system:  NDSC5 workshop style systems provisioning
# Groups/roles/args for Kubernetes Init
  * k8-etcd
  * k8-node
  * k8-master
# Groups/roles/args for Kubernetes Setup
  * k8-tls
