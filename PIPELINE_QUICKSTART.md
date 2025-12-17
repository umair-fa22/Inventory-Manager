# 🚀 CI/CD Pipeline Setup - Quick Start Guide

This guide will help you set up and run the complete CI/CD pipeline for the Inventory Manager application.

---

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] GitHub account with repository access
- [ ] Docker Hub account ([Sign up free](https://hub.docker.com/signup))
- [ ] AWS account with IAM credentials ([Create free tier](https://aws.amazon.com/free/))
- [ ] GitHub repository with Actions enabled

---

## ⚡ Quick Setup (5 minutes)

### Step 1: Configure GitHub Secrets

Go to your GitHub repository settings:

```
https://github.com/YOUR_USERNAME/Inventory-Manager/settings/secrets/actions
```

Click **"New repository secret"** and add:

| Secret Name | How to Get It |
|------------|---------------|
| `DOCKER_USERNAME` | Your Docker Hub username |
| `DOCKER_PASSWORD` | Create at [Docker Hub → Account Settings → Security → New Access Token](https://hub.docker.com/settings/security) |
| `AWS_ACCESS_KEY_ID` | Create at [AWS Console → IAM → Users → Security Credentials](https://console.aws.amazon.com/iam/) |
| `AWS_SECRET_ACCESS_KEY` | Same as above (shown only once when created) |

### Step 2: Push to GitHub

```bash
# Ensure all pipeline files are committed
git add .github/workflows/main.yml CI_CD_PIPELINE.md
git commit -m "feat: add CI/CD pipeline"
git push origin main
```

### Step 3: Monitor Pipeline

1. Go to **Actions** tab in your GitHub repository
2. Click on the running workflow
3. Watch each stage complete in real-time

---

## 🔧 Automated Setup Script

Use the provided setup script for automated configuration:

```bash
# Run the setup script
./setup-pipeline.sh

# Follow the interactive prompts
```

---

## 🧪 Test Locally Before Pushing

Test the pipeline stages locally to catch issues early:

```bash
# Run local pipeline simulation
./test-pipeline-locally.sh
```

This will:
- ✅ Run all tests with coverage
- ✅ Perform security scans
- ✅ Build Docker image
- ✅ Validate Terraform configs
- ✅ Check Kubernetes manifests
- ✅ Run smoke tests

---

## 📊 Pipeline Stages Overview

```
1. Build & Test (2-3 min)
   ├─ Install Python dependencies
   ├─ Run pytest with coverage
   └─ Upload coverage reports

2. Security & Linting (1-2 min)
   ├─ Flake8 code linting
   ├─ Bandit security scan
   └─ Safety dependency check

3. Docker Build & Push (3-4 min)
   ├─ Build multi-stage image
   ├─ Push to Docker Hub
   └─ Trivy vulnerability scan

4. Terraform Provision (5-8 min)
   ├─ Initialize Terraform
   ├─ Validate configuration
   ├─ Plan infrastructure
   └─ Apply changes (main branch only)

5. Kubernetes Deploy (3-5 min)
   ├─ Update kubeconfig
   ├─ Deploy MongoDB & Redis
   ├─ Deploy application
   └─ Apply ingress rules

6. Smoke Tests (1-2 min)
   ├─ Health check endpoint
   ├─ Test GET /api/items
   ├─ Test POST /api/items
   └─ Verify deployment

Total Duration: ~15-24 minutes
```

---

## 🎯 Triggering the Pipeline

### Automatic Triggers

The pipeline runs automatically on:

1. **Push to main branch:**
   ```bash
   git push origin main
   ```

2. **Push to develop branch:**
   ```bash
   git push origin develop
   ```

3. **Pull request to main:**
   ```bash
   gh pr create --base main --head feature-branch
   ```

### Manual Trigger

Via GitHub UI:
1. Go to **Actions** tab
2. Select "CI/CD Pipeline - Inventory Manager"
3. Click **"Run workflow"**
4. Select branch and click **"Run workflow"**

Via GitHub CLI:
```bash
gh workflow run "CI/CD Pipeline - Inventory Manager"
```

---

## 📸 Getting Pipeline Screenshots

### For Documentation/Submission

1. **Navigate to Actions:**
   ```
   https://github.com/YOUR_USERNAME/Inventory-Manager/actions
   ```

2. **Click on successful workflow run**

3. **Take screenshot showing:**
   - ✅ All stages with green checkmarks
   - ✅ Total duration
   - ✅ Commit hash and message
   - ✅ Timestamp

4. **Individual stage logs:**
   - Click each stage to expand
   - Screenshot the logs showing success

### Example Screenshot Layout

```
┌─────────────────────────────────────────┐
│ CI/CD Pipeline - Inventory Manager      │
│ ✓ Workflow completed successfully       │
│                                          │
│ ✓ Build & Test            2m 34s       │
│ ✓ Security & Linting      1m 45s       │
│ ✓ Docker Build & Push     3m 12s       │
│ ✓ Terraform Provision     6m 23s       │
│ ✓ Kubernetes Deploy       4m 56s       │
│ ✓ Smoke Tests             1m 38s       │
│                                          │
│ Total: 20m 28s                          │
└─────────────────────────────────────────┘
```

---

## 🐛 Troubleshooting

### Pipeline Fails at "Build & Test"

**Error:** `ModuleNotFoundError: No module named 'flask'`

**Fix:**
```bash
# Ensure all dependencies are in requirements.txt
pip freeze > requirements.txt
git add requirements.txt
git commit -m "fix: update requirements"
git push
```

### Pipeline Fails at "Docker Build & Push"

**Error:** `denied: requested access to the resource is denied`

**Fix:**
1. Verify `DOCKER_USERNAME` is correct (case-sensitive)
2. Regenerate `DOCKER_PASSWORD` token with **Write** permissions
3. Update secrets in GitHub

### Pipeline Fails at "Terraform Provision"

**Error:** `Error: error configuring Terraform AWS Provider`

**Fix:**
1. Verify AWS credentials in GitHub secrets
2. Check IAM user has required permissions
3. Ensure AWS region is correct in workflow

### Pipeline Fails at "Kubernetes Deploy"

**Error:** `error: You must be logged in to the server`

**Fix:**
1. Verify EKS cluster is created by Terraform
2. Check cluster name matches in workflow
3. Ensure AWS credentials have EKS access

### Pipeline Fails at "Smoke Tests"

**Error:** `Health check failed`

**Fix:**
```bash
# Check pod status
kubectl get pods -n inventory-manager
kubectl logs -n inventory-manager deployment/inventory-manager --tail=50

# Check if MongoDB and Redis are running
kubectl get pods -n inventory-manager -l app=mongodb
kubectl get pods -n inventory-manager -l app=redis
```

---

## 📚 Additional Resources

### Pipeline Files

- [.github/workflows/main.yml](.github/workflows/main.yml) - Complete pipeline definition
- [CI_CD_PIPELINE.md](CI_CD_PIPELINE.md) - Detailed documentation
- [setup-pipeline.sh](setup-pipeline.sh) - Automated setup script
- [test-pipeline-locally.sh](test-pipeline-locally.sh) - Local testing

### Helper Scripts

```bash
# Setup GitHub secrets
./setup-pipeline.sh

# Test pipeline locally
./test-pipeline-locally.sh

# View pipeline status
gh run list --workflow="CI/CD Pipeline - Inventory Manager"

# View specific run logs
gh run view <run-id> --log

# Re-run failed jobs
gh run rerun <run-id> --failed
```

### Documentation

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Build & Push](https://github.com/marketplace/actions/build-and-push-docker-images)
- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [AWS EKS with kubectl](https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html)

---

## ✅ Verification Checklist

After pipeline completes successfully:

- [ ] All 6 stages show green checkmarks
- [ ] Docker image pushed to Docker Hub
- [ ] Infrastructure created in AWS
- [ ] Application deployed to Kubernetes
- [ ] Smoke tests passed
- [ ] Screenshot taken for documentation

---

## 🎓 Best Practices

### Before Pushing

1. ✅ Test locally with `./test-pipeline-locally.sh`
2. ✅ Run tests: `pytest tests/ -v`
3. ✅ Check code style: `flake8 main.py`
4. ✅ Verify Docker build: `docker build -t test .`

### During Development

1. Use feature branches
2. Create PRs for review
3. Monitor pipeline status
4. Fix failures immediately

### For Production

1. Use environment protection
2. Require manual approval
3. Enable branch protection
4. Regular security scans

---

## 💡 Tips for Success

### Speed Up Pipeline

1. **Use caching effectively** (already configured)
2. **Skip stages for feature branches:**
   ```yaml
   if: github.ref == 'refs/heads/main'
   ```
3. **Run tests in parallel**

### Reduce Costs

1. **Destroy test infrastructure:**
   ```bash
   cd infra && terraform destroy -auto-approve
   ```
2. **Use spot instances in Terraform**
3. **Set up auto-shutdown schedules**

### Improve Reliability

1. **Add retry logic to flaky tests**
2. **Increase timeout for slow operations**
3. **Monitor failure patterns**

---

## 🎉 Success!

If your pipeline completes successfully, you now have:

- ✅ Automated testing on every commit
- ✅ Security scanning integrated
- ✅ Automatic Docker image builds
- ✅ Infrastructure as Code deployment
- ✅ Kubernetes application deployment
- ✅ Post-deployment verification

---

## 📞 Support

- **Documentation:** [CI_CD_PIPELINE.md](CI_CD_PIPELINE.md)
- **GitHub Issues:** Report problems in the repository
- **Pipeline Logs:** Check Actions tab for detailed logs

---

**Last Updated:** December 17, 2025  
**Version:** 1.0  
**Status:** Production Ready ✅
