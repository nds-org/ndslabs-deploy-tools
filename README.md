# NDSLabs deploy tools
Tooling and support for deploying NDSLabs developer systems and production clusters based on CoreOS in private clouds

# Tools:
  * Openstack clients: nova, heat, glance, keystone - openstack cli's
  * Openstack shade:  Simple openstack cli, also used by anisble
  * Ansible: A declarative configuration/management tool for managing systems at scale

# NDSLabs deployment resources
  * Ansible roles and playbooks for deploying developer systems at scale
  * Ansible roles and playbooks for deploying kubernetes production clusters

# Prerequisites
  * OpenStack:  You need an openstack "rc" API file

# Usage:
  * Create a container
  * Add your openstack rc file or OS_* environment variables
  * OpenStack API's are directly accessible:
  $ nova credentials
  * Ansible playbooks used by NDSLabs are in ${HOME} and are available as examples and to copy/modify

