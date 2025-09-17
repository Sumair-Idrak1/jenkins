pipeline {
    agent any
    
    environment {
	DOCKER_HOST = "tcp://localhost:2375"
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials')  
        DOCKERHUB_USER = 'sumairjaved'
        IMAGE_NAME = 'simple-frontend'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE_NAME = "${DOCKERHUB_USER}/${IMAGE_NAME}"
    }
    
    stages {
        stage('Checkout') {
            steps { 
                checkout scm 
                echo "✅ Code checked out successfully"
            }
        }
        
        stage('Verify Docker') {
            steps {
                sh """
                    echo "Checking Docker installation..."
                    docker --version
                    docker info
                """
            }
        }
        
        stage('Build Docker Image') {
            steps { 
                echo "🔨 Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest ." 
                echo "✅ Docker image built successfully"
            }
        }
        
        stage('Tag Docker Image') {
            steps { 
                echo "🏷️ Tagging Docker image"
                sh """
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${FULL_IMAGE_NAME}:${IMAGE_TAG}
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${FULL_IMAGE_NAME}:latest
                """
                echo "✅ Docker image tagged successfully"
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
            steps {
                echo "🚀 Pushing images to Docker Hub"
                sh """
                    docker push ${FULL_IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${FULL_IMAGE_NAME}:latest
                """
                echo "✅ Images pushed successfully"
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
                """
                echo "✅ Local images cleaned up"
            }
        }
    }
    
    post {
        always {
            sh 'docker logout || true'
            echo "🔓 Logged out of Docker Hub"
        }
        success { 
            echo '🎉 Docker image built and pushed successfully!' 
            echo "📦 Image available at: ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
            echo "📦 Image available at: ${FULL_IMAGE_NAME}:latest"
        }
        failure { 
            echo '❌ Build failed!' 
            sh 'docker system prune -f || true'
        }
    }
}
