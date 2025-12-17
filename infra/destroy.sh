#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "===> Terraform destroy"
terraform destroy -auto-approve | tee destroy.log

echo "\nDestroy complete. Keep destroy.log as proof of cleanup."
