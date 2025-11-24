# Terraform Multi-Environment Infrastructure

This project contains Terraform configurations for managing infrastructure across multiple environments: **dev**, **uat**, and **prod**.

The infrastructure is organized by **components** (EC2, ECR, etc.) within each environment, allowing independent management and deployment.

## Directory Structure

```
terraform/
├── modules/                        # Reusable Terraform modules
│   ├── ec2/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ecr/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── vpc/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── devops-test/
    ├── dev/
    │   ├── terraform-vpc/
    │   │   ├── main.tf             # Uses ../../../modules/vpc
    │   │   ├── variables.tf
    │   │   ├── providers.tf
    │   │   ├── terraform.tf
    │   │   ├── outputs.tf
    │   │   └── terraform.tfvars
    │   ├── terraform-ecr/
    │   │   ├── main.tf             # Uses ../../../modules/ecr
    │   │   ├── variables.tf
    │   │   ├── providers.tf
    │   │   ├── terraform.tf
    │   │   ├── outputs.tf
    │   │   └── terraform.tfvars
    │   ├── terraform-ec2/
    │   │   ├── main.tf             # Uses ../../../modules/ec2
    │   │   ├── variables.tf
    │   │   ├── providers.tf
    │   │   ├── terraform.tf
    │   │   ├── outputs.tf
    │   │   └── terraform.tfvars
    │   └── user_data.tpl           # User data template for EC2
    ├── uat/
    │   ├── devops-test-uat-vpc.tfvars
    │   ├── devops-test-uat-ecr.tfvars
    │   ├── devops-test-uat-ec2.tfvars
    │   └── user_data.tpl
    └── prod/
        ├── devops-test-prod-vpc.tfvars
        ├── devops-test-prod-ecr.tfvars
        ├── devops-test-prod-ec2.tfvars
        └── user_data.tpl
```

## Architecture Design

**Component-Based Structure:**
- Each infrastructure component (VPC, ECR, EC2, etc.) is isolated in its own folder
- Components can be deployed, updated, or destroyed independently
- All Terraform code lives in `dev/terraform-{component}/`
- **Reusable modules** in `terraform/modules/` provide core infrastructure logic
- `uat/` and `prod/` contain flat tfvars files with naming pattern: `{project}-{env}-{component}.tfvars`
- User data templates for EC2 are stored at environment level for customization

**Benefits:**
- ✅ **Isolation**: Changes to one component don't affect others
- ✅ **Flexibility**: Deploy only what you need
- ✅ **Safety**: Smaller blast radius if something goes wrong
- ✅ **Scalability**: Easy to add new components
- ✅ **Team Collaboration**: Different teams can own different components

## Components

### terraform-vpc

Manages Virtual Private Cloud and networking infrastructure.

**Features:**

- Configurable CIDR blocks
- Public and private subnets
- Internet Gateway for public access
- NAT Gateway for private subnet (optional)
- Route tables and associations
- Network ACLs

### terraform-ecr

Manages Elastic Container Registry for Docker images.

**Features:**

- Multiple repository support
- Image vulnerability scanning
- Lifecycle policies for image cleanup
- Encryption (AES256 for dev/uat, KMS for prod)
- Tag mutability control

### terraform-ec2

Manages EC2 instances for running applications.

**Features:**

- Configurable instance types per environment
- Security group management with SSH, HTTP, and StatsD ports
- IAM roles and policies with ECR access
- CloudWatch logging
- Elastic IP support (optional)
- EBS volume encryption
- User data script for automated deployment
- VPC auto-discovery by Name tag

## Environment Configurations

### Dev Environment

**VPC:**

- CIDR Block: `10.10.0.0/16`
- VPC Name: `devops-test-vpc`
- Subnets: Public only
- NAT Gateway: Not created

**ECR:**

- Tag Mutability: `MUTABLE`
- Encryption: `AES256`
- Lifecycle: Keep 10 images, remove untagged after 7 days
- Repositories: nodejs-app, statsd, graphite

**EC2:**

