# Infrastructure as Code (Terraform) - AWS

This directory provisions AWS infrastructure for the Inventory Manager:

- VPC with public/private subnets and NAT
- EKS (Kubernetes) cluster with managed node group (optional EC2 fallback)
- RDS PostgreSQL (or optional S3 bucket for persistence)
- Security groups and outputs

No secrets are hardcoded. Provide AWS credentials via environment or profile; provide DB password via `TF_VAR_db_password`.

## Prerequisites

- Terraform >= 1.5
- AWS account + credentials (`AWS_PROFILE` or `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`)
- kubectl + AWS CLI (if using EKS)

## Quick Start

```bash
# 1) Go to infra folder
cd infra

# 2) Copy example vars
cp terraform.tfvars.example terraform.tfvars

# 3) Set strong DB password securely (recommended)
export TF_VAR_db_password=$(openssl rand -base64 32)

# 4) Initialize and validate
terraform init
terraform fmt -recursive
terraform validate

# 5) Plan & Apply
terraform plan -out plan.out
terraform apply -auto-approve plan.out

# 6) Show outputs
terraform output
terraform output -json > outputs.json
```

## Configure AWS Credentials

Use one of the following (do not hardcode):

```bash
# Option A: AWS profile
export AWS_PROFILE=myprofile

# Option B: Access keys (not recommended for dev machines)
export AWS_ACCESS_KEY_ID=AKIA...
export AWS_SECRET_ACCESS_KEY=...
export AWS_REGION=us-east-1
```

## Flags (Feature Toggles)

- `enable_eks` (default: true): Provision EKS cluster
- `enable_ec2` (default: false): Provision a single EC2 instance as fallback
- `enable_rds` (default: true): Provision PostgreSQL database
- `enable_s3` (default: false): Provision S3 bucket

## After Provisioning

If EKS is enabled, configure kubeconfig:

```bash
aws eks update-kubeconfig --name $(terraform output -raw eks_cluster_name) \
  --region $(terraform output -raw aws_region 2>/dev/null || echo "set-in-tfvars")
```

Then verify cluster nodes:

```bash
kubectl get nodes
```

To connect to RDS from your app, use:

```bash
# Example connection string
psql "host=$(terraform output -raw rds_endpoint) port=$(terraform output -raw rds_port) dbname=$(terraform output -raw vpc_id) user=appuser"
```

Note: Security group for RDS allows access from within the VPC. For stricter access, bind to EKS node SG or app SG.

## Clean Up (Destroy)

```bash
terraform destroy -auto-approve
```

Save the destroy output to `destroy.log` as proof of cleanup if required:

```bash
terraform destroy -auto-approve | tee destroy.log
```

## Deliverables Checklist

- [x] `infra/` folder with Terraform code
- [ ] `outputs.txt` or `outputs.json`: Run `terraform output` after apply and save
- [ ] AWS Console screenshot showing resources (VPC/EKS/RDS/S3)
- [ ] `destroy.log`: Run destroy and keep log as proof

## Notes

- Subnets are tagged for Kubernetes load balancer compatibility
- No hardcoded secrets; pass DB password via `TF_VAR_db_password`
- All resources are tagged with `Project` and `Environment`
