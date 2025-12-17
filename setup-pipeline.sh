#!/bin/bash

# CI/CD Pipeline Setup Script
# This script helps configure GitHub Actions secrets and verify setup

set -e

echo "=========================================="
echo "  CI/CD Pipeline Setup - Inventory Manager"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${NC}ℹ${NC} $1"
}

# Check if GitHub CLI is installed
if command -v gh &> /dev/null; then
    print_success "GitHub CLI (gh) is installed"
    GH_CLI_AVAILABLE=true
else
    print_warning "GitHub CLI (gh) is not installed"
    print_info "Install from: https://cli.github.com/"
    GH_CLI_AVAILABLE=false
fi

echo ""
echo "=========================================="
echo "  Step 1: Verify Required Tools"
echo "=========================================="
echo ""

# Check Docker
if command -v docker &> /dev/null; then
    print_success "Docker is installed: $(docker --version)"
else
    print_error "Docker is not installed"
fi

# Check kubectl
if command -v kubectl &> /dev/null; then
    print_success "kubectl is installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
    print_warning "kubectl is not installed"
fi

# Check Terraform
if command -v terraform &> /dev/null; then
    print_success "Terraform is installed: $(terraform version -json | jq -r '.terraform_version')"
else
    print_warning "Terraform is not installed"
fi

# Check AWS CLI
if command -v aws &> /dev/null; then
    print_success "AWS CLI is installed: $(aws --version)"
else
    print_warning "AWS CLI is not installed"
fi

# Check Python
if command -v python3 &> /dev/null; then
    print_success "Python is installed: $(python3 --version)"
else
    print_error "Python is not installed"
fi

echo ""
echo "=========================================="
echo "  Step 2: Configure GitHub Secrets"
echo "=========================================="
echo ""

if [ "$GH_CLI_AVAILABLE" = true ]; then
    print_info "Setting up GitHub secrets..."
    
    # Check if user is logged in
    if gh auth status &> /dev/null; then
        print_success "Authenticated with GitHub"
        
        echo ""
        read -p "Do you want to set GitHub secrets now? (y/n): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Docker Hub credentials
            echo ""
            print_info "Setting up Docker Hub credentials..."
            read -p "Enter Docker Hub username: " DOCKER_USERNAME
            read -sp "Enter Docker Hub password/token: " DOCKER_PASSWORD
            echo ""
            
            gh secret set DOCKER_USERNAME --body "$DOCKER_USERNAME"
            gh secret set DOCKER_PASSWORD --body "$DOCKER_PASSWORD"
            print_success "Docker Hub credentials set"
            
            # AWS credentials
            echo ""
            print_info "Setting up AWS credentials..."
            read -p "Enter AWS Access Key ID: " AWS_ACCESS_KEY_ID
            read -sp "Enter AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
            echo ""
            
            gh secret set AWS_ACCESS_KEY_ID --body "$AWS_ACCESS_KEY_ID"
            gh secret set AWS_SECRET_ACCESS_KEY --body "$AWS_SECRET_ACCESS_KEY"
            print_success "AWS credentials set"
            
            echo ""
            print_success "All secrets configured successfully!"
        else
            print_info "Skipping secret configuration"
            print_info "You can set secrets manually at: https://github.com/OWNER/REPO/settings/secrets/actions"
        fi
    else
        print_warning "Not authenticated with GitHub"
        print_info "Run: gh auth login"
    fi
else
    print_info "Manual setup required:"
    echo ""
    echo "1. Go to: https://github.com/YOUR_USERNAME/Inventory-Manager/settings/secrets/actions"
    echo "2. Click 'New repository secret'"
    echo "3. Add the following secrets:"
    echo ""
    echo "   - DOCKER_USERNAME: Your Docker Hub username"
    echo "   - DOCKER_PASSWORD: Your Docker Hub access token"
    echo "   - AWS_ACCESS_KEY_ID: Your AWS access key"
    echo "   - AWS_SECRET_ACCESS_KEY: Your AWS secret key"
    echo ""
fi

echo ""
echo "=========================================="
echo "  Step 3: Verify Workflow File"
echo "=========================================="
echo ""

if [ -f ".github/workflows/main.yml" ]; then
    print_success "Workflow file exists: .github/workflows/main.yml"
    
    # Count stages
    stage_count=$(grep -c "^  [a-z-]*:" .github/workflows/main.yml || echo "0")
    print_info "Pipeline has $stage_count job stages defined"
else
    print_error "Workflow file not found: .github/workflows/main.yml"
fi

echo ""
echo "=========================================="
echo "  Step 4: Test Configuration"
echo "=========================================="
echo ""

# Test Docker login
if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
    print_info "Testing Docker Hub authentication..."
    if echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin &> /dev/null; then
        print_success "Docker Hub authentication successful"
        docker logout &> /dev/null
    else
        print_error "Docker Hub authentication failed"
    fi
fi

# Test AWS credentials
if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
    print_info "Testing AWS credentials..."
    export AWS_ACCESS_KEY_ID
    export AWS_SECRET_ACCESS_KEY
    if aws sts get-caller-identity &> /dev/null; then
        print_success "AWS credentials valid"
        aws_account=$(aws sts get-caller-identity --query Account --output text)
        print_info "AWS Account: $aws_account"
    else
        print_error "AWS credentials invalid"
    fi
fi

echo ""
echo "=========================================="
echo "  Step 5: Next Steps"
echo "=========================================="
echo ""

print_info "To trigger the pipeline:"
echo ""
echo "  1. Commit and push changes:"
echo "     git add ."
echo "     git commit -m 'feat: setup CI/CD pipeline'"
echo "     git push origin main"
echo ""
echo "  2. Monitor the pipeline:"
echo "     - Go to: https://github.com/YOUR_USERNAME/Inventory-Manager/actions"
echo "     - Or run: gh run list"
echo ""
echo "  3. View pipeline documentation:"
echo "     cat CI_CD_PIPELINE.md"
echo ""

print_success "Setup verification complete!"
echo ""

# Summary
echo "=========================================="
echo "  Setup Summary"
echo "=========================================="
echo ""

if [ "$GH_CLI_AVAILABLE" = true ]; then
    echo "GitHub CLI: Available"
else
    echo "GitHub CLI: Not available (manual secret setup required)"
fi

if [ -f ".github/workflows/main.yml" ]; then
    echo "Workflow File: ✓ Present"
else
    echo "Workflow File: ✗ Missing"
fi

echo ""
echo "Required Secrets:"
echo "  - DOCKER_USERNAME"
echo "  - DOCKER_PASSWORD"
echo "  - AWS_ACCESS_KEY_ID"
echo "  - AWS_SECRET_ACCESS_KEY"
echo ""

print_info "For detailed documentation, see: CI_CD_PIPELINE.md"
echo ""
