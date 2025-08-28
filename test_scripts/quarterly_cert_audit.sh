#!/bin/bash

# Quarterly Certificate Audit Script
# This script verifies that the certificate fingerprints in the app match the live certificates
# It should be scheduled to run quarterly as part of your security compliance process

set -e  # Exit immediately if a command exits with a non-zero status

# Configuration
API_DOMAINS=("api.yourdomain.com" "api.example.com")  # Add all domains that need certificate pinning
FINGERPRINTS_FILE="../lib/security/certificate_fingerprints.json"  # Path to fingerprints file relative to script
AUDIT_LOG_FILE="certificate_audit.log"  # Log file for audit operations
AUDIT_REPORT_FILE="certificate_audit_report.html"  # HTML report file
NOTIFICATION_EMAIL="security@yourdomain.com"  # Email for notifications
MAX_CERT_AGE_DAYS=90  # Maximum allowed certificate age in days

# Create log file if it doesn't exist
touch "$AUDIT_LOG_FILE"

# Log function
log() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $1" | tee -a "$AUDIT_LOG_FILE"
}

# Function to get certificate details
get_certificate_details() {
  local domain=$1
  local output_file=$(mktemp)
  
  log "Getting certificate details for $domain"
  
  # Get the certificate details
  echo | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null | \
    openssl x509 -noout -text > "$output_file"
  
  if [ ! -s "$output_file" ]; then
    log "ERROR: Failed to get certificate details for $domain"
    rm -f "$output_file"
    return 1
  fi
  
  echo "$output_file"
}

# Function to get certificate fingerprint (SHA-256)
get_certificate_fingerprint() {
  local domain=$1
  
  log "Getting certificate fingerprint for $domain"
  
  # Get the certificate and compute its SHA-256 fingerprint
  local fingerprint=$(echo | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null | \
                     openssl x509 -noout -fingerprint -sha256 | \
                     sed 's/SHA256 Fingerprint=//g' | sed 's/://g')
  
  if [ -z "$fingerprint" ]; then
    log "ERROR: Failed to get certificate fingerprint for $domain"
    return 1
  fi
  
  echo "$fingerprint"
}

# Function to get certificate expiration date
get_certificate_expiration() {
  local domain=$1
  
  log "Getting certificate expiration for $domain"
  
  # Get the certificate expiration date
  local expiration=$(echo | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null | \
                    openssl x509 -noout -enddate | \
                    sed 's/notAfter=//g')
  
  if [ -z "$expiration" ]; then
    log "ERROR: Failed to get certificate expiration for $domain"
    return 1
  fi
  
  echo "$expiration"
}

# Function to calculate days until certificate expiration
days_until_expiration() {
  local expiration_date="$1"
  
  # Convert expiration date to seconds since epoch
  local expiration_seconds=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$expiration_date" +%s 2>/dev/null)
  if [ $? -ne 0 ]; then
    # Try alternative format for Linux
    expiration_seconds=$(date -d "$expiration_date" +%s 2>/dev/null)
    if [ $? -ne 0 ]; then
      log "ERROR: Failed to parse expiration date: $expiration_date"
      return 1
    fi
  fi
  
  # Get current time in seconds since epoch
  local current_seconds=$(date +%s)
  
  # Calculate difference in seconds and convert to days
  local diff_seconds=$((expiration_seconds - current_seconds))
  local diff_days=$((diff_seconds / 86400))
  
  echo "$diff_days"
}

