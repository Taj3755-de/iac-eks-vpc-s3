pipeline {
  agent any
  environment { AWS_REGION = 'us-east-1' ; TF_WORKDIR = "environments/${params.ENVIRONMENT}" }
  stages {
    stage('Init') {
      steps {
        dir("${TF_WORKDIR}") {
          withCredentials([[$class:'AmazonWebServicesCredentialsBinding', credentialsId:'aws-creds']]) {
            sh 'terraform init -input=false'
          }
        }
      }
    }

    stage('Plan') {
      steps {
        dir("${TF_WORKDIR}") {
          withCredentials([[$class:'AmazonWebServicesCredentialsBinding', credentialsId:'aws-creds']]) {
            sh '''
              terraform plan -out=tfplan -input=false
              terraform show -no-color tfplan > tfplan.txt
              aws s3 cp tfplan.txt s3://my-terraform-state-bucket/plans/${JOB_NAME}-${BUILD_NUMBER}.txt
            '''
          }
        }
      }
    }

    stage('Apply (manual)') {
      steps {
        input message: "Approve apply?"
        dir("${TF_WORKDIR}") {
          withCredentials([[$class:'AmazonWebServicesCredentialsBinding', credentialsId:'aws-creds']]) {
            sh 'terraform apply -auto-approve tfplan'
            sh 'terraform output -json > outputs.json'
            sh 'aws s3 cp outputs.json s3://my-terraform-state-bucket/outputs/${JOB_NAME}-${BUILD_NUMBER}.json'
          }
        }
      }
    }
  }
}
