#!/bin/bash

# Script to apply ingress configuration with environment variable substitution
# Usage: DOMAIN_NAME=yourdomain.com ./apply-ingress.sh

if [ -z "$DOMAIN_NAME" ]; then
  echo "Error: DOMAIN_NAME environment variable is required"
  echo "Usage: DOMAIN_NAME=yourdomain.com ./apply-ingress.sh"
  exit 1
fi

# Create a temporary file with substituted values
envsubst < ../kubernetes/ingress.yaml > ../kubernetes/ingress-substituted.yaml

# Apply the configuration
kubectl apply -f ../kubernetes/ingress-substituted.yaml

# Clean up
rm ../kubernetes/ingress-substituted.yaml

echo "Ingress applied successfully for domain: $DOMAIN_NAME" 