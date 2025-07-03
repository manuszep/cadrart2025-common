#!/bin/bash

# Check if DOMAIN_NAME is provided
if [ -z "$DOMAIN_NAME" ]; then
  echo "Error: DOMAIN_NAME environment variable is required"
  echo "Usage: DOMAIN_NAME=yourdomain.com ./updateK3s.sh"
  exit 1
fi

echo "Updating K3s cluster with domain: $DOMAIN_NAME"

kubectl apply -f ./infrastructure/kubernetes/configmap.yaml
kubectl apply -f ./infrastructure/kubernetes/secrets.yaml

kubectl apply -f ./infrastructure/kubernetes/static-volume-persistentvolumeclaim.yaml
kubectl apply -f ./infrastructure/kubernetes/db-volume-persistentvolumeclaim.yaml
kubectl apply -f ./infrastructure/kubernetes/logs-volume-persistentvolumeclaim.yaml
kubectl apply -f ./infrastructure/kubernetes/prometheus-storage-persistentvolumeclaim.yaml

kubectl apply -f ./infrastructure/kubernetes/db-deployment.yaml
kubectl apply -f ./infrastructure/kubernetes/db-service.yaml

# Apply NetworkPolicies for security
kubectl apply -f ./infrastructure/kubernetes/db-network-policy.yaml
kubectl apply -f ./infrastructure/kubernetes/backend-network-policy.yaml

# Apply monitoring and logging components
kubectl apply -f ./infrastructure/kubernetes/prometheus-auth-secret.yaml
kubectl apply -f ./infrastructure/kubernetes/prometheus-exporter.yaml
kubectl apply -f ./infrastructure/kubernetes/log-cleanup-cronjob.yaml

# Use the new apply-ingress.sh script with environment variable substitution
cd ./infrastructure/kubernetes
./apply-ingress.sh
cd ../..

echo "K3s cluster updated successfully!"
