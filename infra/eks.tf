module "eks" {
  count   = var.enable_eks ? 1 : 0
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      instance_types = var.cluster_node_instance_types
      min_size       = var.cluster_min_size
      desired_size   = var.cluster_desired_size
      max_size       = var.cluster_max_size
    }
  }

  enable_cluster_creator_admin_permissions = true

  tags = local.tags
}
