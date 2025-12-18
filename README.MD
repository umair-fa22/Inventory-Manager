# Inventory Manager

A full-stack inventory management system with CRUD operations, MongoDB integration, and a modern web interface. Built with Python Flask.

## Features

- ✓ Add, view, update, and delete inventory items
- ✓ Real-time total value calculation
- ✓ Inline editing with live price updates
- ✓ RESTful API endpoints
- ✓ MongoDB backend with validation
- ✓ Responsive web UI
- ✓ Comprehensive test suite with pytest

## Quick Start

### Prerequisites

- Python 3.7+
- MongoDB (running locally or remote)
- pip

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/ud3v/Inventory-Manager.git
   cd Inventory-Manager
   ```

2. **Configure environment**
   
   Create a `.env` file in the root directory:
   ```env
   MONGODB_URI=mongodb://localhost:27017
   PORT=3000
   DATABASE=inventorydb
   COLLECTION=products
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run the application**
   ```bash
   python main.py
   ```

5. **Access the application**
   
   Open your browser: http://localhost:3000

## Project Structure

```
Inventory-Manager/
├── main.py              # Flask server
├── mongomgr.py          # MongoDB utility manager
├── requirements.txt     # Python dependencies
├── pyproject.toml       # Python project config
├── pytest.ini           # Pytest configuration
├── .env                 # Environment variables
├── static/
│   ├── index.html       # Frontend UI
│   └── style.css        # Styling
└── tests/
    ├── __init__.py
    ├── conftest.py      # Test fixtures
    └── test_main.py     # Test suite
```

## API Endpoints

| Method | Endpoint | Description | Body |
|--------|----------|-------------|------|
| GET | `/api/items` | Get all items | - |
| GET | `/api/items/:id` | Get item by ID | - |
| POST | `/api/items` | Create new item | `{name, unitPrice, quantity}` |
| PUT | `/api/items/:id` | Update item | `{name, unitPrice, quantity}` |
| DELETE | `/api/items/:id` | Delete item | - |

### Example Request

```bash
curl -X POST http://localhost:3000/api/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","unitPrice":899.99,"quantity":10}'
```

## MongoDB Manager

The `mongomgr.py` utility provides person/user management with duplicate validation:

```python
from mongomgr import MongoDBManager

manager = MongoDBManager()
if manager.connect():
    # Add person (validates email uniqueness)
    manager.add_person("John Doe", "john@example.com", age=30)
    
    # Check if exists
    if manager.person_exists("john@example.com"):
        print("Person found!")
    
    # Get person details
    person = manager.get_person("john@example.com")
    
    manager.close()
```

## Testing

Run the test suite with pytest:

```bash
# Run all tests
pytest

# Run with verbose output
pytest -v

# Run with coverage report
pytest --cov=. --cov-report=html

# View coverage report
open htmlcov/index.html
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MONGODB_URI` | *required* | MongoDB connection string |
| `PORT` | `3000` | Server port |
| `DATABASE` | `inventorydb` | Database name |
| `COLLECTION` | `products` | Collection name |

## Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run with auto-reload (debug mode)
python main.py

# Run tests
pytest -v

# Run tests with coverage
pytest --cov=. --cov-report=html
```

## Troubleshooting

**Connection Error**
- Verify MongoDB is running: `mongosh` or `mongo`
- Check `MONGODB_URI` in `.env` file
- Ensure network connectivity to MongoDB server

**Import Errors (Python)**
- Install dependencies: `pip install -r requirements.txt`
- Check Python version: `python --version` (requires 3.7+)

**Empty Items List**
- Check API endpoint: `curl http://localhost:3000/api/items`
- Verify MongoDB has data in the collection
- Check browser console for errors

**Port Already in Use**
- Change `PORT` in `.env` file
- Kill existing process: `lsof -ti:3000 | xargs kill`

## Deployment Options

### Option 1: Run Locally

**Prerequisites:**
- Python 3.7+
- MongoDB running locally or remotely
- Redis (optional, for caching)

**Steps:**

1. **Set up environment variables**
   ```bash
   # Create .env file
   cat > .env << 'EOF'
   MONGODB_URI=mongodb://localhost:27017
   PORT=3000
   DATABASE=inventorydb
   COLLECTION=products
   REDIS_HOST=localhost
   REDIS_PORT=6379
   REDIS_PASSWORD=
   CACHE_TTL=300
   EOF
   ```

2. **Install dependencies**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. **Start MongoDB** (if not running)
   ```bash
   # Using Docker
   docker run -d -p 27017:27017 --name mongodb mongo:7.0
   
   # Or install locally from https://www.mongodb.com/
   ```

4. **Start Redis** (optional)
   ```bash
   docker run -d -p 6379:6379 --name redis redis:7-alpine
   ```

5. **Run the application**
   ```bash
   python main.py
   ```

6. **Access the application**
   - Web UI: http://localhost:3000
   - API: http://localhost:3000/api/items
   - Metrics: http://localhost:3000/metrics

