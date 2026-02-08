# EKS Module - variables.tf

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.27"
}

variable "cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  type        = string
}

variable "cluster_role_policy_dependencies" {
  description = "Policy attachment dependencies for cluster role"
  type        = any
}

variable "node_role_arn" {
  description = "ARN of the EKS node IAM role"
  type        = string
}

variable "node_role_policy_dependencies" {
  description = "Policy attachment dependencies for node role"
  type        = any
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "control_plane_security_group_id" {
  description = "ID of the control plane security group"
  type        = string
}

variable "worker_node_security_group_id" {
  description = "ID of the worker node security group"
  type        = string
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_instance_types" {
  description = "List of instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_disk_size" {
  description = "Disk size for worker nodes in GiB"
  type        = number
  default     = 20
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "log_retention_days" {
  description = "Number of days to retain EKS cluster logs"
  type        = number
  default     = 7
}
