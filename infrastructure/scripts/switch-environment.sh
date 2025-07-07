#!/bin/bash

# Environment switch script for blue-green deployment
# Usage: ./switch-environment.sh <new-production-namespace>

set -e

NEW_PROD_NAMESPACE=$1

if [ -z "$NEW_PROD_NAMESPACE" ]; then
    echo "Usage: $0 <new-production-namespace>"
    echo "Example: $0 cadrart-b"
    exit 1
fi

# Validate namespace exists
if ! kubectl get namespace $NEW_PROD_NAMESPACE > /dev/null 2>&1; then
    echo "❌ Namespace $NEW_PROD_NAMESPACE does not exist"
    exit 1
fi

# Determine current production namespace
CURRENT_PROD_NAMESPACE=$(kubectl get service frontend-production -n cadrart-system -o jsonpath='{.spec.externalName}' 2>/dev/null | sed 's/\.svc\.cluster\.local//' | sed 's/frontend\.//' || echo "cadrart-a")

if [ "$CURRENT_PROD_NAMESPACE" == "$NEW_PROD_NAMESPACE" ]; then
    echo "Already in production: $NEW_PROD_NAMESPACE"
    exit 0
fi

echo "🔄 Switching production environment from $CURRENT_PROD_NAMESPACE to $NEW_PROD_NAMESPACE"

# Lock production database before switch
echo "Locking production database..."
kubectl exec -n $CURRENT_PROD_NAMESPACE $(kubectl get pods -n $CURRENT_PROD_NAMESPACE -l app=db -o jsonpath='{.items[0].metadata.name}') -- \
  mysql -u root -p$(kubectl get secret cadrart-secret -n $CURRENT_PROD_NAMESPACE -o jsonpath='{.data.DATABASE_ROOT_PASSWORD}' | base64 -d) -e "FLUSH TABLES WITH READ LOCK;"

# Sync database from current production to new production
echo "🔄 Syncing database..."
$(dirname "$0")/sync-database.sh $CURRENT_PROD_NAMESPACE $NEW_PROD_NAMESPACE

# Sync static volume from current production to new production
echo "🔄 Syncing static volume..."
$(dirname "$0")/sync-static-volume.sh $CURRENT_PROD_NAMESPACE $NEW_PROD_NAMESPACE

# Update production services to point to new environment
echo "🔄 Updating production services..."
kubectl patch service frontend-production -n cadrart-system --type='merge' -p="{\"spec\":{\"externalName\":\"frontend.$NEW_PROD_NAMESPACE.svc.cluster.local\"}}"
kubectl patch service backend-production -n cadrart-system --type='merge' -p="{\"spec\":{\"externalName\":\"backend.$NEW_PROD_NAMESPACE.svc.cluster.local\"}}"

# Update staging services to point to old environment
echo "🔄 Updating staging services..."
kubectl patch service frontend-staging -n cadrart-system --type='merge' -p="{\"spec\":{\"externalName\":\"frontend.$CURRENT_PROD_NAMESPACE.svc.cluster.local\"}}"
kubectl patch service backend-staging -n cadrart-system --type='merge' -p="{\"spec\":{\"externalName\":\"backend.$CURRENT_PROD_NAMESPACE.svc.cluster.local\"}}"

# Unlock production database
echo "🔓 Unlocking production database..."
kubectl exec -n $CURRENT_PROD_NAMESPACE $(kubectl get pods -n $CURRENT_PROD_NAMESPACE -l app=db -o jsonpath='{.items[0].metadata.name}') -- \
  mysql -u root -p$(kubectl get secret cadrart-secret -n $CURRENT_PROD_NAMESPACE -o jsonpath='{.data.DATABASE_ROOT_PASSWORD}' | base64 -d) -e "UNLOCK TABLES;"

echo "✅ Environment switch completed successfully!"
echo "🌐 Production now points to: $NEW_PROD_NAMESPACE"
echo "Staging now points to: $CURRENT_PROD_NAMESPACE"
echo ""
echo "📋 Summary:"
echo "  - Production (ateliercadrart.com) → $NEW_PROD_NAMESPACE"
echo "  - Staging (stg.ateliercadrart.com) → $CURRENT_PROD_NAMESPACE" 