- Instance Type: `t3.micro`
- Security: More permissive (SSH, HTTP, StatsD from anywhere, public IP)
- Log Retention: 7 days
- Volume: Standard, unencrypted
- User Data: Builds and deploys from Git repository

### UAT Environment

**VPC:**

- CIDR Block: `10.11.0.0/16`
- VPC Name: `devops-test-vpc-uat`
- Subnets: Public only
- NAT Gateway: Not created

**ECR:**

- Tag Mutability: `MUTABLE`
- Encryption: `AES256`
- Lifecycle: Keep 15 images, remove untagged after 14 days

**EC2:**

- Instance Type: `t3.small`
- Security: Moderate restrictions
- Log Retention: 14 days
- Volume: Encrypted with GP3
- User Data: Pulls pre-built images from ECR

### Prod Environment

**VPC:**

- CIDR Block: `10.12.0.0/16`
- VPC Name: `devops-test-vpc-prod`
- Subnets: Public only
- NAT Gateway: Not created

**ECR:**

- Tag Mutability: `IMMUTABLE`
- Encryption: `KMS`
- Lifecycle: Keep 30 images, remove untagged after 3 days

**EC2:**

- Instance Type: `t3.medium`
- Security: Highly restrictive (VPC-only, no public IP, IMDSv2)
- Log Retention: 90 days
- Volume: Encrypted with KMS, preserved on termination
- User Data: Pulls immutable production images from ECR

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. Git repository with your application code
4. SSH key pair in AWS (for EC2 access)
5. KMS key for production encryption (optional, for prod ECR)

## Usage

### Deployment Order

For initial setup, deploy components in this order:

1. **VPC** - Creates the networking infrastructure
2. **ECR** - Creates Docker image repositories
3. **EC2** - Creates compute instances (will auto-discover VPC)

### Working with Dev Environment (Default)

Each component is managed independently:

```bash
# 1. VPC Component (Deploy first)
cd terraform/devops-test/dev/terraform-vpc
terraform init
terraform plan
terraform apply
terraform destroy

# 2. ECR Component (Deploy second)
cd terraform/devops-test/dev/terraform-ecr
terraform init
terraform plan
terraform apply
terraform destroy

# 3. EC2 Component (Deploy last - will auto-discover VPC)
cd terraform/devops-test/dev/terraform-ec2
terraform init
terraform plan
terraform apply
terraform destroy
```

### Working with UAT Environment

Use `-var-file` to specify UAT configuration:

```bash
# 1. VPC Component
cd terraform/devops-test/dev/terraform-vpc
terraform init
terraform plan -var-file=../../uat/devops-test-uat-vpc.tfvars
terraform apply -var-file=../../uat/devops-test-uat-vpc.tfvars

# 2. ECR Component
cd terraform/devops-test/dev/terraform-ecr
terraform init
terraform plan -var-file=../../uat/devops-test-uat-ecr.tfvars
terraform apply -var-file=../../uat/devops-test-uat-ecr.tfvars

# 3. EC2 Component
cd terraform/devops-test/dev/terraform-ec2
terraform init
terraform plan -var-file=../../uat/devops-test-uat-ec2.tfvars
terraform apply -var-file=../../uat/devops-test-uat-ec2.tfvars
```

### Working with Prod Environment

Use `-var-file` to specify prod configuration:

```bash
# 1. VPC Component
cd terraform/devops-test/dev/terraform-vpc
terraform init
terraform plan -var-file=../../prod/devops-test-prod-vpc.tfvars
terraform apply -var-file=../../prod/devops-test-prod-vpc.tfvars

# 2. ECR Component
cd terraform/devops-test/dev/terraform-ecr
terraform init
terraform plan -var-file=../../prod/devops-test-prod-ecr.tfvars
terraform apply -var-file=../../prod/devops-test-prod-ecr.tfvars

# 3. EC2 Component
cd terraform/devops-test/dev/terraform-ec2
terraform init
terraform plan -var-file=../../prod/devops-test-prod-ec2.tfvars
terraform apply -var-file=../../prod/devops-test-prod-ec2.tfvars
```