export async function emitOcPrimeEvent(event: { type: string; payload: unknown }) {
  return { accepted: true, dryRun: true, event };
}
