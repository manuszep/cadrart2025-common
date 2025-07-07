#!/bin/bash

# Deploy with variable substitution for dynamic environment
echo "Deploying with dynamic environment substitution..."

# Get current test environment
COLOR_TEST=$(kubectl get configmap environment-config -n cadrart -o jsonpath='{.data.COLOR_TEST}')

if [[ "$COLOR_TEST" != "blue" && "$COLOR_TEST" != "green" ]]; then
    echo "Error: Invalid test environment color: $COLOR_TEST"
    exit 1
fi

echo "Current test environment: $COLOR_TEST"

# Create temporary files with variable substitution
echo "Creating temporary deployment files..."

# Backend deployment
cat cadrart2025-backend/infrastructure/kubernetes/base/deployment.yaml | \
  sed "s/\$COLOR_TEST/$COLOR_TEST/g" | \
  kubectl apply -f -

# Frontend deployment
cat cadrart2025-frontend/infrastructure/kubernetes/base/deployment.yaml | \
  sed "s/\$COLOR_TEST/$COLOR_TEST/g" | \
  kubectl apply -f -

# Backend service
cat cadrart2025-backend/infrastructure/kubernetes/base/service.yaml | \
  sed "s/\$COLOR_TEST/$COLOR_TEST/g" | \
  kubectl apply -f -

# Frontend service
cat cadrart2025-frontend/infrastructure/kubernetes/base/service.yaml | \
  sed "s/\$COLOR_TEST/$COLOR_TEST/g" | \
  kubectl apply -f -

echo "Deployment to test environment $COLOR_TEST completed" 