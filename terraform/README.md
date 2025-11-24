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

- Multiple repository support (nodejs-app, statsd, graphite)
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

- CIDR Block: `10.10.0.0/16`
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

- CIDR Block: `10.10.0.0/16`
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

**Benefits of this approach:**
- ✅ No need to copy/backup files
- ✅ All environment configs visible in one place
- ✅ Clear naming convention makes it easy to identify files
- ✅ Stay in the dev component directory - no frequent `cd` commands

## Deployment Helper Script

Create a deployment script for easier management:

```bash
#!/bin/bash
# deploy.sh
# Usage: ./deploy.sh [dev|uat|prod] [vpc|ecr|ec2|all]

PROJECT="devops-test"
ENV=$1
COMPONENT=$2

if [ -z "$ENV" ] || [ -z "$COMPONENT" ]; then
  echo "Usage: ./deploy.sh [dev|uat|prod] [vpc|ecr|ec2|all]"
  exit 1
fi

deploy_component() {
  local comp=$1
  echo "Deploying terraform-$comp for $ENV environment..."

  cd "dev/terraform-$comp" || exit 1

  # Determine var-file path
  if [ "$ENV" == "dev" ]; then
    VAR_FILE=""
  else
    VAR_FILE="-var-file=../../$ENV/$PROJECT-$ENV-$comp.tfvars"
  fi

  # Deploy
  terraform init -upgrade
  terraform plan $VAR_FILE

  read -p "Apply changes? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    terraform apply $VAR_FILE
  fi

  cd ../..
}

if [ "$COMPONENT" == "all" ]; then
  # Deploy in correct order
  deploy_component "vpc"
  deploy_component "ecr"
  deploy_component "ec2"
else
  deploy_component "$COMPONENT"
fi
```

Make it executable:

```bash
chmod +x deploy.sh

# Deploy all components to dev (in correct order)
./deploy.sh dev all

# Deploy VPC to UAT environment
./deploy.sh uat vpc

# Deploy ECR to prod
./deploy.sh prod ecr
```

## Configuration Before First Use

### For VPC Component

Update in each environment's tfvars:

- `vpc_name`: Name tag for your VPC
- `cidr_block`: VPC CIDR range
- `create_private_subnet`: Set to `true` if you need private subnets
- `create_nat_gateway`: Set to `true` if you need NAT Gateway for private subnets

### For ECR Component

Update repository names in the `repository_names` list:

- Default: `nodejs-app`, `statsd`, `graphite`
- For prod: Update `kms_key_id` if using KMS encryption

### For EC2 Component

Update in each environment's tfvars:

- `ec2_existing_key_pair_name`: Your SSH key pair name in AWS
- `ec2_git_repo`: Your Git repository URL
- `ec2_image_name`: Docker image name to build/use
- `vpc_id` and `subnet_id`: Leave null to auto-discover VPC by name
- Adjust security group rules as needed for your use case

## Key Features

### Security Best Practices

- **Dev**: Open for development but still tagged and managed
- **UAT**: Enhanced security with encryption and restricted access
- **Prod**: Maximum security with:
  - Immutable image tags (ECR)
  - KMS encryption
  - No public IP on EC2
  - VPC-only access
  - IMDSv2 required
  - Volume preservation on termination
  - Extended log retention

### Modular Design

All environments use the same modules located at `terraform/modules/`, ensuring consistency and easy maintenance:

- `modules/vpc/` - Networking infrastructure
- `modules/ecr/` - Container registry management
- `modules/ec2/` - Compute instances with user data support

### Environment-Specific Configurations

Each environment can be customized through its `terraform.tfvars` file without modifying the core Terraform code.

### VPC Auto-Discovery

EC2 component automatically discovers VPC by Name tag when `vpc_id` is not specified, simplifying multi-environment deployments.

## State Management

Each component maintains its own Terraform state file, providing:

- **Isolation**: Changes to one component don't lock others
- **Safety**: Smaller blast radius for state corruption
- **Flexibility**: Different teams can work on different components

For production, configure S3 backend in each component's `terraform.tf`:

```hcl
backend "s3" {
  bucket  = "your-terraform-state-bucket"
  key     = "devops-test/prod/vpc/terraform.tfstate"  # Unique per component
  region  = "ap-southeast-1"
  encrypt = true

  dynamodb_table = "terraform-state-lock"  # For state locking
}
```

## Adding New Components

To add a new component (e.g., `terraform-rds`):

1. Create the module structure:

```bash
mkdir -p terraform/modules/rds
```

2. Create the component structure:

```bash
mkdir -p devops-test/dev/terraform-rds
```

3. Create Terraform files in `dev/terraform-rds/`:
   - `main.tf` (uses `../../../modules/rds`)
   - `variables.tf`
   - `providers.tf`
   - `terraform.tf`
   - `outputs.tf`
   - `terraform.tfvars`

4. Create flat tfvars for uat and prod:
   - `uat/devops-test-uat-rds.tfvars`
   - `prod/devops-test-prod-rds.tfvars`

5. Initialize and deploy:

```bash
cd dev/terraform-rds
terraform init
terraform plan
terraform apply
```

## Outputs

Each component provides outputs for integration:

**VPC Outputs:**

- VPC ID, CIDR block, subnet IDs, route table IDs

**ECR Outputs:**

- Repository URLs, ARNs, Registry IDs

**EC2 Outputs:**

- Instance ID, public/private IPs, security group IDs, IAM role details

Access outputs:

```bash
# Get VPC outputs
cd dev/terraform-vpc
terraform output vpc_id

# Get ECR repository URLs
cd dev/terraform-ecr
terraform output repository_urls

# Get EC2 instance details
cd dev/terraform-ec2
terraform output instance_id
```

## Best Practices

1. **Deploy in order**: VPC → ECR → EC2
2. **Review plan output** carefully before applying
3. **Use state locking** (DynamoDB) for production
4. **Enable MFA** for production deployments
5. **Test in dev** before deploying to uat/prod
6. **Document changes** in git commits
7. **Use tags** for cost tracking and resource management
8. **Backup tfvars files** before making changes
9. **Use VPC auto-discovery** by leaving `vpc_id` null in EC2 configs

## Next Steps

1. **Configure AWS credentials** for authentication
2. Update `terraform.tfvars` files with your specific values:
   - VPC: CIDR blocks and subnet preferences
   - ECR: Repository names and encryption settings
   - EC2: Key pair name, Git repository, and security rules
3. **Deploy infrastructure** starting with VPC:

   ```bash
   cd terraform/devops-test/dev/terraform-vpc
   terraform init && terraform apply
   ```

4. Configure **S3 backend** for state management (recommended for team use)
5. Set up **KMS encryption** for production ECR
6. Add more components as needed (RDS, S3, Lambda, etc.)
7. Implement **CI/CD pipeline** for automated deployments
8. Set up **monitoring and alerting** with CloudWatch
9. Configure **backup policies** for production resources
10. Review and customize **user data templates** for each environment
