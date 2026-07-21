#!/bin/bash

set -e

echo "Running the deploy script"

echo -n "Checking for kubectl... "
if ! command -v kubectl &> /dev/null; then
	echo "FAILED"
	exit 1
else
	echo "SUCCESS"
fi

echo -n "Checking for helm... "
if ! command -v helm &> /dev/null; then
	echo "FAILED"
	exit 1
else
	echo "SUCCESS"
fi

echo -n "Checking if docker is running... "
if ! systemctl is-active docker &>/dev/null;  then
	echo "FAILED"
	echo -n "Attempting to start the docker daemon... "
	if ! systemctl start docker &>/dev/null; then
		echo "FAILED"
		exit 1
	else
		echo "SUCCESS"
	fi
else
	echo "SUCCESS"
fi	

echo -n "Checking for minikube... "
if ! command -v minikube &>/dev/null; then
	echo "FAILED"
	exit 1
else
	echo "SUCCESS"
fi

echo -n "Checking if minikube is running... "
if ! minikube status &>/dev/null; then
	echo "FAILED"
	echo -n "Attempting to launch the minikube... "
	if ! minikube start &>/dev/null; then
		echo "FAILED"
		exit 1
	else
		echo "SUCCESS"
	fi
else
    echo "SUCCESS"
fi

echo "Change directory to mymanifests"
cd mymanifests

echo -n "Attempting to create namespaces... "
if ! kubectl apply -f namespaces.yaml>/dev/null; then
	echo "FAILED"
	exit 1
else
	echo "SUCCESS"
fi

echo -n "Attempting to apply manifests... "
for cmd in appserver db redis ui; do
	if ! kubectl apply -f $cmd/ -R>/dev/null; then
		echo "FAILED"
		exit 1
	fi
done
echo "SUCCESS"

echo -n "Attempting to install monitoring stack... "
if ! helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null; then
	echo "FAILED"
	exit 1
fi
if ! helm repo update>/dev/null; then
	echo "FAILED"
	exit 1
fi
if ! helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace >/dev/null; then
	echo "FAILED"
	exit 1
fi
echo "SUCCESS"

echo "Done!"
kubectl get pods -A
