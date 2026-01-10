# NCA Toolkit - One-Click GCP Installer

Deploy the [No-Code Architects Toolkit](https://github.com/stephengpope/no-code-architects-toolkit) to Google Cloud Platform with one click.

---

## 🚀 Deploy Now

Click the button below to open Google Cloud Shell and run the installer:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/hamchowderr/nca-toolkit-installer&cloudshell_git_branch=main&cloudshell_workspace=.&cloudshell_tutorial=tutorial.md)

---

## Prerequisites

Before clicking the button, make sure you have:

- ✅ **Google Workspace account** (recommended)
- ✅ **GCP Project** with billing enabled
- ✅ ~5 minutes

> **New to GCP?** New accounts get $300 in free credits. [Sign up here](https://cloud.google.com/).

---

## What This Installer Does

| Step | Manual Process | This Installer |
|------|---------------|----------------|
| 1 | Enable 5 APIs manually | ✅ Automatic |
| 2 | Create service account | ✅ Automatic |
| 3 | Assign IAM roles | ✅ Automatic |
| 4 | Generate JSON credentials | ✅ Automatic |
| 5 | Create storage bucket | ✅ Automatic + public read |
| 6 | Deploy Cloud Run (16GB, 4 CPU, Gen2) | ✅ Pre-configured |
| 7 | Set all environment variables | ✅ Automatic |

**Time:** ~30 min manual → ~5 min with installer

---

## Deployment Specs

The installer configures Cloud Run with these settings (matching [official NCA docs](https://github.com/stephengpope/no-code-architects-toolkit/blob/main/docs/cloud-installation/gcp.md)):

| Setting | Value |
|---------|-------|
| Memory | 16 GB |
| CPU | 4 vCPUs |
| Min Instances | 0 (scale to zero) |
| Max Instances | 5 |
| Timeout | 300 seconds |
| Execution Environment | Gen2 |
| CPU Boost | Enabled |

---

## What You'll Be Asked

The script prompts for:

1. **Project ID** - Select existing or create new
2. **API Key** - Your choice or auto-generated (save this!)
3. **Region** - Where to deploy (default: `us-central1`)
4. **Service Name** - Name for Cloud Run service (default: `nca-toolkit`)
5. **Bucket Name** - For file storage (default: `{project-id}-nca-toolkit`)

---

## After Deployment

You'll receive:

```
╔══════════════════════════════════════════════════════════════╗
║                    DEPLOYMENT COMPLETE!                       ║
╚══════════════════════════════════════════════════════════════╝

  Service URL:    https://nca-toolkit-xxxxx-xx.a.run.app
  API Key:        your-api-key-here
  Bucket:         your-project-nca-toolkit
  Region:         us-central1
```

Config is also saved to `~/nca-toolkit-config.txt` in Cloud Shell.

---

## Test Your Deployment

```bash
curl -X GET "YOUR_SERVICE_URL/v1/toolkit/test" \
  -H "x-api-key: YOUR_API_KEY"
```

**Expected response:**
```json
{
  "code": 200,
  "message": "success"
}
```

---

## Using with n8n / Make

### n8n
1. Add **HTTP Request** node
2. Method: `GET`
3. URL: `https://YOUR-SERVICE-URL/v1/toolkit/test`
4. Header: `x-api-key` = `YOUR-API-KEY`

### Make
1. Add **HTTP > Make a request** module
2. Method: `GET`
3. URL: `https://YOUR-SERVICE-URL/v1/toolkit/test`
4. Header: `x-api-key` = `YOUR-API-KEY`

### Postman
1. Import the [Postman Collection](https://bit.ly/49Gkh61)
2. Set environment variables:
   - `base_url`: Your Service URL
   - `x-api-key`: Your API Key

---

## Manual Installation (Alternative)

If the button doesn't work, run manually in [Cloud Shell](https://shell.cloud.google.com):

```bash
git clone https://github.com/hamchowderr/nca-toolkit-installer.git
cd nca-toolkit-installer
chmod +x deploy.sh
./deploy.sh
```

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| "Billing not enabled" | No payment method | [Enable billing](https://console.cloud.google.com/billing) |
| "Permission denied" on service account | Org policy | Contact Workspace admin |
| "Public access prevention" on bucket | Org policy | Contact Workspace admin or use different project |
| Deployment timeout | Large image pull | Wait and retry |
| `401 Unauthorized` on test | Wrong API key | Check key matches what you entered |

---

## Resources

- [NCA Toolkit Repository](https://github.com/stephengpope/no-code-architects-toolkit)
- [Full GCP Installation Docs](https://github.com/stephengpope/no-code-architects-toolkit/blob/main/docs/cloud-installation/gcp.md)
- [API Documentation](https://github.com/stephengpope/no-code-architects-toolkit/tree/main/docs)
- [Video Tutorial](https://youtu.be/6bC93sek9v8)
- [NCA Community](https://skool.com/no-code-architects)

---

## License

This installer is provided as-is. The NCA Toolkit itself is licensed under [GPL-2.0](https://github.com/stephengpope/no-code-architects-toolkit/blob/main/LICENSE).
