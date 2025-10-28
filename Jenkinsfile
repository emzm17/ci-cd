pipeline {
    agent {
        kubernetes {
            label 'k8s-agent'
        }
    }
    environment {
        IMAGE_NAME = 'simple-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        HELM_CHART_DIR = 'helm/simple-application'
        HELM_CHART_NAME = 'simple-application'
    }
    stages {
        stage('Docker Login, Build and Push') {
            steps {
                container('docker') { 
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'docker', 
                            usernameVariable: 'DOCKER_USER', 
                            passwordVariable: 'DOCKER_PASS'
                        ),
                        string(
                            credentialsId: 'docker-registry', 
                            variable: 'REGISTRY'
                        )
                    ]) {
                        script {
                            // Docker login
                            sh "docker login -u ${DOCKER_USER} -p ${DOCKER_PASS} ${REGISTRY}"
                            
                            // Build and push image
                            sh """
                                docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} .
                                docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                            """
                        }
                    }
                }  
            }
        }
        
        stage('Update Helm Chart Image Tag') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'docker-registry', 
                        variable: 'REGISTRY'
                    )
                ]) {
                    script {
                        sh """
                            sed -i 's|^  repository:.*|  repository: ${REGISTRY}/${IMAGE_NAME}|' ${HELM_CHART_DIR}/values.yaml
                            sed -i 's|^  tag:.*|  tag: "${IMAGE_TAG}"|' ${HELM_CHART_DIR}/values.yaml
                        """
                    }
                }
            }
        }
        
        stage('Lint Helm Chart') {
            steps {
                dir("${HELM_CHART_DIR}") {
                    sh 'helm lint .'
                }
            }
        }
        
        stage('Package Helm Chart') {
            steps {
                dir("${HELM_CHART_DIR}") {
                    sh """
                        helm package . --version ${IMAGE_TAG} --app-version ${IMAGE_TAG}
                    """
                }
            }
        }
        
        stage('Push Helm Chart to Nexus') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'nexus-credentials',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASS'
                    ),
                    string(
                        credentialsId: 'nexus-url',
                        variable: 'NEXUS_URL'
                    ),
                    string (
                        credentialsId: 'helm-repo',
                        variable: 'HELM_REPO'
                    )
                ]) {
                    script {
                        sh """
                            curl -v -u ${NEXUS_USER}:${NEXUS_PASS} \
                                --upload-file ${HELM_CHART_DIR}/${HELM_CHART_NAME}-${IMAGE_TAG}.tgz \
                                ${NEXUS_URL}/repository/${HELM_REPO}/${HELM_CHART_NAME}-${IMAGE_TAG}.tgz
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            container('docker') {
                sh 'docker logout || true'
            }
        }
        success {
            echo "Pipeline completed successfully!"
            echo "Docker Image: ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
            echo "Helm Chart uploaded to: ${NEXUS_URL}/repository/helm-charts/${HELM_CHART_NAME}-${IMAGE_TAG}.tgz"
        }
        failure {
            echo "Pipeline failed. Check logs for details."
        }
    }
}

