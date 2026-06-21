export async function mailerAdapter(action: string, payload: unknown) {
  // Placeholder adapter for mailer. Replace with production credentials and API calls.
  return { service: 'mailer', action, accepted: true, dryRun: true, payload };
}
