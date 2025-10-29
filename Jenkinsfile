pipeline {
  agent any

  parameters {
    choice(
      name: 'DEPLOY_ENV',
      choices: ['dev', 'staging', 'prod'],
      description: 'Select the environment to deploy to'
    )
  }

  environment {
    AWS_DEFAULT_REGION = 'us-east-1'
    S3_BUCKET = 'my-terraform-state-bucket'     // ✅ Change to your actual S3 bucket name
    TF_WORKDIR = "environments/${params.DEPLOY_ENV}"
  }

  stages {

    /* -----------------------------
     * GIT CHECKOUT
     * ----------------------------- */
    stage('Checkout') {
      steps {
        echo "📦 Checking out source code..."
        checkout scm
      }
    }

    /* -----------------------------
     * SECRET SCANNING
     * ----------------------------- */
    stage('TruffleHog - Secret Scan') {
      steps {
        echo "🔍 Running TruffleHog secret scan..."
        sh '''
          docker run --rm -v $(pwd):/repo ghcr.io/trufflesecurity/trufflehog:latest \
            filesystem /repo --fail --json > trufflehog-report.json || echo "⚠️ Secrets found — check report"
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'trufflehog-report.json', fingerprint: true
        }
      }
    }

    /* -----------------------------
     * IaC SECURITY SCAN - CHECKOV
     * ----------------------------- */
    stage('Checkov - IaC Security Scan') {
      steps {
        echo "🛡️ Running Checkov on Terraform code..."
        sh '''
          checkov --directory environments/${DEPLOY_ENV} \
                  --output-file-path checkov-report.json \
                  --output json || echo "⚠️ Checkov found issues — review report"
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'checkov-report.json', fingerprint: true
        }
      }
    }

    /* -----------------------------
     * POLICY COMPLIANCE - OPA (CONTFEST)
     * ----------------------------- */
    stage('OPA - Policy Compliance (Conftest)') {
      steps {
        echo "📜 Running Conftest OPA policy checks..."
        sh '''
          docker run --rm -v $(pwd):/project openpolicyagent/conftest \
            test /project/environments/${DEPLOY_ENV} \
            --policy /project/policy \
            --output json > opa-report.json || echo "⚠️ OPA policy violations found — review report"
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'opa-report.json', fingerprint: true
        }
      }
    }

    /* -----------------------------
     * TERRAFORM INIT
     * ----------------------------- */
    stage('Terraform Init') {
      steps {
        echo "🔧 Initializing Terraform in ${TF_WORKDIR}..."
        dir("${TF_WORKDIR}") {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
            sh 'terraform init -input=false'
          }
        }
      }
    }

    /* -----------------------------
     * TERRAFORM VALIDATE
     * ----------------------------- */
    stage('Terraform Validate') {
      steps {
        echo "✅ Validating Terraform configuration..."
        dir("${TF_WORKDIR}") {
          sh 'terraform validate'
        }
      }
    }

    /* -----------------------------
     * TERRAFORM PLAN
     * ----------------------------- */
    stage('Terraform Plan') {
      steps {
        echo "📋 Running Terraform plan for ${DEPLOY_ENV}..."
        dir("${TF_WORKDIR}") {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
            sh '''
              terraform plan -out=tfplan -input=false
              terraform show -no-color tfplan > tfplan.txt
            '''
          }
        }
      }
    }

    /* -----------------------------
     * MANUAL APPROVAL
     * ----------------------------- */
    stage('Manual Approval') {
      steps {
        input message: "✅ Approve deployment to ${params.DEPLOY_ENV} environment?"
      }
    }

    /* -----------------------------
     * TERRAFORM APPLY
     * ----------------------------- */
    stage('Terraform Apply') {
      steps {
        echo "🚀 Applying Terraform changes..."
        dir("${TF_WORKDIR}") {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
            sh '''
              terraform apply -auto-approve tfplan
              terraform output -json > outputs.json
            '''
          }
        }
      }
    }
  }

  /* -----------------------------
   * POST-STAGE REPORT ARCHIVING
   * ----------------------------- */
  post {
    always {
      echo "🧾 Archiving Terraform artifacts..."
      archiveArtifacts artifacts: "${TF_WORKDIR}/tfplan.txt, ${TF_WORKDIR}/outputs.json, trufflehog-report.json, checkov-report.json, opa-report.json", fingerprint: true
    }
    success {
      echo "✅ Terraform deployment completed successfully for ${params.DEPLOY_ENV}!"
    }
    failure {
      echo "❌ Terraform pipeline failed for ${params.DEPLOY_ENV}!"
    }
  }
}

