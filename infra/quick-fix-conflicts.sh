#!/bin/bash
# Quick fix script for Terraform resource conflicts

set -e

echo "========================================="
echo "Terraform Conflict Quick Fix"
echo "========================================="
echo ""

cd infra

echo "1. Checking Terraform state..."
if terraform state list | grep -q "module.eks\|module.rds"; then
    echo "   ✓ Resources found in state"
else
    echo "   ⚠ No resources in state - importing..."
    ./import-existing-resources.sh
fi

echo ""
echo "2. Running Terraform plan..."
terraform plan -out=tfplan

echo ""
echo "3. Review the plan above."
read -p "Apply changes? (yes/no): " apply_confirm

if [ "$apply_confirm" = "yes" ]; then
    echo ""
    echo "4. Applying changes..."
    terraform apply tfplan
    echo ""
    echo "✓ Complete!"
else
    echo "Skipped apply."
fi

echo ""
echo "========================================="
echo "To manually fix conflicts, run:"
echo "  cd infra && ./import-existing-resources.sh"
echo "========================================="
