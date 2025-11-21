# Terraform Practice Project

โปรเจกต์สำหรับฝึก Terraform โดยใช้โครงสร้างแบบ Module-based เหมือนโปรเจกต์จริง

## โครงสร้างโปรเจกต์

```
terraform/
├── modules/                    # Reusable Terraform modules
│   └── ec2/                   # EC2 module
│       ├── main.tf            # EC2 resources
│       ├── variables.tf       # Input variables
│       └── outputs.tf         # Output values
│
└── practice-project/          # Practice project
    └── dev/                   # Development environment
        └── terraform-ec2/     # EC2 deployment
            ├── terraform.tf   # Terraform & backend config
            ├── providers.tf   # AWS provider config
            ├── variables.tf   # Variable declarations
            ├── main.tf        # Main configuration
            ├── outputs.tf     # Outputs
            └── practice-dev-ec2.tfvars  # Variable values
```

## คุณสมบัติของ EC2 Module

- สร้าง EC2 Instance พร้อม Amazon Linux 2023 (auto-detect architecture)
- Security Group พร้อม ingress/egress rules ที่กำหนดเอง
- IAM Role และ Instance Profile
- Key Pair management
- Elastic IP (optional)
- Root และ EBS block device configuration
- User data script support
- Metadata service v2 (IMDSv2) enabled by default

## การเริ่มต้นใช้งาน

### 1. ติดตั้ง Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured
- AWS Account และ credentials

### 2. Configure AWS Credentials

```bash
aws configure
```

### 3. แก้ไขไฟล์ tfvars

แก้ไขไฟล์ `practice-project/dev/terraform-ec2/practice-dev-ec2.tfvars`:

```hcl
# เปลี่ยน VPC และ Subnet ID
vpc_id    = "vpc-xxxxx"        # VPC ID ของคุณ
subnet_id = "subnet-xxxxx"      # Subnet ID ของคุณ
```

### 4. รัน Terraform Commands

```bash
# เข้าไปยัง directory
cd practice-project/dev/terraform-ec2

# Initialize Terraform
terraform init

# ดู plan ก่อนสร้าง resources
terraform plan -var-file=practice-dev-ec2.tfvars

# Apply เพื่อสร้าง resources
terraform apply -var-file=practice-dev-ec2.tfvars

# ลบ resources เมื่อเสร็จแล้ว
terraform destroy -var-file=practice-dev-ec2.tfvars
```

## ตัวอย่างการใช้งาน

### การสร้าง EC2 แบบง่าย

ไฟล์ tfvars ที่มีอยู่แล้วมี configuration พื้นฐาน:
- t3.micro instance (Free tier)
- Amazon Linux 2023
- Security group เปิด port 22 (SSH), 80 (HTTP), 443 (HTTPS)
- IAM role สำหรับ Systems Manager
- User data ติดตั้ง Apache web server

### การเพิ่ม Key Pair

หากต้องการ SSH เข้า EC2:

```hcl
# 1. Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/practice-key

# 2. แก้ไข tfvars
ec2_create_key_pair = true
ec2_key_pair_name   = "practice-dev-key"
ec2_public_key      = "<paste your public key here>"
```

### การเพิ่ม Elastic IP

```hcl
ec2_create_eip = true
```

## การปรับแต่ง

### เปลี่ยน Instance Type

```hcl
ec2_instance_type = "t3.small"  # หรือ t3.medium, t3.large, etc.
```

### เพิ่ม EBS Volume

```hcl
ec2_ebs_block_devices = [
  {
    device_name           = "/dev/sdf"
    volume_type           = "gp3"
    volume_size           = 20
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    kms_key_id            = null
    snapshot_id           = null
    delete_on_termination = true
  }
]
```

### ปรับ Security Group Rules

```hcl
ec2_ingress_rules = [
  {
    description      = "Custom port"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.0/16"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
]
```

## Best Practices

1. **Security**
   - จำกัด SSH access ด้วย IP ที่เฉพาะเจาะจง
   - ใช้ IMDSv2 (enabled by default)
   - Encrypt EBS volumes

2. **Cost Optimization**
   - ใช้ t3.micro สำหรับ practice (Free tier)
   - ลบ resources หลังใช้งานเสร็จ: `terraform destroy`

3. **State Management**
   - สำหรับ production ควรใช้ remote state (S3)
   - ไฟล์ terraform.tf มี backend config ให้แล้ว (comment out)

4. **Version Control**
   - อย่า commit `.tfvars` ที่มี sensitive data
   - อย่า commit `terraform.tfstate`

## Troubleshooting

### Error: Invalid VPC or Subnet

ตรวจสอบว่า VPC และ Subnet ID ถูกต้อง:
```bash
aws ec2 describe-vpcs
aws ec2 describe-subnets
```

### Error: Insufficient IAM Permissions

ตรวจสอบว่า AWS credentials มี permissions:
- ec2:*
- iam:CreateRole, iam:AttachRolePolicy

### Error: Key pair already exists

ลบ key pair เดิมหรือใช้ชื่อใหม่:
```bash
aws ec2 delete-key-pair --key-name practice-dev-key
```

## Next Steps

หลังจากลองสร้าง EC2 แล้ว สามารถเพิ่ม modules อื่นได้:
- VPC module
- RDS module
- S3 module
- Load Balancer module

## Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
