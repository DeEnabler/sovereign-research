---
name: deep-research
title: Deep sovereign web research
description: Multi-query search, extract, archive, and cited report via local OrioSearch
---

# Deep Research (local stack)

Use when the user wants **depth**, not a one-line fact.

## When to use

- Compare frameworks, products, or approaches
- Landscape / "state of X" questions
- Anything needing 10+ sources and a saved report

## When NOT to use

- Single factual lookup → `web-search` only
- Code changes, deploys, infra ops → not your job

## Procedure

1. Choose depth: `quick` (default) or `deep` if user says thorough / comprehensive.
2. Run:
   ```bash
   deep-research "TOPIC" --depth quick
   ```
3. Read `report.md` and `sources.json` from the printed outbox path.
4. Reply with:
   - 1 short paragraph synthesis
   - 3–5 best source links
   - path to full report
5. If sources thin or contradictory, say so — do not invent citations.

## Follow-up turns

Before new searches on the same topic, check:

```bash
ls -lt /workspace/outbox | head -5
```

Read prior `sources.json` to avoid duplicate fetches.

## 8-step loop (what the harness automates)

PLAN (sub-queries) → RECALL (SearXNG) → READ (extract) → RANK (score by snippet relevance)
→ SYNTH (report.md) → archive sources.json → optional skeptic note in report footer.

Skeptic pass in v1: harness adds a "Gaps & conflicts" section when extract fails or snippets disagree.
