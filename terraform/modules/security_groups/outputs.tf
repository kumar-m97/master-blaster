# Security Groups Module - outputs.tf

output "control_plane_security_group_id" {
  description = "ID of the control plane security group"
  value       = aws_security_group.control_plane.id
}

output "worker_node_security_group_id" {
  description = "ID of the worker node security group"
  value       = aws_security_group.worker_node.id
}
