# Local Values
locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Terraform   = "true"
  })
}

# Data source to get instance type details
data "aws_ec2_instance_type" "selected" {
  instance_type = var.instance_type
}

# Data source for latest Amazon Linux 2023 AMI (architecture-aware)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    values = [
      data.aws_ec2_instance_type.selected.supported_architectures[0] == "arm64"
      ? "al2023-ami-*-arm64"
      : "al2023-ami-*-x86_64"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = [data.aws_ec2_instance_type.selected.supported_architectures[0]]
  }
}

# IAM Role for EC2 Instance
resource "aws_iam_role" "ec2" {
  count = var.create_iam_role ? 1 : 0
  name  = "${var.instance_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-role"
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  count = var.create_iam_role ? 1 : 0
  name  = "${var.instance_name}-profile"
  role  = aws_iam_role.ec2[0].name

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-profile"
  })
}

# IAM Policy Attachments
resource "aws_iam_role_policy_attachment" "ec2_additional_policies" {
  count      = var.create_iam_role ? length(var.iam_policy_arns) : 0
  role       = aws_iam_role.ec2[0].name
  policy_arn = var.iam_policy_arns[count.index]
}

# Security Group for EC2 Instance
resource "aws_security_group" "ec2" {
  count       = var.create_security_group ? 1 : 0
  name        = var.security_group_name != null ? var.security_group_name : "${var.instance_name}-sg"
  description = "Security group for ${var.instance_name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description      = ingress.value.description
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      prefix_list_ids  = ingress.value.prefix_list_ids
      security_groups  = ingress.value.security_groups
      self             = ingress.value.self
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      description      = egress.value.description
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      prefix_list_ids  = egress.value.prefix_list_ids
      security_groups  = egress.value.security_groups
      self             = egress.value.self
    }
  }

  tags = merge(local.common_tags, {
    Name = var.security_group_name != null ? var.security_group_name : "${var.instance_name}-sg"
  })
}

# Key Pair
resource "aws_key_pair" "ec2" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = var.key_pair_name != null ? var.key_pair_name : "${var.instance_name}-key"
  public_key = var.public_key

  tags = merge(local.common_tags, {
    Name = var.key_pair_name != null ? var.key_pair_name : "${var.instance_name}-key"
  })
}

# EC2 Instance
resource "aws_instance" "ec2" {
  ami                         = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  key_name                    = var.create_key_pair ? aws_key_pair.ec2[0].key_name : var.existing_key_pair_name
  vpc_security_group_ids      = var.create_security_group ? [aws_security_group.ec2[0].id] : var.existing_security_group_ids
  subnet_id                   = var.subnet_id
  iam_instance_profile        = var.create_iam_role ? aws_iam_instance_profile.ec2[0].name : var.existing_iam_instance_profile
  associate_public_ip_address = var.associate_public_ip_address
  source_dest_check           = var.source_dest_check
  user_data                   = var.user_data
  user_data_base64            = var.user_data_base64

  dynamic "root_block_device" {
    for_each = var.root_block_device != null ? [var.root_block_device] : []
    content {
      volume_type           = root_block_device.value.volume_type
      volume_size           = root_block_device.value.volume_size
      iops                  = root_block_device.value.iops
      throughput            = root_block_device.value.throughput
      encrypted             = root_block_device.value.encrypted
      kms_key_id            = root_block_device.value.kms_key_id
      delete_on_termination = root_block_device.value.delete_on_termination
    }
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_devices
    content {
      device_name           = ebs_block_device.value.device_name
      volume_type           = ebs_block_device.value.volume_type
      volume_size           = ebs_block_device.value.volume_size
      iops                  = ebs_block_device.value.iops
      throughput            = ebs_block_device.value.throughput
      encrypted             = ebs_block_device.value.encrypted
      kms_key_id            = ebs_block_device.value.kms_key_id
      snapshot_id           = ebs_block_device.value.snapshot_id
      delete_on_termination = ebs_block_device.value.delete_on_termination
    }
  }

  metadata_options {
    http_endpoint               = var.metadata_options.http_endpoint
    http_tokens                 = var.metadata_options.http_tokens
    http_put_response_hop_limit = var.metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = var.metadata_options.instance_metadata_tags
  }

  tags = merge(local.common_tags, {
    Name = var.instance_name
  })

  volume_tags = merge(local.common_tags, {
    Name = "${var.instance_name}-volume"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP
resource "aws_eip" "ec2" {
  count    = var.create_eip ? 1 : 0
  instance = aws_instance.ec2.id
  domain   = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-eip"
  })

  depends_on = [aws_instance.ec2]
}
