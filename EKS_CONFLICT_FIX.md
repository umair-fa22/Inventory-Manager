# EKS Cluster Conflict Resolution

## Problem
The Terraform pipeline is failing with the error:
```
Error: creating EKS Cluster (inventory-manager-dev-eks): operation error EKS: CreateCluster, 
https response error StatusCode: 409, RequestID: ..., 
ResourceInUseException: Cluster already exists with name: inventory-manager-dev-eks
```

This happens when an EKS cluster already exists in AWS but is not in Terraform's state file.

## Solution 1: Import Existing Cluster (RECOMMENDED)

This is the recommended approach as it preserves your existing cluster and its data.

### Quick Fix (Run Locally)
```bash
./fix-eks-conflict.sh
```

This script will:
1. Check if the cluster exists in AWS
2. Import it into Terraform state
3. Import any associated node groups

### Manual Steps
If you prefer to do it manually:

```bash
cd infra

# Initialize Terraform
terraform init

# Import the EKS cluster
terraform import 'module.eks[0].aws_eks_cluster.this[0]' inventory-manager-dev-eks

# Import node groups (if any)
# First, list the node groups
aws eks list-nodegroups --cluster-name inventory-manager-dev-eks --region us-east-1

# Then import each one (replace <node-group-name> with actual name)
terraform import 'module.eks[0].module.eks_managed_node_group["default"].aws_eks_node_group.this[0]' \
  inventory-manager-dev-eks:<node-group-name>

# Verify the state
terraform plan
```

### Automated in Pipeline
The `import-existing-resources.sh` script has been updated to automatically import:
- EKS cluster
- EKS node groups
- CloudWatch log groups
- KMS keys
- RDS instances

The next pipeline run should automatically import these resources.

## Solution 2: Use a Different Cluster Name

If you want to create a NEW cluster instead of importing the existing one:

### Option A: Manually set a custom name in terraform.tfvars
```bash
cd infra
echo 'cluster_name = "inventory-manager-dev-eks-v2"' >> terraform.tfvars
```

### Option B: Add timestamp to cluster name (in locals.tf)
Edit `infra/locals.tf`:
```terraform
locals {
  name         = "${var.project_name}-${var.environment}"
  cluster_name = var.cluster_name != "" ? var.cluster_name : "${local.name}-eks-${formatdate("YYYYMMDD", timestamp())}"
  tags = {
    ManagedBy   = "Terraform"
    Project     = var.project_name
    Environment = var.environment
  }
}
```

**Note:** This will create a new cluster, leaving the old one running. You'll need to manually delete the old cluster to avoid costs.

## Solution 3: Delete Existing Cluster

⚠️ **WARNING**: This will delete all data in the cluster!

```bash
# Delete the EKS cluster
aws eks delete-cluster --name inventory-manager-dev-eks --region us-east-1

# Wait for deletion (can take 10-15 minutes)
aws eks wait cluster-deleted --name inventory-manager-dev-eks --region us-east-1

# Then run Terraform again
cd infra
terraform apply
```

## Recommended Workflow

1. **First time:** Use Solution 1 to import the existing cluster
2. **Verify:** Run `terraform plan` to ensure everything is in sync
3. **Continue:** Push changes and the pipeline will work normally

## Pipeline Updates Made

The following files have been updated:

1. **`infra/import-existing-resources.sh`**
   - Now checks for existing EKS clusters
   - Automatically imports cluster and node groups
   - Handles both new and existing resources gracefully

2. **`fix-eks-conflict.sh`** (NEW)
   - Quick script to fix the issue locally
   - Can be run before pushing to test the fix

## Verification

After applying the fix, verify with:

```bash
cd infra
terraform state list | grep eks
```

You should see:
```
module.eks[0].aws_eks_cluster.this[0]
module.eks[0].module.eks_managed_node_group["default"].aws_eks_node_group.this[0]
```

## Next Steps

1. Run `./fix-eks-conflict.sh` to import the cluster locally
2. Commit and push the changes
3. The pipeline will now work correctly
4. Future runs will not have this issue as the cluster is now in state

## Preventing This Issue

To prevent similar issues in the future:
- Always run `import-existing-resources.sh` before `terraform apply`
- The pipeline now does this automatically
- Use consistent naming conventions
- Keep Terraform state in sync with AWS resources
