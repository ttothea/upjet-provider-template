#!/bin/bash

# This script downloads the Terraform azurerm provider and extracts its schema

set -e

PROVIDER_VERSION="4.78.0"
WORKSPACE_DIR=$(pwd)

echo "=== Downloading Terraform azurerm Provider ==="
echo "Provider: hashicorp/azurerm v${PROVIDER_VERSION}"

# Create a temporary directory for Terraform files
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

cd "$TEMP_DIR"

# Create a minimal Terraform configuration to get the schema
cat > main.tf <<EOF
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "${PROVIDER_VERSION}"
    }
  }
}

provider "azurerm" {
  features {}
}
EOF

echo "Initializing Terraform..."
terraform init -upgrade

echo "Generating provider schema..."
terraform providers schema -json > provider_schema.json

# Extract the Azure provider schema
SCHEMA_PATH="provider_schema.json"

if [ -f "$SCHEMA_PATH" ]; then
    # Use jq to extract just the azurerm provider schema
    jq '.provider_schemas | to_entries[] | select(.key == "registry.terraform.io/hashicorp/azurerm") | .value' "$SCHEMA_PATH" > "$WORKSPACE_DIR/config/schema.json"
    echo "✓ Schema extracted to config/schema.json"
else
    echo "✗ Failed to generate schema"
    exit 1
fi

cd "$WORKSPACE_DIR"
echo "Done!"
