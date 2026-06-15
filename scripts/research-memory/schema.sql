-- Research memory on OUR Supabase (srjtsuqhcusvtgegwcpo)
-- NOT the client project (fiezodastotdurqyshih / recipients / send_logs)
-- Run once: Supabase Dashboard → SQL Editor → paste → Run

create extension if not exists vector;

create table if not exists public.research_chunks (
  id bigserial primary key,
  report_slug text not null,
  topic text,
  url text,
  title text,
  retriever text default 'web',
  chunk_text text not null,
  embedding vector(1536),
  created_at timestamptz not null default now()
);

create index if not exists research_chunks_report_slug_idx
  on public.research_chunks (report_slug);

create index if not exists research_chunks_embedding_idx
  on public.research_chunks
  using hnsw (embedding vector_cosine_ops);

create or replace function public.match_research_chunks(
  query_embedding vector(1536),
  match_count int default 8,
  min_similarity float default 0.5
)
returns table (
  id bigint,
  report_slug text,
  topic text,
  url text,
  title text,
  retriever text,
  chunk_text text,
  similarity float
)
language sql stable
as $$
  select
    rc.id,
    rc.report_slug,
    rc.topic,
    rc.url,
    rc.title,
    rc.retriever,
    rc.chunk_text,
    1 - (rc.embedding <=> query_embedding) as similarity
  from public.research_chunks rc
  where rc.embedding is not null
    and 1 - (rc.embedding <=> query_embedding) >= min_similarity
  order by rc.embedding <=> query_embedding
  limit match_count;
$$;

-- Service-role harness only; disable RLS on this private research table
alter table public.research_chunks disable row level security;
