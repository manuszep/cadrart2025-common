#!/bin/bash

# Get current active environment
echo "Checking current active environment..."

FRONTEND_TARGET=$(kubectl get service frontend-proxy -n cadrart -o jsonpath='{.spec.selector.app}')
BACKEND_TARGET=$(kubectl get service backend-proxy -n cadrart -o jsonpath='{.spec.selector.app}')

if [[ "$FRONTEND_TARGET" == "frontend-a" && "$BACKEND_TARGET" == "backend-a" ]]; then
    echo "Current active environment: A"
    echo "A"
elif [[ "$FRONTEND_TARGET" == "frontend-b" && "$BACKEND_TARGET" == "backend-b" ]]; then
    echo "Current active environment: B"
    echo "B"
else
    echo "Error: Inconsistent environment configuration"
    echo "Frontend proxy points to: $FRONTEND_TARGET"
    echo "Backend proxy points to: $BACKEND_TARGET"
    exit 1
fi 