#!/usr/bin/env python3
"""Crawl URLs for training data"""
import sys
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse
import argparse

def crawl_url(url, depth=3, visited=None):
    if visited is None:
        visited = set()
    
    if depth == 0 or url in visited:
        return
    
    visited.add(url)
    print(f"Crawling: {url}")
    
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Extract text
        text = soup.get_text(separator='\n', strip=True)
        filename = f"training_data_{len(visited)}.txt"
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(text)
        print(f"  Saved to: {filename}")
        
        # Find links
        for link in soup.find_all('a', href=True):
            next_url = urljoin(url, link['href'])
            if urlparse(next_url).netloc == urlparse(url).netloc:
                crawl_url(next_url, depth-1, visited)
    except Exception as e:
        print(f"  Error: {e}", file=sys.stderr)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("url", help="URL to crawl")
    parser.add_argument("--depth", type=int, default=3)
    args = parser.parse_args()
    crawl_url(args.url, args.depth)
