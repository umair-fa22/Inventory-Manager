# Feature toggles
variable "enable_eks" {
  type    = bool
  default = true
}

variable "enable_ec2" {
  type    = bool
  default = false
}

variable "enable_rds" {
  type    = bool
  default = true
}

variable "enable_s3" {
  type    = bool
  default = false
}

# Networking
variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR for VPC"
}

# Kubernetes / EKS
variable "cluster_name" {
  type    = string
  default = ""
}

variable "cluster_version" {
  type    = string
  default = "1.29"
}

variable "cluster_node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "cluster_min_size" {
  type    = number
  default = 2
}

variable "cluster_desired_size" {
  type    = number
  default = 2
}

variable "cluster_max_size" {
  type    = number
  default = 4
}

# EC2 fallback
variable "ec2_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ec2_key_name" {
  type        = string
  default     = ""
  description = "Optional EC2 key pair name for SSH"
}

variable "allowed_ssh_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

# RDS PostgreSQL
variable "db_name" {
  type    = string
  default = "inventory_db"
}

variable "db_username" {
  type    = string
  default = "appuser"
}

variable "db_password" {
  type      = string
  default   = null
  sensitive = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

# S3
variable "s3_enable_versioning" {
  type    = bool
  default = true
}
