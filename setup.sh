#!/bin/bash

# ==============================================================================
# NCA TOOLKIT AUTO-SETUP SCRIPT
# ==============================================================================
# This script automates the manual steps from the installation tutorial:
# 1. Creates a unique Cloud Storage Bucket.
# 2. Creates a Service Account with the correct permissions.
# 3. Links them to the Cloud Run service.
# 4. Tests the API to verify everything works.
# ==============================================================================

# 1. GENERATE UNIQUE BUCKET NAME
RANDOM_ID=$((10000 + RANDOM % 90000))
BUCKET_NAME="nca-toolkit-storage-${RANDOM_ID}"
SA_NAME="nca-toolkit-sa"

echo "--------------------------------------------------------"
echo "🛠️  STARTING AUTO-SETUP..."
echo "--------------------------------------------------------"

# 2. WAIT FOR APIS
echo "⏳ Waiting 10 seconds for Google Cloud APIs to warm up..."
sleep 10

# 3. CREATE STORAGE BUCKET
if gsutil ls -b gs://$BUCKET_NAME >/dev/null 2>&1; then
    echo "✅ Bucket $BUCKET_NAME already exists."
else
    echo "📦 Creating Storage Bucket: $BUCKET_NAME..."
    gcloud storage buckets create gs://$BUCKET_NAME --location=$GOOGLE_CLOUD_REGION
    
    echo "🔓 Setting Public Access permissions..."
    gcloud storage buckets add-iam-policy-binding gs://$BUCKET_NAME \
        --member=allUsers --role=roles/storage.objectViewer
fi

# 4. CREATE SERVICE ACCOUNT
if gcloud iam service-accounts describe $SA_NAME@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com >/dev/null 2>&1; then
    echo "✅ Service Account $SA_NAME already exists."
else
    echo "🔧 Creating Service Account: $SA_NAME..."
    gcloud iam service-accounts create $SA_NAME --display-name="NCA Toolkit SA"
fi

# 5. ASSIGN ROLES (Storage Admin)
echo "🔐 Granting permissions to Service Account..."
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
    --member=serviceAccount:$SA_NAME@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com \
    --role=roles/storage.admin

# 6. INJECT CONFIG INTO CLOUD RUN
echo "🔄 Updating Cloud Run configuration..."
gcloud run services update $K_SERVICE \
    --service-account=$SA_NAME@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com \
    --update-env-vars=GCP_BUCKET_NAME=$BUCKET_NAME \
    --region=$GOOGLE_CLOUD_REGION \
    --quiet

# 7. TEST API CONNECTION
echo "⏳ Waiting 15 seconds for Cloud Run to restart..."
sleep 15

SERVICE_URL=$(gcloud run services describe $K_SERVICE --region=$GOOGLE_CLOUD_REGION --format='value(status.url)')

echo "🧪 Testing API connection..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$SERVICE_URL/v1/toolkit/test" -H "x-api-key: $API_KEY")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ API test passed! Bucket connection verified."
else
    echo "⚠️ API returned status code: $HTTP_CODE"
    echo "   Response: $BODY"
    echo "   (This may be normal during initial startup - try manually in 30 seconds)"
fi

echo "--------------------------------------------------------"
echo "✅ SETUP COMPLETE!"
echo "--------------------------------------------------------"
echo "👉 Your API URL: $SERVICE_URL"
echo "👉 Your Bucket Name: $BUCKET_NAME"
echo "--------------------------------------------------------"
