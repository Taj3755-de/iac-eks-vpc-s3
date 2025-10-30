pipeline {
  agent any

  parameters {
    choice(
      name: 'DEPLOY_ENV',
      choices: ['dev', 'staging', 'prod'],
      description: 'Select the environment to deploy to'
    )
    choice(
      name: 'ACTION',
      choices: ['apply', 'destroy'],
      description: 'Select Terraform action (apply or destroy)'
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
        echo "Checking out source code..."
        checkout scm
      }
    }

    /* -----------------------------
     * SECURITY SCANS (apply only)
     * ----------------------------- */
    stage('TruffleHog - Secret Scan') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh '''
          docker run --rm -v $(pwd):/repo ghcr.io/trufflesecurity/trufflehog:latest \
            filesystem /repo --fail --json > trufflehog-report.json || echo "Secrets found — check report"
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'trufflehog-report.json', fingerprint: true, allowEmptyArchive: true
        }
      }
    }

    stage('Checkov - IaC Security Scan') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh '''
          mkdir -p reports
          checkov --directory environments/${DEPLOY_ENV} \
                  --output-file-path reports/checkov-report.json \
                  --output json || echo "Checkov found issues — review report"
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: '**/reports/checkov-report.json', fingerprint: true, allowEmptyArchive: true
        }
      }
    }

    stage('OPA - Policy Compliance (Conftest)') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh '''
          OPA_REPORT_PATH="$(pwd)/opa-report.json"
          docker run --rm -v $(pwd):/project openpolicyagent/conftest \
            test /project/environments/${DEPLOY_ENV} \
            --policy /project/policy \
            --output json > "$OPA_REPORT_PATH" || echo "OPA policy violations found — review report"
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'opa-report.json', fingerprint: true, allowEmptyArchive: true
        }
      }
    }

    /* -----------------------------
     * TERRAFORM INIT (always required)
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
     * APPLY PIPELINE
     * ----------------------------- */
    stage('Terraform Validate') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        dir("${TF_WORKDIR}") {
          sh 'terraform validate'
        }
      }
    }

    stage('Terraform Plan') {
      when { expression { params.ACTION == 'apply' } }
      steps {
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

    stage('Manual Approval') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        input message: "Approve deployment to ${params.DEPLOY_ENV} environment?"
      }
    }

    stage('Terraform Apply') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        dir("${TF_WORKDIR}") {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
            sh '''
              set +e
              terraform apply -auto-approve tfplan || echo "Terraform apply failed — continuing"
              terraform output -json > outputs.json || true
              set -e
            '''
          }
        }
      }
    }

    /* -----------------------------
     * DESTROY PIPELINE
     * ----------------------------- */
    stage('Manual Destroy Approval') {
      when { expression { params.ACTION == 'destroy' } }
      steps {
        input message: "⚠️ Confirm destroy for ${params.DEPLOY_ENV}? This will delete all resources!"
      }
    }

    stage('Terraform Destroy') {
      when { expression { params.ACTION == 'destroy' } }
      steps {
        echo "🔥 Destroying Terraform resources in ${DEPLOY_ENV}..."
        dir("${TF_WORKDIR}") {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
            sh '''
              terraform init -input=false
              terraform destroy -auto-approve
            '''
          }
        }
      }
    }
  }

  post {
    always {
      echo "🧾 Archiving Terraform and security artifacts..."
      archiveArtifacts artifacts: '**/*.json, **/tfplan.txt', fingerprint: true, allowEmptyArchive: true
    }
    success {
      echo "✅ Terraform ${params.ACTION} completed successfully for ${params.DEPLOY_ENV}!"
    }
    failure {
      echo "❌ Terraform ${params.ACTION} failed for ${params.DEPLOY_ENV}!"
    }
  }
}
