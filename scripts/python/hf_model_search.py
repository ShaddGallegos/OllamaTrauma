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
from huggingface_hub import HfApi

api = HfApi()

FETCH_LIMIT = 80
TOP_N = 10


def get_downloads_safe(repo_id):
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
    try:
        info = api.model_info(repo_id)
        t = getattr(info, "lastModified", None)
        if t:
            # try to parse common ISO formats
            try:
                from dateutil import parser

                try:
                    return parser.parse(t)
                except Exception:
                    pass
            except Exception:
                pass
            # fallback to datetime.fromisoformat if available
            try:
                import datetime

                return datetime.datetime.fromisoformat(t.replace('Z', '+00:00'))
            except Exception:
                return None
        return None
    except Exception:
        return None


def search_by_name(keyword, fetch_limit=FETCH_LIMIT):
    # huggingface_hub supports search param
    models = api.list_models(search=keyword, limit=fetch_limit)
    return models


def search_by_tag(tag, fetch_limit=FETCH_LIMIT):
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


def rank_models(models, top_n=TOP_N, sort_mode="composite"):
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

    now = datetime.datetime.utcnow()
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
        # weights: downloads 0.5, likes 0.3, recency 0.2
        score = dl_norm * 0.5 + likes_norm * 0.3 + rec_norm * 0.2 + tag_boost
        scored.append((score, x["repo_id"], x["model"], x))

    scored.sort(reverse=True, key=lambda x: x[0])
    # prepare output with representative metric (composite score -> show downloads for context)
    out = []
    for s, repo_id, m, meta in scored[:top_n]:
        out.append((int(meta["downloads"]), repo_id, m))
    return out


def show_top_list(scored_list):
    if not scored_list:
        print("No models found.")
        return
    print("\nTop models:")
    for i, (dl, repo_id, m) in enumerate(scored_list, start=1):
        name = getattr(m, "modelId", repo_id)
        card = getattr(m, "cardData", None)
        short = getattr(m, "pipeline_tag", "") or (m.tags[0] if getattr(m, "tags", None) else "")
        print(f"{i}. {name} — downloads: {dl} — tag: {short}")

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
            dl, repo_id, m = scored_list[idx - 1]
            show_model_detail(repo_id, m, dl)
            print("\nBack to list — choose another number or 0 to go back.")
        else:
            print("Out of range; try again.")


def show_model_detail(repo_id, m, downloads):
    print("\n--- Model Detail ---")
    print(f"ID: {repo_id}")
    print(f"Downloads: {downloads}")
    print(f"Type: {getattr(m, 'type', '')}")
    print(f"Tags: {', '.join(getattr(m, 'tags', []) or [])}")
    print(f"Pipeline tag: {getattr(m, 'pipeline_tag', '')}")
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
    args = parser.parse_args()
    if args.name:
        models = search_by_name(args.name, fetch_limit=args.limit)
        scored = rank_models(models, top_n=args.top, sort_mode=args.sort)
        show_top_list(scored)
        sys.exit(0)
    if args.tag:
        models = search_by_tag(args.tag, fetch_limit=args.limit)
        scored = rank_models(models, top_n=args.top, sort_mode=args.sort)
        show_top_list(scored)
        sys.exit(0)

    interactive_menu()
