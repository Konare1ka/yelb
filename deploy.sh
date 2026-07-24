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
if ! minikube status --profile=minikube | grep -q "Running" >/dev/null; then
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
cd manifests

echo -n "Attempting to create namespaces... "
if ! kubectl apply -f namespaces.yaml>/dev/null; then
	echo "FAILED"
	exit 1
else
	echo "SUCCESS"
fi

echo -n "Attempting to apply manifests... "
for cmd in appserver db redis ui reverse-proxy; do
	if ! kubectl apply -f $cmd/ -R>/dev/null; then
		echo "FAILED"
		exit 1
	fi
done
echo "SUCCESS"

echo -n "Attempting to install monitoring stack... "
if ! helm repo add prometheus-community https://prometheus-community.github.io/helm-charts>/dev/null; then
	echo "FAILED"
	exit 1
fi
if ! helm repo update>/dev/null; then
	echo "FAILED"
	exit 1
fi
if ! helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace -f monitoring-values.yaml >/dev/null; then
	echo "FAILED"
	exit 1
fi
echo "SUCCESS"

kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=120s

echo "Exposing grafana via nodeport"
kubectl patch svc monitoring-grafana -n monitoring -p '{"spec":{"type":"NodePort"}}'

echo "Grafana url - $(minikube ip):$(kubectl get svc -n monitoring monitoring-grafana | awk 'NR==2 {split($5,a,":"); split(a[2],b,"/"); print b[1]}')" #show external ip
echo "Grafana login - admin"
echo "Grafana password - $(kubectl get secret -n monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 -d)"


echo "Done!"
kubectl get pods -A
