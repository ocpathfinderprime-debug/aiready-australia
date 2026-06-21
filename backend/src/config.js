export function getConfig(env = process.env) {
  return {
    port: Number(env.PORT || 3001),
    dataDir: env.AIREADY_DATA_DIR || './data',
    allowedOrigins: String(env.AIREADY_ALLOWED_ORIGINS || 'https://aireadyaudit.com.au,http://localhost:8802,http://127.0.0.1:8802')
      .split(',')
      .map((origin) => origin.trim())
      .filter(Boolean),
    stripeWebhookSecret: env.STRIPE_WEBHOOK_SECRET || '',
    adminApiToken: env.ADMIN_API_TOKEN || '',
  };
}

export function isAllowedOrigin(origin, allowedOrigins) {
  if (!origin) return true;
  return allowedOrigins.includes(origin);
}
