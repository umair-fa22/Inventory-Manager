#!/bin/bash
set -e

echo "========================================="
echo "Importing Existing AWS Resources"
echo "========================================="

# Variables
CLUSTER_NAME="inventory-manager-dev-eks"
DB_INSTANCE="inventory-manager-dev-pg"
LOG_GROUP="/aws/eks/${CLUSTER_NAME}/cluster"
KMS_ALIAS="alias/eks/${CLUSTER_NAME}"
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "AWS Region: ${AWS_REGION}"
echo "AWS Account: ${AWS_ACCOUNT_ID}"
echo ""

# Function to check if resource exists in state
resource_in_state() {
    terraform state show "$1" &>/dev/null
}

# Function to import resource if it exists in AWS but not in state
import_if_exists() {
    local resource_address="$1"
    local resource_id="$2"
    local resource_name="$3"
    
    echo "Checking: ${resource_name}..."
    
    if resource_in_state "${resource_address}"; then
        echo "  ✓ Already in state"
    else
        echo "  → Attempting to import..."
        if terraform import "${resource_address}" "${resource_id}" 2>/dev/null; then
            echo "  ✓ Successfully imported"
        else
            echo "  ⚠ Import failed or resource doesn't exist in AWS (this is okay)"
        fi
    fi
    echo ""
}

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
    echo ""
fi

echo "Starting resource import process..."
echo "========================================="
echo ""

# Import KMS Key (need to get the key ID first)
echo "Attempting to find KMS key..."
KMS_KEY_ID=$(aws kms list-aliases --region ${AWS_REGION} \
    --query "Aliases[?AliasName=='${KMS_ALIAS}'].TargetKeyId" \
    --output text 2>/dev/null || echo "")

if [ -n "${KMS_KEY_ID}" ] && [ "${KMS_KEY_ID}" != "None" ]; then
    echo "Found KMS Key ID: ${KMS_KEY_ID}"
    import_if_exists "module.eks[0].module.kms.aws_kms_key.this[0]" "${KMS_KEY_ID}" "KMS Key"
    import_if_exists "module.eks[0].module.kms.aws_kms_alias.this[\"cluster\"]" "${KMS_ALIAS}" "KMS Alias"
else
    echo "No existing KMS key found, skipping..."
fi
echo ""

# Import CloudWatch Log Group
import_if_exists "module.eks[0].aws_cloudwatch_log_group.this[0]" "${LOG_GROUP}" "CloudWatch Log Group"

# Import RDS Instance
import_if_exists "module.rds[0].module.db_instance.aws_db_instance.this[0]" "${DB_INSTANCE}" "RDS DB Instance"

# Import RDS Subnet Group (if exists)
DB_SUBNET_GROUP="${DB_INSTANCE}"
import_if_exists "module.rds[0].module.db_subnet_group.aws_db_subnet_group.this[0]" "${DB_SUBNET_GROUP}" "RDS Subnet Group"

echo "========================================="
echo "Import process complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Run 'terraform plan' to verify the state"
echo "2. Run 'terraform apply' to update any differences"