### Option 2: Run with Docker Compose

**Prerequisites:**
- Docker 20.10+
- Docker Compose 2.0+

**Steps:**

1. **Create environment file**
   ```bash
   cat > .env << 'EOF'
   # MongoDB Configuration
   MONGO_USERNAME=admin
   MONGO_PASSWORD=secure_password_123
   MONGO_PORT=27017
   
   # Redis Configuration
   REDIS_PASSWORD=redis_password_123
   REDIS_PORT=6379
   
   # Application Configuration
   APP_PORT=3000
   DATABASE=inventory_db
   COLLECTION=items
   CACHE_TTL=300
   EOF
   ```

2. **Start all services**
   ```bash
   # Build and start
   docker-compose up -d
   
   # View logs
   docker-compose logs -f
   
   # Check status
   docker-compose ps
   ```

3. **Access services**
   - Application: http://localhost:3000
   - MongoDB: localhost:27017
   - Redis: localhost:6379

4. **Stop services**
   ```bash
   # Stop containers
   docker-compose stop
   
   # Stop and remove containers
   docker-compose down
   
   # Stop and remove containers + volumes (⚠️ deletes data)
   docker-compose down -v
   ```

**Useful Commands:**
```bash
# Rebuild after code changes
docker-compose up -d --build

# View specific service logs
docker-compose logs -f inventory-manager

# Execute command in container
docker-compose exec inventory-manager sh

# Scale services (if needed)
docker-compose up -d --scale inventory-manager=3
```

### Option 3: Run on Kubernetes

**Prerequisites:**
- Kubernetes cluster (minikube, EKS, GKE, AKS, etc.)
- kubectl configured
- Docker registry access (optional for custom images)

**Steps:**

1. **Navigate to k8s directory**
   ```bash
   cd k8s
   ```

2. **Create namespace**
   ```bash
   kubectl apply -f namespace.yaml
   ```

3. **Configure secrets**
   ```bash
   # Create secrets for sensitive data
   kubectl create secret generic mongodb-credentials \
     --from-literal=username=admin \
     --from-literal=password=secure_password_123 \
     -n inventory-manager
   
   kubectl create secret generic redis-credentials \
     --from-literal=password=redis_password_123 \
     -n inventory-manager
   ```

4. **Deploy infrastructure**
   ```bash
   # Deploy persistent volumes
   kubectl apply -f persistent-volumes.yaml
   
   # Deploy MongoDB
   kubectl apply -f mongodb-deployment.yaml
   
   # Deploy Redis
   kubectl apply -f redis-deployment.yaml
   
   # Wait for databases to be ready
   kubectl wait --for=condition=ready pod -l app=mongodb -n inventory-manager --timeout=300s
   kubectl wait --for=condition=ready pod -l app=redis -n inventory-manager --timeout=300s
   ```

5. **Deploy application**
   ```bash
   # Apply ConfigMap
   kubectl apply -f configmap.yaml
   
   # Deploy application
   kubectl apply -f app-deployment.yaml
   
   # Wait for app to be ready
   kubectl wait --for=condition=ready pod -l app=inventory-manager -n inventory-manager --timeout=300s
   ```

6. **Deploy monitoring (optional)**
   ```bash
   kubectl apply -f prometheus-deployment.yaml
   kubectl apply -f grafana-deployment.yaml
   ```

7. **Apply network policies (optional)**
   ```bash
   kubectl apply -f network-policies.yaml
   ```

8. **Access the application**
   ```bash
   # Port forward to access locally
   kubectl port-forward -n inventory-manager svc/inventory-manager 3000:3000
   
   # Or get LoadBalancer/NodePort external IP
   kubectl get svc -n inventory-manager
   ```

9. **Automated deployment script**
   ```bash
   # Use the deploy script for automated setup
   chmod +x deploy.sh
   ./deploy.sh
   ```

**Useful Kubernetes Commands:**
```bash
# View all resources
kubectl get all -n inventory-manager

# View logs
kubectl logs -f deployment/inventory-manager -n inventory-manager

# Describe pod for troubleshooting
kubectl describe pod <pod-name> -n inventory-manager

# Execute command in pod
kubectl exec -it <pod-name> -n inventory-manager -- sh

# Scale deployment
kubectl scale deployment/inventory-manager --replicas=5 -n inventory-manager

# View events
kubectl get events -n inventory-manager --sort-by='.lastTimestamp'

# Delete all resources
kubectl delete namespace inventory-manager
```

## Infrastructure Setup (AWS with Terraform)

**Prerequisites:**
- Terraform >= 1.5
- AWS account with credentials configured
- AWS CLI installed
- kubectl for EKS access

**Setup Steps:**

1. **Navigate to infrastructure directory**
   ```bash
   cd infra
   ```

2. **Configure Terraform variables**
   ```bash
   # Copy example file
   cp terraform.tfvars.example terraform.tfvars
   
   # Edit terraform.tfvars with your values
   nano terraform.tfvars
   ```

