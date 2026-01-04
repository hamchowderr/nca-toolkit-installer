# No-Code Architects Toolkit (One-Click Installer)

This repository provides an automated installer for Stephen Pope's **NCA Toolkit**. It automatically provisions the necessary Cloud Storage buckets and Service Accounts so you don't have to do it manually.

---

## ⚠️ READ BEFORE CLICKING

1. **Create a NEW Google Cloud Project** — When prompted, create a dedicated project (e.g., `nca-toolkit-production`). Don't deploy this into a project that contains other apps or sensitive data.

2. **Billing Required** — You need a Google Cloud account with a valid credit card on file (even for the free tier).

3. **Wait for it** — The setup takes about **3 minutes**. Do not close the window until you see the green success checkmark.

4. **API Key** — When asked, create a strong password (e.g., `my-secret-key-123`). You will need this later to connect your automation platform.

---

## 🚀 Deploy Now

Click the button below to start the installation in Google Cloud Shell.

[![Run on Google Cloud](https://deploy.cloud.run/button.svg)](https://deploy.cloud.run)

---

## What does this do?

- Deploys the `stephengpope/no-code-architects-toolkit` Docker image
- Creates a private **Service Account** with storage permissions
- Creates a publicly accessible **Storage Bucket** (auto-named)
- Configures the toolkit to use these resources automatically
- Runs a test API call to verify everything works

---

## After Deployment

1. Copy your Cloud Run URL from the deployment logs (looks like `https://nca-toolkit-xxxxx-xx.a.run.app`)
2. Copy your Bucket Name from the deployment logs
3. Use the test request below to verify your setup

---

## Test Your Installation

Use this request to verify your NCA Toolkit is working. This works in **n8n**, **Make**, or any automation platform that supports HTTP requests.

```bash
curl -X GET "https://YOUR-CLOUD-RUN-URL/v1/toolkit/test" \
  -H "x-api-key: YOUR-API-KEY"
```

**Replace:**
- `YOUR-CLOUD-RUN-URL` — Your Cloud Run URL from the deployment logs
- `YOUR-API-KEY` — The API key you created during setup

**Expected Response (200 OK):**

```json
{
  "code": 200,
  "message": "success",
  "response": "https://storage.googleapis.com/nca-toolkit-storage-xxxxx/success.txt"
}
```

If you get this response, your toolkit is ready to use!

---

## Platform Setup Guides

### n8n
1. Add an **HTTP Request** node
2. Set method to `GET`
3. Set URL to `https://YOUR-CLOUD-RUN-URL/v1/toolkit/test`
4. Add header: `x-api-key` = `YOUR-API-KEY`

### Make
1. Add an **HTTP > Make a request** module
2. Set method to `GET`
3. Set URL to `https://YOUR-CLOUD-RUN-URL/v1/toolkit/test`
4. Add header: `x-api-key` = `YOUR-API-KEY`

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `401 Unauthorized` | Check your API key is correct |
| `500 Internal Server Error` | Wait 30 seconds and try again — Cloud Run may still be starting |
| Bucket permission errors | Verify the setup script completed successfully |

---

## Resources

- [NCA Toolkit GitHub](https://github.com/stephengpope/no-code-architects-toolkit)
- [NCA Toolkit API Documentation](https://github.com/stephengpope/no-code-architects-toolkit/tree/main/docs)
- [No-Code Architects Community](https://www.skool.com/no-code-architects)
