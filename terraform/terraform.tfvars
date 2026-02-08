# AWS Configuration
aws_region = "us-east-1"

# General
environment  = "dev"
project_name = "eks-cluster"

# VPC Configuration
vpc_cidr                  = "10.0.0.0/16"
availability_zones_count  = 2

# EKS Cluster Configuration
cluster_name     = "my-eks-cluster"
cluster_version  = "1.27"

# Node Group Configuration
node_desired_size       = 2
node_max_size           = 4
node_min_size           = 1
node_instance_types     = ["t3.medium"]
node_disk_size          = 20

# Cluster Access
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # Restrict this in production

# Logging
log_retention_days = 7
