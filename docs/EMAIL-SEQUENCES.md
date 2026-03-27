# AIReady Australia — Client Email Sequences

> **Usage Note:** These three emails are the full post-purchase onboarding sequence. Send Email 1 automatically on payment confirmation. Send Email 2 manually when the report PDF is ready. Send Email 3 7 days after Email 2. All emails sent from hello@aireadyaudit.com.au.

---

## EMAIL 1 — Sent immediately after payment

**To:** [CLIENT EMAIL]
**From:** hello@aireadyaudit.com.au
**Subject:** Your AIReady Audit — here's what happens next
**Trigger:** Payment confirmed

---

Hi [FIRST NAME],

Thanks for booking — genuinely appreciate you trusting us with this.

Here's what happens now.

**Step 1: Fill in your intake form**
Everything starts here:
👉 **aireadyaudit.com.au/intake**

The form takes about 15 minutes. Answer as specifically as you can — the more detail you give, the more useful your report will be. Vague answers get vague recommendations.

**Please complete it within 48 hours.** That's what keeps us on track for your delivery deadline.

**What we do with your answers:**
- Review your intake responses in full
- Audit your website independently
- Score your business across 5 AI readiness categories
- Identify your top 3 AI opportunities and build a 90-day roadmap

**Your delivery timeline:**
Starter Audit: **5 business days from when you submit the intake form.**

Your report will arrive as a PDF attached to an email from this address.

If anything's unclear or you want to add something after submitting, just reply here.

Talk soon,

**The AIReady Australia Team**
aireadyaudit.com.au

---

## EMAIL 2 — Sent when report is ready

**To:** [CLIENT EMAIL]
**From:** hello@aireadyaudit.com.au
**Subject:** Your AIReady Audit Report is Ready
**Trigger:** Report complete — send manually with PDF attached
**Attachment:** [BUSINESS NAME] — AIReady Audit Report.pdf

---

Hi [FIRST NAME],

Your report is ready. It's attached to this email.

Here's what we found:

---

**Your AI Readiness Score: [SCORE] / 100**

**Top 3 opportunities for [BUSINESS NAME]:**

1. **[OPPORTUNITY 1 TITLE]** — [One sentence describing what it is and the key benefit. E.g. "Automating your weekly client reports — estimated 3 hours saved per week at $47/month."]

2. **[OPPORTUNITY 2 TITLE]** — [One sentence. E.g. "AI-assisted email drafting for your customer service inbox — cuts response time from 40 minutes to 10."]

3. **[OPPORTUNITY 3 TITLE]** — [One sentence. E.g. "Meeting transcription and auto-generated action items — stops things falling through the cracks after every internal meeting."]

---

The full report covers the scoring breakdown, tool recommendations with costs, implementation difficulty ratings, and a 90-day roadmap.

If the attachment is loading slowly, the three points above are the headline findings — everything else in the report is the detail behind them.

Read it, sit with it for a day, then reply with any questions. We're happy to clarify anything.

Talk soon,

**The AIReady Australia Team**
aireadyaudit.com.au

---

## EMAIL 3 — Sent 7 days after Email 2

**To:** [CLIENT EMAIL]
**From:** hello@aireadyaudit.com.au
**Subject:** Have you started on your AI roadmap?
**Trigger:** 7 days after Email 2 is sent

---

Hi [FIRST NAME],

Just checking in — it's been a week since we sent your report.

Quick question: have you started on any of the three opportunities?

No right answer. Some people move fast, some need a few weeks to clear the decks first. Just curious where you're at.

If you've hit a snag — tool setup, not sure where to begin, want a second opinion on something — reply here and I'll help.

And if you've read the report and want more than just recommendations — if you want the actual workflows built, the tools set up, and someone walking alongside you through the 90 days — that's what the Business Audit is for.

👉 **aireadyaudit.com.au/upgrade**

It goes deeper: full process mapping, custom workflow design, side-by-side tool comparisons, and two live sessions. $997.

No pressure. The Starter report stands on its own. But if you want to move faster, that's the way to do it.

Either way — good luck. Hope the report was useful.

**The AIReady Australia Team**
aireadyaudit.com.au

---

## SEQUENCE SUMMARY

| Email | Trigger | Subject | Goal |
|---|---|---|---|
| Email 1 | Payment confirmed (auto) | "Your AIReady Audit — here's what happens next" | Get intake form completed within 48 hours |
| Email 2 | Report ready (manual send) | "Your AIReady Audit Report is Ready" | Deliver report + preview top 3 findings |
| Email 3 | 7 days after Email 2 (manual or scheduled) | "Have you started on your AI roadmap?" | Check in + offer Business tier upgrade |

**Notes for Prime:**
- Email 1: Automate via payment platform webhook if possible (Stripe → email automation). Otherwise, send manually within 5 minutes of payment confirmation.
- Email 2: Personalise the Top 3 findings section before sending. Pull directly from the report.
- Email 3: If the client has already replied or upgraded, skip this email or adjust accordingly.
