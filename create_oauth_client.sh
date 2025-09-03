#!/bin/bash

# OAuth Client ID Creation Script for Android
# This script automates the creation of OAuth client ID for your MuteApp project

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="muteapp"
PACKAGE_NAME="com.muteapp.muteapp"
APP_NAME="MuteApp"

echo -e "${BLUE}=== OAuth Client ID Creation Script ===${NC}"
echo -e "${BLUE}Project: $PROJECT_NAME${NC}"
echo -e "${BLUE}Package: $PACKAGE_NAME${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if gcloud is installed
check_gcloud() {
    if ! command -v gcloud &> /dev/null; then
        print_error "Google Cloud CLI (gcloud) is not installed."
        echo "Please install it from: https://cloud.google.com/sdk/docs/install"
        echo "Or run: curl https://sdk.cloud.google.com | bash"
        exit 1
    fi
    print_status "Google Cloud CLI found"
}

# Check if user is authenticated
check_auth() {
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 > /dev/null; then
        print_warning "Not authenticated with Google Cloud"
        echo "Please run: gcloud auth login"
        exit 1
    fi
    
    ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1)
    print_status "Authenticated as: $ACCOUNT"
}

# Get or create project
setup_project() {
    echo ""
    echo -e "${BLUE}=== Project Setup ===${NC}"
    
    # List existing projects
    echo "Available projects:"
    gcloud projects list --format="table(projectId,name,projectNumber)"
    
    echo ""
    read -p "Enter existing project ID or press Enter to create new project '$PROJECT_NAME': " PROJECT_ID
    
    if [ -z "$PROJECT_ID" ]; then
        PROJECT_ID="$PROJECT_NAME-$(date +%s)"
        print_status "Creating new project: $PROJECT_ID"
        
        gcloud projects create $PROJECT_ID --name="$APP_NAME"
        
        # Set billing account (required for API usage)
        echo ""
        echo "Available billing accounts:"
        gcloud billing accounts list --format="table(name,displayName,open)"
        
        read -p "Enter billing account ID (format: XXXXXX-XXXXXX-XXXXXX): " BILLING_ACCOUNT
        if [ ! -z "$BILLING_ACCOUNT" ]; then
            gcloud billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT
            print_status "Billing account linked"
        else
            print_warning "No billing account linked. Some APIs may not work."
        fi
    fi
    
    # Set current project
    gcloud config set project $PROJECT_ID
    print_status "Using project: $PROJECT_ID"
}

# Enable required APIs
enable_apis() {
    echo ""
    echo -e "${BLUE}=== Enabling APIs ===${NC}"
    
    APIS=(
        "cloudresourcemanager.googleapis.com"
        "iamcredentials.googleapis.com"
        "plus.googleapis.com"
        "gmail.googleapis.com"
        "drive.googleapis.com"
        "youtube.googleapis.com"
    )
    
    for api in "${APIS[@]}"; do
        print_status "Enabling $api"
        gcloud services enable $api
    done
    
    print_status "All APIs enabled"
}

# Get SHA-1 fingerprint
get_sha1_fingerprint() {
    echo ""
    echo -e "${BLUE}=== Getting SHA-1 Fingerprint ===${NC}"
    
    # Check if debug keystore exists
    DEBUG_KEYSTORE="$HOME/.android/debug.keystore"
    
    if [ ! -f "$DEBUG_KEYSTORE" ]; then
        print_warning "Debug keystore not found at $DEBUG_KEYSTORE"
        print_status "Creating debug keystore..."
        
        mkdir -p "$HOME/.android"
        keytool -genkey -v -keystore "$DEBUG_KEYSTORE" \
                -alias androiddebugkey \
                -keyalg RSA \
                -keysize 2048 \
                -validity 10000 \
                -storepass android \
                -keypass android \
                -dname "CN=Android Debug,O=Android,C=US"
    fi
    
    # Extract SHA-1 fingerprint
    SHA1_FINGERPRINT=$(keytool -list -v -keystore "$DEBUG_KEYSTORE" \
                       -alias androiddebugkey \
                       -storepass android \
                       -keypass android | \
                       grep "SHA1:" | \
                       cut -d' ' -f3)
    
    if [ -z "$SHA1_FINGERPRINT" ]; then
        print_error "Failed to extract SHA-1 fingerprint"
        exit 1
    fi
    
    print_status "SHA-1 Fingerprint: $SHA1_FINGERPRINT"
}

# Configure OAuth consent screen
configure_consent_screen() {
    echo ""
    echo -e "${BLUE}=== Configuring OAuth Consent Screen ===${NC}"
    
    read -p "Enter your support email: " SUPPORT_EMAIL
    if [ -z "$SUPPORT_EMAIL" ]; then
        SUPPORT_EMAIL=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1)
    fi
    
    # Create consent screen configuration
    cat > oauth_consent_config.json << EOF
{
  "userType": "EXTERNAL",
  "applicationTitle": "$APP_NAME",
  "supportEmail": "$SUPPORT_EMAIL",
  "developerContactEmails": ["$SUPPORT_EMAIL"],
  "scopes": [
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/userinfo.profile"
  ]
}
EOF

    print_status "OAuth consent screen configuration created"
    print_warning "Note: You may need to manually configure the consent screen in the Google Cloud Console"
    print_warning "Visit: https://console.cloud.google.com/apis/credentials/consent"
}

