#!/bin/bash

# CI Certificate Pinning Test Script
# This script tests SSL pinning in a CI environment by validating certificates against expected values

echo "===== CI Certificate Pinning Test ===="
echo "This test verifies that the app's pinned certificates match the expected certificates"

# Define variables
API_ENDPOINT="https://api.yourdomain.com" # Your actual API endpoint
LOG_FILE="ci_certificate_pinning_test.log"
JSON_REPORT="ci_certificate_pinning_test.json"
HTML_REPORT="ci_certificate_pinning_test.html"
REPORTS_DIR="../reports/security"
CERTS_DIR="./certs"
# Primary (current) certificate fingerprint
PRIMARY_FINGERPRINT="AE:2D:AC:CE:88:0C:7F:3B:BE:70:8F:38:24:F1:0B:3E:81:8C:A8:AC:B3:44:15:6B:79:61:01:FB:5D:81:A3:5D"
# Backup (next) certificate fingerprint for rotation
BACKUP_FINGERPRINT="5E:8F:16:52:78:84:DF:09:C0:3E:34:7D:9E:B6:1A:DF:5E:3B:7F:A6:0D:48:4A:C1:3D:B2:0E:79:56:E5:5A:44"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Parse command line arguments
CI_MODE=false
for arg in "$@"
do
    case $arg in
        --ci-mode)
        CI_MODE=true
        shift
        ;;
    esac
done

# Clear previous log file
rm -f "$LOG_FILE"
touch "$LOG_FILE"

# Create necessary directories
mkdir -p "$CERTS_DIR"
mkdir -p "$REPORTS_DIR"

echo "Fetching certificate from $API_ENDPOINT..."
echo "Fetching certificate from $API_ENDPOINT..." >> "$LOG_FILE"

# Fetch the server certificate
openssl s_client -connect $(echo $API_ENDPOINT | sed 's|https://||' | sed 's|/.*||'):443 -servername $(echo $API_ENDPOINT | sed 's|https://||' | sed 's|/.*||') </dev/null 2>/dev/null | openssl x509 -outform PEM > "$CERTS_DIR/server_cert.pem"

# Check if certificate was successfully retrieved
if [ ! -s "$CERTS_DIR/server_cert.pem" ]; then
    echo "❌ TEST FAILED: Could not retrieve server certificate."
    echo "Could not retrieve server certificate." >> "$LOG_FILE"
    exit 1
fi

# Calculate the certificate fingerprint
ACTUAL_FINGERPRINT=$(openssl x509 -in "$CERTS_DIR/server_cert.pem" -noout -fingerprint -sha256 | cut -d'=' -f2)

echo "Primary fingerprint: $PRIMARY_FINGERPRINT"
echo "Backup fingerprint: $BACKUP_FINGERPRINT"
echo "Actual fingerprint: $ACTUAL_FINGERPRINT"

echo "Primary fingerprint: $PRIMARY_FINGERPRINT" >> "$LOG_FILE"
echo "Backup fingerprint: $BACKUP_FINGERPRINT" >> "$LOG_FILE"
echo "Actual fingerprint: $ACTUAL_FINGERPRINT" >> "$LOG_FILE"

# Check if the app's source code contains both primary and backup fingerprints
PRIMARY_FINGERPRINT_IN_CODE=false
BACKUP_FINGERPRINT_IN_CODE=false

if grep -r "$PRIMARY_FINGERPRINT" --include="*.dart" ../lib/ > /dev/null; then
    PRIMARY_FINGERPRINT_IN_CODE=true
fi

if grep -r "$BACKUP_FINGERPRINT" --include="*.dart" ../lib/ > /dev/null; then
    BACKUP_FINGERPRINT_IN_CODE=true
fi

# Check certificate expiration date
CERT_EXPIRY=$(openssl x509 -in "$CERTS_DIR/server_cert.pem" -noout -enddate | cut -d'=' -f2)
CERT_EXPIRY_SECONDS=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$CERT_EXPIRY" +%s 2>/dev/null || date -d "$CERT_EXPIRY" +%s 2>/dev/null)
CURRENT_SECONDS=$(date +%s)
TWO_WEEKS_SECONDS=$((14 * 24 * 60 * 60))
EXPIRY_THRESHOLD=$((CERT_EXPIRY_SECONDS - TWO_WEEKS_SECONDS))

