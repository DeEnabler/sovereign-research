---
name: deep-research
title: Deep sovereign web research
description: Multi-query search, specialist retrievers, extract, archive, gaps review via local OrioSearch
---

# Deep Research (local stack)

Use when the user wants **depth**, not a one-line fact.

## When to use

- Compare frameworks, products, or approaches
- Landscape / "state of X" questions
- Anything needing 10+ sources and a saved report

## When NOT to use

- Single factual lookup → `web-search` only
- Code changes, deploys, VPS ops → not your job

## Procedure

1. Choose depth: `quick` (default) or `deep` if user says thorough / comprehensive.
2. Run:
   ```bash
   deep-research "TOPIC" --depth quick
   ```
   This automatically:
   - Queries **OrioSearch** (SearXNG + rerank), **arXiv**, **Semantic Scholar**, **GitHub**
   - Extracts top URLs, writes `report.md`, `sources.json`
   - Runs `gaps-review` → `gaps.json`
3. Read `report.md`, `sources.json`, and **`gaps.json`** from the printed outbox path.
4. Reply in Telegram:
   - 1 short paragraph synthesis (from extracted `full_text`, not snippets alone)
   - Retriever coverage (web / arxiv / scholar / github counts)
   - Explicit gaps from checklist (extract failures, thin coverage)
   - 3–5 best source links + path to full report
5. If sources thin or contradictory, say so — do not invent citations.

## Follow-up turns

Before new searches on the same topic, check:

```bash
ls -lt /workspace/outbox | head -5
```

Read prior `sources.json` to avoid duplicate fetches.

## Multi-retriever loop

PLAN (sub-queries) → RECALL (web + arxiv + scholar + github) → READ (extract) → RANK
→ SYNTH (report.md) → GAPS (gaps.json) → archive sources.json

Never skip the gaps step. Never reply before reading `gaps.json`.
