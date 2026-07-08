# ⚠️ Gemini API Quota Exceeded

## The Problem

Your API returned: **Error 429 - Quota Exceeded**

```
"You exceeded your current quota, please check your plan and billing details."
```

**Your free tier quota is: 0** (completely used up)

---

## How to Fix It (3 Options)

### ✅ Option 1: Enable Billing (Recommended for Development)

1. Go to: https://console.cloud.google.com/
2. **Find your project** (top-left dropdown)
3. Click the **project name** to go to project settings
4. On the left sidebar, click **Billing**
5. Click **Link a billing account**
6. Select your existing billing account or **Create a new one**
7. Add a **valid payment method** (credit card)

**Then wait 5-10 minutes** for the quota to refresh.

Your free tier includes:
- **1.5 million tokens/month** (free)
- Pay-as-you-go rates: ~$0.075 per 1M input tokens, ~$0.30 per 1M output tokens

---

### ✅ Option 2: Check Your Current Quota

1. Go to: https://ai.google.dev/rate-limit
2. Check your current usage
3. See when quota resets (typically daily for free tier)

---

### ✅ Option 3: Use Alternative Models

The service now tries these models in order:
1. `gemini-1.5-flash` (cheaper, faster)
2. `gemini-1.5-pro` (more capable)
3. `gemini-pro-vision` (older, might have different quotas)

**Test different models** by setting in `.env`:
```env
GEMINI_MODEL=gemini-1.5-pro
```

Then restart: `rails s`

---

## Verify It's Working

After enabling billing/quota:

### 1. Test in Rails Console
```bash
rails console

result = ImageAnalysis::GeminiVisionService.call("https://example.com/food.jpg")
puts result.inspect
```

You should see actual nutrition data (not "Plat détecté (mock)").

### 2. Upload a Test Image
1. Go to your app
2. Upload a food image
3. **Wait 5-10 seconds** (not instant - API takes time)
4. See real Gemini analysis appear

---

## Verify the Fix

Check your logs:
```bash
tail -f log/development.log | grep -i "gemini"
```

You should see:
```
Analyzing image with Gemini: http://localhost:3000/...
gemini-1.5-flash response status: 200
Gemini raw response: {"name": "...", "calories": ...}
```

NOT:
```
Status: 429
All Gemini models failed, falling back to mock
```

---

## Quick Checklist

- [ ] API key is set in `.env`
- [ ] Billing is **enabled** in Google Cloud Console
- [ ] Payment method is **valid**
- [ ] At least 5 minutes have passed since enabling billing
- [ ] Rails server is **restarted** after changes
- [ ] Quota shows **usage** (not 0) on https://ai.google.dev/rate-limit

---

## Still Getting Mock Data?

1. Check logs: `tail -50 log/development.log`
2. Look for error messages starting with "Gemini"
3. Copy the error message and check Google Cloud Console
4. Verify billing is actually enabled (not just selected)

---

## Free Tier Limits

| Metric | Limit |
|--------|-------|
| RPM (requests/minute) | 15 |
| Tokens/minute | 1M |
| Tokens/day | ~400K (approx) |

Each food image analysis = ~500-1000 tokens

---

## Support

If still having issues:
- Check: https://status.cloud.google.com/ (API status)
- Test: https://ai.google.dev/tutorials/rest_quickstart
- Docs: https://ai.google.dev/docs/rate-limits
