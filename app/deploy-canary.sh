#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
set -o xtrace
# set -eox pipefail #safety for script

# https://kubernetes.io/blog/2020/04/two-phased-canary-rollout-with-gloo/
echo "============================gloo=============================================================="
# Deploying Gloo
# install gloo with the glooctl command line tool
#curl -sL https://run.solo.io/gloo/install | sh #No versions of glooctl found.
curl -sL https://run.solo.io/gloo/install | sh

export PATH=$HOME/.gloo/bin:$PATH
glooctl version
glooctl install gateway
kubectl get pod -n gloo-system
kubectl get pods --all-namespaces
echo echo "Waiting for gloo to be ready ..."
for i in {1..150}; do # Timeout after 5 minutes, 60x5=300 secs
      if kubectl get pods --namespace=gloo-system  | grep ContainerCreating ; then
        sleep 10
      else
        break
      fi
done
kubectl get pods --all-namespaces


kubectl apply -f https://raw.githubusercontent.com/solo-io/gloo-ref-arch/blog-30-mar-20/platform/prog-delivery/two-phased-with-os-gloo/1-setup/echo.yaml
kubectl get all -n echo
kubectl get pods --all-namespaces

kubectl apply -f https://raw.githubusercontent.com/solo-io/gloo-ref-arch/blog-30-mar-20/platform/prog-delivery/two-phased-with-os-gloo/1-setup/upstream.yaml
kubectl apply -f https://raw.githubusercontent.com/solo-io/gloo-ref-arch/blog-30-mar-20/platform/prog-delivery/two-phased-with-os-gloo/1-setup/vs.yaml
# curl $(glooctl proxy url)/

# Two-Phased Rollout Strategy
# Phase 1: Initial canary rollout of v2
kubectl apply -f https://raw.githubusercontent.com/solo-io/gloo-ref-arch/blog-30-mar-20/platform/prog-delivery/two-phased-with-os-gloo/2-initial-subset-routing-to-v2/vs-1.yaml
# curl $(glooctl proxy url)/
# Deploying echo v2
kubectl apply -f https://raw.githubusercontent.com/solo-io/gloo-ref-arch/blog-30-mar-20/platform/prog-delivery/two-phased-with-os-gloo/2-initial-subset-routing-to-v2/echo-v2.yaml

kubectl get pod -n echo # TODO echo-v1-5c7c8bbc97-252zt   0/1     ContainerCreating   0          5s

# Adding a route to v2 for canary testing
kubectl apply -f https://raw.githubusercontent.com/solo-io/gloo-ref-arch/blog-30-mar-20/platform/prog-delivery/two-phased-with-os-gloo/2-initial-subset-routing-to-v2/vs-2.yaml
# Canary testing
# curl $(glooctl proxy url)/ version:v1
# curl $(glooctl proxy url)/ -H "stage: canary" #version:v2 # TODO Failed to connect to 10.30.0.73 port 31154: Connection refused





# echo "=============================Inspection============================================================="
# - kubectl get pod -o wide #The IP column will contain the internal cluster IP address for each pod.
# - kubectl get service --all-namespaces # find a Service IP,list all services in all namespaces
# #linkerd
# - sudo sh -c "curl -sL https://run.linkerd.io/install | sh" #Install the CLI
# - export PATH=$PATH:$HOME/.linkerd2/bin
# - linkerd version
# - linkerd check --pre #Validate your Kubernetes cluster
# - sudo sh -c "linkerd install | kubectl apply -f -" #Install Linkerd onto the cluster
# - linkerd check
# - sudo kubectl -n linkerd get deploy
# - linkerd dashboard &
# # - linkerd -n linkerd top deploy/linkerd-web
# #Install the demo app
# - sudo sh -c "curl -sL https://run.linkerd.io/emojivoto.yml | kubectl apply -f -"
# - sudo kubectl -n emojivoto port-forward svc/web-svc 8080:80 #forward web-svc locally to port 8080
# #add Linkerd to emojivoto
# - sudo sh -c "kubectl get -n emojivoto deploy -o yaml | linkerd inject - | kubectl apply -f -"
# #Just as with the control plane, it is possible to verify that everything worked the way it should with the data plane
# - linkerd -n emojivoto check --proxy
# - linkerd -n emojivoto stat deploy #see live traffic metrics by running
# - linkerd -n emojivoto top deploy #get a real-time view of which paths are being called:
# - linkerd -n emojivoto tap deploy/web #use tap shows the stream of requests across a single pod, deployment, or even everything in the emojivoto namespace
# #Install Flagger in the linkerd namespace
# - sudo kubectl apply -k github.com/weaveworks/flagger//kustomize/linkerd
# #Create a test namespace and enable Linkerd proxy injection
# - sudo kubectl create ns test
# - sudo kubectl annotate namespace test linkerd.io/inject=enabled
# #Install the load testing service to generate traffic during the canary analysis
# - sudo kubectl apply -k github.com/weaveworks/flagger//kustomize/tester
# #Create a deployment and a horizontal pod autoscaler:
# - sudo kubectl apply -k github.com/weaveworks/flagger//kustomize/podinfo
# #Create a canary custom resource for the podinfo deploymen
# - sudo kubectl apply -f canary/podinfo-canary.yaml
# #Trigger a canary deployment by updating the container image
# - sudo kubectl -n test set image deployment/podinfo podinfod=stefanprodan/podinfo:3.1.1
# - sudo kubectl -n test describe canary/podinfo
# # monitor all canaries
# - watch kubectl get canaries --all-namespaces
# #Automated rollback
# #Trigger another canary deployment
# - sudo kubectl -n test set image deployment/podinfo podinfod=stefanprodan/podinfo:3.1.2
# #Exec into the load tester pod
# # - sudo kubectl -n test exec -it flagger-loadtester-xx-xx sh
# #Generate HTTP 500 errors
# # - watch -n 1 curl http://podinfo-canary.test:9898/status/500
# #Generate latency
# - watch -n 1 curl http://podinfo-canary.test:9898/delay/1
# - kubectl -n test describe canary/podinfo
# #Trigger a canary deployment by updating the container image
# - sudo kubectl -n test set image deployment/podinfo podinfod=stefanprodan/podinfo:3.1.3
# #Generate 404s
# - watch -n 1 curl http://podinfo-canary:9898/status/404
# #Watch Flagger logs
# - sudo kubectl -n linkerd logs deployment/flagger -f | jq .msg
# #There are two ingress controllers that are compatible with both Flagger and Linkerd: NGINX and Gloo
# #Install NGINX
# - sudo helm upgrade -i nginx-ingress stable/nginx-ingress --namespace ingress-nginx
