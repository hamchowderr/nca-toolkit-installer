# NCA Toolkit - GCP Deployment

<walkthrough-tutorial-duration duration="5"></walkthrough-tutorial-duration>

## Welcome

This tutorial deploys the **No-Code Architects Toolkit API** to Google Cloud Platform.

**What you'll get:**
- Cloud Run service (16GB RAM, 4 CPU, Gen2)
- Cloud Storage bucket with public read access
- Service account with proper permissions
- Your API endpoint and key

<walkthrough-tutorial-difficulty difficulty="2"></walkthrough-tutorial-difficulty>

Click **Next** to begin.

## Select Your Project

First, select or create a Google Cloud project.

<walkthrough-project-setup billing="true"></walkthrough-project-setup>

**Important:** 
- Billing must be enabled
- New accounts get $300 in free credits

Once your project is selected, click **Next**.

## Run the Deployment Script

Now let's deploy. Run this command in the terminal below:

```bash
chmod +x deploy.sh && ./deploy.sh
```

The script will prompt you for:
- **Project ID** - Your selected project
- **API Key** - Choose your own or press Enter for random
- **Region** - Default is `us-central1`
- **Service Name** - Default is `nca-toolkit`
- **Bucket Name** - Default is `{project}-nca-toolkit`

<walkthrough-footnote>Deployment takes 3-5 minutes. Don't close the window.</walkthrough-footnote>

## Deployment Complete

When finished, you'll see:

```
╔══════════════════════════════════════════════════════════════╗
║                    DEPLOYMENT COMPLETE!                       ║
╚══════════════════════════════════════════════════════════════╝

  Service URL:    https://nca-toolkit-xxxxx.run.app
  API Key:        your-api-key-here
  Bucket:         your-bucket-name
```

**Save these values!** They're also in `~/nca-toolkit-config.txt`

## Test Your API

Verify the deployment works:

```bash
# View your saved config
cat ~/nca-toolkit-config.txt
```

Then test the API (replace with your values):

```bash
curl -X GET "YOUR_SERVICE_URL/v1/toolkit/test" \
  -H "x-api-key: YOUR_API_KEY"
```

You should get a success response.

## Next Steps

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

**Your NCA Toolkit is ready!**

### Set up Postman
1. Import [Postman Collection](https://bit.ly/49Gkh61)
2. Set `base_url` to your Service URL
3. Set `x-api-key` to your API Key

### Useful Links
- [Cloud Run Console](https://console.cloud.google.com/run)
- [API Documentation](https://github.com/stephengpope/no-code-architects-toolkit/tree/main/docs)
- [NCA Community](https://skool.com/no-code-architects)

### Need Help?
Join the [No-Code Architects Community](https://www.skool.com/no-code-architects)
