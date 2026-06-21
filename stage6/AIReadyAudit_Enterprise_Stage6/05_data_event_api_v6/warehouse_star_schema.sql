create table if not exists fact_lead_conversion (
  date_key date,
  source text,
  market text,
  leads int,
  score_completions int,
  purchases int,
  revenue numeric
);

create table if not exists fact_ai_citations (
  date_key date,
  engine text,
  market text,
  prompt_intent text,
  prompts_tested int,
  citations int,
  competitor_mentions int
);

create table if not exists dim_content_page (
  url text primary key,
  page_type text,
  target_intent text,
  market text,
  published_at date
);
