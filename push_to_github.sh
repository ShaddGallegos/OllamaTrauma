# push_to_github.sh
# OllamaTrauma Project GitHub Setup Script
#!/bin/bash

# Set your GitHub repository URL
GITHUB_URL="https://github.com/shaddgalegos/OllamaTrauma.git"

# Initialize the Git repository if not already initialized
if [ ! -d ".git" ]; then
    echo "Initializing Git repository..."
    git init
else
    echo "Git repository already exists."
fi

# Add all files to Git
echo "Adding files to Git..."
git add .

# Commit changes
echo "Committing changes..."
git commit -m "Initial commit for OllamaTrauma project"

# Set remote origin
echo "Setting up remote repository..."
git remote add origin "$GITHUB_URL"

# Verify remote origin
git remote -v

# Push to GitHub
echo "Pushing project to GitHub..."
git branch -M main
git push -u origin main

echo "Done! Your OllamaTrauma project is now on GitHub."
