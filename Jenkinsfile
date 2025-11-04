pipeline {
    agent {
        kubernetes {
            label 'k8s-agent'
        }
    }
    environment {
        IMAGE_NAME = 'simple-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        HELM_CHART_DIR = 'helm/simple-app'
        HELM_CHART_NAME = 'simple-app'
        SONARQUBE_SERVER = 'MySonarQube'          // Name configured in Jenkins
        SCANNER_HOME = tool 'SonarQubeScanner'
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
                            sh "docker login -u ${DOCKER_USER} -p ${DOCKER_PASS}"
                            
                            sh """
                                docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} .
                                docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                            """
                        }
                    }
                }  
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectKey=simple-apps \
                        -Dsonar.token=$SONAR_AUTH_TOKEN \
                        -Dsonar.host.url=$SONAR_HOST_URL \
                    """
                }
            }
        }
        stage('Quality Gate') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    script {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline failed due to quality gate failure: ${qg.status}"
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
                container('helm') {
                    dir("${HELM_CHART_DIR}") {
                        sh 'helm lint .'
                    }
                }
            }
        }
        
        stage('Package Helm Chart') {
            steps {
                    container('helm') {
                    dir("${HELM_CHART_DIR}") {
                        sh """
                            helm package . --version ${IMAGE_TAG} --app-version ${IMAGE_TAG}
                            ls -lart
                        """
                    }
                }
            }
        }
        
        stage('Push Helm Chart to Nexus') {
            steps {
                container('helm') {
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
                        if ! helm plugin list | grep push; then
                            helm plugin install https://github.com/chartmuseum/helm-push.git
                        fi
                        # Push chart
                        helm push ${HELM_CHART_DIR}/${HELM_CHART_NAME}-${IMAGE_TAG}.tgz ${HELM_REPO}

                        """
                    }
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
        }
        failure {
            echo "Pipeline failed. Check logs for details."
        }
    }
}

