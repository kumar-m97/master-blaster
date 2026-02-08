# AWS EKS Cluster Terraform Project

This Terraform project provisions a production-ready Amazon EKS (Elastic Kubernetes Service) cluster on AWS using **reusable Terraform modules** with remote state management. The infrastructure is organized into modular components for easy maintenance and scalability.

## Features

- **Modular Architecture**: Reusable modules for VPC, EKS, IAM, and Security Groups
- **Remote State Management**: S3 backend with DynamoDB locking for safe state management
- **Highly Available EKS Cluster**: Multi-AZ deployment across availability zones
- **VPC with Public and Private Subnets**: Properly segmented networking with NAT gateways
- **Auto Scaling Worker Nodes**: Managed node group with configurable scaling
- **Security Best Practices**:
  - Security groups with proper ingress/egress rules
  - Private worker nodes with NAT gateway access
  - OIDC provider for IAM Roles for Service Accounts (IRSA)
  - CloudWatch logging for cluster events
- **Comprehensive Outputs**: All resource details for downstream integration

## Project Structure

```
master-blaster/
├── README.md                          # This file
└── terraform/
    ├── main.tf                        # Module orchestration
    ├── variables.tf                   # Input variables
    ├── outputs.tf                     # Output values
    ├── terraform.tfvars               # Variable values (customize before deployment)
    ├── backend-config.hcl.example     # Backend configuration example
    ├── modules/                       # Reusable Terraform modules
    │   ├── vpc/
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   ├── iam/
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   ├── security_groups/
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   └── eks/
    │       ├── main.tf
    │       ├── variables.tf
    │       └── outputs.tf
    └── backend/                       # Terraform backend resources
        ├── main.tf                    # S3 bucket and DynamoDB table
        ├── variables.tf
        ├── outputs.tf
        ├── provider.tf
        └── terraform.tfvars.example   # Backend configuration example
```

## Prerequisites