# Validate the certificate against both primary and backup fingerprints
if [[ "$ACTUAL_FINGERPRINT" = "$PRIMARY_FINGERPRINT" || "$ACTUAL_FINGERPRINT" = "$BACKUP_FINGERPRINT" ]] && 
   [[ "$PRIMARY_FINGERPRINT_IN_CODE" = true && "$BACKUP_FINGERPRINT_IN_CODE" = true ]]; then
    echo "✅ TEST PASSED: Certificate pinning is correctly configured with both primary and backup certificates."
    echo "The server's certificate matches one of the expected fingerprints and both are found in the code."
    
    # Check if certificate is expiring soon
    if [ $CURRENT_SECONDS -gt $EXPIRY_THRESHOLD ]; then
        echo "⚠️ WARNING: Certificate is expiring in less than two weeks on $CERT_EXPIRY"
        echo "Certificate is expiring in less than two weeks on $CERT_EXPIRY" >> "$LOG_FILE"
        RESULT_MESSAGE="Certificate pinning is correctly configured, but the certificate is expiring soon on $CERT_EXPIRY. Ensure the backup certificate is ready for rotation."
    else
        RESULT_MESSAGE="Certificate pinning is correctly configured with both primary and backup certificates."
    fi
    
    echo "See $LOG_FILE for details."
    TEST_RESULT="PASSED"
    EXIT_CODE=0
else
    echo "❌ TEST FAILED: Certificate pinning may not be correctly configured."
    TEST_RESULT="FAILED"
    RESULT_MESSAGE="Certificate pinning may not be correctly configured."
    
    if [[ "$ACTUAL_FINGERPRINT" != "$PRIMARY_FINGERPRINT" && "$ACTUAL_FINGERPRINT" != "$BACKUP_FINGERPRINT" ]]; then
        echo "The server's certificate does not match either the primary or backup fingerprint."
        RESULT_MESSAGE="$RESULT_MESSAGE The server's certificate does not match either the primary or backup fingerprint."
    fi
    
    if [ "$PRIMARY_FINGERPRINT_IN_CODE" != true ]; then
        echo "The primary fingerprint was not found in the code."
        RESULT_MESSAGE="$RESULT_MESSAGE The primary fingerprint was not found in the code."
    fi
    
    if [ "$BACKUP_FINGERPRINT_IN_CODE" != true ]; then
        echo "The backup fingerprint was not found in the code."
        RESULT_MESSAGE="$RESULT_MESSAGE The backup fingerprint was not found in the code."
    fi
    
    echo "See $LOG_FILE for details."
    
    # In CI mode, exit with error code
    if [ "$CI_MODE" = true ]; then
        EXIT_CODE=1
    else
        EXIT_CODE=0
    fi
fi

# Generate JSON report
cat > "$REPORTS_DIR/$JSON_REPORT" << EOF
{
  "test_name": "Certificate Pinning Test",
  "timestamp": "$TIMESTAMP",
  "result": "$TEST_RESULT",
  "message": "$RESULT_MESSAGE",
  "details": {
    "api_endpoint": "$API_ENDPOINT",
    "primary_fingerprint": "$PRIMARY_FINGERPRINT",
    "backup_fingerprint": "$BACKUP_FINGERPRINT",
    "actual_fingerprint": "$ACTUAL_FINGERPRINT",
    "primary_fingerprint_in_code": $PRIMARY_FINGERPRINT_IN_CODE,
    "backup_fingerprint_in_code": $BACKUP_FINGERPRINT_IN_CODE
  }
}
EOF

# Generate HTML report
cat > "$REPORTS_DIR/$HTML_REPORT" << EOF
<!DOCTYPE html>
<html>
<head>
  <title>Certificate Pinning Test Report</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    .passed { color: green; }
    .failed { color: red; }
    .container { border: 1px solid #ddd; padding: 20px; border-radius: 5px; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #f2f2f2; }
  </style>
</head>
<body>
  <h1>Certificate Pinning Test Report</h1>
  <div class="container">
    <h2 class="$(echo ${TEST_RESULT} | tr '[:upper:]' '[:lower:]')">Test Result: ${TEST_RESULT}</h2>
    <p><strong>Timestamp:</strong> ${TIMESTAMP}</p>
    <p><strong>Message:</strong> ${RESULT_MESSAGE}</p>
    
    <h3>Details:</h3>
    <table>
      <tr>
        <th>Property</th>
        <th>Value</th>
      </tr>
      <tr>
        <td>API Endpoint</td>
        <td>${API_ENDPOINT}</td>
      </tr>
      <tr>
        <td>Primary Fingerprint</td>
        <td>${PRIMARY_FINGERPRINT}</td>
      </tr>
      <tr>
        <td>Backup Fingerprint</td>
        <td>${BACKUP_FINGERPRINT}</td>
      </tr>
      <tr>
        <td>Actual Fingerprint</td>
        <td>${ACTUAL_FINGERPRINT}</td>
      </tr>
      <tr>
        <td>Primary Fingerprint Found in Code</td>
        <td>${PRIMARY_FINGERPRINT_IN_CODE}</td>
      </tr>
      <tr>
        <td>Backup Fingerprint Found in Code</td>
        <td>${BACKUP_FINGERPRINT_IN_CODE}</td>
      </tr>
    </table>
  </div>
</body>
</html>
EOF

# Print report locations
echo "Reports generated at:"
echo "- JSON: $REPORTS_DIR/$JSON_REPORT"
echo "- HTML: $REPORTS_DIR/$HTML_REPORT"

exit $EXIT_CODE
echo "- HTML: $REPORTS_DIR/$HTML_REPORT"

exit $EXIT_CODE