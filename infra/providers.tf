variable "aws_region" {
  description = "AWS region to deploy resources to"
  type        = string
  default     = "us-east-1"
}

provider "aws" {
  region = var.aws_region
  # No hardcoded credentials. Use environment variables or profiles.
  # export AWS_PROFILE=your-profile OR export AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Project     = var.project_name
      Environment = var.environment
    }
  }
}
