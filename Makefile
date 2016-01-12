IMAGES		:=	deploy-heat

include ../../../../devtools/Makefiles/Makefile.nds


TESTNAME=testdeploy
test:
	-docker rm -f $(TESTNAME)
	docker create --name $(TESTNAME) -it deploy-heat bash
	docker cp ~/.openstack/NDSLabsDev-openrc.sh $(TESTNAME):/nds/config/openstackrc.sh
	docker start -ai $(TESTNAME)
