#!/bin/bash

# Deploy to current test environment
echo "Deploying to test environment..."

# Get current test environment
COLOR_TEST=$(kubectl get configmap environment-config -n cadrart -o jsonpath='{.data.COLOR_TEST}')

if [[ "$COLOR_TEST" != "blue" && "$COLOR_TEST" != "green" ]]; then
    echo "Error: Invalid test environment color: $COLOR_TEST"
    exit 1
fi

echo "Current test environment: $COLOR_TEST"

# Export the color for use in deployments
export COLOR_TEST

# Apply backend deployment
echo "Applying backend deployment..."
kubectl apply -f cadrart2025-backend/infrastructure/kubernetes/base/deployment.yaml

# Apply frontend deployment
echo "Applying frontend deployment..."
kubectl apply -f cadrart2025-frontend/infrastructure/kubernetes/base/deployment.yaml

# Apply backend service
echo "Applying backend service..."
kubectl apply -f cadrart2025-backend/infrastructure/kubernetes/base/service.yaml

# Apply frontend service
echo "Applying frontend service..."
kubectl apply -f cadrart2025-frontend/infrastructure/kubernetes/base/service.yaml

echo "Deployment to test environment $COLOR_TEST completed" 