#!/bin/bash

# This script downloads the Terraform azurerm provider and extracts its schema

set -e

PROVIDER_VERSION="4.78.0"

# Get the root workspace directory (parent of scripts directory)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "=== Downloading Terraform azurerm Provider ==="
echo "Provider: hashicorp/azurerm v${PROVIDER_VERSION}"
echo "Workspace: $WORKSPACE_DIR"

# Create a temporary directory for Terraform files
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

cd "$TEMP_DIR"

# Create a minimal Terraform configuration to get the schema
cat > main.tf <<'TFEOF'
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.78.0"
    }
  }
}

provider "azurerm" {
  features {}
}
TFEOF

echo "Initializing Terraform..."
terraform init -upgrade -no-color 2>&1 | grep -v "^$" | head -10

echo "Generating provider schema..."
terraform providers schema -json > provider_schema.json

# Extract the Azure provider schema
SCHEMA_PATH="provider_schema.json"

if [ -f "$SCHEMA_PATH" ]; then
    # Extract just the azurerm provider with proper format_version wrapper
    jq '{format_version: "1.0", provider_schemas: {("registry.terraform.io/hashicorp/azurerm"): .provider_schemas["registry.terraform.io/hashicorp/azurerm"]}}' "$SCHEMA_PATH" > "$WORKSPACE_DIR/config/schema.json"
    
    if [ -f "$WORKSPACE_DIR/config/schema.json" ]; then
        echo "✓ Schema extracted to config/schema.json"
        SIZE=$(du -h "$WORKSPACE_DIR/config/schema.json" | cut -f1)
        echo "  File size: $SIZE"
        
        # Verify the schema has format_version
        if jq -e '.format_version' "$WORKSPACE_DIR/config/schema.json" > /dev/null 2>&1; then
            echo "  ✓ format_version field present"
        else
            echo "  ✗ format_version field missing"
            exit 1
        fi
    else
        echo "✗ Failed to write schema file"
        exit 1
    fi
else
    echo "✗ Failed to generate schema"
    exit 1
fi

cd "$WORKSPACE_DIR"
echo ""
echo "✓ Done! Next step: run 'go run cmd/generator/main.go \"\$PWD\"'"
