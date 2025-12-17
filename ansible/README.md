# Ansible Configuration for Inventory Manager

## Overview
This directory contains Ansible playbooks and configuration for automated server setup and application deployment.

## Directory Structure
```
ansible/
├── ansible.cfg              # Ansible configuration
├── playbook.yaml           # Main deployment playbook
├── test-connection.yaml    # Connection test playbook
├── hosts.ini               # Static inventory file
├── aws_ec2.py             # Dynamic AWS inventory script
├── templates/             
│   ├── app_config.env.j2          # Application environment template
│   └── inventory-manager.service.j2 # Systemd service template
└── README.md              # This file
```

## Prerequisites

### 1. Install Ansible
```bash
# On Ubuntu/Debian
sudo apt update
sudo apt install ansible -y

# On RHEL/CentOS
sudo yum install ansible -y

# Using pip
pip install ansible boto3
```

### 2. AWS Credentials
Ensure AWS credentials are configured:
```bash
aws configure
# Or export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
```

### 3. SSH Key
Ensure you have the SSH private key for EC2 instances:
```bash
# Place your key in ~/.ssh/
chmod 400 ~/.ssh/inventory-manager.pem
```

## Configuration Files

### Static Inventory (hosts.ini)
Edit `hosts.ini` and add your EC2 instance IP addresses:
```ini
[ec2_instances]
inventory-manager-01 ansible_host=YOUR_EC2_PUBLIC_IP ansible_user=ec2-user
```

### Dynamic Inventory (aws_ec2.py)
Automatically discovers EC2 instances tagged with `Project=inventory-manager`:
```bash
# Test dynamic inventory
./aws_ec2.py --list

# Use with ansible
ansible-playbook -i aws_ec2.py playbook.yaml
```

## Playbooks

### 1. Test Connection
Verify connectivity to EC2 instances:
```bash
cd /home/devops/Desktop/Inventory-Manager/ansible
ansible-playbook test-connection.yaml
```

### 2. Main Deployment Playbook
Deploy and configure the Inventory Manager application:
```bash
ansible-playbook playbook.yaml
```

**What it does:**
- Updates system packages
- Installs Docker, Python, Git, and dependencies
- Configures Docker service
- Installs Docker Compose
- Clones the application repository
- Installs Python requirements
- Configures application environment
- Sets up systemd service (optional)
- Configures firewall rules

### 3. Run Specific Tags
Execute only specific tasks:
```bash
# Only install packages
ansible-playbook playbook.yaml --tags packages

# Only Docker setup
ansible-playbook playbook.yaml --tags docker

# Deploy application only
ansible-playbook playbook.yaml --tags app,deploy

# Show info only
ansible-playbook playbook.yaml --tags info
```

## Usage Examples

### Check Syntax
```bash
ansible-playbook playbook.yaml --syntax-check
```

### Dry Run (Check Mode)
```bash
ansible-playbook playbook.yaml --check
```

### Run with Verbose Output
```bash
ansible-playbook playbook.yaml -v
# or -vv, -vvv, -vvvv for more verbosity
```

### Target Specific Hosts
```bash
ansible-playbook playbook.yaml --limit inventory-manager-01
```

### Use Dynamic Inventory
```bash
ansible-playbook -i aws_ec2.py playbook.yaml
```

### Override Variables
```bash
ansible-playbook playbook.yaml -e "app_env=production app_port=8080"
```

## Quick Start Guide

### Step 1: Provision Infrastructure
First, provision EC2 instances using Terraform (Step 2):
```bash
cd ../infra
terraform apply -auto-approve
```

### Step 2: Update Inventory
Get the EC2 public IP from Terraform outputs:
```bash
cd ../infra
terraform output -json | jq -r '.ec2_instance_id.value'
aws ec2 describe-instances --region us-east-1 --instance-ids INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
```

Update `hosts.ini` with the IP address.

### Step 3: Test Connection
```bash
cd ../ansible
ansible all -m ping
```

### Step 4: Run Deployment Playbook
```bash
ansible-playbook playbook.yaml
```

### Step 5: Verify Deployment
```bash
# Check Docker status
ansible all -m shell -a "docker --version"

# Check application directory
ansible all -m shell -a "ls -la /opt/inventory-manager"

# Check running containers
ansible all -m shell -a "docker ps"
```

## Variables

### Playbook Variables
Can be overridden with `-e`:
- `app_user`: Application user (default: `ec2-user`)
- `app_dir`: Application directory (default: `/opt/inventory-manager`)
- `python_version`: Python version (default: `3.11`)
- `docker_compose_version`: Docker Compose version (default: `2.24.0`)
- `app_env`: Environment (default: `development`)
- `app_port`: Application port (default: `5000`)

### Template Variables
For `app_config.env.j2`:
- `db_host`, `db_port`, `db_name`, `db_user`, `db_password`
- `redis_host`, `redis_port`
- `s3_bucket`, `aws_region`
- `log_level`, `secret_key`, `allowed_hosts`

## Troubleshooting

### Connection Issues
```bash
# Test SSH connection manually
ssh -i ~/.ssh/inventory-manager.pem ec2-user@YOUR_EC2_IP

# Check Ansible can reach hosts
ansible all -m ping -vvv
```

### Permission Denied
Ensure the SSH key has correct permissions:
```bash
chmod 400 ~/.ssh/inventory-manager.pem
```

### Python Not Found
If Python 3 is not in the default path:
```bash
ansible all -m raw -a "which python3"
# Update ansible_python_interpreter in hosts.ini
```

### Check Logs
```bash
# View Ansible log
tail -f ansible.log

# View application logs on remote server
ansible all -m shell -a "tail -f /var/log/inventory-manager/app.log"
```

## Best Practices

1. **Use Variables**: Define environment-specific variables in separate files
2. **Tag Tasks**: Use tags for selective execution
3. **Idempotency**: Ensure playbooks can be run multiple times safely
4. **Version Control**: Keep playbooks in Git
5. **Secrets Management**: Use Ansible Vault for sensitive data:
   ```bash
   ansible-vault create secrets.yml
   ansible-playbook playbook.yaml --ask-vault-pass
   ```
6. **Testing**: Always test playbooks in development before production
7. **Documentation**: Document all custom variables and configurations

## Advanced Usage

### Using Ansible Vault
Encrypt sensitive variables:
```bash
# Create encrypted file
ansible-vault create secrets.yml

# Edit encrypted file
ansible-vault edit secrets.yml

# Run playbook with vault
ansible-playbook playbook.yaml --ask-vault-pass
```

### Creating Roles
For complex deployments, organize into roles:
```bash
ansible-galaxy init roles/inventory-manager
```

### Continuous Deployment
Integrate with CI/CD:
```bash
# In CI/CD pipeline
ansible-playbook -i aws_ec2.py playbook.yaml --tags deploy
```

## Common Tasks

### Update Application
```bash
ansible-playbook playbook.yaml --tags app,deploy
```

### Restart Docker
```bash
ansible all -m systemd -a "name=docker state=restarted" --become
```

### Check System Resources
```bash
ansible all -m shell -a "df -h"
ansible all -m shell -a "free -h"
ansible all -m shell -a "docker system df"
```

## Support
For issues or questions, refer to:
- [Ansible Documentation](https://docs.ansible.com/)
- [AWS EC2 Dynamic Inventory](https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_ec2_inventory.html)
- Project repository issues
