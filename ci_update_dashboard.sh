#!/bin/bash

# Script to update the security dashboard after CI/CD builds
# This script should be called from your CI/CD pipeline

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
DASHBOARD_URL="http://localhost:8080/webhook.html"
BUILD_NUMBER="${GITHUB_RUN_NUMBER:-unknown}"
BUILD_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
BRANCH="${GITHUB_REF_NAME:-${CIRCLE_BRANCH:-unknown}}"
COMMIT_HASH="${GITHUB_SHA:-${CIRCLE_SHA1:-unknown}}"
BUILD_STATUS="success"
TEST_RESULTS_PATH="${SCRIPT_DIR}/reports/merged/test_results.json"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dashboard-url=*)
      DASHBOARD_URL="${1#*=}"
      ;;
    --build-number=*)
      BUILD_NUMBER="${1#*=}"
      ;;
    --build-date=*)
      BUILD_DATE="${1#*=}"
      ;;
    --branch=*)
      BRANCH="${1#*=}"
      ;;
    --commit-hash=*)
      COMMIT_HASH="${1#*=}"
      ;;
    --build-status=*)
      BUILD_STATUS="${1#*=}"
      ;;
    --test-results=*)
      TEST_RESULTS_PATH="${1#*=}"
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --dashboard-url=URL    Dashboard webhook URL (default: http://localhost:8080/webhook)"
      echo "  --build-number=NUM     Build number (default: from CI environment)"
      echo "  --build-date=DATE      Build date in ISO format (default: current UTC time)"
      echo "  --branch=BRANCH        Branch name (default: from CI environment)"
      echo "  --commit-hash=HASH     Commit hash (default: from CI environment)"
      echo "  --build-status=STATUS  Build status (default: success)"
      echo "  --test-results=PATH    Path to test results JSON (default: reports/merged/test_results.json)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

echo "Updating security dashboard at $DASHBOARD_URL"

# Read test results if file exists
TEST_DATA="{}"
if [[ -f "$TEST_RESULTS_PATH" ]]; then
  TEST_DATA=$(cat "$TEST_RESULTS_PATH")
fi

# Calculate build duration if in GitHub Actions
BUILD_DURATION="unknown"
if [[ -n "$GITHUB_ACTION" && -n "$GITHUB_RUN_ID" ]]; then
  # This is a simplified calculation - in a real scenario you'd want to track start time
  START_TIME=$(date -d "$(git show -s --format=%ci $COMMIT_HASH)" +%s)
  END_TIME=$(date +%s)
  DURATION_SEC=$((END_TIME - START_TIME))
  DURATION_MIN=$((DURATION_SEC / 60))
  DURATION_SEC=$((DURATION_SEC % 60))
  BUILD_DURATION="${DURATION_MIN}m ${DURATION_SEC}s"
fi

# Create webhook payload
PAYLOAD=$(cat <<EOF
{
  "event": "build_completed",
  "buildMetadata": {
    "buildNumber": "$BUILD_NUMBER",
    "buildDate": "$BUILD_DATE",
    "branch": "$BRANCH",
    "commitHash": "$COMMIT_HASH",
    "buildStatus": "$BUILD_STATUS",
    "duration": "$BUILD_DURATION"
  },
  "testResults": $TEST_DATA
}
EOF
)

# Send webhook to dashboard
curl -X POST "$DASHBOARD_URL" \
  -H "Content-Type: application/json" \
  -H "X-Build-Secret: ${BUILD_WEBHOOK_SECRET:-dashboard-secret}" \
  -d "$PAYLOAD"

echo "Dashboard update complete"