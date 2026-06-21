export async function submitIndexNow(urls: string[]) {
  const key = process.env.INDEXNOW_KEY;
  if (!key) throw new Error('INDEXNOW_KEY is required');
  return { submitted: urls.length, dryRun: process.env.NODE_ENV !== 'production' };
}
