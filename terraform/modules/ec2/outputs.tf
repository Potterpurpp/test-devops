# EC2 Instance Outputs
output "ec2_instance" {
  description = "All EC2 instance information"
  value = {
    instance = {
      id                = aws_instance.ec2.id
      arn               = aws_instance.ec2.arn
      state             = aws_instance.ec2.instance_state
      type              = aws_instance.ec2.instance_type
      private_ip        = aws_instance.ec2.private_ip
      public_ip         = aws_instance.ec2.public_ip
      private_dns       = aws_instance.ec2.private_dns
      public_dns        = aws_instance.ec2.public_dns
      availability_zone = aws_instance.ec2.availability_zone
      subnet_id         = aws_instance.ec2.subnet_id
      security_groups   = aws_instance.ec2.vpc_security_group_ids
      key_name          = aws_instance.ec2.key_name
    }
    security_group = var.create_security_group ? {
      id   = aws_security_group.ec2[0].id
      arn  = aws_security_group.ec2[0].arn
      name = aws_security_group.ec2[0].name
    } : null
    iam = var.create_iam_role ? {
      role_arn              = aws_iam_role.ec2[0].arn
      role_name             = aws_iam_role.ec2[0].name
      instance_profile_arn  = aws_iam_instance_profile.ec2[0].arn
      instance_profile_name = aws_iam_instance_profile.ec2[0].name
    } : null
    key_pair = var.create_key_pair ? {
      name        = aws_key_pair.ec2[0].key_name
      fingerprint = aws_key_pair.ec2[0].fingerprint
    } : null
    elastic_ip = var.create_eip ? {
      public_ip     = aws_eip.ec2[0].public_ip
      allocation_id = aws_eip.ec2[0].id
    } : null
  }
}
