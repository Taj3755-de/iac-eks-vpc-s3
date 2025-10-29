
# Terraform AWS VPC + EKS (Modular) with S3 Backend and Env Separation (us-east-1)

This package is configured **entirely for `us-east-1` (N. Virginia)**.

- VPC with public/private subnets (IGW, NAT)
- EKS cluster + managed node group with IAM roles
- S3 bucket + DynamoDB table for Terraform remote state (bootstrap)
- Environment separation: `dev`, `staging`, `prod`
- Version pinning and reusable modules
- Backends use `use_lockfile = true` (no deprecated `dynamodb_table` in backend)

## Requirements
- Terraform >= 1.5
- AWS provider `~> 5.0`
- AWS credentials with permissions for S3, DynamoDB, EKS, EC2, IAM in `us-east-1`

## Quick Start

1. **Pick a globally-unique S3 bucket name** for Terraform state, e.g. `tajudeen-tf-state-us-east-1-123abc`.
2. Edit the bootstrap tfvars:
   ```bash
   cd environments/bootstrap
   # open terraform.tfvars and set bucket_name and region = "us-east-1"
   terraform init
   terraform apply -auto-approve
   ```
3. Stamp the same bucket name & region into all env backends:
   ```bash
   cd ../..
   ./scripts/set-backend.sh tajudeen-tf-state-us-east-1-123abc us-east-1
   ```
4. Deploy an environment (e.g., dev):
   ```bash
   cd environments/dev
   terraform init
   terraform apply
   ```

Destroy when done:
```bash
terraform destroy
```

## Structure
```
modules/        # vpc, eks, s3-backend
environments/   # bootstrap, dev, staging, prod
scripts/        # helper to stamp backend bucket & region
```

## Notes
- Backend `s3` blocks are hard-coded; use `scripts/set-backend.sh` after bootstrap.
- VPC uses a **single NAT Gateway** by default. Change via module input if needed.
- EKS endpoint allows both public & private access by default; tune via variables.
