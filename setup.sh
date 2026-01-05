#!/bin/bash

# ==============================================================================
# NCA TOOLKIT AUTO-SETUP SCRIPT (Cloud Shell Compatible)
# ==============================================================================

# Configuration
SERVICE_NAME="nca-toolkit"
SA_NAME="nca-toolkit-sa"
REGION="${GOOGLE_CLOUD_REGION:-us-central1}"

echo "--------------------------------------------------------"
echo "🛠️  STARTING AUTO-SETUP..."
echo "--------------------------------------------------------"

# 1. GET PROJECT ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: No Google Cloud Project selected."
    echo "   Please run 'gcloud config set project YOUR_PROJECT_ID' and try again."
    exit 1
fi
echo "📍 Project: $PROJECT_ID"
echo "📍 Region:  $REGION"

# 2. GENERATE UNIQUE BUCKET NAME
# We use the Project ID hash to ensure it's unique but consistent for this project
PROJECT_HASH=$(echo -n "$PROJECT_ID" | md5sum | cut -c1-6)
BUCKET_NAME="nca-toolkit-${PROJECT_HASH}"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# 3. ENABLE APIS
echo "🔌 Enabling required APIs (this may take a minute)..."
gcloud services enable run.googleapis.com storage.googleapis.com iam.googleapis.com >/dev/null 2>&1

# 4. CREATE SERVICE ACCOUNT
if gcloud iam service-accounts describe "$SA_EMAIL" >/dev/null 2>&1; then
    echo "✅ Service Account $SA_NAME already exists."
else
    echo "👤 Creating Service Account: $SA_NAME..."
    gcloud iam service-accounts create "$SA_NAME" --display-name="NCA Toolkit SA"
fi

# 5. CREATE STORAGE BUCKET
if gsutil ls -b "gs://$BUCKET_NAME" >/dev/null 2>&1; then
    echo "✅ Bucket $BUCKET_NAME already exists."
else
    echo "📦 Creating Storage Bucket: $BUCKET_NAME..."
    gcloud storage buckets create "gs://$BUCKET_NAME" --location="$REGION"
    
    echo "🔓 Setting Public Access permissions..."
    gcloud storage buckets add-iam-policy-binding "gs://$BUCKET_NAME" \
        --member=allUsers --role=roles/storage.objectViewer >/dev/null 2>&1
fi

# 6. GRANT PERMISSIONS
echo "🔐 Granting Storage Admin role..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role=roles/storage.admin --condition=None --quiet >/dev/null 2>&1

# 7. GENERATE SA KEY (Required by App)
echo "🔑 Generating Service Account Key..."
KEY_FILE="nca-key.json"
gcloud iam service-accounts keys create "$KEY_FILE" \
    --iam-account="$SA_EMAIL" \
    --quiet >/dev/null 2>&1

# Read key and compact it (remove newlines)
SA_CREDENTIALS=$(cat "$KEY_FILE" | tr -d '\n')

# 8. UPDATE CLOUD RUN SERVICE
echo "🔄 Configuring Cloud Run Service: $SERVICE_NAME..."

# Update with Bucket, Credentials, and Performance settings
gcloud run services update "$SERVICE_NAME" \
    --region="$REGION" \
    --service-account="$SA_EMAIL" \
    --update-env-vars=GCP_BUCKET_NAME="$BUCKET_NAME" \
    --update-env-vars=GCP_SA_CREDENTIALS="$SA_CREDENTIALS" \
    --update-env-vars=GUNICORN_TIMEOUT=300 \
    --update-env-vars=GUNICORN_WORKERS=4 \
    --quiet

# Cleanup key
rm "$KEY_FILE"

if [ $? -eq 0 ]; then
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format='value(status.url)')
    
    echo "--------------------------------------------------------"
    echo "✅ SETUP COMPLETE!"
    echo "--------------------------------------------------------"
    echo "👉 App URL:     $SERVICE_URL"
    echo "👉 Bucket Name: $BUCKET_NAME"
    echo "👉 Test URL:    $SERVICE_URL/v1/toolkit/test"
    echo "--------------------------------------------------------"
else
    echo "⚠️  Service update failed. The service '$SERVICE_NAME' might not be deployed yet."
    echo "   Ensure you are running this after the Cloud Run deployment starts."
fi
