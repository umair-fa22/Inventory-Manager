#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "===> Terraform init"
terraform init

echo "===> Terraform fmt/validate"
terraform fmt -recursive
terraform validate

echo "===> Terraform plan"
terraform plan -out plan.out

echo "===> Terraform apply"
terraform apply -auto-approve plan.out

echo "===> Terraform outputs"
terraform output | tee outputs.txt
terraform output -json > outputs.json

echo "\nDone. Save outputs.txt and take AWS Console screenshot of resources."
