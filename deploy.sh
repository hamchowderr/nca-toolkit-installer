#!/bin/bash
# NCA Toolkit - One-Click GCP Deployment Script
# https://github.com/stephengpope/no-code-architects-toolkit
#
# This script automates the deployment process for Google Workspace users.
# Run via Cloud Shell button or manually in Cloud Shell.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration defaults
DOCKER_IMAGE="stephengpope/no-code-architects-toolkit:latest"
CLOUD_RUN_MEMORY="16Gi"
CLOUD_RUN_CPU="4"
CLOUD_RUN_TIMEOUT="300"
CLOUD_RUN_MIN_INSTANCES="0"
CLOUD_RUN_MAX_INSTANCES="5"
CONTAINER_PORT="8080"

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║       NCA Toolkit - One-Click GCP Deployment                 ║"
echo "║       No-Code Architects Toolkit API                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# =============================================================================
# PREREQUISITE CHECKS
# =============================================================================

echo -e "${YELLOW}[1/8] Checking prerequisites...${NC}"

# Check if gcloud is available
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}ERROR: gcloud CLI not found. Please run this in Google Cloud Shell.${NC}"
    exit 1
fi

# Check if user is authenticated
ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
if [ -z "$ACCOUNT" ]; then
    echo -e "${YELLOW}Not authenticated. Starting authentication...${NC}"
    gcloud auth login --no-launch-browser
    ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
fi
echo -e "${GREEN}✓ Authenticated as: ${ACCOUNT}${NC}"

# =============================================================================
# PROJECT SELECTION
# =============================================================================

echo ""
echo -e "${YELLOW}[2/8] Project Selection${NC}"
echo ""

# List available projects in a readable format
echo "Available projects:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "  ${BLUE}%-45s${NC} %s\n" "PROJECT ID" "NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
gcloud projects list --format="csv[no-heading](projectId,name)" 2>/dev/null | while IFS=',' read -r id name; do
    printf "  %-45s %s\n" "$id" "$name"
done
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
read -p "Enter your GCP Project ID (or 'new' to create one): " PROJECT_ID

if [ "$PROJECT_ID" == "new" ]; then
    read -p "Enter new project ID (lowercase, no spaces): " PROJECT_ID
    read -p "Enter project name: " PROJECT_NAME
    
    echo "Creating project..."
    gcloud projects create "$PROJECT_ID" --name="$PROJECT_NAME" || {
        echo -e "${RED}Failed to create project. It may already exist or you lack permissions.${NC}"
        exit 1
    }
fi

# Set the project
gcloud config set project "$PROJECT_ID"
echo -e "${GREEN}✓ Using project: ${PROJECT_ID}${NC}"

# Check if billing is enabled
BILLING_ENABLED=$(gcloud beta billing projects describe "$PROJECT_ID" --format="value(billingEnabled)" 2>/dev/null || echo "false")
if [ "$BILLING_ENABLED" != "True" ]; then
    echo -e "${RED}ERROR: Billing is not enabled for this project.${NC}"
    echo "Please enable billing at: https://console.cloud.google.com/billing/linkedaccount?project=${PROJECT_ID}"
    echo ""
    read -p "Press Enter after enabling billing to continue..."
fi

# =============================================================================
# ENABLE REQUIRED APIS
# =============================================================================

echo ""
echo -e "${YELLOW}[3/8] Enabling required APIs...${NC}"

APIS=(
    "run.googleapis.com"
    "storage.googleapis.com"
    "storage-api.googleapis.com"
    "iam.googleapis.com"
    "cloudresourcemanager.googleapis.com"
)

for api in "${APIS[@]}"; do
    echo "  Enabling $api..."
    gcloud services enable "$api" --quiet || {
        echo -e "${RED}Failed to enable $api${NC}"
        exit 1
    }
done
echo -e "${GREEN}✓ All APIs enabled${NC}"

# =============================================================================
# USER INPUT
# =============================================================================

echo ""
echo -e "${YELLOW}[4/8] Configuration${NC}"

# Generate a random API key suggestion
RANDOM_KEY=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)

read -p "Enter API key for your NCA Toolkit (or press Enter for random): " API_KEY
API_KEY=${API_KEY:-$RANDOM_KEY}

# Region selection
echo ""
echo "Available regions (recommended: us-central1, europe-west1, asia-east1):"
read -p "Enter Cloud Run region [us-central1]: " REGION
REGION=${REGION:-us-central1}

# Service name
read -p "Enter Cloud Run service name [nca-toolkit]: " SERVICE_NAME
SERVICE_NAME=${SERVICE_NAME:-nca-toolkit}

# Bucket name (must be globally unique)
SUGGESTED_BUCKET="${PROJECT_ID}-nca-toolkit"
read -p "Enter Cloud Storage bucket name [${SUGGESTED_BUCKET}]: " BUCKET_NAME
BUCKET_NAME=${BUCKET_NAME:-$SUGGESTED_BUCKET}

# Service account name
SA_NAME="nca-toolkit-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# =============================================================================
# CREATE SERVICE ACCOUNT
# =============================================================================

echo ""
echo -e "${YELLOW}[5/8] Creating service account...${NC}"

# Check if SA already exists
SA_EXISTS=$(gcloud iam service-accounts list --filter="email:${SA_EMAIL}" --format="value(email)" 2>/dev/null)

