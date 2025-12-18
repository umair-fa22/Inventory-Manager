# Terraform Resource Conflict Resolution

## Problem
When running `terraform apply` in GitHub Actions, you're seeing errors like:
- `AlreadyExistsException` for KMS Alias
- `ResourceAlreadyExistsException` for CloudWatch Log Group  
- `DBInstanceAlreadyExists` for RDS Instance

This happens when resources exist in AWS but aren't tracked in your Terraform state file.

## Solutions

### Option 1: Import Existing Resources (Recommended)

This is the safest option that preserves existing resources.

**In GitHub Actions (already configured):**
The workflow now automatically runs the import script before applying changes.

**Manually (if needed):**
```bash
cd infra
./import-existing-resources.sh
terraform plan
terraform apply
```

### Option 2: Delete and Recreate (Development Only)

⚠️ **WARNING**: This destroys data! Only use in development environments.

```bash
cd infra
./force-recreate-resources.sh
# Wait 5-10 minutes for RDS deletion
terraform apply
```

### Option 3: Manual Import Commands

If the script doesn't work, import resources manually:

```bash
cd infra

# Get your AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
CLUSTER_NAME="inventory-manager-dev-eks"

# Import KMS resources
KMS_KEY_ID=$(aws kms list-aliases --query "Aliases[?AliasName=='alias/eks/${CLUSTER_NAME}'].TargetKeyId" --output text)
terraform import "module.eks[0].module.kms.aws_kms_key.this[0]" "${KMS_KEY_ID}"
terraform import "module.eks[0].module.kms.aws_kms_alias.this[\"cluster\"]" "alias/eks/${CLUSTER_NAME}"

# Import CloudWatch Log Group
terraform import "module.eks[0].aws_cloudwatch_log_group.this[0]" "/aws/eks/${CLUSTER_NAME}/cluster"

# Import RDS Instance
terraform import "module.rds[0].module.db_instance.aws_db_instance.this[0]" "inventory-manager-dev-pg"

# Verify
terraform plan
```

## Prevention

To prevent this issue in the future:

1. **Always use Terraform for infrastructure changes**
2. **Store state remotely** (S3 backend recommended)
3. **Never manually delete resources** managed by Terraform
4. **Use workspace-specific state files** for different environments

## What Changed

1. ✅ Created [infra/import-existing-resources.sh](infra/import-existing-resources.sh) - automatically imports existing resources
2. ✅ Created [infra/force-recreate-resources.sh](infra/force-recreate-resources.sh) - nuclear option for dev environments
3. ✅ Updated [.github/workflows/main.yml](.github/workflows/main.yml) - added import step before terraform apply
4. ✅ Made scripts executable

## Next Steps

**For your current situation:**
1. Commit and push these changes
2. Re-run your GitHub Actions workflow
3. The import script will automatically handle the conflicts

**If it still fails:**
Run the manual import commands above from your local machine, then push the updated state.
