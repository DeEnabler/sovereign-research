# TOOLS.md — Research agent

## Local search API (OrioSearch)

| Env (in hermes/.env) | Value |
|----------------------|-------|
| `TAVILY_BASE_URL` | `http://orio-search-api:8000` (Docker) or `http://127.0.0.1:8000` (host) |
| `TAVILY_API_KEY` | `local` (dummy; local stack, auth off) |
| `ORIOSEARCH_URL` | same as TAVILY_BASE_URL (for harness scripts) |

Health check:

```bash
curl -sS --max-time 10 "${ORIOSEARCH_URL:-http://127.0.0.1:8000}/health"
```

## Harness scripts

### web-search

```bash
web-search "query" [--max 8]
```

Calls OrioSearch `/search`. Prints ranked URLs + snippets to stdout.

### deep-research

```bash
deep-research "topic" [--depth quick|deep]
```

Runs multi-query search, extracts top pages, writes:

```
/workspace/outbox/<timestamp>-<slug>/
  sources.json
  report.md
  queries.txt
```

`--depth quick`: 3 sub-queries, 5 URLs each.  
`--depth deep`: 6 sub-queries, 8 URLs each, more extract passes.

## Hermes native web tools

With `web.search_backend: tavily` and `extract_backend: tavily`, Hermes `web_search`
and `web_extract` hit the **local** OrioSearch instance (not api.tavily.com).

**Important:** Do not add `browser` to `disabled_toolsets` — Hermes also removes
`web_search` when the browser toolset is disabled.

## Outbox

Container path: `/workspace/outbox/`

## Deploy / recreate

```bash
hermes gateway run   # or your process manager
# After config.yaml or .env change, restart the gateway.
```

Scripts and skills reload without recreate when only SOUL/skills/bin change.
