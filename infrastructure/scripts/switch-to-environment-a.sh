#!/bin/bash

# Switch traffic to environment A
echo "Switching traffic to environment A..."

# Update proxy services to point to environment A
kubectl patch service frontend-proxy -n cadrart --type='json' -p='[{"op": "replace", "path": "/spec/selector/app", "value": "frontend-a"}]'
kubectl patch service backend-proxy -n cadrart --type='json' -p='[{"op": "replace", "path": "/spec/selector/app", "value": "backend-a"}]'

echo "Traffic switched to environment A"
echo "Current proxy configuration:"
kubectl get service frontend-proxy backend-proxy -n cadrart -o wide 