# Function to verify fingerprints against the JSON file
verify_fingerprints() {
  local domain=$1
  local live_fingerprint=$2
  local issues_found=0
  
  log "Verifying fingerprints for $domain"
  
  # Check if jq is installed
  if ! command -v jq &> /dev/null; then
    log "ERROR: jq is required but not installed. Please install jq."
    exit 1
  fi
  
  # Check if the fingerprints file exists
  if [ ! -f "$FINGERPRINTS_FILE" ]; then
    log "ERROR: Fingerprints file not found at $FINGERPRINTS_FILE"
    return 1
  fi
  
  # Get the primary fingerprint from the file
  local primary=$(jq -r ".domains[\"$domain\"].primary // \"\"" "$FINGERPRINTS_FILE")
  
  # Get the backup fingerprints from the file
  local backups=$(jq -r ".domains[\"$domain\"].backup // [] | .[]" "$FINGERPRINTS_FILE")
  
  # Get the rotation date from the file
  local rotation_date=$(jq -r ".domains[\"$domain\"].rotation_date // \"Unknown\"" "$FINGERPRINTS_FILE")
  
  # Check if the domain exists in the fingerprints file
  if [ -z "$primary" ]; then
    log "ERROR: Domain $domain not found in fingerprints file"
    echo "Domain $domain not found in fingerprints file"
    return 1
  fi
  
  # Initialize result array
  local results=()
  
  # Check if the live fingerprint matches the primary fingerprint
  if [ "$live_fingerprint" == "$primary" ]; then
    results+=("✅ Live certificate matches primary fingerprint")
    log "Live certificate matches primary fingerprint for $domain"
  else
    # Check if the live fingerprint matches any backup fingerprint
    local found_in_backup=false
    while IFS= read -r backup; do
      if [ -n "$backup" ] && [ "$live_fingerprint" == "$backup" ]; then
        found_in_backup=true
        break
      fi
    done <<< "$backups"
    
    if [ "$found_in_backup" == "true" ]; then
      results+=("⚠️ Live certificate matches a backup fingerprint, not the primary")
      log "WARNING: Live certificate matches a backup fingerprint for $domain, not the primary"
      issues_found=1
    else
      results+=("❌ Live certificate does not match any stored fingerprint")
      log "ERROR: Live certificate does not match any stored fingerprint for $domain"
      issues_found=1
    fi
  fi
  
  # Check rotation date
  if [ "$rotation_date" != "Unknown" ]; then
    # Calculate days since last rotation
    local rotation_seconds=$(date -j -f "%Y-%m-%d" "$rotation_date" +%s 2>/dev/null)
    if [ $? -ne 0 ]; then
      # Try alternative format for Linux
      rotation_seconds=$(date -d "$rotation_date" +%s 2>/dev/null)
      if [ $? -ne 0 ]; then
        log "ERROR: Failed to parse rotation date: $rotation_date"
        results+=("⚠️ Failed to parse rotation date: $rotation_date")
        issues_found=1
      fi
    fi
    
    if [ -n "$rotation_seconds" ]; then
      local current_seconds=$(date +%s)
      local diff_seconds=$((current_seconds - rotation_seconds))
      local days_since_rotation=$((diff_seconds / 86400))
      
      if [ "$days_since_rotation" -gt "$MAX_CERT_AGE_DAYS" ]; then
        results+=("⚠️ Certificate rotation is overdue (last rotation: $rotation_date, $days_since_rotation days ago)")
        log "WARNING: Certificate rotation is overdue for $domain (last rotation: $rotation_date, $days_since_rotation days ago)"
        issues_found=1
      else
        results+=("✅ Certificate rotation is up to date (last rotation: $rotation_date, $days_since_rotation days ago)")
        log "Certificate rotation is up to date for $domain (last rotation: $rotation_date, $days_since_rotation days ago)"
      fi
    fi
  else
    results+=("⚠️ No rotation date found")
    log "WARNING: No rotation date found for $domain"
    issues_found=1
  fi
  
  # Return results
  printf "%s\n" "${results[@]}"
  
  return $issues_found
}

