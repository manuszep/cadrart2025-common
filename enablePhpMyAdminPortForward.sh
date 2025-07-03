#!/bin/bash

# Port-forward phpMyAdmin service to localhost:8080
# Usage: ./enablePhpMyAdminPortForward.sh

NAMESPACE=cadrart
SERVICE=phpmyadmin-service
LOCAL_PORT=8080
REMOTE_PORT=80

set -e

echo "Forwarding $SERVICE in namespace $NAMESPACE to http://localhost:$LOCAL_PORT ..."
kubectl port-forward -n $NAMESPACE svc/$SERVICE $LOCAL_PORT:$REMOTE_PORT 