
terraform {
  backend "s3" {
    bucket        = "tajudeen-tf-state-us-east-1"
    key           = "staging/terraform.tfstate"
    region        = "us-east-1"
    encrypt       = true
    use_lockfile  = true
  }
}
