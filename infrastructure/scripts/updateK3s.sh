#!/bin/bash

# Check if DOMAIN_NAME is provided
if [ -z "$DOMAIN_NAME" ]; then
  echo "Error: DOMAIN_NAME environment variable is required"
  echo "Usage: DOMAIN_NAME=yourdomain.com ./updateK3s.sh"
  exit 1
fi

echo "Updating K3s cluster with domain: $DOMAIN_NAME"

kubectl apply -f ../kubernetes/config/configmap.yaml
kubectl apply -f ../kubernetes/config/secrets.yaml

kubectl apply -f ../kubernetes/static-volume-persistentvolumeclaim.yaml
kubectl apply -f ../kubernetes/db/db-volume-persistentvolumeclaim.yaml
kubectl apply -f ../kubernetes/logs/logs-volume-persistentvolumeclaim.yaml
kubectl apply -f ../kubernetes/prometheus/prometheus-storage-persistentvolumeclaim.yaml

kubectl apply -f ../kubernetes/db/db-deployment.yaml
kubectl apply -f ../kubernetes/db/db-service.yaml

# Apply NetworkPolicies for security
kubectl apply -f ../kubernetes/db/db-network-policy.yaml
kubectl apply -f ../kubernetes/backend-network-policy.yaml

# Apply monitoring and logging components
kubectl apply -f ../kubernetes/config/prometheus-auth-secret.yaml
kubectl apply -f ../kubernetes/prometheus/prometheus-exporter.yaml
kubectl apply -f ../kubernetes/logs/log-cleanup-cronjob.yaml

./apply-ingress.sh

echo "K3s cluster updated successfully!"
