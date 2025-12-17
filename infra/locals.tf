variable "project_name" {
  type    = string
  default = "inventory-manager"
}

variable "environment" {
  type    = string
  default = "dev"
}

locals {
  name         = "${var.project_name}-${var.environment}"
  cluster_name = var.cluster_name != "" ? var.cluster_name : "${local.name}-eks"
  tags = {
    ManagedBy   = "Terraform"
    Project     = var.project_name
    Environment = var.environment
  }
}
