#!/bin/bash

# Switch proxy services to blue environment
echo "Switching proxy services to blue environment..."

# Update frontend proxy to point to blue
kubectl patch service frontend-proxy -n cadrart --type='json' -p='[{"op": "replace", "path": "/spec/selector/app", "value": "frontend-blue"}]'

# Update backend proxy to point to blue
kubectl patch service backend-proxy -n cadrart --type='json' -p='[{"op": "replace", "path": "/spec/selector/app", "value": "backend-blue"}]'

echo "Proxy services switched to blue environment"
echo "Current proxy configuration:"
kubectl get service frontend-proxy backend-proxy -n cadrart -o wide 