#!/bin/bash

# Backup current production database and save as SQL dump locally
# Usage: ./backup-prod-database.sh [output-file.sql]

set -e

OUTPUT_FILE=${1:-cadrart_prod_backup.sql}

# Detect current production namespace from proxy service
CURRENT_PROD_NAMESPACE=$(kubectl get service frontend-production -n cadrart-system -o jsonpath='{.spec.externalName}' 2>/dev/null | sed 's/\.svc\.cluster\.local//' | sed 's/frontend\.//' || echo "cadrart-a")

if [ -z "$CURRENT_PROD_NAMESPACE" ]; then
  echo "❌ Could not determine current production namespace."
  exit 1
fi

echo "📦 Backing up production database from namespace: $CURRENT_PROD_NAMESPACE"

# Get DB credentials from secrets
DB_USER=$(kubectl get secret cadrart-secret -n $CURRENT_PROD_NAMESPACE -o jsonpath='{.data.DATABASE_USER}' | base64 -d)
DB_PASSWORD=$(kubectl get secret cadrart-secret -n $CURRENT_PROD_NAMESPACE -o jsonpath='{.data.DATABASE_PASSWORD}' | base64 -d)
DB_NAME=$(kubectl get configmap cadrart-config -n $CURRENT_PROD_NAMESPACE -o jsonpath='{.data.DATABASE_DATABASE}')

# Get DB pod name
DB_POD=$(kubectl get pods -n $CURRENT_PROD_NAMESPACE -l app=db -o jsonpath='{.items[0].metadata.name}')

if [ -z "$DB_POD" ]; then
  echo "❌ Could not find DB pod in namespace $CURRENT_PROD_NAMESPACE."
  exit 1
fi

echo "💾 Creating SQL dump..."
kubectl exec -n $CURRENT_PROD_NAMESPACE $DB_POD -- mysqldump -u$DB_USER -p$DB_PASSWORD $DB_NAME > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
  echo "✅ Database backup saved to $OUTPUT_FILE"
else
  echo "❌ Database backup failed."
  exit 1
fi 