IMAGES		:=	deploy-heat

include ../../../../devtools/Makefiles/Makefile.nds

imt: 
	echo $(FILES.deploy-heat)


TESTNAME=testdeploy
test: IMAGE.deploy-heat
	-docker rm -f $(TESTNAME)
	export | grep OS_ > $(BUILDDIR)/osenv
	docker create --name $(TESTNAME) -it deploy-heat bash
	docker cp $(BUILDDIR)/osenv $(TESTNAME):/nds/config/openstackrc.sh
	docker start -ai $(TESTNAME)
