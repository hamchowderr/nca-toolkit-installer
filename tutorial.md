# NCA Toolkit - GCP Deployment

<walkthrough-tutorial-duration duration="5"></walkthrough-tutorial-duration>

## Welcome

This tutorial deploys the **No-Code Architects Toolkit API** to Google Cloud Platform.

**What you'll get:**
- Cloud Run service (16GB RAM, 4 CPU)
- Cloud Storage bucket
- Your API endpoint and key

Click **Next** to begin.

## Select Your Project

Select the Google Cloud project where you want to deploy:

<walkthrough-project-setup billing="true"></walkthrough-project-setup>

**Important:** Billing must be enabled on your project.

Once selected, click **Next**.

## Run the Installer

Run this command in the terminal:

```bash
chmod +x deploy.sh && ./deploy.sh
```

The script will:
1. ✅ Use the project you selected above
2. Ask for your **API key** (or generate one)
3. Ask for your preferred **region**
4. Create everything automatically

<walkthrough-footnote>Deployment takes about 3 minutes.</walkthrough-footnote>

## Save Your Credentials

When complete, you'll see:

```
╔══════════════════════════════════════════════════════════════╗
║                    DEPLOYMENT COMPLETE!                       ║
╚══════════════════════════════════════════════════════════════╝

  Service URL:    https://nca-toolkit-xxxxx.run.app
  API Key:        your-api-key-here
```

**Save these!** They're also stored in `~/nca-toolkit-config.txt`

## Done!

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

**Your NCA Toolkit is ready!**

### Test it:
```bash
cat ~/nca-toolkit-config.txt
```

### Next steps:
- Import [Postman Collection](https://bit.ly/49Gkh61)
- Read the [API Docs](https://github.com/stephengpope/no-code-architects-toolkit/tree/main/docs)
- Join [NCA Community](https://skool.com/no-code-architects)
