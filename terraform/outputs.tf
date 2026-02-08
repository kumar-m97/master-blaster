# Outputs - outputs.tf

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# IAM Outputs
output "cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = module.iam.cluster_role_arn
}

output "cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  value       = module.iam.cluster_role_name
}

output "node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = module.iam.node_role_arn
}

output "node_role_name" {
  description = "Name of the EKS node IAM role"
  value       = module.iam.node_role_name
}

# Security Groups Outputs
output "control_plane_security_group_id" {
  description = "ID of the control plane security group"
  value       = module.security_groups.control_plane_security_group_id
}

output "worker_node_security_group_id" {
  description = "ID of the worker node security group"
  value       = module.security_groups.worker_node_security_group_id
}

# EKS Cluster Outputs
output "cluster_id" {
  description = "The ID/name of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = module.eks.cluster_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "node_group_id" {
  description = "EKS node group ID"
  value       = module.eks.node_group_id
}

# Backend Configuration Outputs
output "backend_config_example" {
  description = "Example backend configuration for terraform init"
  value = {
    bucket         = "eks-terraform-state-XXXXXXXXXXXX"
    key            = "eks/terraform.tfstate"
    region         = var.aws_region
    encrypt        = true
    dynamodb_table = "eks-cluster-terraform-lock"
  }
}
