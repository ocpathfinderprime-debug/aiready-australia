export type OcPrimeEvent = { type: string; tenantId: string; source: 'aiready_audit'; payload: unknown; occurredAt: string };

export async function emitToOcPrime(event: OcPrimeEvent) {
  // TODO: sign request and POST to OC Prime event endpoint.
  return { accepted: true, dryRun: true, event };
}
