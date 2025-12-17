#!/bin/bash

# Terraform Cleanup Script
# This script helps clean up stuck/existing Terraform resources

set -e

echo "==========================================="
echo "  Terraform Resource Cleanup"
echo "==========================================="
echo ""

cd infra

# Option 1: Remove specific resources from state that already exist
echo "Option 1: Remove problematic resources from state"
echo "This allows Terraform to import/recreate them"
echo ""

read -p "Do you want to remove stuck resources from state? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing KMS alias from state..."
    terraform state rm 'module.eks[0].module.kms.aws_kms_alias.this["cluster"]' 2>/dev/null || echo "Not in state"
    
    echo "Removing CloudWatch log group from state..."
    terraform state rm 'module.eks[0].aws_cloudwatch_log_group.this[0]' 2>/dev/null || echo "Not in state"
    
    echo "✓ Resources removed from state"
    echo ""
    echo "Now run: terraform apply"
fi

echo ""
echo "==========================================="
echo "Option 2: Destroy all resources and start fresh"
echo "==========================================="
echo ""

read -p "Do you want to destroy ALL resources? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "⚠️  WARNING: This will destroy ALL infrastructure!"
    read -p "Are you SURE? Type 'yes' to confirm: " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo "Destroying infrastructure..."
        terraform destroy -auto-approve
        echo "✓ All resources destroyed"
        echo ""
        echo "You can now run: terraform apply"
    else
        echo "Cancelled"
    fi
fi

echo ""
echo "==========================================="
echo "Option 3: Import existing resources"
echo "==========================================="
echo ""

read -p "Do you want to import existing resources? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Importing KMS alias..."
    terraform import 'module.eks[0].module.kms.aws_kms_alias.this["cluster"]' 'alias/eks/inventory-manager-dev-eks' 2>/dev/null || echo "Already in state or doesn't exist"
    
    echo "Importing CloudWatch log group..."
    terraform import 'module.eks[0].aws_cloudwatch_log_group.this[0]' '/aws/eks/inventory-manager-dev-eks/cluster' 2>/dev/null || echo "Already in state or doesn't exist"
    
    echo "✓ Import complete"
    echo ""
    echo "Now run: terraform apply"
fi

echo ""
echo "Done!"
