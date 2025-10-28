pipeline {
    agent {
        kubernetes {
            label 'k8s-agent'  // Label of your pre-configured pod template
        }
    }
    environment {
        IMAGE_NAME = 'simple-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        HELM_CHART_DIR = 'helm/simple-application'
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
                            sh "docker login -u ${DOCKER_USER} -p ${DOCKER_PASS}"
                            
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
                    ]){
                script {
                    sh """
                        sed -i 's|^  repository:.*|  repository: ${REGISTRY}/${IMAGE_NAME}|' ${HELM_CHART_DIR}/values.yaml
                        sed -i 's|^  tag:.*|  tag: ${IMAGE_TAG}|' ${HELM_CHART_DIR}/values.yaml
                    """
                }
                    }
            }
        }
    //     stage('Lint Helm Chart') {
    //         steps {
    //             dir("${HELM_CHART_DIR}") {
    //                 sh 'helm lint .'
    //             }
    //         }
    //     }
    //     stage('Package Helm Chart') {
    //         steps {
    //             dir("${HELM_CHART_DIR}") {
    //                 sh """
    //                     helm package . --version ${IMAGE_TAG} --app-version ${IMAGE_TAG}
    //                 """
    //             }
    //         }
    //     }
    //     stage('Push Helm Chart (Optional)') {
    //         steps {
    //             script {
    //                 echo "Helm chart packaged. Push to repository as needed."
    //             }
    //         }
    //     }
    }
    post {
        always {
            container('docker') {  // ← ADD THIS!
                // Logout from Docker safely
                sh 'docker logout || true'
            }  // ← CLOSE THIS!
        }
    }
}
