# Azure Managed DevOps Pool Provider Setup Guide

This guide helps you complete the setup of the Crossplane provider for Azure Managed DevOps Pool.

## Prerequisites

- Terraform 1.5.x (as specified in Makefile)
- Go 1.24+
- jq (for JSON processing)
- Git
- Make

## Setup Steps

### Step 1: Fetch the Azure Provider Schema

The provider schema needs to be downloaded from the Terraform provider. Run:

```bash
# Make the script executable
chmod +x scripts/fetch-azurerm-schema.sh

# Run the script to fetch and extract the schema
scripts/fetch-azurerm-schema.sh
```

This script will:
1. Create a temporary Terraform configuration
2. Initialize Terraform with azurerm v4.78.0
3. Extract the provider schema
4. Save it to `config/schema.json`

### Step 2: Run Code Generation

The code generation pipeline will create the Crossplane API types and controllers:

```bash
go run cmd/generator/main.go "$PWD"
```

This generates:
- API types in `apis/` directory
- Controllers in `internal/controller/` directory
- CRD definitions in `package/crds/` directory

### Step 3: Build and Test

Build the provider:

```bash
make build
```

Build the container image:

```bash
make build.images
```

Build the XPKG (Crossplane package):

```bash
make build.xpkg
```

## Generated Resources

After code generation, you'll have:

### Custom Resource Definitions (CRDs)

- **Cluster-scoped**: `ManagedDevOpsPool` in group `template.crossplane.io`
- **Namespaced**: `ManagedDevOpsPool` in group `template.m.crossplane.io`

### Controller

The controller manages the lifecycle of the Managed DevOps Pool resource, including:
- Creation
- Updates
- Deletion
- Dependency management

## Resource Usage Example

Once deployed to a Kubernetes cluster, you can create a Managed DevOps Pool like this:

```yaml
apiVersion: devopsinfra.template.crossplane.io/v1alpha1
kind: ManagedDevOpsPool
metadata:
  name: example-pool
spec:
  managementPolicy: Observe
  forProvider:
    location: West Europe
    resourceGroupName: example-resources
    devCenterProjectId: /subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.DevCenter/projects/xxx
    maximumConcurrency: 1
    azureDevopsOrganization:
      organization:
        - parallelism: 1
          url: https://dev.azure.com/example
    statelessAgent: {}
    virtualMachineScaleSetFabric:
      skuName: Standard_D2ads_v5
      image:
        - wellKnownImageName: ubuntu-24.04/buffer
```

## Configuration Details

### External Name Mapping

- The resource uses the `name` field as the external identifier
- This maps to the Azure resource name

### References

- `devCenterProjectId` references `azurerm_dev_center_project` resources

### Next Steps

1. Update `config/external_name.go` if you need to customize identifier handling
2. Extend `config/cluster/azurerm/config.go` for additional resource customizations
3. Test the generated code with `make test`
4. Install the provider in a Crossplane cluster using the XPKG

## Troubleshooting

### Schema Download Fails

If `fetch-azurerm-schema.sh` fails:
1. Ensure Terraform is installed: `terraform version`
2. Check internet connectivity
3. Verify jq is installed: `jq --version`

### Code Generation Fails

If code generation fails:
1. Check that `config/schema.json` exists and is valid JSON
2. Verify Go version: `go version` (should be 1.24+)
3. Check for import errors: `go mod tidy`

### Build Fails

1. Run `go mod tidy` to update dependencies
2. Check that all APIs are properly generated in `apis/`
3. Review controller generation in `internal/controller/`

## Additional Resources

- [Upjet Documentation](https://github.com/crossplane/upjet/blob/main/docs/generating-a-provider.md)
- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_devops_pool)
- [Crossplane Provider Development](https://docs.crossplane.io/latest/packages/providers/)