if [ -z "$SA_EXISTS" ]; then
    gcloud iam service-accounts create "$SA_NAME" \
        --display-name="NCA Toolkit Service Account" \
        --description="Service account for NCA Toolkit API"
    echo "  Created service account: ${SA_EMAIL}"
else
    echo "  Service account already exists: ${SA_EMAIL}"
fi

# Assign roles
echo "  Assigning roles..."
ROLES=(
    "roles/storage.admin"
    "roles/viewer"
)

for role in "${ROLES[@]}"; do
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:${SA_EMAIL}" \
        --role="$role" \
        --quiet 2>/dev/null || true
done

# Generate JSON key
echo "  Generating service account key..."
KEY_FILE="/tmp/nca-toolkit-sa-key.json"
gcloud iam service-accounts keys create "$KEY_FILE" \
    --iam-account="$SA_EMAIL" \
    --quiet

GCP_SA_CREDENTIALS=$(cat "$KEY_FILE" | tr -d '\n')
echo -e "${GREEN}✓ Service account configured${NC}"

# =============================================================================
# CREATE STORAGE BUCKET
# =============================================================================

echo ""
echo -e "${YELLOW}[6/8] Creating Cloud Storage bucket...${NC}"

# Check if bucket exists
if gsutil ls -b "gs://${BUCKET_NAME}" &>/dev/null; then
    echo "  Bucket already exists: ${BUCKET_NAME}"
else
    gsutil mb -l "$REGION" "gs://${BUCKET_NAME}" || {
        echo -e "${RED}Failed to create bucket. Name may be taken globally.${NC}"
        read -p "Enter a different bucket name: " BUCKET_NAME
        gsutil mb -l "$REGION" "gs://${BUCKET_NAME}"
    }
    echo "  Created bucket: ${BUCKET_NAME}"
fi

# Configure bucket for public read access
echo "  Configuring bucket permissions..."
gsutil uniformbucketlevelaccess set on "gs://${BUCKET_NAME}"
gsutil iam ch allUsers:objectViewer "gs://${BUCKET_NAME}"

echo -e "${GREEN}✓ Bucket configured with public read access${NC}"

# =============================================================================
# DEPLOY TO CLOUD RUN
# =============================================================================

echo ""
echo -e "${YELLOW}[7/8] Deploying to Cloud Run...${NC}"
echo "  This may take a few minutes..."

gcloud run deploy "$SERVICE_NAME" \
    --image="$DOCKER_IMAGE" \
    --platform=managed \
    --region="$REGION" \
    --allow-unauthenticated \
    --memory="$CLOUD_RUN_MEMORY" \
    --cpu="$CLOUD_RUN_CPU" \
    --timeout="$CLOUD_RUN_TIMEOUT" \
    --min-instances="$CLOUD_RUN_MIN_INSTANCES" \
    --max-instances="$CLOUD_RUN_MAX_INSTANCES" \
    --port="$CONTAINER_PORT" \
    --cpu-boost \
    --execution-environment=gen2 \
    --set-env-vars="API_KEY=${API_KEY}" \
    --set-env-vars="GCP_BUCKET_NAME=${BUCKET_NAME}" \
    --set-env-vars="^@^GCP_SA_CREDENTIALS=${GCP_SA_CREDENTIALS}" \
    --quiet

# Get the service URL
SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format="value(status.url)")

echo -e "${GREEN}✓ Deployment complete!${NC}"

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    DEPLOYMENT COMPLETE!                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo -e "${BLUE}Your NCA Toolkit API Details:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  Service URL:    ${GREEN}${SERVICE_URL}${NC}"
echo -e "  API Key:        ${GREEN}${API_KEY}${NC}"
echo -e "  Bucket:         ${GREEN}${BUCKET_NAME}${NC}"
echo -e "  Region:         ${GREEN}${REGION}${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo -e "${YELLOW}Quick Test:${NC}"
echo "curl -X GET \"${SERVICE_URL}/v1/toolkit/test\" \\"
echo "  -H \"x-api-key: ${API_KEY}\""

echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Test your deployment with the curl command above"
echo "  2. Import the Postman collection: https://bit.ly/49Gkh61"
echo "  3. Set base_url to: ${SERVICE_URL}"
echo "  4. Set x-api-key to: ${API_KEY}"

echo ""
echo -e "${YELLOW}Resources:${NC}"
echo "  • Cloud Run Console: https://console.cloud.google.com/run?project=${PROJECT_ID}"
echo "  • Storage Console: https://console.cloud.google.com/storage/browser/${BUCKET_NAME}?project=${PROJECT_ID}"
echo "  • NCA Toolkit Docs: https://github.com/stephengpope/no-code-architects-toolkit"

# Save config to file for reference
CONFIG_FILE="$HOME/nca-toolkit-config.txt"
cat > "$CONFIG_FILE" << EOF
NCA Toolkit Deployment - $(date)
================================
Project ID: ${PROJECT_ID}
Service URL: ${SERVICE_URL}
API Key: ${API_KEY}
Bucket Name: ${BUCKET_NAME}
Region: ${REGION}
Service Account: ${SA_EMAIL}
EOF

echo ""
echo -e "${GREEN}Configuration saved to: ${CONFIG_FILE}${NC}"

# Cleanup
rm -f "$KEY_FILE"

echo ""
echo -e "${GREEN}Done! Your NCA Toolkit is ready to use.${NC}"
