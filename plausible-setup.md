# Plausible Analytics — Self-Hosted Setup
**For:** aireadyaudit.com.au  
**Last updated:** 2026-03-28

---

## Current Status

Checked 2026-03-28:
- `docker ps | grep plausible` — **no Plausible container running**
- Port 8000 — **not responding** (HTTP 000)
- Port 8080 — **not responding** (HTTP 000)

Plausible is not currently running on this server.

---

## Option A — Use GoatCounter Hosted (Recommended First Step)

GoatCounter offers a free hosted plan at goatcounter.com — no server setup, no Docker, no maintenance.

**Manual signup required** (API requires auth; free accounts created via web):

1. Go to: https://www.goatcounter.com/signup
2. **Site code:** `aireadyaudit` (gives you aireadyaudit.goatcounter.com)
3. **Email:** use ocpathfinderprime@gmail.com or hello@aireadyaudit.com.au once active
4. Add the tracking snippet to the website `<head>`:

```html
<script data-goatcounter="https://aireadyaudit.goatcounter.com/count"
        async src="//gc.zgo.at/count.js"></script>
```

5. Add to the website's HTML — in the aiready website folder at:
   `/home/path-finder-prime/.openclaw/workspace/aiready/website/`

**What you get (free):**
- 100,000 pageviews/month
- No cookies, GDPR-compliant out of the box
- Public or private dashboard
- No personal data collected

---

## Option B — Self-Hosted Plausible (Docker Compose)

Use this if you want full data ownership and expect > 100k pageviews/month.

### Prerequisites
- Docker + Docker Compose installed
- Port 8000 available (or change it)
- Minimum 1 GB RAM, 10 GB disk

### Setup

**1. Create directory:**
```bash
mkdir -p ~/plausible && cd ~/plausible
```

**2. Create `docker-compose.yml`:**
```yaml
version: "3.8"

services:
  mail:
    image: bytemark/smtp
    restart: always

  plausible_db:
    image: postgres:16-alpine
    restart: always
    volumes:
      - db-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_PASSWORD=postgres

  plausible_events_db:
    image: clickhouse/clickhouse-server:24.3.3.102-alpine
    restart: always
    volumes:
      - event-data:/var/lib/clickhouse
      - ./clickhouse/clickhouse-config.xml:/etc/clickhouse-server/config.d/logging.xml:ro
      - ./clickhouse/clickhouse-user-config.xml:/etc/clickhouse-server/users.d/logging.xml:ro
    ulimits:
      nofile:
        soft: 262144
        hard: 262144

  plausible:
    image: ghcr.io/plausible/community-edition:v2.1.4
    restart: always
    command: sh -c "sleep 10 && /entrypoint.sh db createdb && /entrypoint.sh db migrate && /entrypoint.sh run"
    depends_on:
      - plausible_db
      - plausible_events_db
      - mail
    ports:
      - 127.0.0.1:8000:8000
    environment:
      - BASE_URL=https://stats.aireadyaudit.com.au
      - SECRET_KEY_BASE=CHANGE_ME_generate_with_openssl_rand_64_base64
      - DATABASE_URL=postgres://postgres:postgres@plausible_db:5432/plausible_db
      - CLICKHOUSE_DATABASE_URL=http://plausible_events_db:8123/plausible_events_db
      - MAILER_EMAIL=hello@aireadyaudit.com.au
      - SMTP_HOST_ADDR=mail
      - SMTP_HOST_PORT=25
      - DISABLE_REGISTRATION=true

volumes:
  db-data:
    driver: local
  event-data:
    driver: local
```

**3. Create ClickHouse config files:**
```bash
mkdir -p clickhouse

cat > clickhouse/clickhouse-config.xml << 'EOF'
<clickhouse>
  <logger>
    <level>warning</level>
    <console>true</console>
  </logger>
  <query_thread_log remove="remove"/>
  <query_log remove="remove"/>
  <text_log remove="remove"/>
  <trace_log remove="remove"/>
  <metric_log remove="remove"/>
  <asynchronous_metric_log remove="remove"/>
  <session_log remove="remove"/>
  <part_log remove="remove"/>
</clickhouse>
EOF

cat > clickhouse/clickhouse-user-config.xml << 'EOF'
<clickhouse>
  <profiles>
    <default>
      <log_queries>0</log_queries>
      <log_query_threads>0</log_query_threads>
    </default>
  </profiles>
</clickhouse>
EOF
```

**4. Generate a secret key:**
```bash
openssl rand -base64 64 | tr -d '\n'
# Paste the output into SECRET_KEY_BASE in docker-compose.yml
```

**5. Start Plausible:**
```bash
docker compose up -d
```

**6. Access:** http://localhost:8000 (or proxy via nginx to stats.aireadyaudit.com.au)

**7. Create first account** at the web UI — registration is open on first run, then set `DISABLE_REGISTRATION=true`

### Add tracking snippet to website:
```html
<script defer data-domain="aireadyaudit.com.au" src="https://stats.aireadyaudit.com.au/js/script.js"></script>
```

---

## Recommendation

**Start with GoatCounter (Option A)** — zero infrastructure, 5-minute setup, handles early traffic easily. Migrate to self-hosted Plausible later if you need higher volume or richer features.

GoatCounter signup: https://www.goatcounter.com/signup
