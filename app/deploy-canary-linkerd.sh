#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
set -o xtrace
# set -eox pipefail #safety for script

# https://linkerd.io/2/getting-started/
echo "============================Install Linkerd=============================================================="
curl -sL https://run.linkerd.io/install | sh

export PATH=$PATH:$HOME/.linkerd2/bin
linkerd dashboard &


#https://docs.flagger.app/tutorials/linkerd-progressive-delivery#a-b-testing
# Prerequisites
# Flagger requires a Kubernetes cluster v1.11 or newer and Linkerd 2.4 or newer
echo "============================Linkerd Flagger Canary Deployments=============================================================="
kubectl get pods --all-namespaces
kubectl create ns linkerd #Create a namespace called Linkerd
kubectl apply -k github.com/weaveworks/flagger//kustomize/linkerd #Install Flagger in the linkerd namespace
kubectl get pods --all-namespaces
