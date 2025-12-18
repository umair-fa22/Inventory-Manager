# VPC Limit Exceeded Error

## Problem
```
Error: creating EC2 VPC: operation error EC2: CreateVpc, https response error StatusCode: 400, 
RequestID: e624d139-005e-4997-9647-51a71f4d043c, api error VpcLimitExceeded: 
The maximum number of VPCs has been reached.
```

Your AWS account has reached the maximum VPC limit (5 VPCs per region by default).

## Quick Fix

### Option 1: Delete Unused VPCs (Fastest)

**Check which VPCs you have:**
```bash
./infra/list-vpcs.sh
```

This will show all VPCs and mark which ones are safe to delete (no active resources).

**Delete an unused VPC:**
```bash
./cleanup-vpc.sh vpc-xxxxxxxxxxxxx
```

The script will:
- Delete all dependencies (NAT Gateways, Subnets, Route Tables, etc.)
- Release Elastic IPs
- Terminate EC2 instances (if any)
- Finally delete the VPC

### Option 2: Import Existing VPC (Reuse Infrastructure)

If you want to reuse an existing VPC instead of creating a new one:

```bash
cd infra
./import-vpc.sh vpc-xxxxxxxxxxxxx
```

This imports the VPC into Terraform state so it won't try to create a new one.

### Option 3: Request VPC Limit Increase

Request a limit increase from AWS:
1. Go to [Service Quotas Console](https://console.aws.amazon.com/servicequotas/home/services/vpc/quotas)
2. Search for "VPCs per Region"
3. Request an increase (typically approved within minutes)

## Prevention

The GitHub Actions workflow now checks VPC limits before terraform apply and will fail early with helpful instructions.

## What Changed

1. ✅ Created [infra/list-vpcs.sh](infra/list-vpcs.sh) - Lists all VPCs and shows which are safe to delete
2. ✅ Updated [cleanup-vpc.sh](cleanup-vpc.sh) - Already exists, deletes VPC and dependencies
3. ✅ Created [infra/import-vpc.sh](infra/import-vpc.sh) - Import existing VPC to reuse it
4. ✅ Updated [.github/workflows/main.yml](.github/workflows/main.yml) - Added VPC limit check

## Recommended Action

**For your situation right now:**

1. List your VPCs to see what you have:
   ```bash
   ./infra/list-vpcs.sh
   ```

2. Either delete unused VPCs or import an existing one:
   ```bash
   # Delete unused VPC
   ./cleanup-vpc.sh vpc-xxxxxxxxxxxxx
   
   # OR import existing VPC
   cd infra && ./import-vpc.sh vpc-xxxxxxxxxxxxx
   ```

3. Commit the state changes and re-run the pipeline:
   ```bash
   git add infra/terraform.tfstate*
   git commit -m "fix: Resolve VPC limit by cleaning up unused resources"
   git push
   ```

## Architecture Decision

Consider whether you really need a new VPC for each environment or if you should:
- **Reuse a single VPC** with different subnets per environment
- **Delete old development VPCs** when not in use
- **Use VPC data source** in Terraform to reference existing VPCs
