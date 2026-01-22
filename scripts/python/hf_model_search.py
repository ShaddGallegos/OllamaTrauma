#!/usr/bin/env python3
"""
Interactive Hugging Face model search CLI.
- Search by name keyword or tag keyword
- Fetch up to `fetch_limit` matches, then query download counts and show top 10 by downloads
- All menus use `0` to go back (or exit at top menu)

Usage:
  python3 scripts/hf_model_search.py         # interactive
  python3 scripts/hf_model_search.py --name "gpt"   # one-shot name search
  python3 scripts/hf_model_search.py --tag "text-generation"  # one-shot tag search

Requires: `huggingface_hub` (already listed in requirements.txt)
"""

import sys
import argparse
import time

# lazy import of huggingface_hub to avoid editor/CI import errors when the package isn't available
api = None


def ensure_api():
    global api
    if api is None:
        try:
            from huggingface_hub import HfApi as _HfApi
            api = _HfApi()
        except Exception:
            print("Error: huggingface_hub is not installed; install with: pip install huggingface_hub")
            sys.exit(1)


FETCH_LIMIT = 80
TOP_N = 10


def get_downloads_safe(repo_id):
    ensure_api()
    try:
        info = api.model_info(repo_id)
        # some versions expose .downloads, some in ._json or .to_dict(); handle defensively
        if hasattr(info, "downloads") and info.downloads is not None:
            return int(info.downloads)
        d = None
        try:
            d = info._json.get("downloads") if hasattr(info, "_json") else None
        except Exception:
            d = None
        if d is not None:
            return int(d)
        # fallback to 0 if not available
        return 0
    except Exception:
        return 0


def get_likes_safe(repo_id):
    ensure_api()
    try:
        info = api.model_info(repo_id)
        if hasattr(info, "likes") and info.likes is not None:
            return int(info.likes)
        try:
            j = info._json if hasattr(info, "_json") else {}
            if isinstance(j, dict) and "likes" in j:
                return int(j.get("likes", 0) or 0)
        except Exception:
            pass
        return 0
    except Exception:
        return 0


def get_lastmodified_safe(repo_id):
    ensure_api()
    try:
        info = api.model_info(repo_id)
        t = getattr(info, "lastModified", None)
        if t:
            # try to parse common ISO/RFC3339 formats using only the stdlib (avoid external dateutil dependency)
            try:
                import datetime

                s = t
                # normalize 'Z' timezone
                if isinstance(s, str) and s.endswith("Z"):
                    s = s.replace("Z", "+00:00")
                # try fromisoformat first (handles many ISO/RFC3339 forms with offset)
                try:
                    return datetime.datetime.fromisoformat(s)
                except Exception:
                    pass
                # try a few common strptime formats as fallback
                fmts = [
                    "%Y-%m-%dT%H:%M:%S.%f%z",
                    "%Y-%m-%dT%H:%M:%S%z",
                    "%Y-%m-%d %H:%M:%S%z",
                    "%Y-%m-%dT%H:%M:%S.%f",
                    "%Y-%m-%dT%H:%M:%S",
                    "%Y-%m-%d %H:%M:%S",
                ]
                for fmt in fmts:
                    try:
                        return datetime.datetime.strptime(t, fmt)
                    except Exception:
                        continue
            except Exception:
                pass
            return None
        return None
    except Exception:
        return None


def search_by_name(keyword, fetch_limit=FETCH_LIMIT):
    ensure_api()
    # huggingface_hub supports search param
    models = api.list_models(search=keyword, limit=fetch_limit)
    return models


def search_by_tag(tag, fetch_limit=FETCH_LIMIT):
    ensure_api()
    # list_models supports filter by pipeline_tag via filter argument in newer versions
    # We'll use naive search + tag filtering to be robust
    models = api.list_models(search=tag, limit=fetch_limit)
    # filter by tag if model has pipeline_tag
    filtered = []
    for m in models:
        tags = set()
        try:
            if getattr(m, "pipeline_tag", None):
                tags.add(m.pipeline_tag)
            if getattr(m, "tags", None):
                tags.update(m.tags)
        except Exception:
            pass
        if tag.lower() in {t.lower() for t in tags} or tag.lower() in (m.modelId.lower() if hasattr(m, "modelId") else ""):
            filtered.append(m)
    return filtered


def _parse_b_from_id(repo_id):
    # heuristic: look for patterns like '7b', '13B', '3.5b'
    import re

    m = re.search(r"(\d+(?:\.\d+)?)\s*[bB]\b", repo_id)
    if m:
        try:
            return float(m.group(1))
        except Exception:
            return None
    return None


