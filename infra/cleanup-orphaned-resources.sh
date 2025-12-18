#!/usr/bin/env bash
set -euo pipefail

# Cleanup orphaned AWS resources that may cause Terraform conflicts
echo "===> Cleaning up orphaned AWS resources"

CLUSTER_NAME="inventory-manager-dev-eks"
LOG_GROUP_NAME="/aws/eks/${CLUSTER_NAME}/cluster"
KMS_ALIAS="alias/eks/${CLUSTER_NAME}"
REGION="${AWS_REGION:-us-east-1}"

# Delete CloudWatch Log Group if it exists
echo "Checking for orphaned CloudWatch Log Group..."
if aws logs describe-log-groups --region "$REGION" --log-group-name-prefix "$LOG_GROUP_NAME" 2>/dev/null | grep -q "$LOG_GROUP_NAME"; then
    echo "Deleting CloudWatch Log Group: $LOG_GROUP_NAME"
    aws logs delete-log-group --region "$REGION" --log-group-name "$LOG_GROUP_NAME" || true
else
    echo "CloudWatch Log Group not found (OK)"
fi

# Delete KMS Alias if it exists (note: you can't delete the key immediately, but removing alias is enough)
echo "Checking for orphaned KMS Alias..."
if aws kms describe-alias --region "$REGION" --alias-name "$KMS_ALIAS" 2>/dev/null; then
    KEY_ID=$(aws kms describe-alias --region "$REGION" --alias-name "$KMS_ALIAS" --query 'AliasArn' --output text | grep -oP '(?<=key/)[a-f0-9-]+' || echo "")
    if [ -n "$KEY_ID" ]; then
        echo "Deleting KMS Alias: $KMS_ALIAS"
        aws kms delete-alias --region "$REGION" --alias-name "$KMS_ALIAS" || true
    fi
else
    echo "KMS Alias not found (OK)"
fi

# Check if EKS cluster exists
echo "Checking for existing EKS cluster..."
if aws eks describe-cluster --region "$REGION" --name "$CLUSTER_NAME" 2>/dev/null; then
    echo "WARNING: EKS cluster '$CLUSTER_NAME' already exists!"
    echo "To avoid conflicts, consider running: aws eks delete-cluster --region $REGION --name $CLUSTER_NAME"
    echo "Then wait for full deletion before re-running terraform apply"
else
    echo "EKS cluster not found (OK)"
fi

echo "===> Cleanup complete"
