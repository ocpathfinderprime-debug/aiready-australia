create table if not exists partners (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references tenants(id),
  name text not null,
  tier text not null default 'referral',
  status text not null default 'candidate',
  created_at timestamptz not null default now()
);

create table if not exists partner_leads (
  id uuid primary key default gen_random_uuid(),
  partner_id uuid references partners(id),
  lead_id uuid references leads(id),
  attribution jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists marketplace_submissions (
  id uuid primary key default gen_random_uuid(),
  marketplace text not null,
  app_name text not null,
  status text not null default 'draft',
  submitted_at timestamptz,
  notes text
);
