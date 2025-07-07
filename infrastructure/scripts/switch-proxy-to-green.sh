#!/bin/bash

# Switch proxy services to green environment
echo "Switching proxy services to green environment..."

# Update frontend proxy to point to green
kubectl patch service frontend-proxy -n cadrart --type='json' -p='[{"op": "replace", "path": "/spec/selector/app", "value": "frontend-green"}]'

# Update backend proxy to point to green
kubectl patch service backend-proxy -n cadrart --type='json' -p='[{"op": "replace", "path": "/spec/selector/app", "value": "backend-green"}]'

echo "Proxy services switched to green environment"
echo "Current proxy configuration:"
kubectl get service frontend-proxy backend-proxy -n cadrart -o wide 