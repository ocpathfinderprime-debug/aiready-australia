export function getConfig(env = process.env) {
  return {
    port: Number(env.PORT || 3001),
    dataDir: env.AIREADY_DATA_DIR || './data',
    storageDriver: env.AIREADY_STORAGE_DRIVER || (env.NETLIFY ? 'netlify-blobs' : 'jsonl'),
    blobsStore: env.AIREADY_BLOBS_STORE || 'aiready-records',
    serveStatic: env.AIREADY_SERVE_STATIC !== 'false',
    staticDir: env.AIREADY_STATIC_DIR || './website',
    allowedOrigins: String(env.AIREADY_ALLOWED_ORIGINS || 'https://aireadyaudit.com.au,https://www.aireadyaudit.com.au,http://localhost:8802,http://127.0.0.1:8802')
      .split(',')
      .map((origin) => origin.trim())
      .filter(Boolean),
    stripeWebhookSecret: env.STRIPE_WEBHOOK || env.STRIPE_WEBHOOK_SECRET || '',
    adminApiToken: env.ADMIN_API_TOKEN || '',
  };
}

export function isAllowedOrigin(origin, allowedOrigins) {
  if (!origin) return true;
  return allowedOrigins.includes(origin);
}
