#!/bin/bash

# AWS VPC Cleanup Script
# Deletes unused VPCs to free up space

set -e

# Set AWS region
export AWS_REGION=${AWS_REGION:-us-east-1}
export AWS_DEFAULT_REGION=$AWS_REGION

echo "==========================================="
echo "  AWS VPC Cleanup"
echo "==========================================="
echo ""
echo "Using AWS Region: $AWS_REGION"
echo ""

# Check current VPC count
echo "Checking current VPCs..."
vpc_count=$(aws ec2 describe-vpcs --region $AWS_REGION --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output text | wc -l)
echo "Current VPC count: $vpc_count"
echo ""

if [ "$vpc_count" -ge 5 ]; then
    echo "⚠️  WARNING: VPC limit reached or near limit (max 5)"
    echo ""
fi

# List all VPCs
echo "Available VPCs:"
echo "----------------------------------------"
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0],IsDefault,CidrBlock]' --output table

echo ""
echo "==========================================="
echo "Cleanup Options"
echo "==========================================="
echo ""

echo "1. Delete specific VPC by ID"
echo "2. Delete all non-default VPCs (DANGEROUS!)"
echo "3. Show VPC details"
echo "4. Exit"
echo ""

read -p "Choose option (1-4): " choice

case $choice in
    1)
        read -p "Enter VPC ID to delete: " vpc_id
        echo ""
        echo "⚠️  This will delete VPC: $vpc_id"
        read -p "Are you sure? (yes/no): " confirm
        
        if [ "$confirm" = "yes" ]; then
            echo "Deleting VPC $vpc_id..."
            
            # Delete dependent resources first
            echo "1. Deleting subnets..."
            for subnet in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[*].SubnetId' --output text); do
                echo "  Deleting subnet: $subnet"
                aws ec2 delete-subnet --subnet-id $subnet 2>/dev/null || true
            done
            
            echo "2. Deleting internet gateways..."
            for igw in $(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc_id" --query 'InternetGateways[*].InternetGatewayId' --output text); do
                echo "  Detaching IGW: $igw"
                aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc_id 2>/dev/null || true
                echo "  Deleting IGW: $igw"
                aws ec2 delete-internet-gateway --internet-gateway-id $igw 2>/dev/null || true
            done
            
            echo "3. Deleting NAT gateways..."
            for nat in $(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$vpc_id" --query 'NatGateways[*].NatGatewayId' --output text); do
                echo "  Deleting NAT gateway: $nat"
                aws ec2 delete-nat-gateway --nat-gateway-id $nat 2>/dev/null || true
            done
            
            echo "4. Waiting for NAT gateways to delete (60s)..."
            sleep 60
            
            echo "5. Releasing Elastic IPs..."
            for eip in $(aws ec2 describe-addresses --filters "Name=domain,Values=vpc" --query 'Addresses[*].AllocationId' --output text); do
                echo "  Releasing EIP: $eip"
                aws ec2 release-address --allocation-id $eip 2>/dev/null || true
            done
            
            echo "6. Deleting security groups..."
            for sg in $(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc_id" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text); do
                echo "  Deleting security group: $sg"
                aws ec2 delete-security-group --group-id $sg 2>/dev/null || true
            done
            
            echo "7. Deleting route tables..."
            for rt in $(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc_id" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text); do
                echo "  Deleting route table: $rt"
                aws ec2 delete-route-table --route-table-id $rt 2>/dev/null || true
            done
            
            echo "8. Finally, deleting VPC..."
            aws ec2 delete-vpc --vpc-id $vpc_id
            
            echo "✓ VPC deleted successfully!"
        else
            echo "Cancelled"
        fi
        ;;
        
    2)
        echo "⚠️  DANGER: This will delete ALL non-default VPCs!"
        read -p "Type 'DELETE ALL' to confirm: " confirm
        
        if [ "$confirm" = "DELETE ALL" ]; then
            for vpc_id in $(aws ec2 describe-vpcs --query 'Vpcs[?IsDefault==`false`].VpcId' --output text); do
                echo ""
                echo "Deleting VPC: $vpc_id"
                # Use the same deletion logic as option 1
                echo "Skipping automatic deletion. Use option 1 for each VPC."
            done
        else
            echo "Cancelled"
        fi
        ;;
        
    3)
        read -p "Enter VPC ID: " vpc_id
        echo ""
        echo "VPC Details for: $vpc_id"
        echo "----------------------------------------"
        aws ec2 describe-vpcs --vpc-ids $vpc_id --output table
        echo ""
        echo "Subnets:"
        aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone]' --output table
        echo ""
        echo "Internet Gateways:"
        aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc_id" --output table
        echo ""
        echo "NAT Gateways:"
        aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$vpc_id" --output table
        ;;
        
    4)
        echo "Exiting..."
        exit 0
        ;;
        
    *)
        echo "Invalid option"
        ;;
esac

echo ""
echo "Done!"
