pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
    jenkins/kaniko: "true"
spec:
  securityContext:
    runAsUser: 0
    fsGroup: 0
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - /busybox/cat
    tty: true
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "4Gi"
        cpu: "2"
    volumeMounts:
    - name: kaniko-cache
      mountPath: /kaniko-cache
    - name: docker-config
      mountPath: /kaniko/.docker
    env:
    - name: DOCKER_CONFIG
      value: /kaniko/.docker
  - name: git
    image: alpine/git:latest
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"
  volumes:
  - name: kaniko-cache
    emptyDir: {}
  - name: docker-config
    emptyDir: {}
"""
        }
    }
    environment {
        IMAGE_NAME = 'simple-frontend'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE_NAME = "sumairjaved/${IMAGE_NAME}"
        LOCAL_DIR = "${WORKSPACE}/frontend"
    }
    stages {
        stage('Checkout') {
            steps {
                container('git') {
                    echo "🔄 Checking out code..."
                    checkout([$class: 'GitSCM',
                              branches: [[name: '*/main']],
                              userRemoteConfigs: [[url: 'https://github.com/Sumair-Idrak1/jenkins.git']]])
                }
            }
        }
        stage('Prepare Build Context') {
            steps {
                container('kaniko') {
                    sh '''
                        mkdir -p ${LOCAL_DIR}
                        rm -rf ${LOCAL_DIR}/*
                        find . -maxdepth 1 ! -name '.' ! -name 'frontend' ! -name '.git' -exec cp -r {} ${LOCAL_DIR}/ \\;
                        
                        echo "📁 Build context contents:"
                        ls -la ${LOCAL_DIR}/
                        echo "✅ Build context ready at ${LOCAL_DIR}"
                    '''
                }
            }
        }
        stage('Build and Push with Kaniko') {
            steps {
                container('kaniko') {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            # Create Docker config for authentication
                            echo "🔐 Configuring Docker registry authentication..."
                            
                            # Create auth string safely
                            AUTH_STRING=$(echo -n "$DOCKER_USER:$DOCKER_PASS" | base64 -w 0)
                            
                            cat > /kaniko/.docker/config.json << EOF
{
    "auths": {
        "https://index.docker.io/v1/": {
            "auth": "$AUTH_STRING"
        }
    }
}
EOF
                            
                            echo "🏗️  Building and pushing image with Kaniko..."
                        '''
                        
                        sh '''
                            /kaniko/executor \
                                --dockerfile=${LOCAL_DIR}/Dockerfile \
                                --context=dir://${LOCAL_DIR} \
                                --destination=${FULL_IMAGE_NAME}:${IMAGE_TAG} \
                                --destination=${FULL_IMAGE_NAME}:latest \
                                --cache=true \
                                --cache-dir=/kaniko-cache \
                                --compressed-caching=false \
                                --snapshot-mode=redo \
                                --use-new-run \
                                --log-timestamp \
                                --verbosity=info \
                                --force
                            
                            echo "✅ Images successfully built and pushed:"
                            echo "   📦 ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
                            echo "   📦 ${FULL_IMAGE_NAME}:latest"
                        '''
                    }
                }
            }
        }
    }
    post {
        always {
            echo "🧹 Pipeline finished"
            container('kaniko') {
                sh '''
                    rm -rf /kaniko/.docker/config.json 2>/dev/null || true
                    echo "🧹 Cleaned up Docker credentials"
                '''
            }
        }
        success {
            echo "🎉 Pipeline completed successfully!"
            echo "📦 Images available at:"
            echo "   - docker pull ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
            echo "   - docker pull ${FULL_IMAGE_NAME}:latest"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