# Function to generate HTML report
generate_report() {
  local report_data=$1
  local current_date=$(date +"%Y-%m-%d")
  
  log "Generating HTML report"
  
  # Create HTML report
  cat > "$AUDIT_REPORT_FILE" << EOF
<!DOCTYPE html>
<html>
<head>
  <title>Certificate Audit Report - $current_date</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { color: #333; }
    .report-date { color: #666; margin-bottom: 20px; }
    .domain { margin-bottom: 30px; border: 1px solid #ddd; padding: 15px; border-radius: 5px; }
    .domain-header { font-size: 18px; font-weight: bold; margin-bottom: 10px; }
    .success { color: green; }
    .warning { color: orange; }
    .error { color: red; }
    .detail { margin-left: 20px; margin-bottom: 5px; }
    .expiration { margin-top: 10px; }
    .expiration.soon { color: orange; font-weight: bold; }
    .expiration.critical { color: red; font-weight: bold; }
    .summary { margin-top: 30px; padding: 15px; background-color: #f5f5f5; border-radius: 5px; }
  </style>
</head>
<body>
  <h1>Certificate Audit Report</h1>
  <div class="report-date">Generated on $current_date</div>
  
  $report_data
  
  <div class="summary">
    <h2>Summary</h2>
    <p>This report was generated as part of the quarterly certificate audit process.</p>
    <p>If any issues were found, please take appropriate action to update the certificate fingerprints.</p>
  </div>
</body>
</html>
EOF

  log "HTML report generated at $AUDIT_REPORT_FILE"
}

# Function to send notification
send_notification() {
  local subject="$1"
  local message="$2"
  local attachment="$3"
  
  log "Sending notification: $subject"
  
  # This is a placeholder. Replace with your actual notification mechanism
  # (email, Slack, etc.)
  if [ -n "$NOTIFICATION_EMAIL" ]; then
    if [ -n "$attachment" ] && [ -f "$attachment" ]; then
      echo "$message" | mail -s "$subject" -a "$attachment" "$NOTIFICATION_EMAIL" || true
    else
      echo "$message" | mail -s "$subject" "$NOTIFICATION_EMAIL" || true
    fi
  fi
  
  # For CI/CD integration, you might want to output to console as well
  echo "NOTIFICATION: $subject"
  echo "$message"
}

# Main execution
log "Starting quarterly certificate audit"

# Initialize variables
all_issues_found=0
report_data=""

# Process each domain
for domain in "${API_DOMAINS[@]}"; do
  log "Processing domain: $domain"
  
  # Get the live certificate fingerprint
  live_fingerprint=$(get_certificate_fingerprint "$domain")
  if [ $? -ne 0 ]; then
    log "Skipping $domain due to fingerprint retrieval failure"
    report_data+="
  <div class='domain'>
    <div class='domain-header'>$domain</div>
    <div class='error'>❌ Failed to retrieve certificate fingerprint</div>
  </div>"
    all_issues_found=1
    continue
  fi
  
  # Get certificate expiration
  expiration_date=$(get_certificate_expiration "$domain")
  if [ $? -ne 0 ]; then
    log "Failed to get expiration date for $domain"
    expiration_info="<div class='detail error'>❌ Failed to retrieve certificate expiration date</div>"
    all_issues_found=1
  else
    # Calculate days until expiration
    days_left=$(days_until_expiration "$expiration_date")
    if [ $? -ne 0 ]; then
      log "Failed to calculate days until expiration for $domain"
      expiration_info="<div class='detail error'>❌ Failed to calculate days until expiration</div>"
      all_issues_found=1
    else
      # Format expiration info based on days left
      if [ "$days_left" -lt 30 ]; then
        expiration_class="critical"
        expiration_icon="⚠️"
        log "CRITICAL: Certificate for $domain expires in $days_left days"
        all_issues_found=1
      elif [ "$days_left" -lt 60 ]; then
        expiration_class="soon"
        expiration_icon="⚠️"
        log "WARNING: Certificate for $domain expires in $days_left days"
        all_issues_found=1
      else
        expiration_class="normal"
        expiration_icon="✅"
        log "Certificate for $domain expires in $days_left days"
      fi
      
      expiration_info="<div class='detail expiration ${expiration_class}'>${expiration_icon} Certificate expires in $days_left days ($expiration_date)</div>"
    fi
  fi
  
  # Verify fingerprints
  verification_result=$(verify_fingerprints "$domain" "$live_fingerprint")
  issues_found=$?
  
  if [ $issues_found -ne 0 ]; then
    all_issues_found=1
  fi
  
  # Format verification results for HTML report
  verification_html=""
  while IFS= read -r line; do
    if [[ "$line" == *"✅"* ]]; then
      verification_html+="<div class='detail success'>$line</div>"
    elif [[ "$line" == *"⚠️"* ]]; then
      verification_html+="<div class='detail warning'>$line</div>"
    elif [[ "$line" == *"❌"* ]]; then
      verification_html+="<div class='detail error'>$line</div>"
    else
      verification_html+="<div class='detail'>$line</div>"
    fi
  done <<< "$verification_result"
  
  # Add domain section to report
  report_data+="
  <div class='domain'>
    <div class='domain-header'>$domain</div>
    <div class='detail'>Live Fingerprint: $live_fingerprint</div>
    $verification_html
    $expiration_info
  </div>"
  
  log "Completed audit for $domain"
done

# Generate HTML report
generate_report "$report_data"

# Send notification
if [ $all_issues_found -ne 0 ]; then
  send_notification "[ALERT] Certificate Audit Found Issues" \
                   "The quarterly certificate audit has found issues that require attention.\n\nPlease review the attached report for details." \
                   "$AUDIT_REPORT_FILE"
  log "Audit completed with issues found"
  exit 1
else
  send_notification "Certificate Audit Completed Successfully" \
                   "The quarterly certificate audit has completed successfully with no issues found.\n\nReport is attached for your records." \
                   "$AUDIT_REPORT_FILE"
  log "Audit completed successfully with no issues found"
  exit 0
fi