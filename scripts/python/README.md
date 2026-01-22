Hugging Face Model Search CLI

This folder contains the interactive CLI `hf_model_search.py` to search models on huggingface.co.

Usage (interactive):

```bash
python3 scripts/python/hf_model_search.py
```

One-shot examples and flags:

```bash
# Search by name, show top 10 by composite score (downloads + likes + recency + tag boost)
python3 scripts/python/hf_model_search.py --name "gpt" --sort composite --limit 100 --top 10

# Search by tag, sort by downloads
python3 scripts/python/hf_model_search.py --tag "text-generation" --sort downloads --limit 200 --top 20
```

Flags:
- `--name`: search by name keyword (one-shot)
- `--tag`: search by tag keyword (one-shot)
- `--sort`: ranking strategy, one of `composite` (default), `downloads`, or `likes`
- `--limit`: how many candidates to fetch before ranking (default 80)
- `--top`: how many top results to display (default 10)

Notes:
- The composite ranking blends downloads, likes, recency and tag boosts to prefer recently updated and pipeline-relevant models.
- The CLI is defensive: if download/likes counts are unavailable for some models, the composite ranking falls back gracefully.
