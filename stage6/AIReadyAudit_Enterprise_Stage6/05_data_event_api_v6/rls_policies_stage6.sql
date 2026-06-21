alter table tenants enable row level security;
alter table leads enable row level security;
alter table readiness_scores enable row level security;
alter table audit_workspaces enable row level security;
alter table ai_citation_observations enable row level security;
alter table partners enable row level security;

-- Replace app.current_tenant_id with the active tenant context in production.
create policy tenant_isolation_leads on leads using (tenant_id::text = current_setting('app.current_tenant_id', true));
create policy tenant_isolation_scores on readiness_scores using (tenant_id::text = current_setting('app.current_tenant_id', true));
create policy tenant_isolation_audits on audit_workspaces using (tenant_id::text = current_setting('app.current_tenant_id', true));
create policy tenant_isolation_partners on partners using (tenant_id::text = current_setting('app.current_tenant_id', true));
