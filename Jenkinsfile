pipeline {
    agent any

    environment {
        IMAGE_NAME = 'simple-frontend'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE_NAME = "sumairjaved/${IMAGE_NAME}"
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD || echo 'unknown'", returnStdout: true).trim()
        BUILD_DIR = "${WORKSPACE}/local_build" // Local working directory
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "✅ Code checked out successfully"
                echo "📝 Git commit: ${GIT_COMMIT_SHORT}"
            }
        }

        stage('Prepare Local Build Directory') {
            steps {
                sh """
                    mkdir -p ${BUILD_DIR}
                    rm -rf ${BUILD_DIR}/*
                    cp -r * ${BUILD_DIR}/
                    echo "✅ Local build directory prepared at ${BUILD_DIR}"
                """
            }
        }

        stage('Build Docker Image Locally') {
            steps {
                sh """
                    cd ${BUILD_DIR}
                    echo "🔨 Building Docker image..."
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest .
                    echo "✅ Docker image built successfully"
                """
            }
        }

        stage('Run Docker Compose Locally') {
            steps {
                sh """
                    cd ${BUILD_DIR}
                    echo "📦 Running docker-compose..."
                    docker-compose down || true
                    docker-compose up -d
                    echo "✅ Docker Compose services started"
                """
            }
        }

        stage('Optional: Push Docker Image to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${FULL_IMAGE_NAME}:${IMAGE_TAG}
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${FULL_IMAGE_NAME}:latest
                        docker push ${FULL_IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${FULL_IMAGE_NAME}:latest
                        docker logout
                        echo "✅ Docker images pushed to Docker Hub"
                    """
                }
            }
        }
    }

    post {
        always {
            echo "🧹 Local cleanup if needed"
        }
        success {
            echo "🎉 Pipeline completed successfully on localhost!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
