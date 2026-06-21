create table if not exists ai_citation_prompts (
  id text primary key,
  market text not null,
  engine text not null,
  prompt text not null,
  intent text not null,
  active boolean not null default true
);

create table if not exists ai_citation_observations (
  id uuid primary key default gen_random_uuid(),
  prompt_id text references ai_citation_prompts(id),
  observed_at timestamptz not null default now(),
  cited boolean not null,
  cited_url text,
  position_note text,
  competitors jsonb not null default '[]'::jsonb,
  raw_notes text
);

create table if not exists content_assets (
  id uuid primary key default gen_random_uuid(),
  url text unique not null,
  page_type text not null,
  target_intent text,
  status text not null default 'draft',
  last_reviewed_at timestamptz
);
