# AIReady Email Setup
**Domain:** aireadyaudit.com.au  
**Target Gmail:** ocpathfinderprime@gmail.com  
**Last updated:** 2026-03-28

---

## Status

No custom email hosting is active yet. DNS access is required to route email properly. Two paths forward are documented below.

**Immediate public contact:** `hello@aireadyaudit.com.au`  
**Internal note (not public):** Monitored via ocpathfinderprime@gmail.com once setup is complete.

---

## Option A — Zoho Mail (Recommended Free Tier)

Zoho Mail's free plan supports one custom domain, up to 5 users, 5 GB storage each. No credit card.

### What you get
- Real inbox at hello@aireadyaudit.com.au
- Web interface + mobile app
- Calendar, contacts included
- IMAP/POP **not** included on free tier (web only)
- Upgrade to Mail Lite (~$1/user/month) for IMAP access

### DNS records required (from your domain registrar)

You'll need to add these records in the DNS settings of wherever aireadyaudit.com.au is registered:

| Type | Name/Host | Value | TTL |
|------|-----------|-------|-----|
| MX | @ | mx.zoho.com.au | 3600 |
| MX | @ | mx2.zoho.com.au (priority 20) | 3600 |
| MX | @ | mx3.zoho.com.au (priority 50) | 3600 |
| TXT | @ | v=spf1 include:zoho.com.au ~all | 3600 |
| TXT | zmail._domainkey | (Zoho provides after signup) | 3600 |
| CNAME | mail | business.zoho.com.au | 3600 |

> **Note:** Zoho provides the exact records during setup — copy them directly from the Zoho Admin Console, not from a guide like this.

### Steps

1. Go to: https://www.zoho.com/mail/zohomail-pricing.html
2. Click **Sign Up** under the **Free Forever** plan
3. Choose **Custom Domain** setup
4. Enter: `aireadyaudit.com.au`
5. Create your account (use an existing Google/Microsoft login or new credentials)
6. Zoho will show you the exact DNS records to add
7. Log into your domain registrar (wherever aireadyaudit.com.au is registered)
8. Add the MX, SPF, and DKIM records Zoho provides
9. Wait for DNS propagation (15 min – 24 hrs)
10. Zoho will verify the domain and activate the inbox
11. Create mailbox: `hello@aireadyaudit.com.au`

---

## Option B — Gmail "Send As" Alias

This lets you send emails *from* hello@aireadyaudit.com.au via Gmail, and also receive them there — but requires that something is already forwarding email to Gmail (e.g. Zoho forwarding, or the registrar's email forwarding feature).

**Use this as a complement to Option A, not a replacement.**

### Steps to add Send As in Gmail

1. Open **Gmail** at mail.google.com (signed in as ocpathfinderprime@gmail.com)
2. Click the **gear icon** → **See all settings**
3. Go to the **Accounts and Import** tab
4. Under **Send mail as**, click **Add another email address**
5. Fill in:
   - **Name:** AIReady Australia (or your name)
   - **Email address:** hello@aireadyaudit.com.au
   - Uncheck "Treat as an alias" if you want separate management
6. Click **Next Step**
7. Gmail will ask how to send — choose one:
   - **Via Gmail's servers** (simpler, shows "via gmail.com" in some clients)
   - **Via SMTP** (if you have Zoho set up — use Zoho SMTP credentials)
8. If using Zoho SMTP:
   - SMTP Server: `smtp.zoho.com.au`
   - Port: `587` (TLS) or `465` (SSL)
   - Username: hello@aireadyaudit.com.au
   - Password: your Zoho mailbox password
9. Gmail sends a verification email to hello@aireadyaudit.com.au — check Zoho inbox and click the link
10. Done — you can now select hello@aireadyaudit.com.au in Gmail's **From** dropdown

### Receiving in Gmail (forwarding from Zoho)

Once Zoho is active, set up forwarding in Zoho Admin:
1. Log into Zoho Admin Console
2. Go to **Mail Settings** → **Email Forwarding**
3. Forward all mail from hello@aireadyaudit.com.au → ocpathfinderprime@gmail.com
4. Optionally keep a copy in Zoho inbox too

---

## Option C — Registrar-Level Email Forwarding (Quick Check)

Some domain registrars include basic email forwarding for free (no MX record needed, they handle it).

**Check if your registrar offers this:**
- Log into the registrar where aireadyaudit.com.au is managed
- Look for "Email Forwarding" in the domain management panel
- If available: forward hello@aireadyaudit.com.au → ocpathfinderprime@gmail.com
- This is the fastest path — zero DNS complexity

Registrars known to offer free forwarding: Crazy Domains, VentraIP, Netregistry, GoDaddy, Namecheap, Cloudflare (if migrated later).

---

## Recommended Order

1. **First:** Check if registrar has email forwarding (Option C) — takes 5 minutes
2. **If not:** Set up Zoho Mail free tier (Option A) — takes ~30 minutes + DNS propagation
3. **After either:** Add Gmail Send As (Option B) so you can reply from hello@aireadyaudit.com.au

---

## Internal Note (Not for Public Site)

> hello@aireadyaudit.com.au is monitored via ocpathfinderprime@gmail.com

The public website shows only `hello@aireadyaudit.com.au`. This internal note exists so the team knows where to check.
