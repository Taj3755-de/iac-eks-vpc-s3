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
    AWS_DEFAULT_REGION = 'us-east-1'               // Adjust as needed
    S3_BUCKET = 'my-terraform-state-bucket'        // Change to your S3 bucket name
    TF_WORKDIR = "environments/${params.DEPLOY_ENV}"
  }

  stages {

    stage('Init') {
      steps {
        echo "🔧 Initializing Terraform in ${TF_WORKDIR}..."
        dir("${TF_WORKDIR}") {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
            sh '''
              terraform init -input=false
            '''
          }
        }
      }
    }

    stage('Validate') {
      steps {
        echo "✅ Validating Terraform configuration..."
        dir("${TF_WORKDIR}") {
          sh 'terraform validate'
        }
      }
    }

    stage('Plan') {
      steps {
        echo "📋 Running Terraform plan for ${DEPLOY_ENV}..."
        dir("${TF_WORKDIR}") {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
            sh '''
              terraform plan -out=tfplan -input=false
              terraform show -no-color tfplan > tfplan.txt
              echo "📤 Uploading plan file to S3..."
              aws s3 cp tfplan.txt s3://${S3_BUCKET}/plans/${DEPLOY_ENV}/${JOB_NAME}-${BUILD_NUMBER}.txt
            '''
          }
        }
      }
    }

    stage('Manual Approval') {
      steps {
        input message: "✅ Approve deployment to ${DEPLOY_ENV} environment?"
      }
    }

    stage('Apply') {
      steps {
        echo "🚀 Applying Terraform changes to ${DEPLOY_ENV}..."
        dir("${TF_WORKDIR}") {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
            sh '''
              terraform apply -auto-approve tfplan
              terraform output -json > outputs.json
              echo "📤 Uploading outputs to S3..."
              aws s3 cp outputs.json s3://${S3_BUCKET}/outputs/${DEPLOY_ENV}/${JOB_NAME}-${BUILD_NUMBER}.json
            '''
          }
        }
      }
    }
  }

  post {
    always {
      echo "🧾 Archiving Terraform artifacts..."
      archiveArtifacts artifacts: "${TF_WORKDIR}/tfplan.txt, ${TF_WORKDIR}/outputs.json", fingerprint: true
    }
    success {
      echo "✅ Terraform deployment completed successfully for ${DEPLOY_ENV}!"
    }
    failure {
      echo "❌ Terraform pipeline failed for ${DEPLOY_ENV}!"
    }
  }
}
