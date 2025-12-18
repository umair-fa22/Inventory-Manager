#!/bin/bash
# Import an existing VPC into Terraform state

set -e

VPC_ID="$1"
AWS_REGION="${AWS_REGION:-us-east-1}"

if [ -z "${VPC_ID}" ]; then
    echo "Usage: $0 <vpc-id>"
    echo ""
    echo "Example: $0 vpc-0123456789abcdef"
    echo ""
    echo "This will import an existing VPC into Terraform state"
    echo "instead of creating a new one."
    exit 1
fi

echo "========================================="
echo "Import Existing VPC to Terraform"
echo "========================================="
echo "VPC ID: ${VPC_ID}"
echo "Region: ${AWS_REGION}"
echo ""

cd infra

# Check if VPC exists
if ! aws ec2 describe-vpcs --vpc-ids ${VPC_ID} --region ${AWS_REGION} &>/dev/null; then
    echo "Error: VPC ${VPC_ID} not found in ${AWS_REGION}"
    exit 1
fi

VPC_INFO=$(aws ec2 describe-vpcs --vpc-ids ${VPC_ID} --region ${AWS_REGION} --output json)
VPC_NAME=$(echo "${VPC_INFO}" | jq -r '.Vpcs[0].Tags[]? | select(.Key=="Name") | .Value // "N/A"')
VPC_CIDR=$(echo "${VPC_INFO}" | jq -r '.Vpcs[0].CidrBlock')

echo "VPC Name: ${VPC_NAME}"
echo "VPC CIDR: ${VPC_CIDR}"
echo ""

# Initialize terraform if needed
if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
    echo ""
fi

echo "Importing VPC into Terraform state..."
if terraform import 'module.vpc.aws_vpc.this[0]' "${VPC_ID}"; then
    echo "✓ VPC imported successfully!"
    echo ""
    echo "Now importing subnets..."
    
    # Get subnets
    SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --region ${AWS_REGION} --output json)
    PUBLIC_SUBNETS=$(echo "${SUBNETS}" | jq -r '.Subnets[] | select(.MapPublicIpOnLaunch == true) | .SubnetId')
    PRIVATE_SUBNETS=$(echo "${SUBNETS}" | jq -r '.Subnets[] | select(.MapPublicIpOnLaunch == false) | .SubnetId')
    
    # Import public subnets
    idx=0
    for subnet_id in ${PUBLIC_SUBNETS}; do
        echo "Importing public subnet ${subnet_id}..."
        terraform import "module.vpc.aws_subnet.public[${idx}]" "${subnet_id}" || true
        idx=$((idx + 1))
    done
    
    # Import private subnets
    idx=0
    for subnet_id in ${PRIVATE_SUBNETS}; do
        echo "Importing private subnet ${subnet_id}..."
        terraform import "module.vpc.aws_subnet.private[${idx}]" "${subnet_id}" || true
        idx=$((idx + 1))
    done
    
    echo ""
    echo "========================================="
    echo "✓ Import Complete!"
    echo "========================================="
    echo ""
    echo "Next steps:"
    echo "1. Run 'terraform plan' to see any differences"
    echo "2. Update terraform.tfvars if needed to match existing VPC config"
    echo "3. Run 'terraform apply' to sync state"
else
    echo "✗ Failed to import VPC"
    echo ""
    echo "The VPC might already be in the state, or there could be a configuration mismatch."
    exit 1
fi
