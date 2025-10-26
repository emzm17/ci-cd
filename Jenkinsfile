pipeline {
    agent {
        kubernetes {
            label 'k8s-agent'  // Label of your pre-configured pod template
        }
    }

    environment {
        IMAGE_NAME = 'simple-application'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        HELM_CHART_DIR = 'helm/simple-application'
    }

    stages {

        stage('Initialize'){
       steps {
        script {
            def dockerHome = tool 'mydocker'  
            env.PATH = "${dockerHome}/bin:${env.PATH}"
        }
       }
        }

        stage('Docker Login, Build and Push') {
            steps {
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
                        def imageFullName = "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                        docker.build(imageFullName).push()
                    }
                }
            }
        }

        stage('Update Helm Chart Image Tag') {
            steps {
                script {
                    sh """
                        sed -i 's|^  repository:.*|  repository: ${REGISTRY}/${IMAGE_NAME}|' ${HELM_CHART_DIR}/values.yaml
                        sed -i 's|^  tag:.*|  tag: ${IMAGE_TAG}|' ${HELM_CHART_DIR}/values.yaml
                    """
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

        stage('Push Helm Chart (Optional)') {
            steps {
                script {
                    echo "Helm chart packaged. Push to repository as needed."
                }
            }
        }
    }

    post {
        always {
            // Logout from Docker safely
            sh 'docker logout || true'
        }
    }
}
