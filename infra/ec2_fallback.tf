resource "aws_security_group" "ec2" {
  count       = var.enable_ec2 ? 1 : 0
  name        = "${local.name}-ec2-sg"
  description = "SG for EC2 fallback"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-ec2-sg" })
}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "al2023" {
  count       = var.enable_ec2 ? 1 : 0
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "fallback" {
  count                       = var.enable_ec2 ? 1 : 0
  ami                         = data.aws_ami.al2023[0].id
  instance_type               = var.ec2_instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.ec2[0].id]
  key_name                    = var.ec2_key_name != "" ? var.ec2_key_name : null
  associate_public_ip_address = true

  tags = merge(local.tags, { Name = "${local.name}-fallback" })
}
