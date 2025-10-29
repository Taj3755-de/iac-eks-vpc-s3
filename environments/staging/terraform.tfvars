
region = "us-east-1"

tags = {
  Project = "infra"
  Env     = "staging"
}

# VPC settings
vpc_cidr = "10.20.0.0/16"
az_count = 2

# EKS settings
cluster_name    = "staging-eks"
cluster_version = "1.29"
desired_size    = 2
min_size        = 1
max_size        = 3
instance_types  = ["t3.medium"]
disk_size       = 20
endpoint_public_access  = true
endpoint_private_access = true