def rank_models(models, top_n=TOP_N, sort_mode="composite", require_weights=False, gguf_only=False, max_b=None):
    """Rank models using different strategies.

    sort_mode: downloads | likes | composite
    composite blends downloads, likes, recency and tag boosts.
    """
    items = []
    # fetch metrics for each candidate
    for m in models:
        repo_id = getattr(m, "modelId", None) or getattr(m, "id", None) or getattr(m, "modelId", None)
        if not repo_id:
            continue
        downloads = get_downloads_safe(repo_id)
        likes = get_likes_safe(repo_id)
        lastmod = get_lastmodified_safe(repo_id)
        tags = set()
        try:
            if getattr(m, "pipeline_tag", None):
                tags.add(getattr(m, "pipeline_tag", ""))
            if getattr(m, "tags", None):
                tags.update(getattr(m, "tags", []))
        except Exception:
            pass
        items.append({"repo_id": repo_id, "model": m, "downloads": downloads, "likes": likes, "lastmod": lastmod, "tags": tags})
        time.sleep(0.1)

    if not items:
        return []

    if sort_mode == "downloads":
        items.sort(key=lambda x: x["downloads"], reverse=True)
        return [(x["downloads"], x["repo_id"], x["model"]) for x in items[:top_n]]

    if sort_mode == "likes":
        items.sort(key=lambda x: x["likes"], reverse=True)
        return [(x["likes"], x["repo_id"], x["model"]) for x in items[:top_n]]

    # composite scoring
    # normalize components
    max_dl = max((x["downloads"] for x in items), default=1)
    max_likes = max((x["likes"] for x in items), default=1)
    # recency in days: newer -> higher
    import datetime

    now = datetime.datetime.now(datetime.timezone.utc)
    recencies = []
    for x in items:
        if x["lastmod"]:
            try:
                days = max(0, (now - x["lastmod"]).days)
            except Exception:
                days = 365
        else:
            days = 365
        recencies.append(days)
    max_rec = max(recencies) if recencies else 1

    # probe repo files for weight types and owner metadata
    trusted_orgs = {"TheBloke", "stabilityai", "meta", "openai", "huggingface", "EleutherAI", "bigscience", "microsoft"}
    for x in items:
        repo = x["repo_id"]
        weight_types = []
        try:
            files = api.list_repo_files(repo)
            lower = [f.lower() for f in files]
            if any(".gguf" in f for f in lower):
                weight_types.append("gguf")
            if any(f.endswith(".safetensors") for f in lower):
                weight_types.append("safetensors")
            if any("pytorch_model" in f or f.endswith(".bin") for f in lower):
                weight_types.append("pytorch")
        except Exception:
            weight_types = []
        x["weight_types"] = weight_types
        try:
            x["owner"] = repo.split("/")[0]
        except Exception:
            x["owner"] = ""

    # apply filters: gguf_only and max_b
    if gguf_only:
        items = [it for it in items if it.get("weight_types") and "gguf" in it.get("weight_types")]

    if max_b is not None:
        filtered = []
        for it in items:
            size_b = _parse_b_from_id(it["repo_id"]) or None
            # try tags for sizes
            if size_b is None:
                for t in it.get("tags", []):
                    size_b = _parse_b_from_id(t) or size_b
            # include if size known and <= max_b
            if size_b is not None:
                if size_b <= float(max_b):
                    filtered.append(it)
                else:
                    continue
            else:
                # if unknown size, allow only if weights present (gguf/safetensors)
                if it.get("weight_types"):
                    filtered.append(it)
        items = filtered

    scored = []
    for idx, x in enumerate(items):
        dl_norm = x["downloads"] / max_dl if max_dl > 0 else 0
        likes_norm = x["likes"] / max_likes if max_likes > 0 else 0
        recency_days = recencies[idx]
        rec_norm = (max_rec - recency_days) / max_rec if max_rec > 0 else 0
        tag_boost = 0
        low_tags = {t.lower() for t in x["tags"] if t}
        if "text-generation" in low_tags or "text-generation" in (getattr(x["model"], "pipeline_tag", "") or ""):
            tag_boost += 0.2
        if "transformers" in low_tags:
            tag_boost += 0.15
        # boost if weights present (prefer models with gguf/safetensors/pytorch for local use)
        weight_boost = 0
        if x.get("weight_types"):
            if "gguf" in x["weight_types"]:
                weight_boost += 0.35
            if "safetensors" in x["weight_types"]:
                weight_boost += 0.2
            if "pytorch" in x["weight_types"]:
                weight_boost += 0.1

        owner_boost = 0
        if x.get("owner") in trusted_orgs:
            owner_boost = 0.25

        # weights: downloads 0.45, likes 0.25, recency 0.15
        score = dl_norm * 0.45 + likes_norm * 0.25 + rec_norm * 0.15 + tag_boost + weight_boost + owner_boost
        scored.append((score, x["repo_id"], x["model"], x))

    scored.sort(reverse=True, key=lambda x: x[0])
    # prepare output with representative metric (composite score -> show downloads for context)
    # optionally filter to only models that have weights
    if require_weights:
        scored = [s for s in scored if s[3].get("weight_types")]

    out = []
    for s, repo_id, m, meta in scored[:top_n]:
        out.append((int(meta.get("downloads", 0)), repo_id, m, meta))
    return out


