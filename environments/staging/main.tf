
module "vpc" {
  source             = "../../modules/vpc"
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  single_nat_gateway = true
  tags               = merge(var.tags, { Env = terraform.workspace })
}

module "eks" {
  source                  = "../../modules/eks"
  cluster_name            = var.cluster_name
  cluster_version         = var.cluster_version
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  desired_size            = var.desired_size
  min_size                = var.min_size
  max_size                = var.max_size
  instance_types          = var.instance_types
  disk_size               = var.disk_size
  endpoint_public_access  = var.endpoint_public_access
  endpoint_private_access = var.endpoint_private_access
  tags                    = merge(var.tags, { Env = terraform.workspace })
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "node_group_name" {
  value = module.eks.node_group_name
}
