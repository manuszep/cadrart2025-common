#!/bin/bash

# Switch test environment between blue and green
echo "Switching test environment..."

# Get current test environment
CURRENT_COLOR=$(kubectl get configmap environment-config -n cadrart -o jsonpath='{.data.COLOR_TEST}')

if [[ "$CURRENT_COLOR" == "blue" ]]; then
    NEW_COLOR="green"
elif [[ "$CURRENT_COLOR" == "green" ]]; then
    NEW_COLOR="blue"
else
    echo "Error: Invalid current test environment: $CURRENT_COLOR"
    exit 1
fi

# Update the configmap
kubectl patch configmap environment-config -n cadrart --type='merge' -p="{\"data\":{\"COLOR_TEST\":\"$NEW_COLOR\"}}"

echo "Test environment switched from $CURRENT_COLOR to $NEW_COLOR"
echo "New test environment: $NEW_COLOR" 