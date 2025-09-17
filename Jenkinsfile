pipeline {
    agent any

    environment {
        IMAGE_NAME = 'simple-frontend'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE_NAME = "sumairjaved/${IMAGE_NAME}"
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD || echo 'unknown'", returnStdout: true).trim()
        LOCAL_DIR = "${WORKSPACE}/frontend" // Safe workspace directory
        SSH_USER = 'idrak'                // Your system username
        SSH_HOST = '127.0.0.1'            // For local host, use 127.0.0.1
        SSH_PASS = '3625'                  // SSH / sudo password
        REMOTE_DIR = '/home/idrak/Desktop/frontend'
    }

    stages {
        stage('Checkout') {
            steps {
                echo "🔄 Checking out code from Git repository..."
                checkout([$class: 'GitSCM',
                          branches: [[name: '*/main']],
                          userRemoteConfigs: [[url: 'https://github.com/Sumair-Idrak1/jenkins.git']]])
                echo "✅ Code checked out successfully"
                echo "📝 Git commit: ${GIT_COMMIT_SHORT}"
            }
        }

        stage('Prepare Build Folder') {
            steps {
                sh """
                    mkdir -p ${LOCAL_DIR}
                    rm -rf ${LOCAL_DIR}/*
                    # Copy all files except frontend folder itself and .git
                    find . -maxdepth 1 ! -name '.' ! -name 'frontend' ! -name '.git' -exec cp -r {} ${LOCAL_DIR}/ \\;
                    echo "✅ Build folder prepared at ${LOCAL_DIR}"
                """
            }
        }

        stage('Copy Code to Remote / Local Host') {
            steps {
                sh """
                    sshpass -p "${SSH_PASS}" ssh -o StrictHostKeyChecking=no ${SSH_USER}@${SSH_HOST} "mkdir -p ${REMOTE_DIR}"
                    sshpass -p "${SSH_PASS}" scp -o StrictHostKeyChecking=no -r ${LOCAL_DIR}/* ${SSH_USER}@${SSH_HOST}:${REMOTE_DIR}/
                    echo "✅ Code copied to remote / local host"
                """
            }
        }

        stage('Build Docker Image on Host') {
            steps {
                sh """
                    sshpass -p "${SSH_PASS}" ssh -o StrictHostKeyChecking=no ${SSH_USER}@${SSH_HOST} \\
                    "echo '${SSH_PASS}' | sudo -S docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest ${REMOTE_DIR}"
                    echo "✅ Docker image built on host"
                """
            }
        }

        stage('Run Docker Compose on Host') {
            steps {
                sh """
                    sshpass -p "${SSH_PASS}" ssh -o StrictHostKeyChecking=no ${SSH_USER}@${SSH_HOST} \\
                    "echo '${SSH_PASS}' | sudo -S docker-compose -f ${REMOTE_DIR}/docker-compose.yml down || true"
                    sshpass -p "${SSH_PASS}" ssh -o StrictHostKeyChecking=no ${SSH_USER}@${SSH_HOST} \\
                    "echo '${SSH_PASS}' | sudo -S docker-compose -f ${REMOTE_DIR}/docker-compose.yml up -d"
                    echo "✅ Docker Compose started on host"
                """
            }
        }

        stage('Push Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        sshpass -p "${SSH_PASS}" ssh -o StrictHostKeyChecking=no ${SSH_USER}@${SSH_HOST} \\
                        "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin && \\
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${FULL_IMAGE_NAME}:${IMAGE_TAG} && \\
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${FULL_IMAGE_NAME}:latest && \\
                        docker push ${FULL_IMAGE_NAME}:${IMAGE_TAG} && \\
                        docker push ${FULL_IMAGE_NAME}:latest && \\
                        docker logout"
                        echo "✅ Docker images pushed to Docker Hub from host"
                    """
                }
            }
        }
    }

    post {
        always {
            echo "🧹 Pipeline finished / cleanup if needed"
        }
        success {
            echo "🎉 Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
