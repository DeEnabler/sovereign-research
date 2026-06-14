# Sovereign Research

**Self-hosted web search and extraction for AI agents** — a drop-in replacement for Tavily SaaS.

Runs [OrioSearch](https://github.com/vkfolio/orio-search) (SearXNG + Redis + Tavily-compatible API) on your own VPS or laptop. Point any agent framework that speaks the Tavily API at your instance — no paid search subscription, no data leaving your stack.

Built and battle-tested with [Hermes Agent](https://github.com/NousResearch/hermes-agent); harness scripts work with any shell-based agent loop.

## Why this exists

Default agent research tools (Tavily, Exa, etc.) are SaaS — quota caps, vendor lock-in, and your queries on someone else's infra. This repo gives you:

- **Local `/search`** via SearXNG (aggregated web results)
- **Local `/extract`** (page content for RAG / synthesis)
- **Tavily-compatible wire format** — set `TAVILY_BASE_URL` and keep your existing agent code
- **Harness scripts** — `web-search`, `deep-research`, specialist retrievers (arXiv, Scholar, GitHub), `gaps-review`
- **Rerank enabled** — ms-marco cross-encoder for better result ordering

## Architecture

```
┌─────────────┐     Tavily-compatible      ┌──────────────────┐
│ AI Agent    │ ─── POST /search ────────► │ OrioSearch API   │
│ (Hermes,    │ ─── POST /extract ───────► │ :8000            │
│  custom)    │                            └────────┬─────────┘
└─────────────┘                                     │
                    ┌───────────────────────────────┼────────────────┐
                    ▼                               ▼                ▼
              ┌──────────┐                   ┌──────────┐    ┌──────────┐
              │ SearXNG  │                   │ Extract  │    │ Redis    │
              │ :8080    │                   │ workers  │    │ cache    │
              └──────────┘                   └──────────┘    └──────────┘
```

## Quick start (5 minutes)

**Requirements:** Docker, `curl`, `git`, Python 3.10+

```bash
git clone https://github.com/DeEnabler/sovereign-research.git
cd sovereign-research
cp .env.example .env   # optional for harness; defaults work for local API

./scripts/install-orio.sh
./scripts/smoke.sh
```

Try a search:

```bash
export PATH="$PWD/bin:$PATH"
web-search "best open source AI agent frameworks 2026" --max 5
```

Deep research (multi-query → extract → report):

```bash
deep-research "sovereign AI agent search tools" --depth quick
ls -lt workspace/outbox/
```

## Plug into any Tavily client

OrioSearch implements Tavily's `/search` and `/extract` endpoints. Point your client at localhost:

```bash
export TAVILY_BASE_URL=http://127.0.0.1:8000
export TAVILY_API_KEY=local   # dummy — auth disabled in bundled config.yaml
```

Works with Hermes, LangChain Tavily tools, GPT Researcher, or any HTTP client that posts the same JSON shape.

### Hermes Agent

1. Start OrioSearch (`./scripts/install-orio.sh`).
2. Copy `hermes/` files into your agent's Hermes directory.
3. Set in `hermes/.env`:

   ```
   TAVILY_BASE_URL=http://orio-search-api:8000   # if agent runs in Docker on same network
   TAVILY_API_KEY=local
   ```

4. In `config.yaml`, enable web tools:

   ```yaml
   web:
     search_backend: tavily
     extract_backend: tavily
   ```

5. **Do not** add `browser` to `disabled_toolsets` — Hermes incorrectly drops `web_search` when browser is disabled.

6. Mount `bin/` on PATH inside the container (`/usr/local/agent-bin`).

See `docker-compose.agent.yml` for a full example.

## What's in the repo

| Path | Purpose |
|------|---------|
| `oriosearch/` | Docker overlay + config for OrioSearch (clones upstream on install) |
| `bin/web-search` | One-shot CLI search against local API |
| `bin/deep-research` | Multi-retriever research → `workspace/outbox/` + `gaps.json` |
| `bin/arxiv-search`, `scholar-search`, `github-search` | Specialist retrievers |
| `bin/gaps-review` | Post-run checklist for synthesis |
| `hermes/` | Agent persona, config, skill for Hermes gateway |
| `scripts/install-orio.sh` | Clone upstream + `docker compose up` |
| `scripts/smoke.sh` | Health + search + harness checks |

## Configuration

`oriosearch/config.yaml` — tuned for small VPS:

- SearXNG backend (no Google API keys required)
- Auth off (`TAVILY_API_KEY=local` works)
- Rerank on (`ms-marco-MiniLM-L-12-v2`); API container 768m RAM, 1 worker
- Redis cache on

Adjust memory limits in `oriosearch/docker-compose.yml` for your host (defaults: API 512m, SearXNG 256m, Redis 128m).

## Secrets

Copy `.env.example` → `.env` for optional Telegram / OpenRouter integration. **Never commit `.env`.** The OrioSearch stack itself needs no API keys.

## Credits

- [OrioSearch](https://github.com/vkfolio/orio-search) by vkfolio — Tavily-compatible API + SearXNG
- [SearXNG](https://github.com/searxng/searxng) — privacy-respecting metasearch
- Harness + Hermes integration from the sovereign-research VPS setup

## License

MIT — see [LICENSE](LICENSE).
