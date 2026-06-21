create or replace function create_audit_from_score(p_score_id uuid, p_package_type text)
returns uuid language plpgsql as $$
declare
  v_tenant uuid;
  v_lead uuid;
  v_audit uuid;
begin
  select tenant_id, lead_id into v_tenant, v_lead from readiness_scores where id = p_score_id;
  insert into audit_workspaces(tenant_id, lead_id, package_type, status)
  values (v_tenant, v_lead, p_package_type, 'created')
  returning id into v_audit;
  return v_audit;
end;
$$;
