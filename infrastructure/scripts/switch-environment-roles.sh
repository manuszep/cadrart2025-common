#!/bin/bash

# Switch environment roles script
# This script dynamically switches between blue and green environments
# Usage: ./switch-environment-roles.sh

set -e

echo "🔄 Switching environment roles..."

# Check current environment configuration
CURRENT_PROD=$(kubectl get configmap environment-config -n cadrart -o jsonpath='{.data.COLOR_PROD}')
CURRENT_TEST=$(kubectl get configmap environment-config -n cadrart -o jsonpath='{.data.COLOR_TEST}')

echo "Current configuration: Production=$CURRENT_PROD, Test=$CURRENT_TEST"

# Determine the new production environment (switch from current)
if [ "$CURRENT_PROD" == "blue" ]; then
    NEW_PROD="green"
    NEW_TEST="blue"
    echo "🔄 Switching from Blue (Production) → Green (Production)"
elif [ "$CURRENT_PROD" == "green" ]; then
    NEW_PROD="blue"
    NEW_TEST="green"
    echo "🔄 Switching from Green (Production) → Blue (Production)"
else
    echo "❌ Unknown current production environment: $CURRENT_PROD"
    exit 1
fi

# Check if the target backend is ready
TARGET_STATUS=$(kubectl get pods -n cadrart -l io.kompose.service=backend-$NEW_PROD -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
if [ "$TARGET_STATUS" != "true" ]; then
    echo "❌ $NEW_PROD backend is not ready. Please ensure $NEW_PROD backend is running before switching to production."
    kubectl get pods -n cadrart -l io.kompose.service=backend-$NEW_PROD
    exit 1
fi

echo "✅ $NEW_PROD backend is ready"

# Switch production proxy services to point to new production
echo "🔄 Switching production proxy to $NEW_PROD..."
kubectl patch service frontend-prod-proxy -n cadrart --type='merge' -p="{\"spec\":{\"selector\":{\"io.kompose.service\":\"frontend-$NEW_PROD\"}}}"
kubectl patch service backend-prod-proxy -n cadrart --type='merge' -p="{\"spec\":{\"selector\":{\"io.kompose.service\":\"backend-$NEW_PROD\"}}}"

# Switch test proxy services to point to new test
echo "🔄 Switching test proxy to $NEW_TEST..."
kubectl patch service frontend-test-proxy -n cadrart --type='merge' -p="{\"spec\":{\"selector\":{\"io.kompose.service\":\"frontend-$NEW_TEST\"}}}"
kubectl patch service backend-test-proxy -n cadrart --type='merge' -p="{\"spec\":{\"selector\":{\"io.kompose.service\":\"backend-$NEW_TEST\"}}}"

# Update environment configuration
echo "🔄 Updating environment configuration..."
kubectl patch configmap environment-config -n cadrart --type='merge' -p="{\"data\":{\"COLOR_PROD\":\"$NEW_PROD\",\"COLOR_TEST\":\"$NEW_TEST\"}}"

echo "✅ Environment roles switched successfully!"
echo ""
echo "📋 New configuration:"
echo "  - Production (ateliercadrart.com) → $NEW_PROD"
echo "  - Test (stg.ateliercadrart.com) → $NEW_TEST"
echo ""
echo "Current proxy configuration:"
kubectl get service frontend-prod-proxy backend-prod-proxy frontend-test-proxy backend-test-proxy -n cadrart -o wide
echo ""
echo "Environment configuration:"
kubectl get configmap environment-config -n cadrart -o jsonpath='{.data.COLOR_PROD} {.data.COLOR_TEST}' 