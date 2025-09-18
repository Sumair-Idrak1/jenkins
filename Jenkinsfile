pipeline {
    agent any
    environment {
        IMAGE_NAME = 'simple-frontend'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE_NAME = "sumairjaved/${IMAGE_NAME}"
        LOCAL_DIR = "${WORKSPACE}/frontend"
        KANIKO_CACHE = "/kaniko-cache"
    }
    stages {
        stage('Checkout') {
            steps {
                echo "🔄 Checking out code..."
                checkout([$class: 'GitSCM',
                          branches: [[name: '*/main']],
                          userRemoteConfigs: [[url: 'https://github.com/Sumair-Idrak1/jenkins.git']]])
            }
        }
        stage('Prepare Build Folder') {
            steps {
                sh """
                    mkdir -p ${LOCAL_DIR}
                    rm -rf ${LOCAL_DIR}/*
                    find . -maxdepth 1 ! -name '.' ! -name 'frontend' ! -name '.git' -exec cp -r {} ${LOCAL_DIR}/ \\;
                    echo "✅ Build folder ready at ${LOCAL_DIR}"
                """
            }
        }
        stage('Build and Push with Kaniko') {
            steps {
                script {
                    // Create Docker config for authentication
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh """
                            # Create Docker config directory
                            mkdir -p /kaniko/.docker
                            
                            # Create Docker config.json for authentication
                            cat > /kaniko/.docker/config.json << EOF
{
    "auths": {
        "https://index.docker.io/v1/": {
            "auth": "\$(echo -n "${DOCKER_USER}:${DOCKER_PASS}" | base64)"
        }
    }
}
EOF
                            
                            echo "✅ Docker credentials configured for Kaniko"
                        """
                        
                        // Run Kaniko to build and push
                        sh """
                            # Use Kaniko executor to build and push image
                            /kaniko/executor \\
                                --dockerfile=${LOCAL_DIR}/Dockerfile \\
                                --context=${LOCAL_DIR} \\
                                --destination=${FULL_IMAGE_NAME}:${IMAGE_TAG} \\
                                --destination=${FULL_IMAGE_NAME}:latest \\
                                --cache=true \\
                                --cache-dir=${KANIKO_CACHE} \\
                                --compressed-caching=false \\
                                --snapshot-mode=redo \\
                                --use-new-run \\
                                --log-timestamp \\
                                --verbosity=info
                            
                            echo "✅ Docker image built and pushed with Kaniko"
                        """
                    }
                }
            }
        }
    }
    post {
        always {
            echo "🧹 Pipeline finished"
            // Clean up sensitive files
            sh """
                rm -rf /kaniko/.docker/config.json 2>/dev/null || true
                echo "🧹 Cleaned up Docker credentials"
            """
        }
        success {
            echo "🎉 Pipeline completed successfully!"
            echo "📦 Images pushed:"
            echo "   - ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
            echo "   - ${FULL_IMAGE_NAME}:latest"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
