pipeline {
    agent any
    
    environment {
        DOCKER_HOST = "tcp://localhost:2375"
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials')
        DOCKERHUB_USER = 'sumairjaved'
        IMAGE_NAME = 'simple-frontend'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE_NAME = "${DOCKERHUB_USER}/${IMAGE_NAME}"
        // Add Git commit hash for better traceability
        GIT_COMMIT_SHORT = sh(
            script: "git rev-parse --short HEAD || echo 'unknown'",
            returnStdout: true
        ).trim()
    }
    
    stages {
        stage('Checkout') {
            steps { 
                checkout scm 
                echo "✅ Code checked out successfully"
                echo "📝 Git commit: ${GIT_COMMIT_SHORT}"
            }
        }
        
        stage('Verify Docker') {
            steps {
                sh """
                    echo "Checking Docker installation..."
                    docker --version
                    docker info --format 'Docker is running: {{.ServerVersion}}'
                    echo "Docker daemon is accessible at: ${DOCKER_HOST}"
                """
            }
        }

        stage('Verify Dockerfile') {
            steps {
                script {
                    if (fileExists('Dockerfile')) {
                        echo "✅ Dockerfile found"
                        sh 'head -10 Dockerfile'
                    } else {
                        error "❌ Dockerfile not found in repository root"
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps { 
                echo "🔨 Building Docker image: ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
                sh """
                    docker build \
                        --label "build.number=${BUILD_NUMBER}" \
                        --label "git.commit=${GIT_COMMIT_SHORT}" \
                        --label "build.url=${BUILD_URL}" \
                        -t ${IMAGE_NAME}:${IMAGE_TAG} \
                        -t ${IMAGE_NAME}:latest \
                        .
                """
                echo "✅ Docker image built successfully"
            }
        }

        stage('Test Docker Image') {
            steps {
                echo "🧪 Testing Docker image"
                sh """
                    # Basic image inspection
                    docker inspect ${IMAGE_NAME}:${IMAGE_TAG}
                    
                    # Test if image can run (basic smoke test)
                    docker run --rm -d --name test-container-${BUILD_NUMBER} \
                        -p 8080:80 ${IMAGE_NAME}:${IMAGE_TAG}
                    
                    # Wait a moment for container to start
                    sleep 5
                    
                    # Check if container is running
                    docker ps | grep test-container-${BUILD_NUMBER} || exit 1
                    
                    # Optional: Test HTTP endpoint if it's a web app
                    # curl -f http://localhost:8080 || echo "⚠️ HTTP test failed or not applicable"
                    
                    # Stop test container
                    docker stop test-container-${BUILD_NUMBER}
                """
                echo "✅ Docker image tested successfully"
            }
        }
        
        stage('Tag Docker Image') {
            steps { 
                echo "🏷️ Tagging Docker image"
                sh """
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${FULL_IMAGE_NAME}:${IMAGE_TAG}
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${FULL_IMAGE_NAME}:latest
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${FULL_IMAGE_NAME}:git-${GIT_COMMIT_SHORT}
                """
                echo "✅ Docker image tagged successfully"
            }
        }
        
        stage('Security Scan') {
            steps {
                echo "🛡️ Running basic security checks"
                sh """
                    # Check for vulnerabilities in base image (if trivy is available)
                    if command -v trivy &> /dev/null; then
                        trivy image --exit-code 1 --severity HIGH,CRITICAL ${IMAGE_NAME}:${IMAGE_TAG}
                    else
                        echo "⚠️ Trivy not installed, skipping vulnerability scan"
                    fi
                    
                    # Basic image analysis
                    docker history ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
        
        stage('Login to Docker Hub') {
            steps {
                echo "🔐 Logging into Docker Hub"
                sh """
                    echo \$DOCKER_HUB_CREDENTIALS_PSW | docker login -u \$DOCKER_HUB_CREDENTIALS_USR --password-stdin
                """
                echo "✅ Successfully logged into Docker Hub"
            }
        }
        
        stage('Push to Docker Hub') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master' 
                    branch 'develop'
                    expression { return params.FORCE_DEPLOY == true }
                }
            }
            steps {
                echo "🚀 Pushing images to Docker Hub"
                sh """
                    docker push ${FULL_IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${FULL_IMAGE_NAME}:latest
                    docker push ${FULL_IMAGE_NAME}:git-${GIT_COMMIT_SHORT}
                """
                echo "✅ Images pushed successfully"
                
                // Display pushed images
                sh """
                    echo "📦 Pushed images:"
                    echo "  - ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
                    echo "  - ${FULL_IMAGE_NAME}:latest"
                    echo "  - ${FULL_IMAGE_NAME}:git-${GIT_COMMIT_SHORT}"
                """
            }
        }
        
        stage('Clean up local images') {
            steps {
                echo "🧹 Cleaning up local Docker images"
                sh """
                    docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true
                    docker rmi ${IMAGE_NAME}:latest || true
                    docker rmi ${FULL_IMAGE_NAME}:${IMAGE_TAG} || true
                    docker rmi ${FULL_IMAGE_NAME}:latest || true
                    docker rmi ${FULL_IMAGE_NAME}:git-${GIT_COMMIT_SHORT} || true
                    
                    # Clean up dangling images
                    docker image prune -f || true
                """
                echo "✅ Local images cleaned up"
            }
        }
    }
    
    post {
        always {
            sh 'docker logout || true'
            echo "🔓 Logged out of Docker Hub"
            
            // Clean up any remaining test containers
            sh """
                docker rm -f test-container-${BUILD_NUMBER} 2>/dev/null || true
            """
        }
        success { 
            echo '🎉 Docker image built and pushed successfully!' 
            echo "📦 Images available at:"
            echo "  - ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
            echo "  - ${FULL_IMAGE_NAME}:latest"
            echo "  - ${FULL_IMAGE_NAME}:git-${GIT_COMMIT_SHORT}"
            
            // Send notification (if configured)
            // slackSend(message: "✅ Build ${BUILD_NUMBER} successful for ${IMAGE_NAME}")
        }
        failure { 
            echo '❌ Build failed!' 
            sh """
                # Clean up any failed containers
                docker rm -f test-container-${BUILD_NUMBER} 2>/dev/null || true
                # Clean up system
                docker system prune -f || true
            """
            
            // Send failure notification
            // slackSend(message: "❌ Build ${BUILD_NUMBER} failed for ${IMAGE_NAME}")
        }
        unstable {
            echo '⚠️ Build unstable - some tests may have failed'
        }
    }
}
