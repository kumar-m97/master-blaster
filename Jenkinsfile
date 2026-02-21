// ──────────────────────────────────────────────────────────────────────────────
// Jenkinsfile – Frontend App CI/CD Pipeline
//
// Prerequisites (configure in Jenkins → Manage Jenkins → Credentials):
//   DOCKER_REGISTRY_CREDENTIALS  – AWS ECR helper (ecr:<region>:aws-credentials)
//                                   OR a Docker Hub username/password credential
//   AWS_CREDENTIALS               – AWS access key + secret (Kind: AWS Credentials)
//   KUBECONFIG_CREDENTIAL         – Secret file containing the EKS kubeconfig
//
// Jenkins plugins required:
//   • Pipeline, Git, Docker Pipeline, Kubernetes CLI, AWS Credentials
//
// Environment variables that MUST be set (via Jenkins or branch-specific overrides):
//   ECR_REGISTRY     – e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com
//   AWS_REGION       – e.g. us-east-1
//   EKS_CLUSTER_NAME – e.g. my-eks-cluster
//   DOMAIN_NAME      – e.g. frontend.example.com
// ──────────────────────────────────────────────────────────────────────────────

pipeline {
    agent any

    // ── Tool versions ──────────────────────────────────────────────────────────
    tools {
        nodejs 'NodeJS-18'   // Configured in Jenkins → Global Tool Configuration
    }

    // ── Pipeline-wide environment ─────────────────────────────────────────────
    environment {
        APP_NAME          = 'frontend-app'
        ECR_REGISTRY      = "${params.ECR_REGISTRY ?: env.ECR_REGISTRY}"
        AWS_REGION        = "${params.AWS_REGION    ?: env.AWS_REGION    ?: 'us-east-1'}"
        EKS_CLUSTER_NAME  = "${params.EKS_CLUSTER_NAME ?: env.EKS_CLUSTER_NAME ?: 'my-eks-cluster'}"
        DOMAIN_NAME       = "${params.DOMAIN_NAME   ?: env.DOMAIN_NAME   ?: 'frontend.example.com'}"
        // IMAGE_TAG is set during the Checkout stage once the commit SHA is known
        IMAGE_TAG         = 'latest'
        IMAGE_NAME        = "${ECR_REGISTRY}/${APP_NAME}"
        HELM_RELEASE_NAME = 'frontend'
        HELM_CHART_PATH   = 'helm/frontend'
        HELM_NAMESPACE    = 'frontend'
    }

    // ── Build parameters (optional runtime overrides) ─────────────────────────
    parameters {
        string(name: 'ECR_REGISTRY',     defaultValue: '', description: 'AWS ECR Registry URL')
        string(name: 'AWS_REGION',       defaultValue: 'us-east-1', description: 'AWS Region')
        string(name: 'EKS_CLUSTER_NAME', defaultValue: 'my-eks-cluster', description: 'EKS Cluster Name')
        string(name: 'DOMAIN_NAME',      defaultValue: 'frontend.example.com', description: 'Domain for Ingress')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip application tests')
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 60, unit: 'MINUTES')
        timestamps()
        disableConcurrentBuilds()
    }

    // ══════════════════════════════════════════════════════════════════════════
    stages {

        // ── 1. Checkout ────────────────────────────────────────────────────────
        stage('Checkout') {
            steps {
                echo "🔀 Checking out main branch…"
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    extensions: [[$class: 'CleanBeforeCheckout']],
                    userRemoteConfigs: scm.userRemoteConfigs
                ])
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                    env.IMAGE_TAG = env.GIT_COMMIT_SHORT
                    echo "Git commit: ${env.GIT_COMMIT_SHORT}"
                }
            }
        }

        // ── 2. Install dependencies & test ────────────────────────────────────
        stage('Install & Test') {
            when {
                expression { return !params.SKIP_TESTS }
            }
            steps {
                dir('app') {
                    echo "📦 Installing Node.js dependencies…"
                    sh 'npm ci --ignore-scripts'
                    echo "🧪 Running tests…"
                    sh 'npm test'
                }
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'app/test-results/**/*.xml'
                }
            }
        }

        // ── 3. Build Docker image ─────────────────────────────────────────────
        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image: ${IMAGE_NAME}:${env.IMAGE_TAG}"
                script {
                    docker.build(
                        "${IMAGE_NAME}:${env.IMAGE_TAG}",
                        "--file app/Dockerfile app"
                    )
                    // Also tag as latest for convenience
                    sh "docker tag ${IMAGE_NAME}:${env.IMAGE_TAG} ${IMAGE_NAME}:latest"
                }
            }
        }

        // ── 4. Scan Docker image with Trivy ───────────────────────────────────
        stage('Scan Image') {
            steps {
                echo "🔍 Scanning image for vulnerabilities with Trivy…"
                script {
                    // Install Trivy if not present on the agent
                    sh '''
                        if ! command -v trivy &> /dev/null; then
                            echo "Installing Trivy…"
                            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
                                | sh -s -- -b /usr/local/bin
                        fi
                    '''

                    // Run Trivy – fail the build on CRITICAL or HIGH vulnerabilities
                    def trivyExitCode = sh(
                        script: """
                            trivy image \
                                --exit-code 1 \
                                --severity CRITICAL,HIGH \
                                --no-progress \
                                --format table \
                                --output trivy-report.txt \
                                ${IMAGE_NAME}:${env.IMAGE_TAG}
                        """,
                        returnStatus: true
                    )

                    // Archive the report regardless of outcome
                    archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true

                    if (trivyExitCode != 0) {
                        error("❌ Trivy found CRITICAL/HIGH vulnerabilities. Review trivy-report.txt and fix before deploying.")
                    } else {
                        echo "✅ No CRITICAL or HIGH vulnerabilities found."
                    }
                }
            }
        }

        // ── 5. Push image to ECR ──────────────────────────────────────────────
        stage('Push to ECR') {
            steps {
                echo "📤 Pushing image to ECR…"
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'AWS_CREDENTIALS',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} \
                            | docker login --username AWS --password-stdin ${ECR_REGISTRY}

                        # Ensure the ECR repository exists
                        aws ecr describe-repositories \
                            --repository-names ${APP_NAME} \
                            --region ${AWS_REGION} 2>/dev/null || \
                        aws ecr create-repository \
                            --repository-name ${APP_NAME} \
                            --region ${AWS_REGION} \
                            --image-scanning-configuration scanOnPush=true \
                            --image-tag-mutability MUTABLE

                        docker push ${IMAGE_NAME}:${env.IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest
                    """
                }
                echo "✅ Image pushed: ${IMAGE_NAME}:${env.IMAGE_TAG}"
            }
        }

        // ── 6. Manual approval gate ───────────────────────────────────────────
        stage('Approval') {
            steps {
                script {
                    def approver = input(
                        id: 'DeployApproval',
                        message: "🚀 Deploy ${IMAGE_NAME}:${env.IMAGE_TAG} to EKS cluster '${EKS_CLUSTER_NAME}'?",
                        ok: 'Approve & Deploy',
                        submitterParameter: 'approver',
                        parameters: [
                            choice(
                                name: 'ENVIRONMENT',
                                choices: ['production', 'staging'],
                                description: 'Target environment'
                            )
                        ]
                    )
                    echo "✅ Deployment approved by: ${approver}"
                }
            }
        }

        // ── 7. Deploy to EKS via Helm ─────────────────────────────────────────
        stage('Deploy to EKS') {
            steps {
                echo "⚙️  Deploying to EKS cluster '${EKS_CLUSTER_NAME}'…"
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'AWS_CREDENTIALS',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh """
                        # Update kubeconfig for the EKS cluster
                        aws eks update-kubeconfig \
                            --region ${AWS_REGION} \
                            --name ${EKS_CLUSTER_NAME}

                        # Ensure the NGINX Ingress Controller is installed
                        helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
                        helm repo update
                        helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
                            --namespace ingress-nginx \
                            --create-namespace \
                            --set controller.service.type=LoadBalancer \
                            --wait \
                            --timeout 5m || true

                        # Create namespace if it does not exist
                        kubectl get namespace ${HELM_NAMESPACE} 2>/dev/null || \
                            kubectl create namespace ${HELM_NAMESPACE}

                        # Deploy / upgrade the frontend application
                        helm upgrade --install ${HELM_RELEASE_NAME} ${HELM_CHART_PATH} \
                            --namespace ${HELM_NAMESPACE} \
                            --create-namespace \
                            --set image.repository=${IMAGE_NAME} \
                            --set image.tag=${env.IMAGE_TAG} \
                            --set ingress.hosts[0].host=${DOMAIN_NAME} \
                            --set ingress.hosts[0].paths[0].path=/ \
                            --set ingress.hosts[0].paths[0].pathType=Prefix \
                            --atomic \
                            --timeout 10m \
                            --wait
                    """
                }
                echo "✅ Deployment complete. App is live at http://${DOMAIN_NAME}"
            }
        }

        // ── 8. Verify deployment ──────────────────────────────────────────────
        stage('Verify Deployment') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'AWS_CREDENTIALS',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh """
                        aws eks update-kubeconfig \
                            --region ${AWS_REGION} \
                            --name ${EKS_CLUSTER_NAME}

                        echo "--- Deployment status ---"
                        kubectl rollout status deployment \
                            --namespace ${HELM_NAMESPACE} \
                            -l app.kubernetes.io/instance=${HELM_RELEASE_NAME} \
                            --timeout=5m

                        echo "--- Pods ---"
                        kubectl get pods --namespace ${HELM_NAMESPACE} -l app.kubernetes.io/instance=${HELM_RELEASE_NAME}

                        echo "--- Ingress ---"
                        kubectl get ingress --namespace ${HELM_NAMESPACE}
                    """
                }
            }
        }

    } // end stages

    // ══════════════════════════════════════════════════════════════════════════
    post {
        always {
            echo "🧹 Cleaning up local Docker images…"
            sh """
                docker rmi ${IMAGE_NAME}:${env.IMAGE_TAG} || true
                docker rmi ${IMAGE_NAME}:latest || true
            """
            cleanWs()
        }
        success {
            echo "🎉 Pipeline succeeded! Image ${IMAGE_NAME}:${env.IMAGE_TAG} deployed to ${EKS_CLUSTER_NAME}."
        }
        failure {
            echo "💥 Pipeline failed. Check the logs above for details."
        }
    }
}
