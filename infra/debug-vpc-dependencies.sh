#!/bin/bash
# Debug VPC dependencies

VPC_ID="$1"
AWS_REGION="${AWS_REGION:-us-east-1}"

if [ -z "${VPC_ID}" ]; then
    echo "Usage: $0 <vpc-id>"
    exit 1
fi

echo "Checking all dependencies for VPC: ${VPC_ID}"
echo "========================================="

echo ""
echo "Network Interfaces:"
aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=${VPC_ID}" --region ${AWS_REGION} --query 'NetworkInterfaces[*].[NetworkInterfaceId,Status,Description]' --output table

echo ""
echo "NAT Gateways:"
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=${VPC_ID}" --region ${AWS_REGION} --query 'NatGateways[*].[NatGatewayId,State]' --output table

echo ""
echo "VPC Endpoints:"
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=${VPC_ID}" --region ${AWS_REGION} --query 'VpcEndpoints[*].[VpcEndpointId,State,ServiceName]' --output table

echo ""
echo "VPC Peering Connections:"
aws ec2 describe-vpc-peering-connections --filters "Name=requester-vpc-info.vpc-id,Values=${VPC_ID}" --region ${AWS_REGION} --query 'VpcPeeringConnections[*].[VpcPeeringConnectionId,Status.Code]' --output table

echo ""
echo "Subnets:"
aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --region ${AWS_REGION} --query 'Subnets[*].[SubnetId,CidrBlock]' --output table

echo ""
echo "Route Tables:"
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${VPC_ID}" --region ${AWS_REGION} --query 'RouteTables[*].[RouteTableId,Associations[0].Main]' --output table

echo ""
echo "Security Groups:"
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=${VPC_ID}" --region ${AWS_REGION} --query 'SecurityGroups[*].[GroupId,GroupName]' --output table

echo ""
echo "Internet Gateways:"
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=${VPC_ID}" --region ${AWS_REGION} --query 'InternetGateways[*].[InternetGatewayId,Attachments[0].State]' --output table
