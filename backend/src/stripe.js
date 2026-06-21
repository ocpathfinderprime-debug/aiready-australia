import { createHmac, timingSafeEqual } from 'node:crypto';

export function verifyStripeSignature({ rawBody, signatureHeader, secret, toleranceSeconds = 300, now = Date.now() }) {
  if (!secret) {
    return { ok: true, skipped: true, reason: 'STRIPE_WEBHOOK_SECRET not configured' };
  }

  if (!signatureHeader) {
    return { ok: false, skipped: false, reason: 'Missing Stripe-Signature header' };
  }

  const parts = Object.fromEntries(
    signatureHeader.split(',').map((part) => {
      const [key, ...value] = part.split('=');
      return [key, value.join('=')];
    })
  );

  const timestamp = Number(parts.t);
  const signature = parts.v1;

  if (!timestamp || !signature) {
    return { ok: false, skipped: false, reason: 'Malformed Stripe-Signature header' };
  }

  const ageSeconds = Math.abs(Math.floor(now / 1000) - timestamp);
  if (ageSeconds > toleranceSeconds) {
    return { ok: false, skipped: false, reason: 'Stripe-Signature timestamp outside tolerance' };
  }

  const signedPayload = `${timestamp}.${rawBody}`;
  const expected = createHmac('sha256', secret).update(signedPayload, 'utf8').digest('hex');
  const expectedBuffer = Buffer.from(expected, 'hex');
  const actualBuffer = Buffer.from(signature, 'hex');

  if (expectedBuffer.length !== actualBuffer.length) {
    return { ok: false, skipped: false, reason: 'Stripe-Signature length mismatch' };
  }

  const ok = timingSafeEqual(expectedBuffer, actualBuffer);
  return { ok, skipped: false, reason: ok ? 'verified' : 'Stripe-Signature mismatch' };
}

export function inferPackageFromStripeEvent(event) {
  const amount = event?.data?.object?.amount_total;
  if (amount === 49700) return 'starter_audit';
  if (amount === 99700) return 'business_audit';
  if (amount === 299700) return 'enterprise_assessment';
  return 'unknown';
}
