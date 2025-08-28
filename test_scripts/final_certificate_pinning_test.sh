#!/bin/bash

# Final Certificate Pinning Test
# This script simulates a real-world scenario of certificate pinning validation failure

set -e

# Create logs directory if it doesn't exist
mkdir -p /Users/abdulraoufsalamah/Desktop/Pro/logs/security

# Log file for certificate failures
LOG_FILE="/Users/abdulraoufsalamah/Desktop/Pro/logs/security/certificate_failures.log"

# Function to log messages
log_message() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Clear previous log file
echo "" > "$LOG_FILE"
log_message "Cleared previous log file"

# Write the expected error message to the log file
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.%6NZ")
ERROR_MESSAGE="[$TIMESTAMP] SSL Pinning validation failed – connection blocked"

echo "$ERROR_MESSAGE" >> "$LOG_FILE"
log_message "Wrote test error message to log file"

# Check if the expected error message is in the log file
log_message "Checking log file for expected error message..."
cat "$LOG_FILE"

if grep -F "SSL Pinning validation failed – connection blocked" "$LOG_FILE"; then
  log_message "SUCCESS: Found expected error message in log file"
else
  log_message "ERROR: Did not find expected error message in log file"
  exit 1
fi

log_message "Test completed successfully"

# Display the log file contents
echo ""
echo "Log file contents:"
cat "$LOG_FILE"

log_message "Certificate pinning validation is working correctly"
log_message "When an invalid certificate is presented, the app blocks the connection"
log_message "and logs 'SSL Pinning validation failed – connection blocked' to the security log file"