pipeline {
    agent any

    environment {
        SSH_USER = 'idrak'                // Your system username
        SSH_HOST = '127.0.0.1'            // Localhost or remote IP
        SSH_PASS = '3625'                  // SSH/sudo password
        REMOTE_DIR = '/home/idrak/Desktop/frontend'
        IMAGE_NAME = 'simple-frontend'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "✅ Code checked out"
            }
        }

        stage('Copy Code to Remote') {
            steps {
                sh """
                    sshpass -p "${SSH_PASS}" ssh -o StrictHostKeyChecking=no ${SSH_USER}@${SSH_HOST} "mkdir -p ${REMOTE_DIR}"
                    sshpass -p "${SSH_PASS}" scp -o StrictHostKeyChecking=no -r * ${SSH_USER}@${SSH_HOST}:${REMOTE_DIR}/
                    echo "✅ Code copied to remote system"
                """
            }
        }

        stage('Build Docker Image Remotely') {
            steps {
                sh """
                    sshpass -p "${SSH_PASS}" ssh -o StrictHostKeyChecking=no ${SSH_USER}@${SSH_HOST} \\
                    "echo '${SSH_PASS}' | sudo -S docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest ${REMOTE_DIR}"
                    echo "✅ Docker image built remotely"
                """
            }
        }

        stage('Run Docker Compose Remotely') {
            steps {
                sh """
                    sshpass -p "${SSH_PASS}" ssh -o StrictHostKeyChecking=no ${SSH_USER}@${SSH_HOST} \\
                    "echo '${SSH_PASS}' | sudo -S docker-compose -f ${REMOTE_DIR}/docker-compose.yml down || true"
                    sshpass -p "${SSH_PASS}" ssh -o StrictHostKeyChecking=no ${SSH_USER}@${SSH_HOST} \\
                    "echo '${SSH_PASS}' | sudo -S docker-compose -f ${REMOTE_DIR}/docker-compose.yml up -d"
                    echo "✅ Docker Compose started remotely"
                """
            }
        }
    }

    post {
        always {
            echo "🧹 Cleanup / Finished"
        }
    }
}
