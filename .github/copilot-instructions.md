<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

## Terraform AWS EKS Cluster Project

### Project Overview
This workspace contains a Terraform project for provisioning a production-ready Amazon EKS (Elastic Kubernetes Service) cluster on AWS, including all necessary networking, IAM roles, and security configurations.

### Project Structure
- `terraform/` - Terraform configuration files
  - `vpc.tf` - VPC and networking resources
  - `eks.tf` - EKS cluster configuration
  - `iam.tf` - IAM roles and policies
  - `security_groups.tf` - Security group configurations
  - `variables.tf` - Input variables
  - `outputs.tf` - Output values
  - `main.tf` - Provider configuration
  - `terraform.tfvars` - Variable values (to be customized)

### Setup Instructions
1. Ensure Terraform is installed (v1.0+)
2. Configure AWS credentials (AWS CLI, environment variables, or IAM role)
3. Customize `terraform/terraform.tfvars` with your values
4. Run `terraform init` to initialize the working directory
5. Run `terraform plan` to preview changes
6. Run `terraform apply` to create resources

### Requirements
- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- AWS account with sufficient permissions

### Key Features
- Highly available EKS cluster across multiple AZs
- Auto Scaling Group for worker nodes
- VPC with public and private subnets
- NAT Gateway for private subnet internet access
- Security groups with proper ingress/egress rules
- Output of cluster endpoint and kubeconfig data
