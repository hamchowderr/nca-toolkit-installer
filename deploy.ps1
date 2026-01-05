<#
.SYNOPSIS
    Deploys the NCA Toolkit to Google Cloud from Windows.
.DESCRIPTION
    This script automates the creation of a Cloud Storage Bucket, Service Account,
    and Cloud Run service for the NCA Toolkit.
#>

# Configuration
$ImageName = "stephengpope/no-code-architects-toolkit:latest"
$Region = "us-central1" # Default region, can be changed
$ServiceName = "nca-toolkit"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   NCA TOOLKIT - GOOGLE CLOUD DEPLOYER (WINDOWS)" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# 1. Check for Gcloud CLI
try {
    $gcloudVersion = gcloud --version 2>&1
    if ($LASTEXITCODE -ne 0) { throw }
} catch {
    Write-Error "❌ Google Cloud SDK (gcloud) is not installed or not found in PATH."
    Write-Host "Please install it from: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    exit 1
}

# 2. Login / Project Selection
Write-Host "`nchecking authentication..." -ForegroundColor Gray
$CurrentProject = gcloud config get-value project 2>$null
if ([string]::IsNullOrWhiteSpace($CurrentProject)) {
    Write-Host "⚠️  No active project selected." -ForegroundColor Yellow
    Write-Host "Please login and select a project."
    gcloud auth login
    $ProjectId = Read-Host "Enter your Google Cloud Project ID (e.g. my-nca-project)"
    gcloud config set project $ProjectId
} else {
    Write-Host "Active Project: $CurrentProject" -ForegroundColor Green
    $UseCurrent = Read-Host "Deploy to this project? (Y/n)"
    if ($UseCurrent -eq 'n') {
        $ProjectId = Read-Host "Enter your Google Cloud Project ID"
        gcloud config set project $ProjectId
    } else {
        $ProjectId = $CurrentProject
    }
}

# 3. Generate Random Names
$RandomId = Get-Random -Minimum 10000 -Maximum 99999
$BucketName = "nca-toolkit-storage-$RandomId"
$SaName = "nca-toolkit-sa"
$SaEmail = "$SaName@$ProjectId.iam.gserviceaccount.com"

# 4. Enable APIs
Write-Host "`n1️⃣  Enabling necessary Google Cloud APIs..." -ForegroundColor Cyan
gcloud services enable run.googleapis.com storage.googleapis.com iam.googleapis.com

# 5. Create Service Account
Write-Host "`n2️⃣  Creating Service Account ($SaName)..." -ForegroundColor Cyan
$SaExists = gcloud iam service-accounts describe $SaEmail 2>&1
if ($LASTEXITCODE -ne 0) {
    gcloud iam service-accounts create $SaName --display-name="NCA Toolkit SA"
} else {
    Write-Host "   Service account already exists, skipping..." -ForegroundColor DarkGray
}

# 6. Create Storage Bucket
Write-Host "`n3️⃣  Creating Storage Bucket ($BucketName)..." -ForegroundColor Cyan
# Check if bucket exists (simple check)
$BucketExists = gcloud storage buckets list gs://$BucketName 2>&1
if ($BucketExists -notmatch $BucketName) {
    gcloud storage buckets create gs://$BucketName --location=$Region
    
    Write-Host "   Setting public access permissions..." -ForegroundColor DarkGray
    gcloud storage buckets add-iam-policy-binding gs://$BucketName `
        --member=allUsers --role=roles/storage.objectViewer
} else {
    Write-Host "   Bucket already exists." -ForegroundColor Yellow
}

# 7. Grant Permissions
Write-Host "`n4️⃣  Granting Storage Admin role to Service Account..." -ForegroundColor Cyan
gcloud projects add-iam-policy-binding $ProjectId `
    --member=serviceAccount:$SaEmail `
    --role=roles/storage.admin --condition=None --quiet

# 8. Create Service Account Key (Required by App)
Write-Host "`n5️⃣  Generating Service Account Key (required by app)..." -ForegroundColor Cyan
$KeyFile = "gcp_key_temp.json"
gcloud iam service-accounts keys create $KeyFile `
    --iam-account=$SaEmail `
    --quiet

# Read and format key for Env Var
$KeyContent = Get-Content $KeyFile -Raw
# Compress JSON to single line
$KeyContent = $KeyContent -replace "`r", "" -replace "`n", "" -replace "  ", "" 

# 9. Deploy to Cloud Run
Write-Host "`n6️⃣  Deploying to Cloud Run (this takes a few minutes)..." -ForegroundColor Cyan

# Ask for API Key
$ApiKey = Read-Host "Create an API KEY for your toolkit (e.g. mySecret123)"
if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    $ApiKey = "nca-" + (Get-Random -Minimum 100000 -Maximum 999999)
    Write-Host "   Using generated key: $ApiKey" -ForegroundColor Yellow
}

# Deploy
# Note: passing JSON in env vars via CLI can be tricky. We use specific escaping for PowerShell.
# We map the JSON key to GCP_SA_CREDENTIALS
gcloud run deploy $ServiceName `
    --image $ImageName `
    --platform managed `
    --region $Region `
    --allow-unauthenticated `
    --service-account $SaEmail `
    --set-env-vars "API_KEY=$ApiKey" `
    --set-env-vars "GCP_BUCKET_NAME=$BucketName" `
    --set-env-vars "GUNICORN_TIMEOUT=300" `
    --set-env-vars "GUNICORN_WORKERS=4" `
    --set-env-vars "GCP_SA_CREDENTIALS=$KeyContent" `
    --port 8080 `
    --memory 2Gi `
    --cpu 2

# Cleanup Key
Remove-Item $KeyFile -ErrorAction SilentlyContinue

if ($LASTEXITCODE -eq 0) {
    # Get the URL
    $ServiceUrl = gcloud run services describe $ServiceName --region $Region --format 'value(status.url)'
    
    Write-Host "`n✅ DEPLOYMENT COMPLETE!" -ForegroundColor Green
    Write-Host "--------------------------------------------------------"
    Write-Host "URL:         $ServiceUrl"
    Write-Host "Bucket:      $BucketName"
    Write-Host "API Key:     $ApiKey"
    Write-Host "Test Link:   $ServiceUrl/v1/toolkit/test"
    Write-Host "--------------------------------------------------------"
    
    # Run a quick test
    Write-Host "Running connectivity test..."
    try {
        $TestResponse = Invoke-RestMethod -Uri "$ServiceUrl/v1/toolkit/test" -Headers @{"x-api-key"=$ApiKey}
        Write-Host "Test Response: $($TestResponse.message)" -ForegroundColor Green
    } catch {
        Write-Host "Test failed (might just need a moment to start up)." -ForegroundColor Yellow
    }
} else {
    Write-Error "Deployment failed. Check the logs above."
}
