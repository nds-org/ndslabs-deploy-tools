ANSIBLE_CONFIG := ../ansible.cfg
export ANSIBLE_CONFIG

kubespray/contrib/terraform/openstack/terraform.tfstate: kubernetes.tfvars kubespeay/.terraform
	mkdir -p kubespray/artifacts
	cd kubespray; terraform apply \
	  -state=contrib/terraform/openstack/terraform.tfstate \
		-var-file=../kubernetes.tfvars \
		contrib/terraform/openstack
	chmod +x kubespray/artifacts/save_kubernetes_config.sh

clean:
	cd kubespray; terraform destroy \
		-state=contrib/terraform/openstack/terraform.tfstate \
		-var-file=../kubernetes.tfvars \
		contrib/terraform/openstack

		rm -Rf ansible_facts

undeploy:
	kubectl delete secret --ignore-not-found=true ndslabs-tls-secret --namespace=default
	kubectl delete secret --ignore-not-found=true ndslabs-tls-secret --namespace=kube-system

	kubectl delete configmap --ignore-not-found=true ndslabs-config

	kubectl delete clusterrolebinding --ignore-not-found=true permissive-binding
	# Load Balancer
	kubectl delete ingress --ignore-not-found=true ndslabs-ingress
	kubectl delete service --ignore-not-found=true default-http-backend
	kubectl delete rc --ignore-not-found=true default-http-backend
	kubectl delete rc --ignore-not-found=true nginx-ilb-rc

	kubectl delete configmap --ignore-not-found=true nginx-ingress-conf

	# smtp
	kubectl delete service --ignore-not-found=true ndslabs-smtp
	kubectl delete rc --ignore-not-found=true ndslabs-smtp

	# services
	kubectl delete service --ignore-not-found=true ndslabs-etcd
	kubectl delete service --ignore-not-found=true ndslabs-apiserver
	kubectl delete service --ignore-not-found=true ndslabs-webui

	# etcd
	kubectl delete rc --ignore-not-found=true ndslabs-etcd

	# API server
	kubectl delete rc --ignore-not-found=true ndslabs-apiserver

	# WEB UI
	kubectl delete rc --ignore-not-found=true ndslabs-webui

kubespeay/.terraform:
		cd kubespray; terraform init contrib/terraform/openstack

ping: kubespray/contrib/terraform/openstack/terraform.tfstate
	cd kubespray; ansible --key-file ~/.ssh/cloud.key \
	                      -i contrib/terraform/openstack/hosts \
												-m ping all

kubernetes: kubespray/contrib/terraform/openstack/terraform.tfstate
	cp k8s-cluster.yml kubespray/inventory/group_vars
	cp all.yml kubespray/inventory/group_vars
	cd kubespray; ansible-playbook --key-file ~/.ssh/cloud.key \
																 --become \
																 -i contrib/terraform/openstack/hosts \
																 cluster.yml

	kubespray/artifacts/save_kubernetes_config.sh

DOMAIN   := $(shell cat config.yaml | grep domain | awk '{print $$2}' | sed s/\"//g)

.PHONY : workbench secrets loadbalancer smtp services etcd apiserver webui

workbench: secrets config loadbalancer smtp services etcd apiserver webui

workbench-down:
	kubectl delete secret --ignore-not-found=true ndslabs-tls-secret --namespace=default
	kubectl delete secret --ignore-not-found=true ndslabs-tls-secret --namespace=kube-system
	kubectl delete --ignore-not-found=true -f config.yaml
	cat templates/core/loadbalancer.yaml | sed -e "s#{{[ ]*DOMAIN[ ]*}}#${DOMAIN}#g" | kubectl delete --ignore-not-found=true -f  -
	kubectl delete --ignore-not-found=true -f templates/core/svc.yaml
	kubectl delete --ignore-not-found=true -f templates/core/apiserver.yaml
	kubectl delete --ignore-not-found=true -f templates/core/bind.yaml
	kubectl delete --ignore-not-found=true -f templates/core/webui.yaml
	kubectl delete --ignore-not-found=true -f templates/smtp/
	kubectl delete --ignore-not-found=true -f templates/core/etcd.yaml

	kubectl delete clusterrolebinding --ignore-not-found=true permissive-binding
	rm "certs/${DOMAIN}.cert"
	rm "certs/${DOMAIN}.key"

config: config.yaml
	kubectl apply -f config.yaml

certs_dir:
	mkdir -p certs

certs/${DOMAIN}.key: certs config.yaml
	openssl genrsa 2048 >certs/${DOMAIN}.key

certs/${DOMAIN}.cert: certs certs/${DOMAIN}.key
	openssl req -new -x509 -nodes -sha1 -days 3650 -subj "/C=US/ST=IL/L=Champaign/O=NCSA/OU=NDS/CN=*.${DOMAIN}" -key "certs/${DOMAIN}.key" -out "certs/${DOMAIN}.cert"

secrets: certs/${DOMAIN}.key certs/${DOMAIN}.cert
	kubectl delete secret --ignore-not-found=true ndslabs-tls-secret --namespace=default
	kubectl delete secret --ignore-not-found=true ndslabs-tls-secret --namespace=kube-system

	kubectl create secret generic ndslabs-tls-secret --from-file=tls.crt="certs/${DOMAIN}.cert" --from-file=tls.key="certs/${DOMAIN}.key" --namespace=default
	kubectl create secret generic ndslabs-tls-secret --from-file=tls.crt="certs/${DOMAIN}.cert" --from-file=tls.key="certs/${DOMAIN}.key" --namespace=kube-system

permisive-binding:
	kubectl delete clusterrolebinding --ignore-not-found=true permissive-binding

	kubectl create clusterrolebinding permissive-binding \
	 --clusterrole=cluster-admin \
	 --user=admin \
	 --user=kubelet \
	 --group=system:serviceaccounts

loadbalancer: templates/core/loadbalancer.yaml permisive-binding
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
