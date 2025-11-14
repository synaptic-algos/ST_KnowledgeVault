#!/bin/bash

# Symlink Setup Script for Synaptic Trading Knowledge Vault
# This script creates symbolic links from the code repository to the vault content

set -e  # Exit on error

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Synaptic Trading Vault Symlink Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Define paths
VAULT_ROOT="/Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault"
UPMS_VAULT="/Users/nitindhawan/KnowledgeVaults/UPMS_Vault"
CODE_REPO_DOCS="/Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/documentation"

# Check if vault exists
if [ ! -d "$VAULT_ROOT" ]; then
    echo -e "${RED}Error: Vault directory not found at $VAULT_ROOT${NC}"
    exit 1
fi

# Check if UPMS vault exists
if [ ! -d "$UPMS_VAULT" ]; then
    echo -e "${YELLOW}Warning: UPMS Vault directory not found at $UPMS_VAULT${NC}"
    echo -e "${YELLOW}UPMS templates symlink will be skipped${NC}"
fi

# Check if code repo docs exists
if [ ! -d "$CODE_REPO_DOCS" ]; then
    echo -e "${RED}Error: Code repository documentation directory not found at $CODE_REPO_DOCS${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found vault at: $VAULT_ROOT${NC}"
echo -e "${GREEN}✓ Found UPMS vault at: $UPMS_VAULT${NC}"
echo -e "${GREEN}✓ Found code repo docs at: $CODE_REPO_DOCS${NC}"
echo ""

# Navigate to code repo docs
cd "$CODE_REPO_DOCS"

# Function to create symlink
create_symlink() {
    local target=$1
    local link_name=$2

    # Check if target exists
    if [ ! -e "$target" ]; then
        echo -e "${YELLOW}  Warning: Target does not exist: $target${NC}"
        echo -e "${YELLOW}  Skipping: $link_name${NC}"
        return 1
    fi

    # Remove existing symlink or file if it exists
    if [ -L "$link_name" ]; then
        echo -e "${YELLOW}  Removing existing symlink: $link_name${NC}"
        rm "$link_name"
    elif [ -e "$link_name" ]; then
        echo -e "${RED}  Warning: $link_name exists and is not a symlink. Skipping.${NC}"
        return 1
    fi

    # Create symlink
    if ln -s "$target" "$link_name"; then
        echo -e "${GREEN}  ✓ Created: $link_name -> $target${NC}"
        return 0
    else
        echo -e "${RED}  ✗ Failed to create: $link_name${NC}"
        return 1
    fi
}

echo -e "${BLUE}Creating symlinks...${NC}"
echo ""

# Create symlinks to ALL product vault content
create_symlink "$VAULT_ROOT/Product/EPICS" "vault_epics"
create_symlink "$VAULT_ROOT/Product/Strategies" "vault_strategies"
create_symlink "$VAULT_ROOT/Product/PRD" "vault_prd"
create_symlink "$VAULT_ROOT/Product/Research" "vault_research"
create_symlink "$VAULT_ROOT/Product/Design" "vault_design"
create_symlink "$VAULT_ROOT/Product/Issues" "vault_issues"
create_symlink "$VAULT_ROOT/Product/Sprints" "vault_sprints"
create_symlink "$VAULT_ROOT/Product/TechnicalDocumentation" "vault_technical_docs"
create_symlink "$VAULT_ROOT/Product/Templates" "vault_product_templates"

# Create symlink to UPMS templates (if UPMS vault exists)
if [ -d "$UPMS_VAULT" ]; then
    create_symlink "$UPMS_VAULT/Templates" "vault_upms_templates"
fi

echo ""
echo -e "${BLUE}Verifying symlinks...${NC}"
echo ""

# Verify symlinks
verify_symlink() {
    local link_name=$1
    if [ -L "$link_name" ] && [ -e "$link_name" ]; then
        echo -e "${GREEN}✓ $link_name is working${NC}"
    else
        echo -e "${RED}✗ $link_name is broken or missing${NC}"
    fi
}

# Verify all product symlinks
verify_symlink "vault_epics"
verify_symlink "vault_strategies"
verify_symlink "vault_prd"
verify_symlink "vault_research"
verify_symlink "vault_design"
verify_symlink "vault_issues"
verify_symlink "vault_sprints"
verify_symlink "vault_technical_docs"
verify_symlink "vault_product_templates"

# Verify UPMS symlinks (if UPMS vault exists)
if [ -d "$UPMS_VAULT" ]; then
    verify_symlink "vault_upms_templates"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Symlink setup complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "You can now access vault content from the code repository:"
echo "  cd $CODE_REPO_DOCS"
echo "  ls -la vault_*"
echo ""
echo "For more information, see:"
echo "  $VAULT_ROOT/VaultGuide/README.md"
echo ""
