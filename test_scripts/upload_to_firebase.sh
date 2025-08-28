#!/bin/bash

# Script to upload test reports to Firebase Hosting

set -e

# Define variables
REPORTS_DIR="../reports"
FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-your-firebase-project-id}"
FIREBASE_TOKEN="${FIREBASE_TOKEN:-}"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
DEPLOY_TARGET="test-reports-$TIMESTAMP"

# Parse command line arguments
CI_MODE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --ci-mode)
      CI_MODE=true
      shift
      ;;
    --project-id)
      FIREBASE_PROJECT_ID="$2"
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

# Check if Firebase CLI is installed
if ! command -v firebase >/dev/null 2>&1; then
  echo "Error: Firebase CLI not installed. Please install it with 'npm install -g firebase-tools'"
  exit 1
fi

# Create a temporary directory for Firebase hosting files
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"

# Copy reports to temporary directory
cp -r "$REPORTS_DIR/" "$TEMP_DIR/public"

# Create firebase.json configuration file
cat > "$TEMP_DIR/firebase.json" << EOF
{
  "hosting": {
    "public": "public",
    "ignore": [
      "firebase.json",
      "**/.*"
    ],
    "site": "$DEPLOY_TARGET"
  }
}
EOF

# Create .firebaserc file
cat > "$TEMP_DIR/.firebaserc" << EOF
{
  "projects": {
    "default": "$FIREBASE_PROJECT_ID"
  }
}
EOF

# Navigate to temporary directory
cd "$TEMP_DIR"

# Login to Firebase if not in CI mode and no token provided
if [ "$CI_MODE" = false ] && [ -z "$FIREBASE_TOKEN" ]; then
  echo "Logging in to Firebase..."
  firebase login
fi

# Deploy to Firebase Hosting
echo "Deploying reports to Firebase Hosting..."
if [ -n "$FIREBASE_TOKEN" ]; then
  firebase hosting:sites:create "$DEPLOY_TARGET" --project "$FIREBASE_PROJECT_ID" --token "$FIREBASE_TOKEN"
  firebase deploy --only hosting --project "$FIREBASE_PROJECT_ID" --token "$FIREBASE_TOKEN"
else
  firebase hosting:sites:create "$DEPLOY_TARGET" --project "$FIREBASE_PROJECT_ID"
  firebase deploy --only hosting --project "$FIREBASE_PROJECT_ID"
fi

# Get the deployed URL
DEPLOYED_URL="https://$DEPLOY_TARGET.web.app"

echo "Reports successfully deployed to Firebase Hosting"
echo "URL: $DEPLOYED_URL"

# Clean up temporary directory
cd -
rm -rf "$TEMP_DIR"

exit 0