#!/bin/bash

# Database synchronization script for blue-green deployment
# Usage: ./sync-database.sh <source-namespace> <target-namespace>

set -e

SOURCE_NAMESPACE=$1
TARGET_NAMESPACE=$2

if [ -z "$SOURCE_NAMESPACE" ] || [ -z "$TARGET_NAMESPACE" ]; then
    echo "Usage: $0 <source-namespace> <target-namespace>"
    echo "Example: $0 cadrart-a cadrart-b"
    exit 1
fi

echo "🔄 Starting database synchronization from $SOURCE_NAMESPACE to $TARGET_NAMESPACE"

# Get database credentials from secrets
DB_USER=$(kubectl get secret cadrart-secret -n $SOURCE_NAMESPACE -o jsonpath='{.data.DATABASE_USER}' | base64 -d)
DB_PASSWORD=$(kubectl get secret cadrart-secret -n $SOURCE_NAMESPACE -o jsonpath='{.data.DATABASE_PASSWORD}' | base64 -d)
DB_NAME=$(kubectl get configmap cadrart-config -n $SOURCE_NAMESPACE -o jsonpath='{.data.DATABASE_DATABASE}')

# Get pod names
SOURCE_POD=$(kubectl get pods -n $SOURCE_NAMESPACE -l app=db -o jsonpath='{.items[0].metadata.name}')
TARGET_POD=$(kubectl get pods -n $TARGET_NAMESPACE -l app=db -o jsonpath='{.items[0].metadata.name}')

echo "📊 Source database pod: $SOURCE_POD"
echo "📊 Target database pod: $TARGET_POD"

# Create backup from source database
echo "💾 Creating backup from source database..."
kubectl exec -n $SOURCE_NAMESPACE $SOURCE_POD -- mysqldump -u$DB_USER -p$DB_PASSWORD $DB_NAME > /tmp/cadrart_backup.sql

# Copy backup to target pod
echo "📦 Copying backup to target pod..."
kubectl cp /tmp/cadrart_backup.sql $TARGET_NAMESPACE/$TARGET_POD:/tmp/

# Restore to target database
echo "🔄 Restoring to target database..."
kubectl exec -n $TARGET_NAMESPACE $TARGET_POD -- /bin/sh -c "mysql -u$DB_USER -p$DB_PASSWORD $DB_NAME < /tmp/cadrart_backup.sql"

# Cleanup
rm -f /tmp/cadrart_backup.sql
kubectl exec -n $TARGET_NAMESPACE $TARGET_POD -- rm -f /tmp/cadrart_backup.sql

echo "✅ Database synchronization completed successfully!" 