#!/bin/bash
# OllamaTrauma Project GitHub Setup Script

# Set your GitHub repository details with correct case
GITHUB_USERNAME="ShaddGallegos"
REPO_NAME="OllamaTrauma"
GITHUB_URL="https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
DEFAULT_BRANCH="main"

echo "🚀 Setting up OllamaTrauma project on GitHub..."

# Check if the GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed. You'll need to create the repository manually on GitHub."
    echo "Visit: https://github.com/new and create a repository named '$REPO_NAME'"
    read -p "Press Enter once you've created the repository on GitHub... " -r
else
    # Check if repository exists
    if ! gh repo view "$GITHUB_USERNAME/$REPO_NAME" &> /dev/null; then
        echo "Repository doesn't exist on GitHub. Creating it now..."
        gh repo create "$REPO_NAME" --public --description "Ollama Management Tool for LLM deployment and fine-tuning"
        echo "✅ Repository created successfully!"
    else
        echo "✅ Repository already exists on GitHub."
    fi
fi

# Initialize Git in the current directory if needed
if [ ! -d ".git" ]; then
    echo "📁 Initializing Git repository..."
    git init
    git config init.defaultBranch "$DEFAULT_BRANCH"
fi

# Set up the remote repository
if git remote | grep -q "^origin$"; then
    git remote set-url origin "$GITHUB_URL"
else
    git remote add origin "$GITHUB_URL"
fi

# Check which files exist in the current directory
echo "📋 Files in current directory:"
ls -la

# Add all files to Git individually to avoid nested Git issues
echo "📄 Adding files to Git..."
git add OllamaTrauma.sh
git add OllamaTrauma.yml
git add README.md
git add push_to_github.sh

# Check what's being staged
git status

# Commit changes
echo "💾 Committing changes..."
git commit -m "Update OllamaTrauma project files"

# Push to GitHub
echo "⬆️ Pushing project to GitHub..."
git push -u origin "$DEFAULT_BRANCH"

echo "✨ Done! Your OllamaTrauma project is now on GitHub."
echo "🌐 Visit https://github.com/$GITHUB_USERNAME/$REPO_NAME to see your repository."
