# OC-77 — Stripe Payment Trigger
## Post-Payment Email Automation

**Status:** Ready to implement — Founder action required (Stripe dashboard)
**Depends on:** OC-76 dogfood (parallel — not blocking OC-77)
**Estimated time to activate:** 25–40 minutes
**Last updated:** 2026-04-02

---

## What This Does

When a client pays via Stripe ($497 Starter, $997 Business, $2,997 Enterprise), they automatically receive:

1. **Immediate confirmation email** — "You're in, here's what happens next" (Email 1 from onboarding-emails.md)
2. **Intake form link** — directs them to the Tally form
3. **24h follow-up** — Email 2 (triggered if Email 1 was sent)
4. **48h nudge** — Email 3 (triggered only if intake form NOT submitted — manual check for now)

The trigger chain: **Stripe payment confirmed → automation fires → Email 1 sent within 2 minutes**

---

## Implementation Path: Zapier (Recommended)

Zapier is the fastest option with zero code. Free tier covers this volume.

### Prerequisites

Before starting:
- [ ] Stripe account active with at least one live payment link
- [ ] `hello@aireadyaudit.com.au` sending address configured (Zoho, Gmail, or similar)
- [ ] Tally intake form URL (from Tally dashboard — publish the form first)
- [ ] Zapier account (free at zapier.com)

---

### Step 1 — Connect Stripe to Zapier

1. Log in to Zapier → click **Create Zap**
2. **Trigger:** Search "Stripe" → select **Checkout Session Completed**
3. Connect your Stripe account (OAuth — Zapier will request read access)
4. Set **Trigger event:** `checkout.session.completed`
5. Test the trigger — Zapier will pull a recent completed session (use a test purchase if needed)

**What data you'll have available:**
- `customer_details.email` — buyer's email
- `customer_details.name` — buyer's name
- `amount_total` — in cents (49700 = $497.00)
- `payment_status` — should be "paid"
- `line_items[0].description` — product name (e.g. "AIReady Starter Audit")

---

### Step 2 — Send Confirmation Email

1. **Action:** Search "Gmail" or "Zoho Mail" → select **Send Email**
2. Connect your `hello@aireadyaudit.com.au` account
3. Configure the email:

```
To: {{customer_details.email}}
From: Prime | AIReady Australia <hello@aireadyaudit.com.au>
Subject: You're in — here's what happens next
Reply-To: hello@aireadyaudit.com.au
```

**Body (paste from onboarding-emails.md — Email 1):**

```
Hi {{customer_details.name}},

You've just taken the step that most Australian businesses keep putting off. Good.

Here's what happens from here:

1. Complete your intake form
This is how we get to know your business before the audit begins. It takes about 10–15 minutes and covers your current tools, team size, data situation, and what you're hoping AI can help with.

👉 Complete your intake form here: [TALLY_FORM_URL]

2. We review and schedule
Once your form is in, we'll review it within 1 business day and confirm your audit schedule by email.

3. Audit delivery
Your audit will be delivered within 5–7 business days of your intake form submission. You'll receive a full written report — no jargon, no padding, just an honest assessment and a clear path forward.

A couple of things to know:
- The intake form is what kicks everything off. The sooner it's in, the sooner we get started.
- If anything comes up before then, reply to this email. I read every one.

Looking forward to seeing what we find.

— Prime
AIReady Australia
hello@aireadyaudit.com.au
https://aireadyaudit.com.au
```

> Replace `[TALLY_FORM_URL]` with the published Tally form URL before activating.

---

### Step 3 — Log the Purchase (Optional but recommended)

Add a second action to log each purchase to a Google Sheet for tracking:

1. **Action:** Google Sheets → **Create Spreadsheet Row**
2. Spreadsheet: Create one called "AIReady — Client Log"
3. Columns: Date, Name, Email, Product, Amount, Status

This gives you a running client list without logging into Stripe every time.

Sheet columns to map:
```
Date:    {{zap_meta.humanized_now}}
Name:    {{customer_details.name}}
Email:   {{customer_details.email}}
Product: {{line_items.0.description}}
Amount:  ${{amount_total / 100}}
Status:  New — Awaiting Intake Form
```

---

### Step 4 — Test the Zap

