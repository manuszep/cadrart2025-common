#!/bin/bash

# Get current test environment color
echo "Getting current test environment..."

COLOR_TEST=$(kubectl get configmap environment-config -n cadrart -o jsonpath='{.data.COLOR_TEST}')

if [[ "$COLOR_TEST" == "blue" || "$COLOR_TEST" == "green" ]]; then
    echo "Current test environment: $COLOR_TEST"
    echo "$COLOR_TEST"
else
    echo "Error: Invalid test environment color: $COLOR_TEST"
    exit 1
fi 