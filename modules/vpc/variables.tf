
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC (e.g., 10.10.0.0/16)"
}

variable "az_count" {
  type        = number
  description = "Number of AZs to use"
  default     = 2
}

variable "subnet_newbits" {
  type        = number
  description = "Newbits for cidrsubnet when creating subnets (e.g., 8 => /24 from /16)"
  default     = 8
}

variable "single_nat_gateway" {
  type        = bool
  description = "Create only one NAT Gateway to save cost"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Common resource tags"
  default     = {}
}
