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
# curl $(glooctl proxy url)/ -H "stage: canary" #version:v2 # Failed to connect to 10.30.0.73 port 31154: Connection refused
