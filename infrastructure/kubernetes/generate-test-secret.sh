#!/bin/bash

# Script to generate base64 encoded test endpoint secret for Kubernetes
# Usage: ./generate-test-secret.sh "your-secret-value"

echo "Test Endpoint Secret Generator"
echo "=============================="
echo ""

# Check if secret was provided as argument
if [ $# -eq 0 ]; then
    echo "No secret provided as argument."
    echo ""
    echo "Please enter your secret value (special characters are supported):"
    read -s SECRET_VALUE
    echo ""
else
    SECRET_VALUE="$1"
fi

# Validate that we have a secret
if [ -z "$SECRET_VALUE" ]; then
    echo "Error: No secret value provided."
    echo "Usage: $0 \"your-secret-value\""
    echo "Example: $0 \"my-super-secure-test-secret-2024\""
    echo ""
    echo "Or run without arguments to enter the secret interactively."
    exit 1
fi

# Generate base64 encoded value
BASE64_ENCODED=$(echo -n "$SECRET_VALUE" | base64)

echo "Secret processing complete:"
echo "=========================="
echo "Original secret length: ${#SECRET_VALUE} characters"
echo "Base64 encoded: $BASE64_ENCODED"
echo ""
echo "Add this to your Kubernetes secret:"
echo "  TEST_ENDPOINT_SECRET: $BASE64_ENCODED"
echo ""
echo "Or update the secrets.yaml file with:"
echo "  TEST_ENDPOINT_SECRET: $BASE64_ENCODED"
echo ""
echo "Security reminder:"
echo "- Never commit real secrets to version control"
echo "- Use different secrets for different environments"
echo "- Rotate secrets regularly" 