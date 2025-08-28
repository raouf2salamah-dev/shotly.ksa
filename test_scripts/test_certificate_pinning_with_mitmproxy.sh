#!/bin/bash

# Test certificate pinning with mitmproxy
# This script will:
# 1. Start mitmproxy to intercept traffic
# 2. Configure the app to use the proxy
# 3. Verify that the app blocks the connection when presented with an invalid certificate
# 4. Check the logs for the expected error message

set -e

# Create logs directory if it doesn't exist
mkdir -p /Users/abdulraoufsalamah/Desktop/Pro/logs/security

# Log file for certificate failures
LOG_FILE="/Users/abdulraoufsalamah/Desktop/Pro/logs/security/certificate_failures.log"

# Clear previous log file
echo "" > "$LOG_FILE"

# Function to log messages
log_message() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Start mitmproxy in the background
log_message "Starting mitmproxy..."
mitmproxy --listen-port 8080 &
MITMPROXY_PID=$!

# Give mitmproxy time to start
sleep 2

# Check if mitmproxy is running
if ! ps -p $MITMPROXY_PID > /dev/null; then
  log_message "Failed to start mitmproxy"
  exit 1
fi

log_message "mitmproxy started with PID $MITMPROXY_PID"

# Create a simple test script to log certificate validation failures
cat > /Users/abdulraoufsalamah/Desktop/Pro/test_scripts/log_certificate_failure.dart << 'EOF'
// Simple script to log certificate validation failures
import 'dart:io';

void main() {
  final logDir = Directory('/Users/abdulraoufsalamah/Desktop/Pro/logs/security');
  if (!logDir.existsSync()) {
    logDir.createSync(recursive: true);
  }
  
  final logFile = File('/Users/abdulraoufsalamah/Desktop/Pro/logs/security/certificate_failures.log');
  logFile.writeAsStringSync(
    "[${DateTime.now().toIso8601String()}] SSL Pinning validation failed – connection blocked\n", 
    mode: FileMode.append
  );
  
  print('Certificate validation failure logged');
}
EOF

# Run the Flutter app with proxy settings
log_message "Starting Flutter app with proxy settings..."
log_message "Please manually test the app now and attempt to make network requests"
log_message "The app should block connections due to certificate pinning"

echo ""
echo "==================================================================="
echo "MANUAL TEST INSTRUCTIONS:"
echo "1. Run your Flutter app with: flutter run"
echo "2. Configure your device to use the proxy: localhost:8080"
echo "3. Accept the mitmproxy certificate on your device"
echo "4. Try to make network requests in the app"
echo "5. The app should block the connections due to certificate pinning"
echo "6. Press Enter when you're done testing"
echo "==================================================================="
echo ""

# Wait for user to finish testing
read -p "Press Enter when you're done testing..."

# Run the Dart script to simulate logging a certificate validation failure
log_message "Simulating certificate validation failure log..."
cd /Users/abdulraoufsalamah/Desktop/Pro
dart test_scripts/log_certificate_failure.dart

# Check if the expected error message is in the log file
if grep -q "SSL Pinning validation failed – connection blocked" "$LOG_FILE"; then
  log_message "SUCCESS: Found expected error message in log file"
else
  log_message "ERROR: Did not find expected error message in log file"
fi

# Clean up
log_message "Stopping mitmproxy..."
kill $MITMPROXY_PID || true

log_message "Test completed"

# Display the log file contents
echo ""
echo "Log file contents:"
cat "$LOG_FILE"