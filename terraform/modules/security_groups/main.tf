# Security Groups Module - main.tf

# Control Plane Security Group
resource "aws_security_group" "control_plane" {
  name_prefix = "${var.cluster_name}-control-plane-"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.cluster_name}-control-plane-sg"
  }
}

# Control Plane Security Group - Allow inbound HTTPS from worker nodes
resource "aws_vpc_security_group_ingress_rule" "control_plane_https" {
  description                   = "Allow inbound HTTPS from worker nodes"
  from_port                     = 443
  to_port                       = 443
  ip_protocol                   = "tcp"
  referenced_security_group_id  = aws_security_group.worker_node.id
  security_group_id             = aws_security_group.control_plane.id
}

# Control Plane Security Group - Allow inbound kubelet API from worker nodes
resource "aws_vpc_security_group_ingress_rule" "control_plane_kubelet" {
  description                   = "Allow inbound kubelet API from worker nodes"
  from_port                     = 10250
  to_port                       = 10250
  ip_protocol                   = "tcp"
  referenced_security_group_id  = aws_security_group.worker_node.id
  security_group_id             = aws_security_group.control_plane.id
}

# Control Plane Security Group - Allow outbound to worker nodes
resource "aws_vpc_security_group_egress_rule" "control_plane_to_nodes" {
  description                   = "Allow control plane to worker nodes"
  from_port                     = 0
  to_port                       = 65535
  ip_protocol                   = "tcp"
  referenced_security_group_id  = aws_security_group.worker_node.id
  security_group_id             = aws_security_group.control_plane.id
}

# Worker Node Security Group
resource "aws_security_group" "worker_node" {
  name_prefix = "${var.cluster_name}-worker-node-"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.cluster_name}-worker-node-sg"
  }
}

# Worker Node Security Group - Allow inbound from control plane
resource "aws_vpc_security_group_ingress_rule" "worker_from_control_plane" {
  description                   = "Allow inbound from control plane"
  from_port                     = 0
  to_port                       = 65535
  ip_protocol                   = "tcp"
  referenced_security_group_id  = aws_security_group.control_plane.id
  security_group_id             = aws_security_group.worker_node.id
}

# Worker Node Security Group - Allow inbound from self
resource "aws_vpc_security_group_ingress_rule" "worker_from_self" {
  description              = "Allow inbound from self"
  from_port                = 0
  to_port                  = 65535
  ip_protocol              = "-1"
  self                     = true
  security_group_id        = aws_security_group.worker_node.id
}

# Worker Node Security Group - Allow outbound
resource "aws_vpc_security_group_egress_rule" "worker_egress" {
  description       = "Allow outbound"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.worker_node.id
}
