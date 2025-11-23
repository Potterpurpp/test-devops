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
│   └── ecr/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── devops-test/
    ├── dev/
    │   ├── terraform-ec2/
    │   │   ├── main.tf             # Uses ../../../modules/ec2
    │   │   ├── variables.tf
    │   │   ├── providers.tf
    │   │   ├── terraform.tf
    │   │   ├── outputs.tf
    │   │   └── terraform.tfvars
    │   └── terraform-ecr/
    │       ├── main.tf             # Uses ../../../modules/ecr
    │       ├── variables.tf
    │       ├── providers.tf
    │       ├── terraform.tf
    │       ├── outputs.tf
    │       └── terraform.tfvars
    ├── uat/
    │   ├── devops-test-uat-ec2.tfvars
    │   └── devops-test-uat-ecr.tfvars
    └── prod/
        ├── devops-test-prod-ec2.tfvars
        └── devops-test-prod-ecr.tfvars
```

## Architecture Design

**Component-Based Structure:**
- Each infrastructure component (EC2, ECR, VPC, RDS, etc.) is isolated in its own folder
- Components can be deployed, updated, or destroyed independently
- All Terraform code lives in `dev/terraform-{component}/`
- **Reusable modules** in `terraform/modules/` provide core infrastructure logic
- `uat/` and `prod/` contain flat tfvars files with naming pattern: `{project}-{env}-{component}.tfvars`

**Benefits:**
- ✅ **Isolation**: Changes to one component don't affect others
- ✅ **Flexibility**: Deploy only what you need
- ✅ **Safety**: Smaller blast radius if something goes wrong
- ✅ **Scalability**: Easy to add new components
- ✅ **Team Collaboration**: Different teams can own different components

## Components

### terraform-ec2
Manages EC2 instances for running applications.

**Features:**
- Configurable instance types per environment
- Security group management
- IAM roles and policies
- CloudWatch logging
- Elastic IP support
- EBS volume encryption

### terraform-ecr
Manages Elastic Container Registry for Docker images.

**Features:**
- Multiple repository support
- Image vulnerability scanning
- Lifecycle policies for image cleanup
- Encryption (AES256 for dev/test, KMS for prod)
- Tag mutability control

## Environment Configurations

### Dev Environment
**EC2:**
- Instance Type: `t3.micro`
- Security: More permissive (SSH from anywhere, public IP)
- Log Retention: 7 days
- Volume: Standard, unencrypted

**ECR:**
- Tag Mutability: `MUTABLE`
- Encryption: `AES256`
- Lifecycle: Keep 10 images, remove untagged after 7 days

### UAT Environment
**EC2:**
- Instance Type: `t3.small`
- Security: Moderate restrictions
- Log Retention: 14 days
- Volume: Encrypted with GP3

**ECR:**
- Tag Mutability: `MUTABLE`
- Encryption: `AES256`
- Lifecycle: Keep 15 images, remove untagged after 14 days

### Prod Environment
**EC2:**
- Instance Type: `t3.medium`
- Security: Highly restrictive (VPC-only, no public IP, IMDSv2)
- Log Retention: 90 days
- Volume: Encrypted with KMS, preserved on termination

**ECR:**
- Tag Mutability: `IMMUTABLE`
- Encryption: `KMS`
- Lifecycle: Keep 30 images, remove untagged after 3 days

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. Valid VPC and Subnet IDs (for EC2)
4. KMS key for production encryption (optional)

## Usage

### Working with Dev Environment (Default)

Each component is managed independently:

```bash
# EC2 Component
cd terraform/devops-test/dev/terraform-ec2
terraform init
terraform plan
terraform apply
terraform destroy

# ECR Component
cd terraform/devops-test/dev/terraform-ecr
terraform init
terraform plan
terraform apply
terraform destroy
```

### Working with UAT Environment

Use `-var-file` to specify UAT configuration:

```bash
# EC2 Component
cd terraform/devops-test/dev/terraform-ec2
terraform init
terraform plan -var-file=../../uat/devops-test-uat-ec2.tfvars
terraform apply -var-file=../../uat/devops-test-uat-ec2.tfvars

# ECR Component
cd terraform/devops-test/dev/terraform-ecr
terraform init
terraform plan -var-file=../../uat/devops-test-uat-ecr.tfvars
terraform apply -var-file=../../uat/devops-test-uat-ecr.tfvars
```

### Working with Prod Environment

Use `-var-file` to specify prod configuration:

```bash
# EC2 Component
cd terraform/devops-test/dev/terraform-ec2
terraform init
terraform plan -var-file=../../prod/devops-test-prod-ec2.tfvars
terraform apply -var-file=../../prod/devops-test-prod-ec2.tfvars

