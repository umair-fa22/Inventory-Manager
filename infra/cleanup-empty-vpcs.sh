#!/bin/bash
# Quick automated cleanup of the two empty VPCs

set -e

AWS_REGION="${AWS_REGION:-us-east-1}"

echo "========================================="
echo "Automated Empty VPC Cleanup"
echo "========================================="
echo ""

# The two VPCs identified as safe to delete
EMPTY_VPCS=("vpc-0b552943669bd0e79" "vpc-09f4fd1eef6554bc0")

for vpc_id in "${EMPTY_VPCS[@]}"; do
    echo "Processing VPC: ${vpc_id}"
    echo "----------------------------------------"
    
    # Delete Internet Gateways
    echo "→ Deleting Internet Gateways..."
    IGW_IDS=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=${vpc_id}" --region ${AWS_REGION} --query 'InternetGateways[].InternetGatewayId' --output text)
    for igw_id in ${IGW_IDS}; do
        aws ec2 detach-internet-gateway --internet-gateway-id ${igw_id} --vpc-id ${vpc_id} --region ${AWS_REGION} 2>/dev/null || true
        aws ec2 delete-internet-gateway --internet-gateway-id ${igw_id} --region ${AWS_REGION} 2>/dev/null || true
        echo "  ✓ Deleted IGW ${igw_id}"
    done
    
    # Delete Subnets
    echo "→ Deleting Subnets..."
    SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${vpc_id}" --region ${AWS_REGION} --query 'Subnets[].SubnetId' --output text)
    for subnet_id in ${SUBNET_IDS}; do
        aws ec2 delete-subnet --subnet-id ${subnet_id} --region ${AWS_REGION} 2>/dev/null || true
        echo "  ✓ Deleted Subnet ${subnet_id}"
    done
    
    # Delete Route Tables (except main)
    echo "→ Deleting Route Tables..."
    ROUTE_TABLE_IDS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${vpc_id}" --region ${AWS_REGION} --query 'RouteTables[?Associations[0].Main != `true`].RouteTableId' --output text)
    for rt_id in ${ROUTE_TABLE_IDS}; do
        aws ec2 delete-route-table --route-table-id ${rt_id} --region ${AWS_REGION} 2>/dev/null || true
        echo "  ✓ Deleted Route Table ${rt_id}"
    done
    
    # Delete Security Groups (except default)
    echo "→ Deleting Security Groups..."
    SG_IDS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=${vpc_id}" --region ${AWS_REGION} --query 'SecurityGroups[?GroupName != `default`].GroupId' --output text)
    for sg_id in ${SG_IDS}; do
        aws ec2 delete-security-group --group-id ${sg_id} --region ${AWS_REGION} 2>/dev/null || true
        echo "  ✓ Deleted Security Group ${sg_id}"
    done
    
    # Delete VPC
    echo "→ Deleting VPC..."
    if aws ec2 delete-vpc --vpc-id ${vpc_id} --region ${AWS_REGION} 2>/dev/null; then
        echo "  ✓ VPC ${vpc_id} deleted successfully!"
    else
        echo "  ⚠ Could not delete VPC ${vpc_id} (may have dependencies)"
    fi
    
    echo ""
done

echo "========================================="
echo "Cleanup Complete!"
echo "========================================="
echo ""

# Check remaining VPCs
VPC_COUNT=$(aws ec2 describe-vpcs --region ${AWS_REGION} --query 'Vpcs | length' --output text)
echo "Remaining VPCs: ${VPC_COUNT}/5"

if [ "${VPC_COUNT}" -lt 5 ]; then
    echo "✓ VPC limit issue resolved! You can now create new VPCs."
else
    echo "⚠ Still at VPC limit. May need to delete more VPCs."
fi
