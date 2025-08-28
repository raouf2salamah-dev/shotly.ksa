#!/bin/bash

# Script to test the webhook functionality of the security dashboard

set -e

echo "Testing webhook functionality..."

# Default values
DASHBOARD_URL="http://localhost:8080/webhook.html"
BUILD_NUMBER="test-$(date +%s)"
BUILD_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
BRANCH="test-branch"
COMMIT_HASH="test-commit-$(date +%s)"
BUILD_STATUS="success"

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
    "duration": "1m 30s"
  },
  "testResults": {
    "total": 120,
    "passed": 118,
    "failed": 2,
    "tests": [
      {
        "name": "test_login_success",
        "status": "passed",
        "duration": "0.5s"
      },
      {
        "name": "test_login_failure",
        "status": "passed",
        "duration": "0.4s"
      },
      {
        "name": "test_security_feature_enabled",
        "status": "failed",
        "duration": "0.3s",
        "error": "Expected true but got false"
      }
    ]
  }
}
EOF
)

# Send webhook to dashboard
echo "Sending webhook to $DASHBOARD_URL"
curl -X POST "$DASHBOARD_URL" \
  -H "Content-Type: application/json" \
  -H "X-Build-Secret: dashboard-secret" \
  -d "$PAYLOAD"

echo "\nWebhook test complete"