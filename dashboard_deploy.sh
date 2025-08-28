#!/bin/bash

# Script to deploy the security dashboard to GitHub Pages

set -e

echo "Building and deploying security dashboard..."

# Build the web app
flutter build web --web-renderer html --release --target=lib/dashboard/main_dashboard.dart

# Create a temporary directory for GitHub Pages
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"

# Copy build files to temporary directory
cp -r build/web/* "$TEMP_DIR"

# Create a simple index.html file that redirects to the dashboard
cat > "$TEMP_DIR/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta http-equiv="refresh" content="0;url=./index.html">
  <title>Security Dashboard</title>
</head>
<body>
  <p>Redirecting to Security Dashboard...</p>
</body>
</html>
EOF

# Deploy to GitHub Pages using gh-pages branch
echo "Deploying to GitHub Pages..."

# Check if gh-pages branch exists
if git show-ref --quiet refs/heads/gh-pages; then
  echo "gh-pages branch exists, updating it"
else
  echo "Creating gh-pages branch"
  git checkout --orphan gh-pages
  git rm -rf .
  git commit --allow-empty -m "Initial gh-pages commit"
  git checkout main
fi

# Switch to gh-pages branch
git checkout gh-pages

# Remove all files except .git
find . -maxdepth 1 ! -name .git -exec rm -rf {} \;

# Copy files from temp directory
cp -r "$TEMP_DIR"/* .

# Add all files
git add .

# Commit changes
git commit -m "Update dashboard $(date)"

# Push to remote
git push origin gh-pages

# Switch back to main branch
git checkout main

# Clean up temporary directory
rm -rf "$TEMP_DIR"

echo "Dashboard deployed successfully!"
echo "Visit https://YOUR_USERNAME.github.io/YOUR_REPO_NAME/ to view the dashboard"

exit 0