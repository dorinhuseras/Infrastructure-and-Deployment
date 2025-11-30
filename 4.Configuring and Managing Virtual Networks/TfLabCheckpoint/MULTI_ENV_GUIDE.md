# Multi-Environment Terraform Deployment Guide

## Overview

This Terraform configuration supports deploying multiple independent environments using workspaces and environment-specific variable files.

## Directory Structure

```
├── main.tf                          # Root module configuration
├── variables.tf                     # Variable definitions
├── providers.tf                     # Provider configuration
├── deploy.sh                        # Deployment helper script
├── envs/
│   ├── terraform.tfvars.example     # Example variables (template)
│   ├── myapp1.tfvars                # Environment 1 variables
│   └── myapp2.tfvars                # Environment 2 variables
├── modules/
│   └── azure_vm_network_storage_module/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── .gitignore                       # Git ignore rules
```

## Quick Start

### Option 1: Using the Deploy Script (Recommended)

```bash
# Plan first environment
./deploy.sh myapp1 plan

# Apply first environment
./deploy.sh myapp1 apply

# Plan second environment
./deploy.sh myapp2 plan

# Apply second environment
./deploy.sh myapp2 apply

# View current workspace
terraform workspace list

# Switch workspace
terraform workspace select myapp1
terraform workspace select myapp2

# Destroy an environment
./deploy.sh myapp1 destroy
```

### Option 2: Using Terraform CLI Directly

```bash
# Create/select workspace
terraform workspace new myapp1
terraform workspace select myapp1

# Plan and apply with variable file
terraform plan -var-file="myapp1.tfvars" -out=tfplan_myapp1
terraform apply tfplan_myapp1

# Switch to different environment
terraform workspace select myapp2
terraform plan -var-file="myapp2.tfvars" -out=tfplan_myapp2
terraform apply tfplan_myapp2
```

### Option 3: Using CLI Variables Only

```bash
terraform workspace new myapp1
terraform apply \
  -var="name_prefix=myapp1" \
  -var="vnet_octet=1" \
  -var="location=westeurope" \
  -var="vm_size=Standard_B2s" \
  -var="admin_username=azureuser" \
  -var="admin_password=Password123!"
```

## Creating New Environments

1. **Copy the template file:**
   ```bash
   cp envs/terraform.tfvars.example envs/myapp3.tfvars
   ```

2. **Edit the new file with environment-specific values:**
   ```bash
   vim envs/myapp3.tfvars
   ```

3. **Deploy the environment:**
   ```bash
   ./deploy.sh myapp3 plan
   ./deploy.sh myapp3 apply
   ```

## Environment Variables

Each `.tfvars` file should contain:

```terraform
name_prefix = "unique-prefix"     # Used to name all resources
location    = "westeurope"        # Azure region
vnet_octet  = 1                   # Middle octet for VNet (10.X.0.0/16)
vm_size     = "Standard_B2s"      # VM size
admin_username = "azureuser"      # VM admin username
admin_password = "Password123!"   # VM admin password
```

## Resource Naming Convention

All resources are named using the `name_prefix`:

- Resource Group: `{name_prefix}-rg`
- Virtual Network: `{name_prefix}-vnet`
- Subnets: `{name_prefix}-frontend-subnet`, `{name_prefix}-backend-subnet`, `{name_prefix}-data-subnet`
- VM: `{name_prefix}-backend-vm`
- NSG: `{name_prefix}-nsg`
- Public IP: `{name_prefix}-vm-public-ip`
- Storage Account: `{name_prefix_no_hyphens}{random}`
- And more...

## Workspace Management

View all workspaces:
```bash
terraform workspace list
```

Output:
```
default
* myapp1
  myapp2
```

Switch between workspaces:
```bash
terraform workspace select myapp2
```

Show current workspace:
```bash
terraform workspace show
```

## State Management

Each workspace maintains its own state file:
- `terraform.tfstate` (default workspace)
- `env:/myapp1/terraform.tfstate` (myapp1 workspace)
- `env:/myapp2/terraform.tfstate` (myapp2 workspace)

## CI/CD Pipeline Example

### GitHub Actions

```yaml
name: Deploy Infrastructure

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        default: 'myapp1'

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Terraform Init
        run: terraform init
      
      - name: Terraform Plan
        run: terraform plan -var-file="${{ github.event.inputs.environment }}.tfvars" -out=tfplan
      
      - name: Terraform Apply
        run: terraform apply tfplan
```

## Destroying Environments

Use the deploy script (with confirmation):
```bash
./deploy.sh myapp1 destroy
```

Or manually:
```bash
terraform workspace select myapp1
terraform destroy -var-file="myapp1.tfvars"
```

## Troubleshooting

### See current workspace state
```bash
terraform show
```

### View all resources in a workspace
```bash
terraform state list
```

### Get details about a specific resource
```bash
terraform state show 'module.infra.azurerm_resource_group.rg'
```

### Refresh state
```bash
terraform refresh -var-file="myapp1.tfvars"
```

## Best Practices

1. **Always use separate `.tfvars` files** - Never modify `terraform.tfvars` directly
2. **Test with plan first** - Use `plan` before `apply`
3. **Use the deploy script** - It handles workspaces automatically
4. **Keep credentials secure** - Use Azure Key Vault or environment variables for passwords
5. **Commit variable templates** - Add `terraform.tfvars.example` to git, but not `*.tfvars` files
6. **Use descriptive prefixes** - Use environment names that indicate purpose (e.g., `prod`, `staging`, `dev`)

## Security Notes

- Do NOT commit `.tfvars` files with real credentials to git
- Use `.gitignore` to exclude them
- Consider using Azure Key Vault for sensitive values
- Rotate admin passwords regularly
- Use service principals for automated deployments
