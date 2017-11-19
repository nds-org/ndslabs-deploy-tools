cluster: kubernetes.tfvars .terraform
	terraform apply \
	  -state=kubespray/contrib/terraform/openstack/terraform.tfstate \
		-var-file=kubernetes.tfvars \
		kubespray/contrib/terraform/openstack

.terraform:
		terraform init kubespray/contrib/terraform/openstack

DOMAIN   := $(shell cat config.yaml | grep domain | awk '{print $$2}' | sed s/\"//g)
		cur-dir2   := $(shell cat config.yaml | grep domain | awk '{print $2}' | sed s/\"//g)

.PHONY : workbench secrets loadbalancer smtp services etcd apiserver webui

workbench: secrets loadbalancer smtp services etcd apiserver webui


config: config.yaml
	kubectl apply -f config.yaml

certs_dir:
	mkdir -p certs

certs/${DOMAIN}.key: certs config.yaml
	openssl genrsa 2048 >certs/${DOMAIN}.key

certs/${DOMAIN}.cert: certs certs/${DOMAIN}.key
	openssl req -new -x509 -nodes -sha1 -days 3650 -subj "/C=US/ST=IL/L=Champaign/O=NCSA/OU=NDS/CN=*.$DOMAIN" -key "certs/${DOMAIN}.key" -out "certs/${DOMAIN}.cert"

secrets: certs/${DOMAIN}.key certs/${DOMAIN}.cert
	kubectl delete secret ndslabs-tls-secret --namespace=default
	kubectl delete secret ndslabs-tls-secret --namespace=kube-system

	kubectl create secret generic ndslabs-tls-secret --from-file=tls.crt="certs/${DOMAIN}.cert" --from-file=tls.key="certs/${DOMAIN}.key" --namespace=default
	kubectl create secret generic ndslabs-tls-secret --from-file=tls.crt="certs/${DOMAIN}.cert" --from-file=tls.key="certs/${DOMAIN}.key" --namespace=kube-system

loadbalancer: templates/core/loadbalancer.yaml
	cat templates/core/loadbalancer.yaml | sed -e "s#{{[ ]*DOMAIN[ ]*}}#${DOMAIN}#g" | kubectl apply -f -

smtp: templates/smtp/rc.yaml templates/smtp/svc.yaml
	kubectl apply -f templates/smtp/

services: templates/core/svc.yaml
	kubectl apply -f templates/core/svc.yaml

etcd: templates/core/etcd.yaml
	kubectl apply -f templates/core/etcd.yaml

apiserver: templates/core/apiserver.yaml
	kubectl apply -f templates/core/apiserver.yaml

webui: templates/core/webui.yaml
	kubectl apply -f templates/core/webui.yaml