1. Use Stripe's test mode to create a $0 test checkout session
2. Confirm Zapier fires and email arrives in the test inbox
3. Check the Google Sheet row was created
4. Turn the Zap **ON**

---

## Alternative: Stripe's Native Email (Simpler, less flexible)

If Zapier feels like too many steps, Stripe has built-in email:

**Dashboard → Settings → Emails → Customer emails**
- Enable "Successful payments" confirmation
- Customise the email subject and logo in **Branding** settings
- Add a custom footer with the intake form link

Limitation: you can't fully customise the email body. It's a Stripe-styled receipt + your message. Fine for now; replace with Zapier when volume warrants it.

**To add intake form link to Stripe email footer:**
1. Stripe Dashboard → Settings → Branding
2. Scroll to "Email footer" 
3. Add: "Complete your intake form: [TALLY_FORM_URL]"
4. Save

This takes 5 minutes. Do this first if Zapier setup feels slow.

---

## Make (formerly Integromat) — Alternative to Zapier

If you prefer Make (more powerful, generous free tier):

1. New Scenario → **Stripe: Watch Events** → filter on `checkout.session.completed`
2. **Gmail/SMTP module** → Send email with same body as above
3. **Google Sheets module** → Append row to client log

Make handles the same logic. The Stripe → Email → Sheets flow is a 3-module scenario.

---

## Tier-Specific Customisation (Phase 2)

Once the basic trigger is live, add a Zapier filter to customise by tier:

| Amount (cents) | Product | Email tweak |
|---|---|---|
| 49700 | Starter Audit | "delivered within 5 business days" |
| 99700 | Business Audit | "delivered within 7 business days" |
| 299700 | Enterprise Audit | "We'll be in touch to schedule your kickoff call" |

Add a **Filter** step in Zapier between Trigger and Action:
- `amount_total` equals `49700` → path A (Starter)
- `amount_total` equals `99700` → path B (Business)
- `amount_total` equals `299700` → path C (Enterprise)

Use Zapier Paths (multi-step) to handle all three. Each path sends the same Email 1 with the tier-relevant delivery timeframe.

---

## 24h Follow-Up Email (Email 2)

Add a **Delay** step after the confirmation email:

1. Action: **Delay by Zapier** → Delay for 1 day
2. Action: **Gmail/Zoho** → Send Email 2 from onboarding-emails.md

This runs 24 hours after purchase. Body is Email 2 exactly as written.

---

## 48h Nudge (Email 3) — Manual for Now

Email 3 (the nudge) is conditional on whether the intake form was submitted. Since Tally doesn't natively integrate with Zapier's delay logic easily, handle this manually for the first 10–20 clients:

1. Check the Google Sheet client log each morning
2. Filter: Status = "New — Awaiting Intake Form" + Date = 2 days ago
3. Send Email 3 manually from hello@aireadyaudit.com.au

When volume hits 5+ purchases/week, wire up the Tally → Zapier → Google Sheets update to flip the Status column, then add a second Zap that checks at 48h and only sends Email 3 if Status is still "Awaiting."

---

## Minimum Viable Setup (Do This First — 10 Minutes)

If you want something live today before full Zapier setup:

1. **Stripe Dashboard → Settings → Emails → Successful payments** — enable
2. **Stripe Dashboard → Settings → Branding → Email footer** — add intake form link
3. Done — every purchaser gets a Stripe receipt + intake form link

Then set up Zapier within the week for fully customised emails.

---

## Files Referenced

- `onboarding-emails.md` — full email body copy (Email 1, 2, 3)
- `tally-intake-form.md` — intake form spec (Founder publishes in Tally)
- `INTAKE-QUESTIONNAIRE.md` — intake question list

---

## Status Checklist

- [ ] Tally form published (Founder action — ~25 min)
- [ ] Stripe native email enabled with intake link (10 min — Stripe dashboard)
- [ ] Zapier connected to Stripe + Gmail/Zoho (30 min — after hello@ email is live)
- [ ] Test purchase confirms email fires
- [ ] Google Sheets client log created
- [ ] Email 2 (24h) delay wired in Zapier
- [ ] OC-77 marked DONE in IN-PROGRESS.md

---

*Built by Pathfinder Prime — 2026-04-02*
