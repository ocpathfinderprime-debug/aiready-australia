export async function hubspotAdapter(action: string, payload: unknown) {
  // Placeholder adapter for hubspot. Replace with production credentials and API calls.
  return { service: 'hubspot', action, accepted: true, dryRun: true, payload };
}