1. **Terraform**: Version >= 1.0
   - Install from [terraform.io](https://www.terraform.io/downloads.html)

2. **AWS CLI**: Configured with appropriate credentials
   ```bash
   aws configure
   ```
   OR set environment variables:
   ```bash
   export AWS_ACCESS_KEY_ID="your_access_key"
   export AWS_SECRET_ACCESS_KEY="your_secret_key"
   export AWS_DEFAULT_REGION="us-east-1"
   ```

3. **kubectl**: For managing the Kubernetes cluster
   - Install from [kubernetes.io](https://kubernetes.io/docs/tasks/tools/)

4. **AWS Account**: With sufficient permissions to create EKS, VPC, and IAM resources

4. **AWS Account**: With appropriate permissions to create EKS, VPC, IAM resources

## Setup Instructions

### Step 1: Configure Backend Resources (One-time setup)

The backend configuration stores your Terraform state securely in S3 with DynamoDB locking.

1. **Customize backend variables**:
   ```bash
   cd terraform/backend
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars and replace XXXXXXXXXXXX with your AWS Account ID
   ```

2. **Initialize and deploy backend resources**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Note the outputs** - You'll need these values for the next step:
   - S3 bucket name
   - DynamoDB table name

### Step 2: Configure EKS Cluster Terraform

1. **Create backend configuration**:
   ```bash
   cd ../  # Go back to terraform/ directory
   cp backend-config.hcl.example backend-config.hcl
   # Edit backend-config.hcl with the values from backend outputs
   ```

2. **Customize cluster variables**:
   ```bash
   cp terraform.tfvars terraform.tfvars
   # Edit terraform.tfvars with your desired cluster settings
   ```

   Example configuration:
   ```hcl
   aws_region             = "us-east-1"
   environment            = "dev"
   project_name           = "eks-cluster"
   cluster_name           = "my-eks-cluster"
   cluster_version        = "1.27"
   vpc_cidr               = "10.0.0.0/16"
   availability_zones_count = 2
   node_desired_size      = 2
   node_max_size          = 4
   node_min_size          = 1
   node_instance_types    = ["t3.medium"]
   ```

### Step 3: Deploy EKS Cluster

1. **Initialize Terraform** with backend configuration:
   ```bash
   terraform init -backend-config=backend-config.hcl
   ```

2. **Validate configuration**:
   ```bash
   terraform validate
   ```

3. **Plan changes**:
   ```bash
   terraform plan -out=tfplan
   ```

4. **Apply configuration**:
   ```bash
   terraform apply tfplan
   ```

   This typically takes 10-15 minutes. You'll see updates for each module (VPC, IAM, Security Groups, EKS).

### Step 4: Verify and Access Cluster

1. **Update kubeconfig**:
   ```bash
   aws eks update-kubeconfig \
     --region us-east-1 \
     --name my-eks-cluster
   ```

2. **Verify cluster access**:
   ```bash
   kubectl cluster-info
   kubectl get nodes
   kubectl get pods -A
   ```

3. **View cluster outputs**:
   ```bash
   terraform output
   ```

## Module Architecture

The project uses the following modules:

### VPC Module (`modules/vpc/`)
Creates and manages:
- VPC with customizable CIDR block
- Public subnets (internet-accessible)
- Private subnets (NAT-accessible)
- Internet Gateway
- NAT Gateways (for egress)
- Route tables and associations

**Key inputs**: `vpc_cidr`, `cluster_name`, `availability_zones_count`

### IAM Module (`modules/iam/`)
Creates and manages:
- EKS cluster role with necessary policies
- EKS node group role with necessary policies
- Instance profile for worker nodes

**Key inputs**: `cluster_name`

### Security Groups Module (`modules/security_groups/`)
Creates and manages:
- Control plane security group
- Worker node security group
- Ingress/egress rules for cluster communication

**Key inputs**: `cluster_name`, `vpc_id`

### EKS Module (`modules/eks/`)
Creates and manages:
- EKS cluster
- Managed node group
- OIDC provider for IRSA
- CloudWatch log group

**Key inputs**: All the above module outputs + scaling configuration

## Configuration Variables

Key variables in `terraform.tfvars`:

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `environment` | Environment name | `dev` |
| `project_name` | Project name for tagging | `eks-cluster` |
| `cluster_name` | EKS cluster name | `my-eks-cluster` |
| `cluster_version` | Kubernetes version | `1.27` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `availability_zones_count` | Number of AZs | `2` |
| `node_desired_size` | Desired worker nodes | `2` |
| `node_max_size` | Max worker nodes | `4` |
| `node_min_size` | Min worker nodes | `1` |
| `node_instance_types` | Worker node instance types | `["t3.medium"]` |
| `cluster_endpoint_public_access_cidrs` | Public API access | `["0.0.0.0/0"]` |

## Useful Commands

### View all resources
```bash
terraform state list
```

### View specific resource details
```bash
terraform state show module.eks.aws_eks_cluster.main
```

### Destroy all resources (use with caution)
```bash
terraform destroy
```

### Get specific outputs
```bash
terraform output cluster_endpoint
terraform output cluster_id
terraform output oidc_provider_arn
```

## Troubleshooting

### Backend state issues
If you encounter state lock issues:
```bash
terraform force-unlock <LOCK_ID>
```

### Module issues
Review module documentation:
```bash
terraform validate
terraform fmt -recursive
```

### AWS credential issues
Verify AWS credentials:
```bash
aws sts get-caller-identity
```

## Cost Considerations

- **EKS Cluster**: $0.10 per hour (~$73/month)
- **EC2 Nodes**: Cost depends on instance type (t3.medium ~$30/month each)
- **NAT Gateway**: $32/month + data transfer costs
- **S3 & DynamoDB**: Minimal for state management

## Security Notes

- **State File**: Stored in S3 with encryption enabled
- **Cluster Access**: Default allows 0.0.0.0/0 - restrict in production
- **Private Nodes**: Worker nodes are in private subnets
- **IRSA**: OIDC provider enabled for fine-grained IAM permissions

## Support and Contributions

For issues or improvements, please check:
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Terraform Best Practices](https://www.terraform.io/language/files)

## Destroying Resources

To tear down all resources:

```bash
cd terraform
terraform destroy
```

Then clean up backend resources:

```bash
cd terraform/backend
terraform destroy
```

**Note**: This will delete the EKS cluster, VPC, and all associated resources. Ensure you've backed up any important data first.To remove all AWS resources created by this Terraform project:

```bash
terraform destroy
```

**Warning**: This will delete the EKS cluster and all associated resources. Ensure you have backed up any critical data.

## Variables

### Required Variables
- None (all variables have defaults)

### Important Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | us-east-1 |
| `environment` | Environment name | dev |
| `cluster_name` | EKS cluster name | my-eks-cluster |
| `cluster_version` | Kubernetes version | 1.27 |
| `vpc_cidr` | VPC CIDR block | 10.0.0.0/16 |
| `node_desired_size` | Desired worker nodes | 2 |
| `node_max_size` | Maximum worker nodes | 4 |
| `node_min_size` | Minimum worker nodes | 1 |
| `node_instance_types` | EC2 instance types | ["t3.medium"] |
| `enable_vpc_endpoint` | Enable VPC endpoints | true |

## Outputs

After deployment, Terraform will output:

- `cluster_endpoint` - EKS control plane endpoint
- `cluster_id` - EKS cluster ID
- `cluster_certificate_authority_data` - CA certificate for kubectl
- `node_group_id` - EKS node group ID
- `vpc_id` - VPC ID
- `public_subnet_ids` - Public subnet IDs
- `private_subnet_ids` - Private subnet IDs
- `kubeconfig` - Base64-encoded kubeconfig (sensitive)

## Troubleshooting

### Cluster creation fails
- Check AWS credentials: `aws sts get-caller-identity`
- Verify AWS account limits and quotas
- Review Terraform errors for specific resource issues

### kubectl cannot connect to cluster
- Ensure kubeconfig is properly configured
- Verify security groups allow your network access
- Check CloudWatch logs for cluster errors

### Worker nodes not joining cluster
- Verify IAM role permissions
- Check node group status: `aws eks describe-nodegroup`
- Review EC2 console for instance issues

## Cost Optimization

To reduce costs:

1. **Adjust node instance types**: Change `node_instance_types` to smaller instances
2. **Reduce node count**: Lower `node_desired_size`
3. **Use spot instances**: Modify launch template for spot instances
4. **Enable cluster autoscaling**: Implement Kubernetes Cluster Autoscaler
5. **Delete unused resources**: Run `terraform destroy` when not needed

## Security Considerations

- **Public Access**: Update `public_access_cidrs` in `vpc_config` to restrict cluster access
- **Network Policy**: Implement Calico or other network policies for pod-to-pod security
- **RBAC**: Configure proper Kubernetes RBAC policies
- **Secrets**: Use AWS Secrets Manager or HashiCorp Vault for secrets
- **Monitoring**: Enable CloudWatch Container Insights for observability

## Support and Contribution

For issues or improvements, please refer to the project documentation or contact your DevOps team.

## License

This Terraform configuration is provided as-is for AWS EKS cluster provisioning.
