#!/bin/bash

# Static volume synchronization script for blue-green deployment
# Usage: ./sync-static-volume.sh <source-namespace> <target-namespace>

set -e

SOURCE_NAMESPACE=$1
TARGET_NAMESPACE=$2

if [ -z "$SOURCE_NAMESPACE" ] || [ -z "$TARGET_NAMESPACE" ]; then
    echo "Usage: $0 <source-namespace> <target-namespace>"
    echo "Example: $0 cadrart-a cadrart-b"
    exit 1
fi

echo "🔄 Starting static volume synchronization from $SOURCE_NAMESPACE to $TARGET_NAMESPACE"

# Get pod names (assume frontend pod mounts the static volume)
SOURCE_POD=$(kubectl get pods -n $SOURCE_NAMESPACE -l io.kompose.service=frontend -o jsonpath='{.items[0].metadata.name}')
TARGET_POD=$(kubectl get pods -n $TARGET_NAMESPACE -l io.kompose.service=frontend -o jsonpath='{.items[0].metadata.name}')

# Archive static files from source
kubectl exec -n $SOURCE_NAMESPACE $SOURCE_POD -- tar czf /tmp/static_volume_backup.tar.gz -C /var/www/static .

# Copy archive to local
kubectl cp $SOURCE_NAMESPACE/$SOURCE_POD:/tmp/static_volume_backup.tar.gz /tmp/static_volume_backup.tar.gz

# Copy archive to target pod
kubectl cp /tmp/static_volume_backup.tar.gz $TARGET_NAMESPACE/$TARGET_POD:/tmp/static_volume_backup.tar.gz

# Clear target static volume and extract
kubectl exec -n $TARGET_NAMESPACE $TARGET_POD -- rm -rf /var/www/static/*
kubectl exec -n $TARGET_NAMESPACE $TARGET_POD -- tar xzf /tmp/static_volume_backup.tar.gz -C /var/www/static

# Cleanup
kubectl exec -n $SOURCE_NAMESPACE $SOURCE_POD -- rm -f /tmp/static_volume_backup.tar.gz
kubectl exec -n $TARGET_NAMESPACE $TARGET_POD -- rm -f /tmp/static_volume_backup.tar.gz
rm -f /tmp/static_volume_backup.tar.gz

echo "✅ Static volume synchronization completed successfully!" 