#!/bin/bash

# Switch proxy services to green environment
echo "Switching proxy services to green environment..."

# Update production proxy services to point to green
kubectl patch service frontend-prod-proxy -n cadrart --type='merge' -p='{"spec":{"selector":{"io.kompose.service":"frontend-green"}}}'
kubectl patch service backend-prod-proxy -n cadrart --type='merge' -p='{"spec":{"selector":{"io.kompose.service":"backend-green"}}}'

# Update test proxy services to point to blue
kubectl patch service frontend-test-proxy -n cadrart --type='merge' -p='{"spec":{"selector":{"io.kompose.service":"frontend-blue"}}}'
kubectl patch service backend-test-proxy -n cadrart --type='merge' -p='{"spec":{"selector":{"io.kompose.service":"backend-blue"}}}'

# Update environment config to reflect green is now production
kubectl patch configmap environment-config -n cadrart --type='merge' -p='{"data":{"COLOR_PROD":"green","COLOR_TEST":"blue"}}'

echo "Proxy services switched to green environment"
echo "Current proxy configuration:"
kubectl get service frontend-prod-proxy backend-prod-proxy frontend-test-proxy backend-test-proxy -n cadrart -o wide
echo ""
echo "Environment configuration:"
kubectl get configmap environment-config -n cadrart -o jsonpath='{.data.COLOR_PROD} {.data.COLOR_TEST}' 