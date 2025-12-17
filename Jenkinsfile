pipeline {
    agent any
    
    environment {
        // Docker configuration
        DOCKER_IMAGE = "inventory-manager"
        DOCKER_REGISTRY = credentials('DOCKERUSER')
        DOCKER_CREDENTIALS = credentials('docker-hub-credentials')
        
        // AWS configuration
        AWS_REGION = 'us-east-1'
        AWS_CREDENTIALS = credentials('aws-credentials')
        
        // Python version
        PYTHON_VERSION = '3.13'
        
        // Build info
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
        BUILD_TIMESTAMP = sh(script: "date +%Y%m%d-%H%M%S", returnStdout: true).trim()
    }
    
    stages {
        // ====================================================================
        // Stage 1: Build & Test
        // ====================================================================
        stage('Build & Test') {
            steps {
                echo '========================================='
                echo 'Stage 1: Build & Test'
                echo '========================================='
                
                script {
                    // Set up Python virtual environment
                    sh '''
                        python3 -m venv venv
                        . venv/bin/activate
                        python --version
                        pip install --upgrade pip
                    '''
                    
                    // Install dependencies
                    sh '''
                        . venv/bin/activate
                        pip install -r requirements.txt
                    '''
                    
                    // Run tests with coverage
                    sh '''
                        . venv/bin/activate
                        pytest tests/ -v --cov=. --cov-report=xml --cov-report=html --cov-report=term
                    '''
                    
                    // Archive coverage reports
                    publishHTML([
                        reportDir: 'htmlcov',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report',
                        keepAll: true
                    ])
                    
                    // Archive test results
                    junit 'pytest-results.xml'
                }
            }
            post {
                success {
                    echo '✓ Build & Test stage completed successfully'
                }
                failure {
                    echo '✗ Build & Test stage failed'
                }
            }
        }
        
        // ====================================================================
        // Stage 2: Security & Linting
        // ====================================================================
        stage('Security & Linting') {
            steps {
                echo '========================================='
                echo 'Stage 2: Security & Linting'
                echo '========================================='
                
                script {
                    // Install security tools
                    sh '''
                        . venv/bin/activate
                        pip install bandit safety flake8 pylint
                    '''
                    
                    // Run Flake8 linting
                    sh '''
                        . venv/bin/activate
                        echo "Running Flake8..."
                        flake8 main.py tests/ --max-line-length=120 --extend-ignore=E501,W503 --format=html --htmldir=flake8-report || true
                        flake8 main.py tests/ --max-line-length=120 --extend-ignore=E501,W503 || true
                    '''
                    
                    // Run Bandit security scan
                    sh '''
                        . venv/bin/activate
                        echo "Running Bandit security scan..."
                        bandit -r main.py -f json -o bandit-report.json || true
                        bandit -r main.py -f html -o bandit-report.html || true
                        bandit -r main.py || true
                    '''
                    
                    // Check dependencies for vulnerabilities
                    sh '''
                        . venv/bin/activate
                        echo "Checking dependencies with Safety..."
                        safety check --json > safety-report.json || true
                        safety check || true
                    '''
                    
                    // Archive security reports
                    archiveArtifacts artifacts: '*-report.*', allowEmptyArchive: true
                    
                    publishHTML([
                        reportDir: '.',
                        reportFiles: 'bandit-report.html',
                        reportName: 'Bandit Security Report',
                        keepAll: true,
                        alwaysLinkToLastBuild: true
                    ])
                }
            }
            post {
                success {
                    echo '✓ Security & Linting stage completed'
                }
                failure {
                    echo '✗ Security & Linting stage failed'
                }
            }
        }
        
        // ====================================================================
        // Stage 3: Docker Build & Push
        // ====================================================================
        stage('Docker Build & Push') {
            steps {
                echo '========================================='
                echo 'Stage 3: Docker Build & Push'
                echo '========================================='
                
                script {
                    // Build Docker image
                    sh """
                        echo "Building Docker image..."
                        docker build -t ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${GIT_COMMIT_SHORT} .
                        docker build -t ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:latest .
                        docker build -t ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${BUILD_TIMESTAMP} .
                    """
                    
                    // Login to Docker Hub
                    sh '''
                        echo "Logging in to Docker Hub..."
                        echo ${DOCKER_CREDENTIALS_PSW} | docker login -u ${DOCKER_CREDENTIALS_USR} --password-stdin
                    '''
                    
                    // Push Docker image
                    sh """
                        echo "Pushing Docker image..."
                        docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${GIT_COMMIT_SHORT}
                        docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:latest
                        docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${BUILD_TIMESTAMP}
                    """
                    
                    // Run Trivy security scan (if available)
                    sh """
                        if command -v trivy &> /dev/null; then
                            echo "Running Trivy security scan..."
                            trivy image --format json --output trivy-report.json ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:latest || true
                            trivy image ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:latest || true
                        else
                            echo "Trivy not installed, skipping container security scan"
                        fi
                    """
                    
                    // Logout from Docker Hub
                    sh 'docker logout'
                }
            }
            post {
                success {
                    echo "✓ Docker image built and pushed successfully"
                    echo "  - ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${GIT_COMMIT_SHORT}"
                    echo "  - ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:latest"
                    echo "  - ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${BUILD_TIMESTAMP}"
                }
                failure {
                    echo '✗ Docker Build & Push stage failed'
                }
            }
        }
        
        // ====================================================================
        // Stage 4: Terraform Infrastructure Provisioning
        // ====================================================================
        stage('Terraform Apply') {
            when {
                branch 'main'
            }
            steps {
                echo '========================================='
                echo 'Stage 4: Terraform Infrastructure'
                echo '========================================='
                
                script {
                    dir('infra') {
                        // Set AWS credentials
                        withCredentials([
                            string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                            string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                        ]) {
                            // Terraform format check
                            sh '''
                                echo "Checking Terraform format..."
                                terraform fmt -check || true
                            '''
                            
                            // Terraform init
                            sh '''
                                echo "Initializing Terraform..."
                                terraform init -upgrade
                            '''
                            
                            // Terraform validate
                            sh '''
                                echo "Validating Terraform configuration..."
                                terraform validate
                            '''
                            
                            // Terraform plan
                            sh '''
                                echo "Planning infrastructure changes..."
                                terraform plan -out=tfplan
                            '''
                            
                            // Terraform apply
                            sh '''
                                echo "Applying infrastructure changes..."
                                terraform apply -auto-approve tfplan
                            '''
                            
                            // Save outputs
                            sh '''
                                echo "Saving Terraform outputs..."
                                terraform output -json > outputs.json
                                cat outputs.json
                            '''
                            
                            // Archive outputs
                            archiveArtifacts artifacts: 'outputs.json', allowEmptyArchive: false
                        }
                    }
                }
            }
            post {
                success {
                    echo '✓ Infrastructure provisioned successfully'
                }
                failure {
                    echo '✗ Terraform Apply stage failed'
                }
            }
        }
        
        // ====================================================================
        // Stage 5: Kubernetes Deployment
        // ====================================================================
        stage('Kubernetes Deploy') {
            when {
                branch 'main'
            }
            steps {
                echo '========================================='
                echo 'Stage 5: Kubernetes Deployment'
                echo '========================================='
                
                script {
                    withCredentials([
                        string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        // Update kubeconfig
                        sh """
                            echo "Updating kubeconfig for EKS..."
                            aws eks update-kubeconfig --name inventory-manager-cluster --region ${AWS_REGION}
                        """
                        
                        // Update image tag in deployment
                        sh """
                            echo "Updating deployment with new image..."
                            sed -i "s|image:.*inventory-manager.*|image: ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${GIT_COMMIT_SHORT}|g" k8s/app-deployment.yaml
                        """
                        
                        // Create namespace
                        sh '''
                            echo "Creating namespace..."
                            kubectl apply -f k8s/namespace.yaml || true
                        '''
                        
                        // Apply ConfigMap and Secrets
                        sh '''
                            echo "Applying ConfigMap and Secrets..."
                            kubectl apply -f k8s/configmap.yaml -n inventory-manager || true
                            kubectl apply -f k8s/secrets.yaml -n inventory-manager || true
                        '''
                        
                        // Deploy MongoDB and Redis
                        sh '''
                            echo "Deploying MongoDB and Redis..."
                            kubectl apply -f k8s/mongodb-deployment.yaml -n inventory-manager
                            kubectl apply -f k8s/redis-deployment.yaml -n inventory-manager
                        '''
                        
                        // Wait for database services
                        sh '''
                            echo "Waiting for database services to be ready..."
                            kubectl wait --for=condition=ready pod -l app=mongodb -n inventory-manager --timeout=300s || true
                            kubectl wait --for=condition=ready pod -l app=redis -n inventory-manager --timeout=300s || true
                        '''
                        
                        // Deploy application
                        sh '''
                            echo "Deploying application..."
                            kubectl apply -f k8s/app-deployment.yaml -n inventory-manager
                            kubectl apply -f k8s/ingress.yaml -n inventory-manager || true
                        '''
                        
                        // Wait for application deployment
                        sh '''
                            echo "Waiting for application rollout..."
                            kubectl rollout status deployment/inventory-manager -n inventory-manager --timeout=300s
                        '''
                        
                        // Get deployment status
                        sh '''
                            echo "=== Deployment Status ==="
                            kubectl get pods -n inventory-manager
                            kubectl get services -n inventory-manager
                            kubectl get ingress -n inventory-manager || true
                        '''
                    }
                }
            }
            post {
                success {
                    echo '✓ Kubernetes deployment completed successfully'
                }
                failure {
                    echo '✗ Kubernetes deployment failed'
                    sh '''
                        echo "=== Application Logs ==="
                        kubectl logs -n inventory-manager -l app=inventory-manager --tail=50 || true
                    '''
                }
            }
        }
        
        // ====================================================================
        // Stage 6: Post-Deploy Smoke Tests
        // ====================================================================
        stage('Smoke Tests') {
            when {
                branch 'main'
            }
            steps {
                echo '========================================='
                echo 'Stage 6: Post-Deploy Smoke Tests'
                echo '========================================='
                
                script {
                    withCredentials([
                        string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        // Update kubeconfig
                        sh """
                            aws eks update-kubeconfig --name inventory-manager-cluster --region ${AWS_REGION}
                        """
                        
                        // Get service endpoint
                        sh '''
                            echo "Getting service endpoint..."
                            SERVICE_IP=$(kubectl get service inventory-manager-service -n inventory-manager -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
                            
                            if [ -z "$SERVICE_IP" ]; then
                                echo "Using port-forward for testing..."
                                kubectl port-forward -n inventory-manager service/inventory-manager-service 8080:3000 &
                                sleep 10
                                SERVICE_URL="http://localhost:8080"
                            else
                                SERVICE_URL="http://$SERVICE_IP:3000"
                            fi
                            
                            echo "Testing endpoint: $SERVICE_URL"
                            echo "$SERVICE_URL" > service_url.txt
                        '''
                        
                        // Health check with retries
                        sh '''
                            SERVICE_URL=$(cat service_url.txt)
                            max_attempts=10
                            attempt=0
                            
                            while [ $attempt -lt $max_attempts ]; do
                                if curl -f -s "$SERVICE_URL/api/items" > /dev/null 2>&1; then
                                    echo "✓ Health check passed"
                                    break
                                fi
                                attempt=$((attempt + 1))
                                echo "Attempt $attempt/$max_attempts failed, retrying in 10s..."
                                sleep 10
                            done
                            
                            if [ $attempt -eq $max_attempts ]; then
                                echo "✗ Health check failed after $max_attempts attempts"
                                exit 1
                            fi
                        '''
                        
                        // Test API endpoints
                        sh '''
                            SERVICE_URL=$(cat service_url.txt)
                            
                            echo "Testing GET /api/items..."
                            response=$(curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL/api/items")
                            if [ "$response" = "200" ]; then
                                echo "✓ GET /api/items - PASSED (HTTP $response)"
                            else
                                echo "✗ GET /api/items - FAILED (HTTP $response)"
                                exit 1
                            fi
                            
                            echo "Testing POST /api/items..."
                            response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$SERVICE_URL/api/items" \
                                -H "Content-Type: application/json" \
                                -d '{"name":"Jenkins Test Item","quantity":10,"price":29.99}')
                            if [ "$response" = "201" ] || [ "$response" = "200" ]; then
                                echo "✓ POST /api/items - PASSED (HTTP $response)"
                            else
                                echo "✗ POST /api/items - FAILED (HTTP $response)"
                                exit 1
                            fi
                            
                            echo "✓ All smoke tests passed!"
                        '''
                        
                        // Cleanup port-forward if used
                        sh '''
                            pkill -f "kubectl port-forward" || true
                        '''
                    }
                }
            }
            post {
                success {
                    echo '✓ Smoke tests passed - Deployment verified'
                }
                failure {
                    echo '✗ Smoke tests failed'
                    sh '''
                        echo "=== Application Logs ==="
                        kubectl logs -n inventory-manager -l app=inventory-manager --tail=100 || true
                        echo "=== MongoDB Logs ==="
                        kubectl logs -n inventory-manager -l app=mongodb --tail=50 || true
                        echo "=== Redis Logs ==="
                        kubectl logs -n inventory-manager -l app=redis --tail=50 || true
                    '''
                }
            }
        }
    }
    
    // ========================================================================
    // Post-Build Actions
    // ========================================================================
    post {
        always {
            echo '========================================='
            echo 'Pipeline Execution Summary'
            echo '========================================='
            
            script {
                def duration = currentBuild.duration / 1000
                def result = currentBuild.result ?: 'SUCCESS'
                
                echo """
                Pipeline Status: ${result}
                Build Number: ${env.BUILD_NUMBER}
                Commit: ${GIT_COMMIT_SHORT}
                Duration: ${duration}s
                Branch: ${env.BRANCH_NAME}
                Docker Image: ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${GIT_COMMIT_SHORT}
                """
            }
            
            // Cleanup
            sh '''
                # Stop any port-forward processes
                pkill -f "kubectl port-forward" || true
                
                # Remove temporary files
                rm -f service_url.txt
            '''
            
            // Clean up workspace (optional)
            cleanWs(
                deleteDirs: true,
                disableDeferredWipeout: true,
                notFailBuild: true,
                patterns: [
                    [pattern: 'venv', type: 'EXCLUDE']
                ]
            )
        }
        
        success {
            echo '========================================='
            echo '✓ Pipeline completed successfully!'
            echo '========================================='
            
            // Send success notification (configure as needed)
            // emailext subject: "✓ Build #${env.BUILD_NUMBER} - SUCCESS",
            //          body: "The pipeline completed successfully.",
            //          to: "team@example.com"
        }
        
        failure {
            echo '========================================='
            echo '✗ Pipeline failed!'
            echo '========================================='
            
            // Send failure notification (configure as needed)
            // emailext subject: "✗ Build #${env.BUILD_NUMBER} - FAILED",
            //          body: "The pipeline failed. Please check the logs.",
            //          to: "team@example.com"
        }
    }
}
