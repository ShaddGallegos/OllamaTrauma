#!/usr/bin/env bash
# Project bootstrap helpers for OllamaTrauma.

create_project_structure() {
  log_step "Creating project structure..."

  local dirs=(
    "data/models"
    "data/training"
    "data/outputs"
    "data/logs"
    "scripts"
    "config"
    ".backups"
  )

  for dir in "${dirs[@]}"; do
    mkdir -p "${PROJECT_ROOT}/${dir}"
    touch "${PROJECT_ROOT}/${dir}/.gitkeep"
  done

  log_success "Project directories created"
}

create_requirements_txt() {
  local req_file="${PROJECT_ROOT}/requirements.txt"

  if [[ -f "$req_file" ]]; then
    log_info "requirements.txt already exists"
    return 0
  fi

  log_step "Creating requirements.txt..."

  cat > "$req_file" << 'EOF'
# OllamaTrauma Python Dependencies
requests>=2.31.0
beautifulsoup4>=4.12.0
huggingface-hub>=0.19.0
pyyaml>=6.0
tqdm>=4.66.0
lxml>=4.9.0
argparse>=1.4.0
urllib3>=2.0.0
EOF

  log_success "requirements.txt created"
}

create_gitignore() {
  local gitignore="${PROJECT_ROOT}/.gitignore"

  if [[ -f "$gitignore" ]]; then
    log_info ".gitignore already exists"
    return 0
  fi

  log_step "Creating .gitignore..."

  cat > "$gitignore" << 'EOF'
# OllamaTrauma
*.log
.ollamatrauma.lock
.backups/
data/models/*
!data/models/.gitkeep
data/training/*
!data/training/.gitkeep
data/outputs/*
!data/outputs/.gitkeep
data/logs/*
!data/logs/.gitkeep

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
ENV/

# OS
.DS_Store
Thumbs.db
*~
EOF

  log_success ".gitignore created"
}

create_utility_scripts() {
  log_step "Creating utility scripts..."

  # HF Search wrapper (calls the python/hf_model_search.py CLI)
  cat > "${PROJECT_ROOT}/scripts/hf_search.py" << 'EOFPY'
#!/usr/bin/env python3
import os
import sys
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
TARGET = os.path.join(HERE, 'python', 'hf_model_search.py')
if not os.path.exists(TARGET):
    print(f"Missing helper: {TARGET}", file=sys.stderr)
    sys.exit(1)

cmd = [sys.executable, TARGET] + sys.argv[1:]
sys.exit(subprocess.call(cmd))
EOFPY

  chmod +x "${PROJECT_ROOT}/scripts/hf_search.py"
  log_success "Created hf_search.py (wrapper to scripts/python/hf_model_search.py)"

  # URL Crawler Script
  cat > "${PROJECT_ROOT}/scripts/url_crawler.py" << 'EOFPY'
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
EOFPY

  chmod +x "${PROJECT_ROOT}/scripts/url_crawler.py"
  log_success "Created url_crawler.py"

  # Monitor script generation removed — monitoring is inlined in the
  # `monitor_batch_download()` function and platform-specific scripts.
}
