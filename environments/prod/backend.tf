
terraform {
  backend "s3" {
    bucket        = "tajudeen-tf-state-us-east-1-CHANGE-ME"
    key           = "prod/terraform.tfstate"
    region        = "us-east-1"
    encrypt       = true
    use_lockfile  = true
  }
}