def show_top_list(scored_list):
    if not scored_list:
        print("No models found.")
        return
    print("\nTop models:")
    for i, item in enumerate(scored_list, start=1):
        # support returned tuples with meta
        if len(item) == 4:
            dl, repo_id, m, meta = item
        else:
            dl, repo_id, m = item
            meta = {}
        name = getattr(m, "modelId", repo_id)
        short = getattr(m, "pipeline_tag", "") or (m.tags[0] if getattr(m, "tags", None) else "")
        weights = ",".join(meta.get("weight_types", [])) if meta else ""
        likes = meta.get("likes") if meta else None
        extras = []
        if weights:
            extras.append(f"weights:{weights}")
        if likes is not None:
            extras.append(f"likes:{likes}")
        extras_s = f" ({'; '.join(extras)})" if extras else ""
        print(f"{i}. {name} — downloads: {dl} — tag: {short}{extras_s}")

    print("\nEnter a number to view details, or 0 to go back.")
    while True:
        choice = input("> ").strip()
        if choice == "0":
            return
        if not choice.isdigit():
            print("Please enter a number (0 to go back).")
            continue
        idx = int(choice)
        if 1 <= idx <= len(scored_list):
            sel = scored_list[idx - 1]
            if len(sel) == 4:
                dl, repo_id, m, meta = sel
            else:
                dl, repo_id, m = sel
                meta = {}
            show_model_detail(repo_id, m, dl, meta)
            print("\nBack to list — choose another number or 0 to go back.")
        else:
            print("Out of range; try again.")


def show_model_detail(repo_id, m, downloads, meta=None):
    print("\n--- Model Detail ---")
    print(f"ID: {repo_id}")
    print(f"Downloads: {downloads}")
    print(f"Type: {getattr(m, 'type', '')}")
    print(f"Tags: {', '.join(getattr(m, 'tags', []) or [])}")
    print(f"Pipeline tag: {getattr(m, 'pipeline_tag', '')}")
    if meta:
        print(f"Likes: {meta.get('likes', '')}")
        print(f"Weight types: {', '.join(meta.get('weight_types', []) or [])}")
        print(f"Owner: {meta.get('owner', '')}")
        lm = meta.get('lastmod') or getattr(m, 'lastModified', '')
        print(f"Last modified: {lm}")
    else:
        print(f"Last modified: {getattr(m, 'lastModified', '')}")
    print("--- End ---\n")


def interactive_menu():
    while True:
        print("\nHugging Face Model Search")
        print("0) Exit")
        print("1) Search by name keyword")
        print("2) Search by tag keyword")
        choice = input("> ").strip()
        if choice == "0":
            print("Exiting.")
            return
        if choice == "1":
            keyword = input("Enter name keyword (or 0 to cancel): ").strip()
            if keyword == "0":
                continue
            print(f"Searching for name keyword: {keyword}...")
            models = search_by_name(keyword)
            scored = rank_models(models, top_n=TOP_N, sort_mode="composite")
            show_top_list(scored)
        elif choice == "2":
            tag = input("Enter tag keyword (or 0 to cancel): ").strip()
            if tag == "0":
                continue
            print(f"Searching for tag: {tag}...")
            models = search_by_tag(tag)
            scored = rank_models(models, top_n=TOP_N, sort_mode="composite")
            show_top_list(scored)
        else:
            print("Invalid choice — enter 0, 1 or 2.")


def one_shot_name(keyword):
    models = search_by_name(keyword)
    scored = rank_models(models, top_n=TOP_N, sort_mode="composite")
    show_top_list(scored)


def one_shot_tag(tag):
    models = search_by_tag(tag)
    scored = rank_models(models, top_n=TOP_N, sort_mode="composite")
    show_top_list(scored)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Hugging Face model search CLI")
    parser.add_argument("--name", help="Search by name keyword (one-shot)")
    parser.add_argument("--tag", help="Search by tag keyword (one-shot)")
    parser.add_argument("--sort", choices=["composite", "downloads", "likes"], default="composite", help="Ranking strategy for results")
    parser.add_argument("--limit", type=int, default=FETCH_LIMIT, help="How many model candidates to fetch from HF before ranking")
    parser.add_argument("--top", type=int, default=TOP_N, help="How many top results to show")
    parser.add_argument("--require-weights", action="store_true", help="Only show models that include downloadable weight files (gguf/safetensors/bin)")
    parser.add_argument("--gguf-only", action="store_true", help="Only show models that expose GGUF weight files")
    parser.add_argument("--max-b", type=float, default=None, help="Maximum model size in billions of parameters (e.g. 7 for 7B). If provided, models larger than this will be excluded unless they provide local weights).")
    args = parser.parse_args()
    if args.name:
        models = search_by_name(args.name, fetch_limit=args.limit)
        scored = rank_models(models, top_n=args.top, sort_mode=args.sort, require_weights=args.require_weights)
        show_top_list(scored)
        sys.exit(0)
    if args.tag:
        models = search_by_tag(args.tag, fetch_limit=args.limit)
        scored = rank_models(models, top_n=args.top, sort_mode=args.sort, require_weights=args.require_weights)
        show_top_list(scored)
        sys.exit(0)

    interactive_menu()