3. **Set AWS credentials**
   ```bash
   # Option 1: Use AWS profile
   export AWS_PROFILE=your-profile
   
   # Option 2: Use access keys
   export AWS_ACCESS_KEY_ID=your-access-key
   export AWS_SECRET_ACCESS_KEY=your-secret-key
   export AWS_REGION=us-east-1
   ```

4. **Set database password securely**
   ```bash
   # Generate strong password
   export TF_VAR_db_password=$(openssl rand -base64 32)
   
   # Save it securely for later use
   echo $TF_VAR_db_password > db_password.txt
   chmod 600 db_password.txt
   ```

5. **Initialize Terraform**
   ```bash
   terraform init
   terraform fmt -recursive
   terraform validate
   ```

6. **Plan infrastructure changes**
   ```bash
   # Review what will be created
   terraform plan -out=plan.out
   ```

7. **Apply infrastructure**
   ```bash
   # Create resources
   terraform apply plan.out
   
   # Or apply with auto-approve (use carefully)
   terraform apply -auto-approve
   ```

8. **View outputs**
   ```bash
   # Display all outputs
   terraform output
   
   # Export outputs to JSON
   terraform output -json > outputs.json
   
   # Get specific output
   terraform output eks_cluster_endpoint
   ```

9. **Configure kubectl for EKS**
   ```bash
   # Update kubeconfig
   aws eks update-kubeconfig \
     --region us-east-1 \
     --name $(terraform output -raw eks_cluster_name)
   
   # Verify connection
   kubectl get nodes
   ```

**Infrastructure Components Created:**
- VPC with public and private subnets
- NAT Gateway for private subnet internet access
- EKS Cluster with managed node group
- RDS PostgreSQL database (optional)
- Security groups with least privilege
- IAM roles and policies
- S3 bucket (optional)

## Infrastructure Teardown

**⚠️ Warning:** This will destroy all resources and data. Ensure you have backups!

**Steps:**

1. **Delete Kubernetes resources first** (if deployed)
   ```bash
   # Delete application namespace
   kubectl delete namespace inventory-manager
   
   # Or delete specific deployments
   kubectl delete -f k8s/ --all
   ```

2. **Destroy AWS infrastructure**
   ```bash
   cd infra
   
   # Plan destroy (review what will be deleted)
   terraform plan -destroy
   
   # Destroy resources
   terraform destroy
   
   # Or with auto-approve
   terraform destroy -auto-approve
   ```

3. **Handle stuck resources** (if needed)
   ```bash
   # Use cleanup scripts
   ./cleanup-terraform.sh
   ./cleanup-orphaned-resources.sh
   
   # Or manually delete via AWS Console
   ```

4. **Verify cleanup**
   ```bash
   # Check for remaining resources
   terraform state list
   
   # Remove state files if empty
   rm -f terraform.tfstate*
   rm -f plan.out
   ```

5. **Clean local artifacts**
   ```bash
   # Remove Terraform cache
   rm -rf .terraform/
   rm -f .terraform.lock.hcl
   
   # Remove kubectl context
   kubectl config delete-context <context-name>
   ```

**Troubleshooting Teardown:**
```bash
# If resources fail to delete, check dependencies
terraform state list

# Remove specific resource from state (use carefully)
terraform state rm <resource>

# Force unlock if state is locked
terraform force-unlock <lock-id>

# Clean up VPCs manually
./cleanup-vpc.sh

# List and clean orphaned resources
./cleanup-orphaned-resources.sh
```

## Monitoring and Observability

**Access Prometheus:**
```bash
# Port forward Prometheus
kubectl port-forward -n inventory-manager svc/prometheus 9090:9090

# Open in browser
open http://localhost:9090
```

**Access Grafana:**
```bash
# Port forward Grafana
kubectl port-forward -n inventory-manager svc/grafana 3001:3000

# Open in browser
open http://localhost:3001

# Default credentials: admin/admin
```

**View Application Metrics:**
```bash
# Direct access to app metrics endpoint
curl http://localhost:3000/metrics

# Sample queries in Prometheus:
# - inventory_requests_total
# - inventory_request_duration_seconds
# - inventory_active_connections
# - inventory_items_total
```

## CI/CD Pipeline

This project includes a Jenkins pipeline (`Jenkinsfile`) that automates:

1. **Build & Test** - Run pytest with coverage
2. **Security & Linting** - Code quality checks
3. **Docker Build** - Multi-stage optimized image
4. **Push to Registry** - Docker Hub or AWS ECR
5. **Deploy to Kubernetes** - Automated K8s deployment
6. **Integration Tests** - Post-deployment validation
7. **Monitoring Setup** - Deploy Prometheus/Grafana

**Run Pipeline Locally:**
```bash
# Test pipeline stages locally
./test-pipeline-locally.sh

# Or set up Jenkins
./setup-pipeline.sh
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit changes: `git commit -am 'Add feature'`
4. Push to branch: `git push origin feature-name`
5. Submit a pull request

## License

This project is open source and available under the MIT License.
