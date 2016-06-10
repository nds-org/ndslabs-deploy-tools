HUB_IMAGES		:=	deploy-tools
IMAGES			:=	$(HUB_IMAGES)
#RELEASE				:=  nds223-3

include Makefile.nds

ostest: IMAGE.deploy-tools
	docker run --rm -it  -e OS_REGION_NAME -e OS_TENANT_ID -e OS_PROJECT_NAME -e OS_PASSWORD -e OS_AUTH_URL -e OS_USERNAME -e OS_TENANT_NAME  ndslabs/deploy-tools bash -c 'ansible-playbook -i inventory/ostest ostest.yml -vvvv'
