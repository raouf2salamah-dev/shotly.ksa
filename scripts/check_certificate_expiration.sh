#!/bin/bash

# Script to check SSL certificate expiration dates and alert if they're expiring soon

# Configuration
ALERT_THRESHOLD_DAYS=30
LOG_FILE="../logs/security/certificate_expiration.log"
DOMAINS=("api.yourdomain.com" "api.example.com")

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Function to check certificate expiration
check_certificate() {
  local domain=$1
  local port=${2:-443}
  
  echo "Checking certificate for $domain:$port..."
  
  # Get certificate expiration date using OpenSSL
  expiry_date=$(echo | openssl s_client -connect "$domain:$port" 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
  
  if [ -z "$expiry_date" ]; then
    echo "Error: Could not retrieve certificate for $domain:$port"
    return 1
  fi
  
  # Convert expiry date to timestamp
  expiry_timestamp=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$expiry_date" +%s)
  current_timestamp=$(date +%s)
  
  # Calculate days until expiration
  seconds_until_expiry=$((expiry_timestamp - current_timestamp))
  days_until_expiry=$((seconds_until_expiry / 86400))
  
  # Format dates for display
  formatted_expiry=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$expiry_date" +"%Y-%m-%d")
  current_date=$(date +"%Y-%m-%d")
  
  # Log the result
  echo "[$current_date] $domain: Certificate expires on $formatted_expiry ($days_until_expiry days remaining)" | tee -a "$LOG_FILE"
  
  # Check if certificate is expiring soon
  if [ $days_until_expiry -le $ALERT_THRESHOLD_DAYS ]; then
    echo "WARNING: Certificate for $domain will expire in $days_until_expiry days!" | tee -a "$LOG_FILE"
    return 2
  fi
  
  return 0
}

# Main function
main() {
  echo "=== Certificate Expiration Check ($(date)) ===" | tee -a "$LOG_FILE"
  echo "Alert threshold: $ALERT_THRESHOLD_DAYS days" | tee -a "$LOG_FILE"
  echo "" | tee -a "$LOG_FILE"
  
  local alert_count=0
  
  for domain in "${DOMAINS[@]}"; do
    check_certificate "$domain"
    result=$?
    
    if [ $result -eq 2 ]; then
      alert_count=$((alert_count + 1))
    fi
    
    echo "" | tee -a "$LOG_FILE"
  done
  
  echo "Check completed. Found $alert_count certificates expiring within $ALERT_THRESHOLD_DAYS days." | tee -a "$LOG_FILE"
  echo "===================================" | tee -a "$LOG_FILE"
  
  # Return non-zero exit code if any certificates are expiring soon
  if [ $alert_count -gt 0 ]; then
    return 1
  fi
  
  return 0
}

# Run the main function
main

# Exit with the result of the main function
exit $?