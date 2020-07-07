IMAGE := alpine/fio
APP:="app/deploy-openesb.sh"

deploy-minikube:
	bash app/deploy-minikube.sh

deploy-minikube-latest:
	bash app/deploy-minikube-latest.sh

deploy-canary-linkerd:
	bash app/deploy-canary-linkerd.sh

deploy-canary:
	bash app/deploy-canary.sh

push-image:
	docker push $(IMAGE)

.PHONY: deploy-kind deploy-openesb deploy-dashboard deploy-minikube deploy-istio push-image
