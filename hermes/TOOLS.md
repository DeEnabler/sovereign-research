# TOOLS.md — Research agent

## Local search API (OrioSearch)

| Env (in hermes/.env) | Value |
|----------------------|-------|
| `TAVILY_BASE_URL` | `http://orio-search-api:8000` (Docker network to OrioSearch) |
| `TAVILY_API_KEY` | `local` (dummy; local stack, auth off) |
| `ORIOSEARCH_URL` | same as TAVILY_BASE_URL (for harness scripts) |
| `S2_API_KEY` | optional — Semantic Scholar rate limits |
| `GITHUB_TOKEN` | optional — GitHub search rate limits |
| `RESEARCH_SUPABASE_URL` | **OUR** project (`srjtsuqhcusvtgegwcpo`) — NOT client |
| `RESEARCH_SUPABASE_SERVICE_ROLE_KEY` | service role for OUR project |
| `RESEARCH_EMBED_MODEL` | default `openai/text-embedding-3-small` via OpenRouter |

### Supabase projects (do not mix)

| Project | Ref | Tables | Use |
|---------|-----|--------|-----|
| **OURS** | `srjtsuqhcusvtgegwcpo` | `allowed_users`, `allowed_phones`, `research_chunks` | routebot + research memory |
| **CLIENT** | `fiezodastotdurqyshih` | `recipients`, `send_logs` | clawdev only — never research memory |

One-time schema: `scripts/research-memory/schema.sql` on **OUR** dashboard.

Rerank is **enabled** (`ms-marco-MiniLM-L-12-v2`). API container: 768m RAM, 1 gunicorn worker.

Health check from container:

```bash
curl -sS --max-time 10 "${ORIOSEARCH_URL:-http://orio-search-api:8000}/health"
```

## Harness scripts

### web-search

```bash
web-search "query" [--max 8]
```

Calls OrioSearch `/search`. Prints ranked URLs + snippets.

### deep-research

```bash
deep-research "topic" [--depth quick|deep]
```

Multi-retriever recall (web + arxiv + scholar + github), extract, report, gaps-review.

Output:

```
/workspace/outbox/<timestamp>-<slug>/
  sources.json      # retriever tags per source
  report.md
  queries.txt
  gaps.json         # checklist for synthesis
```

### Specialist retrievers

```bash
arxiv-search "query" [--max N]      # no key
scholar-search "query" [--max N]    # optional S2_API_KEY
github-search "query" [--max N]     # optional GITHUB_TOKEN
```

### gaps-review

```bash
gaps-review [outbox/slug-dir]
```

### memory-recall / memory-index (Phase 3 — OUR Supabase)

```bash
memory-recall "query" [--max 8]    # before new research
memory-index [outbox/slug-dir]     # after deep-research (auto-run)
```

Requires `RESEARCH_SUPABASE_*` pointing at **OUR** project, not client.

## Hermes native web tools

With `web.search_backend: tavily` and `extract_backend: tavily`, Hermes `web_search`
and `web_extract` hit the **local** OrioSearch instance (not api.tavily.com).

**Harness-first:** run `web-search` or `deep-research` before native web tools.

**Do not** add `browser` to `disabled_toolsets` — Hermes also removes `web_search`.

## Outbox

Host path: `/srv/agents/research/workspace/outbox/`  
Container: `/workspace/outbox/`

## Quota

Shared `OPENROUTER_API_KEY` + Headroom. On 429: one-line message, stop.

## Deploy / recreate

```bash
agentctl recreate research   # after config.yaml or .env change
```

New bins: scp to `/srv/agents/research/bin/` and `chmod +x`.