# Create OAuth client ID
create_oauth_client() {
    echo ""
    echo -e "${BLUE}=== Creating OAuth Client ID ===${NC}"
    
    CLIENT_NAME="$APP_NAME Android Client"
    
    # Create the OAuth client ID
    print_status "Creating OAuth client ID..."
    
    # Use gcloud to create OAuth client
    OAUTH_CLIENT_OUTPUT=$(gcloud iam oauth-clients create \
        --display-name="$CLIENT_NAME" \
        --format="value(name)" 2>/dev/null || echo "")
    
    if [ -z "$OAUTH_CLIENT_OUTPUT" ]; then
        print_warning "Direct OAuth client creation failed. Using alternative method..."
        
        # Alternative: Create via API
        ACCESS_TOKEN=$(gcloud auth print-access-token)
        PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
        
        # Create OAuth client via REST API
        OAUTH_RESPONSE=$(curl -s -X POST \
            "https://oauth2.googleapis.com/v2/oauth/clients" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"client_name\": \"$CLIENT_NAME\",
                \"client_type\": \"android\",
                \"android_info\": {
                    \"package_name\": \"$PACKAGE_NAME\",
                    \"certificate_hash\": \"$SHA1_FINGERPRINT\"
                }
            }")
        
        CLIENT_ID=$(echo $OAUTH_RESPONSE | grep -o '"client_id":"[^"]*' | cut -d'"' -f4)
    fi
    
    if [ ! -z "$CLIENT_ID" ]; then
        print_status "OAuth Client ID created: $CLIENT_ID"
    else
        print_error "Failed to create OAuth client ID automatically"
        print_warning "Please create manually using the following details:"
        echo "  - Application type: Android"
        echo "  - Package name: $PACKAGE_NAME"
        echo "  - SHA-1 fingerprint: $SHA1_FINGERPRINT"
        echo "  - Visit: https://console.cloud.google.com/apis/credentials"
        return 1
    fi
}

# Update google-services.json
update_google_services() {
    echo ""
    echo -e "${BLUE}=== Updating google-services.json ===${NC}"
    
    GOOGLE_SERVICES_FILE="app/google-services.json"
    
    if [ -f "$GOOGLE_SERVICES_FILE" ]; then
        print_status "Backing up existing google-services.json"
        cp "$GOOGLE_SERVICES_FILE" "${GOOGLE_SERVICES_FILE}.backup"
    fi
    
    # Download updated google-services.json
    print_status "Downloading updated google-services.json"
    
    # This would typically require manual download from console
    print_warning "Please manually download the updated google-services.json from:"
    echo "https://console.cloud.google.com/apis/credentials"
    echo "And replace the file at: $GOOGLE_SERVICES_FILE"
}

# Update build.gradle dependencies
update_dependencies() {
    echo ""
    echo -e "${BLUE}=== Updating Dependencies ===${NC}"
    
    BUILD_GRADLE="app/build.gradle"
    
    if [ -f "$BUILD_GRADLE" ]; then
        # Check if Google Sign-In dependency already exists
        if ! grep -q "play-services-auth" "$BUILD_GRADLE"; then
            print_status "Adding Google Sign-In dependency to build.gradle"
            
            # Add dependency before the closing brace of dependencies block
            sed -i.bak '/^dependencies {/,/^}/ {
                /^}/ i\
    // Google Sign-In\
    implementation '\''com.google.android.gms:play-services-auth:20.7.0'\''
            }' "$BUILD_GRADLE"
            
            print_status "Dependencies updated"
        else
            print_status "Google Sign-In dependency already exists"
        fi
    else
        print_error "build.gradle not found at $BUILD_GRADLE"
    fi
}

# Generate summary
generate_summary() {
    echo ""
    echo -e "${GREEN}=== Setup Complete ===${NC}"
    echo ""
    echo "Summary of created resources:"
    echo "  - Project ID: $PROJECT_ID"
    echo "  - Package Name: $PACKAGE_NAME"
    echo "  - SHA-1 Fingerprint: $SHA1_FINGERPRINT"
    if [ ! -z "$CLIENT_ID" ]; then
        echo "  - OAuth Client ID: $CLIENT_ID"
    fi
    echo ""
    echo "Next steps:"
    echo "1. Download updated google-services.json from Google Cloud Console"
    echo "2. Replace app/google-services.json with the new file"
    echo "3. Sync your project in Android Studio"
    echo "4. Test OAuth authentication in your app"
    echo ""
    echo "Useful links:"
    echo "  - Google Cloud Console: https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID"
    echo "  - OAuth Consent Screen: https://console.cloud.google.com/apis/credentials/consent?project=$PROJECT_ID"
    echo ""
    
    # Save configuration for future reference
    cat > oauth_setup_summary.txt << EOF
OAuth Setup Summary
==================
Date: $(date)
Project ID: $PROJECT_ID
Package Name: $PACKAGE_NAME
SHA-1 Fingerprint: $SHA1_FINGERPRINT
Client ID: ${CLIENT_ID:-"Manual creation required"}
Support Email: ${SUPPORT_EMAIL:-"Not set"}

Google Cloud Console Links:
- Credentials: https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID
- OAuth Consent: https://console.cloud.google.com/apis/credentials/consent?project=$PROJECT_ID
EOF
    
    print_status "Setup summary saved to oauth_setup_summary.txt"
}

# Main execution
main() {
    echo "Starting automated OAuth client ID setup..."
    echo ""
    
    check_gcloud
    check_auth
    setup_project
    enable_apis
    get_sha1_fingerprint
    configure_consent_screen
    create_oauth_client
    update_google_services
    update_dependencies
    generate_summary
    
    echo ""
    echo -e "${GREEN}OAuth client ID setup completed!${NC}"
}

# Run main function
main "$@"
