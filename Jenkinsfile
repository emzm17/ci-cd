pipeline {
    agent any

    environment {
        REGISTRY = 'localhost:5000'
        IMAGE_NAME = 'simple-k8s-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        DOCKER_USERNAME = credentials('docker').username
        DOCKER_PASSWORD = credentials('docker').password
        HELM_CHART_DIR = 'helm/simple-application'
    }

    stages {

        stage('Login to Docker Registry') {
            steps {
                sh """
                    echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin $REGISTRY
                """
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    def imageFullName = "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                    docker.build(imageFullName).push()
                }
            }
        }

        stage('Update Helm Chart Image Tag') {
            steps {
                script {
                    // Update values.yaml with new image tag
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
                    // Example: Push to local Helm repo
                    // sh "helm repo index /path/to/helm-repo --merge /path/to/helm-repo/index.yaml"
                    echo "Helm chart packaged. Push to repository as needed."
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout'
        }
    }
}
