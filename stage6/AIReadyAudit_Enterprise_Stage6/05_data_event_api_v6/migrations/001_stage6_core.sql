create extension if not exists pgcrypto;

create table if not exists tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  region text not null default 'AU',
  created_at timestamptz not null default now()
);

create table if not exists leads (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references tenants(id),
  email text not null,
  company text,
  source text,
  status text not null default 'new',
  created_at timestamptz not null default now()
);

create table if not exists readiness_scores (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references tenants(id),
  lead_id uuid references leads(id),
  score int not null check (score between 0 and 100),
  band text not null,
  input jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists audit_workspaces (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references tenants(id),
  lead_id uuid references leads(id),
  package_type text not null,
  status text not null default 'created',
  due_at timestamptz,
  created_at timestamptz not null default now()
);
