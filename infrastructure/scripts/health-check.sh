#!/bin/bash

# Health check script for blue-green deployment
# Usage: ./health-check.sh <namespace>

set -e

NAMESPACE=$1

if [ -z "$NAMESPACE" ]; then
    echo "Usage: $0 <namespace>"
    echo "Example: $0 cadrart-a"
    exit 1
fi

echo "🏥 Performing health check for namespace: $NAMESPACE"

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE > /dev/null 2>&1; then
    echo "❌ Namespace $NAMESPACE does not exist"
    exit 1
fi

# Check if pods are running
echo "📊 Checking pod status..."
PODS=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
if [ -z "$PODS" ]; then
    echo "❌ No pods found in namespace $NAMESPACE"
    exit 1
fi

for POD in $PODS; do
    STATUS=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.phase}')
    READY=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].ready}')
    
    if [ "$STATUS" != "Running" ] || [ "$READY" != "true" ]; then
        echo "❌ Pod $POD is not ready (Status: $STATUS, Ready: $READY)"
        exit 1
    else
        echo "✅ Pod $POD is ready"
    fi
done

# Check if services are available
echo "🔗 Checking service availability..."
SERVICES=$(kubectl get services -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
if [ -z "$SERVICES" ]; then
    echo "❌ No services found in namespace $NAMESPACE"
    exit 1
fi

for SERVICE in $SERVICES; do
    if kubectl get service $SERVICE -n $NAMESPACE > /dev/null 2>&1; then
        echo "✅ Service $SERVICE is available"
    else
        echo "❌ Service $SERVICE is not available"
        exit 1
    fi
done

# Check backend health endpoints if backend pod exists
BACKEND_POD=$(kubectl get pods -n $NAMESPACE -l app=backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$BACKEND_POD" ]; then
    echo "🔍 Checking backend health endpoints..."
    
    # Check live health
    if kubectl exec -n $NAMESPACE $BACKEND_POD -- curl -f http://localhost:3000/health/live > /dev/null 2>&1; then
        echo "✅ Backend live health check passed"
    else
        echo "❌ Backend live health check failed"
        exit 1
    fi
    
    # Check ready health
    if kubectl exec -n $NAMESPACE $BACKEND_POD -- curl -f http://localhost:3000/health/ready > /dev/null 2>&1; then
        echo "✅ Backend ready health check passed"
    else
        echo "❌ Backend ready health check failed"
        exit 1
    fi
fi

# Check frontend if frontend pod exists
FRONTEND_POD=$(kubectl get pods -n $NAMESPACE -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$FRONTEND_POD" ]; then
    echo "🔍 Checking frontend availability..."
    
    # Check if frontend is responding
    if kubectl exec -n $NAMESPACE $FRONTEND_POD -- curl -f http://localhost:8080/ > /dev/null 2>&1; then
        echo "✅ Frontend health check passed"
    else
        echo "❌ Frontend health check failed"
        exit 1
    fi
fi

echo "✅ All health checks passed for namespace $NAMESPACE" 