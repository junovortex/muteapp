#!/bin/bash

# Google Cloud CLI Installation Script for macOS
# This script installs Google Cloud CLI if not already installed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo -e "${BLUE}=== Google Cloud CLI Installation ===${NC}"

# Check if gcloud is already installed
if command -v gcloud &> /dev/null; then
    print_status "Google Cloud CLI is already installed"
    gcloud version
    exit 0
fi

print_status "Installing Google Cloud CLI..."

# Check if Homebrew is available (preferred method on macOS)
if command -v brew &> /dev/null; then
    print_status "Installing via Homebrew..."
    brew install --cask google-cloud-sdk
else
    print_status "Installing via curl..."
    
    # Download and install
    curl https://sdk.cloud.google.com | bash
    
    # Add to PATH
    echo 'export PATH="$HOME/google-cloud-sdk/bin:$PATH"' >> ~/.bash_profile
    echo 'export PATH="$HOME/google-cloud-sdk/bin:$PATH"' >> ~/.zshrc
    
    # Source the profile
    if [ -f ~/.zshrc ]; then
        source ~/.zshrc
    elif [ -f ~/.bash_profile ]; then
        source ~/.bash_profile
    fi
fi

print_status "Google Cloud CLI installation completed"
print_status "Please restart your terminal or run 'source ~/.zshrc' to use gcloud"

# Initialize gcloud
echo ""
read -p "Do you want to initialize gcloud now? (y/n): " INIT_GCLOUD
if [[ $INIT_GCLOUD =~ ^[Yy]$ ]]; then
    gcloud init
fi

echo ""
print_status "Installation complete! You can now run './create_oauth_client.sh'"
