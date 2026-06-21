create table if not exists report_reviews (
  id uuid primary key default gen_random_uuid(),
  audit_workspace_id uuid references audit_workspaces(id),
  reviewer_id uuid,
  status text not null default 'pending',
  score int check (score between 0 and 100),
  findings jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists audit_log_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references tenants(id),
  actor_id uuid,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