# ECR Component
cd terraform/devops-test/dev/terraform-ecr
terraform init
terraform plan -var-file=../../prod/devops-test-prod-ecr.tfvars
terraform apply -var-file=../../prod/devops-test-prod-ecr.tfvars
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
# Usage: ./deploy.sh [dev|uat|prod] [ec2|ecr|all]

PROJECT="devops-test"
ENV=$1
COMPONENT=$2

if [ -z "$ENV" ] || [ -z "$COMPONENT" ]; then
  echo "Usage: ./deploy.sh [dev|uat|prod] [ec2|ecr|all]"
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
  deploy_component "ec2"
  deploy_component "ecr"
else
  deploy_component "$COMPONENT"
fi
```

Make it executable:
```bash
chmod +x deploy.sh

# Deploy ECR to UAT environment
./deploy.sh uat ecr

# Deploy all components to prod
./deploy.sh prod all

# Deploy EC2 to dev
./deploy.sh dev ec2
```

## Configuration Before First Use

### For EC2 Component

Update the following in each environment's `terraform.tfvars`:
- `vpc_id`: Your VPC ID
- `subnet_id`: Your Subnet ID
- `ec2_existing_key_pair_name`: Your SSH key pair name

### For ECR Component

Update the following in `prod/terraform-ecr/terraform.tfvars`:
- `kms_key_id`: Your KMS key ARN for encryption (if using KMS)

Repository names can be customized in the `repository_names` list.

## Key Features

### Security Best Practices
- **Dev**: Open for development but still tagged and managed
- **Test**: Enhanced security with encryption and restricted access
- **Prod**: Maximum security with:
  - Immutable image tags (ECR)
  - KMS encryption
  - No public IP on EC2
  - VPC-only access
  - IMDSv2 required
  - Volume preservation on termination
  - Extended log retention

### Modular Design
All environments use the same modules located at `terraform/modules/`, ensuring consistency and easy maintenance.

### Environment-Specific Configurations
Each environment can be customized through its `terraform.tfvars` file without modifying the core Terraform code.

## State Management

Each component maintains its own Terraform state file, providing:
- **Isolation**: Changes to one component don't lock others
- **Safety**: Smaller blast radius for state corruption
- **Flexibility**: Different teams can work on different components

For production, configure S3 backend in each component's `terraform.tf`:

```hcl
backend "s3" {
  bucket  = "your-terraform-state-bucket"
  key     = "prod/ec2/terraform.tfstate"  # Unique per component
  region  = "ap-southeast-1"
  encrypt = true

  dynamodb_table = "terraform-state-lock"  # For state locking
}
```

## Adding New Components

To add a new component (e.g., `terraform-rds`):

1. Create the component structure:
```bash
mkdir -p dev/terraform-rds test/terraform-rds prod/terraform-rds
```

2. Create Terraform files in `dev/terraform-rds/`:
   - `main.tf`
   - `variables.tf`
   - `providers.tf`
   - `terraform.tf`
   - `outputs.tf`
   - `terraform.tfvars`

3. Create `terraform.tfvars` for test and prod:
   - `test/terraform-rds/terraform.tfvars`
   - `prod/terraform-rds/terraform.tfvars`

4. Initialize and deploy:
```bash
cd dev/terraform-rds
terraform init
terraform plan
terraform apply
```

## Outputs

Each component provides outputs for integration:

**EC2 Outputs:**
- Instance ID, IPs, security group IDs, IAM role details

**ECR Outputs:**
- Repository URLs, ARNs, Registry IDs

Access outputs:
```bash
cd dev/terraform-ecr
terraform output repository_urls
```

## Best Practices

1. **Always backup** `terraform.tfvars` before switching environments
2. **Review plan output** carefully before applying
3. **Use state locking** (DynamoDB) for production
4. **Enable MFA** for production deployments
5. **Test in dev** before deploying to test/prod
6. **Document changes** in git commits
7. **Use tags** for cost tracking and resource management

## Next Steps

1. Update `terraform.tfvars` with your actual AWS resource IDs
2. Configure S3 backend for state management
3. Set up KMS encryption for production
4. Add more components as needed (VPC, RDS, S3, etc.)
5. Implement CI/CD pipeline for automated deployments
6. Set up monitoring and alerting with CloudWatch
7. Configure backup policies for production resources
