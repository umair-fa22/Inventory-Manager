output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = try(module.eks[0].cluster_name, null)
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = try(module.eks[0].cluster_endpoint, null)
}

output "eks_oidc_issuer_url" {
  description = "EKS OIDC issuer URL"
  value       = try(module.eks[0].cluster_oidc_issuer_url, null)
}

output "eks_update_kubeconfig_cmd" {
  description = "Helper command to set kubeconfig"
  value       = try("aws eks update-kubeconfig --name ${module.eks[0].cluster_name} --region ${var.aws_region}", null)
}

output "ec2_instance_id" {
  description = "EC2 fallback instance ID"
  value       = try(aws_instance.fallback[0].id, null)
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = try(module.rds[0].db_instance_endpoint, null)
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = try(module.rds[0].db_instance_port, null)
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = try(aws_s3_bucket.data[0].id, null)
}
