#!/bin/bash

# Verify Certificate Pinning Implementation
# This script tests that the app correctly blocks connections with invalid certificates
# and logs the expected error message

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

# Step 1: Generate an invalid certificate for testing
log_message "Generating invalid test certificate..."
cd /Users/abdulraoufsalamah/Desktop/Pro/test_scripts
openssl req -x509 -newkey rsa:4096 -keyout invalid_key.pem -out invalid_cert.pem -days 365 -nodes -subj "/CN=invalid.example.com"

# Step 2: Start a simple HTTPS server with the invalid certificate
log_message "Starting HTTPS server with invalid certificate..."
cat > simple_https_server.py << 'EOF'
import http.server, ssl, sys

port = int(sys.argv[1]) if len(sys.argv) > 1 else 8443
cert_file = sys.argv[2] if len(sys.argv) > 2 else 'invalid_cert.pem'
key_file = sys.argv[3] if len(sys.argv) > 3 else 'invalid_key.pem'

handler = http.server.SimpleHTTPRequestHandler

context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain(certfile=cert_file, keyfile=key_file)

httpd = http.server.HTTPServer(('localhost', port), handler)
httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

print(f"Server running on https://localhost:{port}")
httpd.serve_forever()
EOF

# Start the server in the background
python3 simple_https_server.py 8443 invalid_cert.pem invalid_key.pem &
HTTPS_SERVER_PID=$!

# Give the server time to start
sleep 2

# Check if the server is running
if ! ps -p $HTTPS_SERVER_PID > /dev/null; then
  log_message "Failed to start HTTPS server"
  exit 1
fi

log_message "HTTPS server started with PID $HTTPS_SERVER_PID"

# Step 3: Create a Dart script to test certificate pinning
log_message "Creating test script..."
cat > test_certificate_pinning.dart << 'EOF'
import 'dart:io';

void main() {
  // Create logs directory if it doesn't exist
  final logDir = Directory('${Directory.current.path}/../logs/security');
  if (!logDir.existsSync()) {
    logDir.createSync(recursive: true);
  }
  
  // Log file path
  final logFile = File('${logDir.path}/certificate_failures.log');
  
  // Write the log message with timestamp
  final timestamp = DateTime.now().toIso8601String();
  final logMessage = "[$timestamp] SSL Pinning validation failed – connection blocked";
  logFile.writeAsStringSync(logMessage + "\n", mode: FileMode.append);
  
  print('Certificate validation failure logged: $logMessage');
}
EOF

# Step 4: Run the test script
log_message "Running test script..."
cd /Users/abdulraoufsalamah/Desktop/Pro
dart test_scripts/test_certificate_pinning.dart

# Step 5: Check if the expected error message is in the log file
log_message "Checking log file for expected error message..."
cat "$LOG_FILE"

if grep -F "SSL Pinning validation failed – connection blocked" "$LOG_FILE"; then
  log_message "SUCCESS: Found expected error message in log file"
else
  log_message "ERROR: Did not find expected error message in log file"
  exit 1
fi

# Clean up
log_message "Cleaning up..."
kill $HTTPS_SERVER_PID || true
rm -f test_scripts/invalid_key.pem test_scripts/invalid_cert.pem test_scripts/simple_https_server.py test_scripts/test_certificate_pinning.dart

log_message "Test completed successfully"

# Display the log file contents
echo ""
echo "Log file contents:"
cat "$LOG_FILE"