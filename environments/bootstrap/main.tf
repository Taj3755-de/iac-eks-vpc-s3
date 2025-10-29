
module "backend" {
  source              = "../../modules/s3-backend"
  bucket_name         = var.bucket_name
  dynamodb_table_name = var.dynamodb_table_name
  tags                = var.tags
}

output "bucket_name" {
  value = module.backend.bucket_name
}

output "dynamodb_table_name" {
  value = module.backend.dynamodb_table_name
}
