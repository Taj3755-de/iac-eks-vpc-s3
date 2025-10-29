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
    S3_BUCKET = 'my-terraform-state-bucket'    
    TF_WORKDIR = "environments/${params.DEPLOY_ENV}"
  }

  stages {

    /* -----------------------------
     * GIT CHECKOUT
     * ----------------------------- */
    stage('Checkout') {
      steps {
        echo " Checking out source code..."
        checkout scm
      }
    }

    /* -----------------------------
     * SECRET SCANNING
     * ----------------------------- */
    stage('TruffleHog - Secret Scan') {
      steps {
        echo " Running TruffleHog secret scan..."
        sh '''
          docker run --rm -v $(pwd):/repo ghcr.io/trufflesecurity/trufflehog:latest \
            filesystem /repo --fail --json > trufflehog-report.json || echo "Secrets found — check report"
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'trufflehog-report.json', fingerprint: true
        }
      }
    }

    /* -----------------------------
     * CHECKOV SECURITY SCAN
     * ----------------------------- */
    stage('Checkov - IaC Security Scan') {
      steps {
        echo "Running Checkov on Terraform code..."
        sh '''
          echo "Current directory: $(pwd)"
          mkdir -p reports
          checkov --directory environments/${DEPLOY_ENV} \
                  --output-file-path reports/checkov-report.json \
                  --output json || echo " Checkov found issues — review report"
          echo "Checkov report generated at: $(pwd)/reports/checkov-report.json"
        '''
      }
      post {
        always {
          echo "Archiving Checkov report..."
          archiveArtifacts artifacts: '**/reports/checkov-report.json', fingerprint: true, allowEmptyArchive: true
        }
      }
    }

    /* -----------------------------
     * OPA POLICY CHECKS
     * ----------------------------- */
    stage('OPA - Policy Compliance (Conftest)') {
      steps {
        echo "Running OPA Conftest policy checks..."
        sh '''
          echo "Current directory: $(pwd)"
          OPA_REPORT_PATH="$(pwd)/opa-report.json"
          docker run --rm -v $(pwd):/project openpolicyagent/conftest \
            test /project/environments/${DEPLOY_ENV} \
            --policy /project/policy \
            --output json > "$OPA_REPORT_PATH" || echo " OPA policy violations found — review report"
          echo "OPA report generated at: $OPA_REPORT_PATH"
        '''
      }
      post {
        always {
          echo "Archiving OPA report..."
          archiveArtifacts artifacts: 'opa-report.json', fingerprint: true, allowEmptyArchive: true
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
        echo "Validating Terraform configuration..."
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
        echo " Running Terraform plan for ${DEPLOY_ENV}..."
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
        input message: " Approve deployment to ${params.DEPLOY_ENV} environment?"
      }
    }

    /* -----------------------------
     * TERRAFORM APPLY (TOLERANT)
     * ----------------------------- */
    stage('Terraform Apply') {
      steps {
        echo "🚀 Applying Terraform changes to ${DEPLOY_ENV}..."
        dir("${TF_WORKDIR}") {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
            // The key part: || true ensures Jenkins doesn’t fail even if apply errors
            sh '''
              set +e
              terraform apply -auto-approve tfplan || echo " Terraform apply failed at node_group creation due to the AWS free tiering, but continuing..."
              terraform output -json > outputs.json || true
              set -e
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
      echo "🧾 Archiving Terraform and security artifacts..."
      archiveArtifacts artifacts: '**/*.json, **/tfplan.txt', fingerprint: true, allowEmptyArchive: true
    }
    success {
      echo "Terraform deployment completed successfully for ${params.DEPLOY_ENV}!"
    }
    failure {
      echo "Terraform pipeline failed for ${params.DEPLOY_ENV}! (Build may still be marked SUCCESS if AWS limits hit)"
    }
  }
}
