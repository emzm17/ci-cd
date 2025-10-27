pipeline {
    agent {
        kubernetes {
            label 'k8s-agent'
            defaultContainer 'docker-cli'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: k8s-agent
spec:
  containers:
  - name: docker-daemon
    image: docker:24.0-dind
    securityContext:
      privileged: true
    command:
    - dockerd-entrypoint.sh
    args:
    - --host=tcp://0.0.0.0:2375
    tty: true

  - name: docker-cli
    image: docker:24.0
    command:
    - cat
    tty: true
    env:
    - name: DOCKER_HOST
      value: tcp://localhost:2375

  - name: helm
    image: alpine/helm:3.16.1
    command:
    - cat
    tty: true
"""
        }
    }

    environment {
        IMAGE_NAME = 'simple-application'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        HELM_CHART_DIR = 'helm/simple-application'
    }

    stages {

        stage('Docker Login, Build and Push') {
            steps {
                container('docker-cli') {
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
                            sh "docker build -t ${imageFullName} ."
                            sh "docker push ${imageFullName}"
                        }
                    }
                }
            }
        }

        stage('Update Helm Chart Image Tag') {
            steps {
                container('helm') {
                    sh """
                        sed -i 's|^  repository:.*|  repository: ${REGISTRY}/${IMAGE_NAME}|' ${HELM_CHART_DIR}/values.yaml
                        sed -i 's|^  tag:.*|  tag: ${IMAGE_TAG}|' ${HELM_CHART_DIR}/values.yaml
                    """
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
                        sh "helm package . --version ${IMAGE_TAG} --app-version ${IMAGE_TAG}"
                    }
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
            container('docker-cli') {
                sh 'docker logout || true'
            }
        }
    }
}
