
variable "region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

# VPC
variable "vpc_cidr" {
  type = string
}

variable "az_count" {
  type    = number
  default = 2
}

# EKS
variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type    = string
  default = "1.29"
}

variable "desired_size" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 3
}

variable "instance_types" {
  type    = list(string)
  default = ["t3.micro"]
}

variable "disk_size" {
  type    = number
  default = 20
}

variable "endpoint_public_access" {
  type    = bool
  default = true
}

variable "endpoint_private_access" {
  type    = bool
  default = true
}
