#!/bin/bash

# Script to upload test reports to GitHub Pages

set -e

# Define variables
REPORTS_DIR="../reports"
GH_PAGES_BRANCH="gh-pages"
GH_PAGES_DIR="test-reports"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Parse command line arguments
CI_MODE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --ci-mode)
      CI_MODE=true
      shift
      ;;
    --branch)
      GH_PAGES_BRANCH="$2"
      shift 2
      ;;
    --dir)
      GH_PAGES_DIR="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Check if reports directory exists
if [ ! -d "$REPORTS_DIR" ]; then
  echo "Error: Reports directory not found: $REPORTS_DIR"
  exit 1
fi

# Check if git is installed
if ! command -v git >/dev/null 2>&1; then
  echo "Error: Git not installed"
  exit 1
fi

# Get the current repository URL
REPO_URL=$(git config --get remote.origin.url)
if [ -z "$REPO_URL" ]; then
  echo "Error: Could not determine repository URL"
  exit 1
fi

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"

# Clone the repository to the temporary directory
echo "Cloning repository..."
git clone "$REPO_URL" --branch "$GH_PAGES_BRANCH" "$TEMP_DIR" 2>/dev/null || (
  echo "Branch $GH_PAGES_BRANCH does not exist, creating it..."
  git clone "$REPO_URL" "$TEMP_DIR"
  cd "$TEMP_DIR"
  git checkout --orphan "$GH_PAGES_BRANCH"
  git rm -rf .
  echo "# Test Reports" > README.md
  git add README.md
  git config user.name "GitHub Actions"
  git config user.email "actions@github.com"
  git commit -m "Initial commit"
  git push origin "$GH_PAGES_BRANCH"
)

# Navigate to the temporary directory
cd "$TEMP_DIR"

# Create the reports directory if it doesn't exist
mkdir -p "$GH_PAGES_DIR"

# Copy the reports to the GitHub Pages directory
cp -r "$REPORTS_DIR/"* "$GH_PAGES_DIR/"

# Create or update the index.html file
cat > index.html << EOF
<!DOCTYPE html>
<html>
<head>
  <title>Test Reports</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    .container { border: 1px solid #ddd; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
    h1, h2 { color: #333; }
    .report-link { margin: 10px 0; }
    .timestamp { color: #666; font-size: 0.9em; }
  </style>
</head>
<body>
  <h1>Test Reports</h1>
  <div class="timestamp">Last updated: $TIMESTAMP</div>
  
  <div class="container">
    <h2>Latest Reports</h2>
    <div class="report-link">
      <a href="$GH_PAGES_DIR/merged/index.html">View Latest Test Reports</a>
    </div>
  </div>
</body>
</html>
EOF

# Add all files to git
git add .

# Commit the changes
git config user.name "GitHub Actions"
git config user.email "actions@github.com"
git commit -m "Update test reports - $TIMESTAMP"

# Push the changes
echo "Pushing changes to GitHub Pages..."
if [ "$CI_MODE" = true ]; then
  # In CI mode, use the GitHub token for authentication
  git push "https://x-access-token:${GITHUB_TOKEN}@${REPO_URL#https://}" "$GH_PAGES_BRANCH"
else
  # In local mode, use the user's credentials
  git push origin "$GH_PAGES_BRANCH"
fi

# Get the GitHub Pages URL
REPO_NAME=$(basename -s .git "$REPO_URL")
ORG_NAME=$(dirname "$REPO_URL" | xargs basename)
GH_PAGES_URL="https://$ORG_NAME.github.io/$REPO_NAME/$GH_PAGES_DIR/merged/index.html"

echo "Reports successfully uploaded to GitHub Pages"
echo "URL: $GH_PAGES_URL"

# Clean up temporary directory
cd -
rm -rf "$TEMP_DIR"

exit 0