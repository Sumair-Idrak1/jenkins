pipeline {
    agent any

    environment {
        IMAGE_NAME = 'simple-frontend'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE_NAME = "sumairjaved/${IMAGE_NAME}"
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD || echo 'unknown'", returnStdout: true).trim()
        LOCAL_DIR = '/home/idrak/Desktop/frontend' // Path where code lives and will be built
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "✅ Code checked out successfully"
                echo "📝 Git commit: ${GIT_COMMIT_SHORT}"
            }
        }

        stage('Prepare Local Build Folder') {
            steps {
                sh """
                    mkdir -p ${LOCAL_DIR}
                    rm -rf ${LOCAL_DIR}/*
                    cp -r * ${LOCAL_DIR}/
                    echo "✅ Local build folder prepared at ${LOCAL_DIR}"
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    cd ${LOCAL_DIR}
                    echo "🔨 Building Docker image..."
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest .
                    echo "✅ Docker image built successfully"
                """
            }
        }

        stage('Run Docker Compose') {
            steps {
                sh """
                    cd ${LOCAL_DIR}
                    echo "📦 Running docker-compose..."
                    docker-compose down || true
                    docker-compose up -d
                    echo "✅ Docker Compose services started"
                """
            }
        }

        stage('Optional: Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        cd ${LOCAL_DIR}
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
            echo "🧹 Local cleanup can be done here if needed"
        }
        success {
            echo "🎉 Pipeline completed successfully on localhost!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
