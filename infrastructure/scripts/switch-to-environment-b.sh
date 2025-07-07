#!/bin/bash

# Switch traffic to environment B
echo "Switching traffic to environment B..."

# Update proxy services to point to environment B
kubectl patch service frontend-proxy -n cadrart --type='json' -p='[{"op": "replace", "path": "/spec/selector/app", "value": "frontend-b"}]'
kubectl patch service backend-proxy -n cadrart --type='json' -p='[{"op": "replace", "path": "/spec/selector/app", "value": "backend-b"}]'

echo "Traffic switched to environment B"
echo "Current proxy configuration:"
kubectl get service frontend-proxy backend-proxy -n cadrart -o wide 