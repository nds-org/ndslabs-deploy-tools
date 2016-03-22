HUB_IMAGES		:=	deploy-tools
IMAGES			:=	$(HUB_IMAGES)

include Makefile.nds

TESTNAME	=	deploy-heat-test
TESTRC		=	~/.openstack/NDSLabsDev-openrc.sh
test:
	-docker rm -f $(TESTNAME)
	docker create -it --name $(TESTNAME) -v `pwd`/FILES.deploy-heat/usr/local:/usr/local deploy-heat bash
	docker cp $(TESTRC) $(TESTNAME):/nds/config/openstackrc.sh
	docker start -ai $(TESTNAME)test:

DEVNAME	=	deploy-heat-dev
DEVRC		=	~/.openstack/NDSLabsDev-openrc.sh
dev:
	-docker rm -f $(DEVNAME)
	docker create -it --name $(DEVNAME) -v `pwd`/FILES.deploy-heat/usr/local:/usr/local deploy-heat bash
	docker cp $(DEVRC) $(DEVNAME):/nds/config/openstackrc.sh
	docker start -ai $(DEVNAME)
