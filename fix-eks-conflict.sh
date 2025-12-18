#!/bin/bash
set -e

echo "========================================="
echo "EKS Cluster Conflict Resolution"
echo "========================================="
echo ""
echo "This script will import the existing EKS cluster into Terraform state"
echo "to resolve the conflict error."
echo ""

# Variables
CLUSTER_NAME="inventory-manager-dev-eks"
AWS_REGION="${AWS_REGION:-us-east-1}"

cd infra

# Check if EKS is enabled
echo "Checking Terraform configuration..."
if grep -q "enable_eks = false" terraform.tfvars 2>/dev/null; then
    echo "⚠ EKS is disabled in terraform.tfvars (enable_eks = false)"
    echo ""
    echo "To fix this, you have 2 options:"
    echo ""
    echo "Option 1: Enable EKS to import the existing cluster"
    echo "  sed -i 's/enable_eks = false/enable_eks = true/' terraform.tfvars"
    echo "  Then run this script again"
    echo ""
    echo "Option 2: Delete the existing cluster in AWS"
    echo "  aws eks delete-cluster --name ${CLUSTER_NAME} --region ${AWS_REGION}"
    echo ""
    read -p "Enable EKS now and continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Enabling EKS in terraform.tfvars..."
        sed -i 's/enable_eks = false/enable_eks = true/' terraform.tfvars
        echo "✓ EKS enabled"
    else
        echo "Exiting. Please enable EKS manually or delete the cluster."
        exit 0
    fi
fi

# Check if cluster exists
echo "Checking if EKS cluster exists in AWS..."
if aws eks describe-cluster --name "${CLUSTER_NAME}" --region ${AWS_REGION} &>/dev/null; then
    echo "✓ EKS cluster '${CLUSTER_NAME}' found in AWS"
    echo ""
    
    # Initialize Terraform
    echo "Initializing Terraform..."
    terraform init
    echo ""
    
    # Check if already in state
    if terraform state show "module.eks[0].aws_eks_cluster.this[0]" &>/dev/null; then
        echo "✓ EKS cluster already in Terraform state"
        echo "The cluster is already managed by Terraform."
        echo ""
    else
        echo "Importing EKS cluster into Terraform state..."
        if terraform import "module.eks[0].aws_eks_cluster.this[0]" "${CLUSTER_NAME}"; then
            echo "✓ Successfully imported EKS cluster"
            echo ""
        else
            echo "✗ Failed to import EKS cluster"
            echo "Please check the error message above"
            exit 1
        fi
    fi
    
    # Import node groups
    echo "Checking for EKS node groups..."
    NODE_GROUPS=$(aws eks list-nodegroups --cluster-name "${CLUSTER_NAME}" --region ${AWS_REGION} \
        --query 'nodegroups' --output text 2>/dev/null || echo "")
    
    if [ -n "${NODE_GROUPS}" ]; then
        for node_group in ${NODE_GROUPS}; do
            echo "Found node group: ${node_group}"
            
            if terraform state show "module.eks[0].module.eks_managed_node_group[\"default\"].aws_eks_node_group.this[0]" &>/dev/null; then
                echo "  ✓ Node group already in state"
            else
                echo "  Importing node group..."
                terraform import "module.eks[0].module.eks_managed_node_group[\"default\"].aws_eks_node_group.this[0]" \
                    "${CLUSTER_NAME}:${node_group}" || echo "  ⚠ Import failed (may not match expected name)"
            fi
        done
    fi
    
    echo ""
    echo "========================================="
    echo "✓ Import complete!"
    echo "========================================="
    echo ""
    echo "Next steps:"
    echo "1. Run 'terraform plan' to verify the state"
    echo "2. Commit and push changes to trigger the pipeline again"
    echo "3. Or run 'terraform apply' locally if needed"
    
else
    echo "✗ EKS cluster '${CLUSTER_NAME}' not found in AWS"
    echo ""
    echo "This is unexpected. Either:"
    echo "1. The cluster name is different"
    echo "2. The cluster was deleted"
    echo "3. You're connected to a different AWS region/account"
    echo ""
    echo "Current AWS Region: ${AWS_REGION}"
    echo "AWS Account: $(aws sts get-caller-identity --query Account --output text)"
    echo ""
    echo "Listing all EKS clusters:"
    aws eks list-clusters --region ${AWS_REGION} --output table
    exit 1
fi
