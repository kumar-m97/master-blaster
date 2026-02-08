# EKS Cluster Provisioning - main.tf
# This file orchestrates all modules to provision a complete EKS cluster

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    # Backend configuration will be added during terraform init
    # Use: terraform init -backend-config=backend-config.hcl
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      CreatedBy   = "Terraform"
      ManagedBy   = "Terraform-Modules"
    }
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr                  = var.vpc_cidr
  cluster_name              = var.cluster_name
  availability_zones_count  = var.availability_zones_count
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  cluster_name = var.cluster_name
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security_groups"

  cluster_name = var.cluster_name
  vpc_id       = module.vpc.vpc_id
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  cluster_name     = var.cluster_name
  cluster_version  = var.cluster_version
  environment      = var.environment

  # VPC Configuration
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  # IAM Configuration
  cluster_role_arn = module.iam.cluster_role_arn
  node_role_arn    = module.iam.node_role_arn

  # Security Group Configuration
  control_plane_security_group_id = module.security_groups.control_plane_security_group_id
  worker_node_security_group_id   = module.security_groups.worker_node_security_group_id

  # Node Configuration
  node_desired_size             = var.node_desired_size
  node_max_size                 = var.node_max_size
  node_min_size                 = var.node_min_size
  node_instance_types           = var.node_instance_types
  node_disk_size                = var.node_disk_size
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  log_retention_days            = var.log_retention_days

  # Dependencies
  cluster_role_policy_dependencies = [
    aws_iam_role_policy_attachment.eks_cluster_policy.id,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller.id
  ]
  node_role_policy_dependencies = [
    aws_iam_role_policy_attachment.eks_worker_node_policy.id,
    aws_iam_role_policy_attachment.eks_cni_policy.id,
    aws_iam_role_policy_attachment.eks_ecr_policy.id,
    aws_iam_role_policy_attachment.eks_cloudwatch_policy.id
  ]
}

# Attach the EKS Cluster Policy (dependency handling)
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = module.iam.cluster_role_name
}

# Attach the VPC Resource Controller Policy
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = module.iam.cluster_role_name
}

# Attach the EKS Worker Node Policy
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = module.iam.node_role_name
}

# Attach the EKS CNI Policy
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = module.iam.node_role_name
}

# Attach the EC2 Container Registry Policy
resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = module.iam.node_role_name
}

# Attach CloudWatch Logs Policy
resource "aws_iam_role_policy_attachment" "eks_cloudwatch_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = module.iam.node_role_name
}
