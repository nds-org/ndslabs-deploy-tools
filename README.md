# NDSLabs deploy tools
An image with tooling and setup to deploy many instances of the NDSLabs developer environment in OpenStack.


# Usage:

  * The image keeps configuration in a volume on /nds/config
  * It is recommended to create a configuration data-volume per project or deployment
  
1. Create a named data volume container from the image: docker create -it --name <config-name> ndslabs/deploy-tools bash
2. Inject your openstack API rc information in the data volume:   
    Option 1.  Via openrc API file.   You will need to retype your password each time the container is run/started:
        docker cp <my-openrc-file.sh> <config-name>:/nds/config
    Option 2.  Inject openstack environment vars into the container where bash will pick them up (example in bash):
        . <my-openrc.sh> 
        export | grep OS_ > /tmp/my-openrc.env
        docker cp /tmp/my-openrc.env <config-name>:/nds/config
  * Option 1 is safer, as it does not store the password, but can be inconvenient.
  * Either method can store multiple rc or env files to support multiple projects.
  * Start a container, named or ephemeral, using the data volume: docker run -it ndslabs/deploy-tools --volumes-from <config-name>
