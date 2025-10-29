
region              = "us-east-1"
# !! Change to a globally-unique bucket name !!
bucket_name         = "tajudeen-tf-state-us-east-1-CHANGE-ME"
dynamodb_table_name = "infra-tf-lock-shared"
tags = {
  Project = "infra"
  Env     = "bootstrap"
}
