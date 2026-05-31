# DNS Fix — aireadyaudit.com.au + aireadyaudit.co → Netlify

**Status:** Manual action required by Founder  
**Priority:** High — both domains currently show parking page (103.42.108.46)  
**Target:** Site is live at `aireadyaudit.netlify.app`

---

## What Needs to Happen

Two domains need DNS records updated at their registrar(s). The Netlify site is already deployed — this is purely a DNS change.

---

## Exact DNS Records to Add

### For aireadyaudit.com.au

```
Type:  CNAME
Name:  www
Value: aireadyaudit.netlify.app
TTL:   3600 (or Auto)

Type:  A  (apex/root — some registrars support ALIAS/ANAME)
Name:  @  (or blank / aireadyaudit.com.au)
Value: 75.2.60.5    ← Netlify's load balancer IP
Alt:   99.83.190.102 ← (add both if registrar supports multiple A records)
```

> ⚠️ If your registrar supports ALIAS or ANAME records for the apex (@), use:
> `ALIAS @ → aireadyaudit.netlify.app` instead of the A record approach.

### For aireadyaudit.co

```
Type:  CNAME
Name:  www
Value: aireadyaudit.netlify.app
TTL:   3600 (or Auto)

Type:  A  (apex/root)
Name:  @
Value: 75.2.60.5
Alt:   99.83.190.102
```

---

## Step-by-Step: What the Founder Needs to Do

### Step 1 — Log in to your domain registrar

Both domains currently resolve to **103.42.108.46** which is a parking page.

Common registrars for .com.au domains: **VentraIP, Crazy Domains, NetRegistry, GoDaddy Australia, TPP Wholesale, Synergy Wholesale**

Log in to whichever registrar you used when purchasing aireadyaudit.com.au and aireadyaudit.co.

### Step 2 — Find DNS Management

Look for: DNS Zone, DNS Records, DNS Settings, or Manage DNS.

### Step 3 — Delete the existing A record

Remove or replace the current `A @ 103.42.108.46` record (the parking record).

### Step 4 — Add the new records (from the table above)

Add CNAME for `www` → `aireadyaudit.netlify.app`  
Add A record for `@` (apex) → `75.2.60.5`

Repeat for both domains.

### Step 5 — Add Custom Domain in Netlify

1. Go to [app.netlify.com](https://app.netlify.com)
2. Open your site (aireadyaudit.netlify.app)
3. Go to **Site Settings → Domain management → Add custom domain**
4. Enter: `aireadyaudit.com.au` → Verify and confirm
5. Repeat for: `aireadyaudit.co` and `www.aireadyaudit.com.au` and `www.aireadyaudit.co`
6. Netlify will auto-provision SSL (Let's Encrypt) — usually takes 1–5 minutes after DNS propagates

### Step 6 — Wait for propagation

DNS changes can take 15 minutes to 48 hours. Usually faster (~30 min) for Netlify-pointed records.

Check propagation at: https://dnschecker.org/#CNAME/www.aireadyaudit.com.au

---

## Why We Can't Do This Automatically

The Cloudflare API token in secrets (`~/.openclaw/secrets/`) only has access to:
- domelyfe.com
- qualityprotectivecoatings.com
- qualitythermalsolutions.com

**aireadyaudit.com.au and aireadyaudit.co are not managed through Cloudflare** (or this token doesn't have zone permissions for them).

To automate future DNS changes, either:
- Move the domains to Cloudflare (free, recommended)
- Add a new Cloudflare API token with access to these zones

---

## Optional: Move to Cloudflare (Recommended)

Cloudflare nameservers are faster, free, and give us API control.

1. Add aireadyaudit.com.au as a site at cloudflare.com
2. Cloudflare will scan existing DNS records
3. Update nameservers at your registrar to Cloudflare's NS records
4. Add the Cloudflare Zone ID to secrets so Forge can manage DNS programmatically

---

_Last updated: 2026-03-28 | Created by Forge_
