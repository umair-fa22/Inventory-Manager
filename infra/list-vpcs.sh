#!/bin/bash
# List and cleanup unused VPCs in AWS

set -e

AWS_REGION="${AWS_REGION:-us-east-1}"

echo "========================================="
echo "AWS VPC Cleanup Tool"
echo "========================================="
echo "Region: ${AWS_REGION}"
echo ""

# List all VPCs
echo "Listing all VPCs in ${AWS_REGION}..."
echo ""

VPC_LIST=$(aws ec2 describe-vpcs --region ${AWS_REGION} --output json)

echo "Found VPCs:"
echo "----------------------------------------"
echo "${VPC_LIST}" | jq -r '.Vpcs[] | "VPC ID: \(.VpcId) | CIDR: \(.CidrBlock) | Name: \(.Tags[]? | select(.Key=="Name") | .Value // "N/A") | Default: \(.IsDefault)"'
echo ""

VPC_COUNT=$(echo "${VPC_LIST}" | jq '.Vpcs | length')
echo "Total VPCs: ${VPC_COUNT}/5 (AWS default limit)"
echo ""

# Check if we're at the limit
if [ "${VPC_COUNT}" -ge 5 ]; then
    echo "⚠️  WARNING: VPC limit reached!"
    echo ""
fi

# Identify VPCs with no instances
echo "Checking for empty VPCs (safe to delete)..."
echo "----------------------------------------"

for vpc_id in $(echo "${VPC_LIST}" | jq -r '.Vpcs[] | select(.IsDefault == false) | .VpcId'); do
    vpc_name=$(aws ec2 describe-vpcs --vpc-ids ${vpc_id} --region ${AWS_REGION} --query 'Vpcs[0].Tags[?Key==`Name`].Value' --output text 2>/dev/null || echo "N/A")
    
    # Count resources in this VPC
    instances=$(aws ec2 describe-instances --filters "Name=vpc-id,Values=${vpc_id}" --region ${AWS_REGION} --query 'Reservations[].Instances[]' --output json | jq 'length')
    nat_gws=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=${vpc_id}" --region ${AWS_REGION} --query 'NatGateways[?State!=`deleted`]' --output json | jq 'length')
    lb=$(aws elbv2 describe-load-balancers --region ${AWS_REGION} --output json 2>/dev/null | jq --arg vpc "${vpc_id}" '[.LoadBalancers[] | select(.VpcId == $vpc)] | length')
    
    echo ""
    echo "VPC: ${vpc_id} (${vpc_name})"
    echo "  EC2 Instances: ${instances}"
    echo "  NAT Gateways: ${nat_gws}"
    echo "  Load Balancers: ${lb}"
    
    if [ "${instances}" = "0" ] && [ "${nat_gws}" = "0" ] && [ "${lb}" = "0" ]; then
        echo "  Status: ✓ Safe to delete (no active resources)"
    else
        echo "  Status: ⚠ Has active resources"
    fi
done

echo ""
echo "========================================="
echo "Options:"
echo "========================================="
echo ""
echo "1. Delete unused VPCs manually:"
echo "   ./cleanup-vpc.sh <vpc-id>"
echo ""
echo "2. Import existing VPC into Terraform:"
echo "   cd infra && terraform import 'module.vpc.aws_vpc.this[0]' <vpc-id>"
echo ""
echo "3. Request VPC limit increase:"
echo "   https://console.aws.amazon.com/servicequotas/home/services/vpc/quotas"
echo ""
echo "4. Use existing VPC by setting data source in Terraform"
echo ""
