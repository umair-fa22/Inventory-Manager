resource "aws_security_group" "rds" {
  count       = var.enable_rds ? 1 : 0
  name        = "${local.name}-rds-sg"
  description = "RDS PostgreSQL SG"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-rds-sg" })
}

module "rds" {
  count   = var.enable_rds ? 1 : 0
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.4"

  identifier = "${local.name}-pg"

  engine                = "postgres"
  engine_version        = "15.4"
  family                = "postgres15"
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = 100

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  port                = 5432
  multi_az            = false
  publicly_accessible = false
  storage_encrypted   = true
  deletion_protection = false
  skip_final_snapshot = true

  create_db_subnet_group = true
  subnet_ids             = module.vpc.private_subnets

  vpc_security_group_ids = [aws_security_group.rds[0].id]

  tags = local.tags
}
