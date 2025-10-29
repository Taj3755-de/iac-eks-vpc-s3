
variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket for Terraform state"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Name of the DynamoDB table for state locking"
}

variable "tags" {
  type    = map(string)
  default = {}
}
