# Backend Configuration - outputs.tf

output "s3_bucket_name" {
  description = "Name of the S3 bucket storing Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "terraform_backend_config" {
  description = "Backend configuration for terraform init"
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    key            = "eks/terraform.tfstate"
    region         = aws_s3_bucket.terraform_state.region
    encrypt        = true
    dynamodb_table = aws_dynamodb_table.terraform_lock.name
  }
}
