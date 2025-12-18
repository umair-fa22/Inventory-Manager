#!/bin/bash
set -e

echo "========================================="
echo "Force Recreate Conflicting Resources"
echo "========================================="
echo ""
echo "⚠️  WARNING: This will destroy and recreate resources!"
echo "This should only be used in development environments."
echo ""

# Variables
CLUSTER_NAME="inventory-manager-dev-eks"
DB_INSTANCE="inventory-manager-dev-pg"
LOG_GROUP="/aws/eks/${CLUSTER_NAME}/cluster"
KMS_ALIAS="alias/eks/${CLUSTER_NAME}"
AWS_REGION="${AWS_REGION:-us-east-1}"

read -p "Are you sure you want to continue? (type 'yes' to proceed): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Removing conflicting resources from AWS..."
echo "========================================="

# Delete KMS Alias
echo "Deleting KMS Alias..."
aws kms delete-alias --alias-name "${KMS_ALIAS}" --region ${AWS_REGION} 2>/dev/null && echo "✓ Deleted KMS alias" || echo "⚠ KMS alias not found or already deleted"

# Delete CloudWatch Log Group
echo "Deleting CloudWatch Log Group..."
aws logs delete-log-group --log-group-name "${LOG_GROUP}" --region ${AWS_REGION} 2>/dev/null && echo "✓ Deleted log group" || echo "⚠ Log group not found or already deleted"

# Delete RDS Instance
echo "Deleting RDS Instance..."
aws rds delete-db-instance \
    --db-instance-identifier "${DB_INSTANCE}" \
    --skip-final-snapshot \
    --region ${AWS_REGION} 2>/dev/null && echo "✓ Initiated RDS deletion (this takes several minutes)" || echo "⚠ RDS instance not found or already deleted"

echo ""
echo "========================================="
echo "Deletion initiated!"
echo "========================================="
echo ""
echo "Note: RDS deletion can take 5-10 minutes."
echo "Wait for completion before running terraform apply."
echo ""
echo "To check status:"
echo "  aws rds describe-db-instances --db-instance-identifier ${DB_INSTANCE} --region ${AWS_REGION}"
