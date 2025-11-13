#!/usr/bin/env python3
"""Search Hugging Face models"""
import sys
import requests
import argparse

def search_models(query, limit=15):
    url = "https://huggingface.co/api/models"
    params = {"search": query, "limit": limit}
    
    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        models = response.json()
        
        print(f"\nFound {len(models)} models:\n")
        for i, model in enumerate(models, 1):
            print(f"{i}. {model['id']}")
            print(f"   Downloads: {model.get('downloads', 'N/A')}")
            print(f"   Tags: {', '.join(model.get('tags', [])[:3])}\n")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("query", help="Search query")
    parser.add_argument("--limit", type=int, default=15)
    args = parser.parse_args()
    search_models(args.query, args.limit)
