#!/bin/bash

# CI/CD Pipeline Script for Certificate Fingerprint Rotation
# This script automates the process of updating certificate fingerprints when certificates are renewed
# It should be integrated into your CI/CD pipeline and triggered when certificates are renewed

set -e  # Exit immediately if a command exits with a non-zero status

# Configuration
API_DOMAINS=("api.yourdomain.com" "api.example.com")  # Add all domains that need certificate pinning
FINGERPRINTS_FILE="../lib/security/certificate_fingerprints.json"  # Path to fingerprints file relative to script
BACKUP_DIR="../backups/certificate_fingerprints"  # Directory to store backups
LOG_FILE="certificate_rotation.log"  # Log file for rotation operations
NOTIFICATION_EMAIL="security@yourdomain.com"  # Email for notifications
ROLLOUT_CONFIG="../deployment/rollout_config.json"  # Phased rollout configuration

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create log file if it doesn't exist
touch "$LOG_FILE"

# Log function
log() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Function to create a backup of the current fingerprints file
backup_fingerprints() {
  local backup_file="$BACKUP_DIR/fingerprints_$(date +"%Y%m%d_%H%M%S").json"
  
  if [ -f "$FINGERPRINTS_FILE" ]; then
    cp "$FINGERPRINTS_FILE" "$backup_file"
    log "Created backup of fingerprints file at $backup_file"
    echo "$backup_file"  # Return the backup file path
  else
    log "ERROR: Fingerprints file not found at $FINGERPRINTS_FILE"
    exit 1
  fi
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

# Function to update fingerprints in the JSON file
update_fingerprints() {
  local domain=$1
  local new_fingerprint=$2
  local backup_file=$3
  
  log "Updating fingerprint for $domain to $new_fingerprint"
  
  # Load the current fingerprints file
  if [ ! -f "$FINGERPRINTS_FILE" ]; then
    # Create a new file if it doesn't exist
    log "Creating new fingerprints file"
    echo '{"domains":{}}' > "$FINGERPRINTS_FILE"
  fi
  
  # Check if jq is installed
  if ! command -v jq &> /dev/null; then
    log "ERROR: jq is required but not installed. Please install jq."
    exit 1
  fi
  
  # Get the current primary fingerprint (if any)
  local current_primary=$(jq -r ".domains[\"$domain\"].primary // \"\"" "$FINGERPRINTS_FILE")
  
  # If the current primary is the same as the new one, no update needed
  if [ "$current_primary" == "$new_fingerprint" ]; then
    log "No update needed for $domain, fingerprint unchanged"
    return 0
  fi
  
  # Create a temporary file for the updated JSON
  local temp_file=$(mktemp)
  
  # Update the JSON: move current primary to backup, set new primary
  if [ -n "$current_primary" ]; then
    # Get current backups as an array
    local backups=$(jq -r ".domains[\"$domain\"].backup // []" "$FINGERPRINTS_FILE")
    
    # Add current primary to backups if it's not empty
    jq --arg domain "$domain" \
       --arg new_primary "$new_fingerprint" \
       --arg current "$current_primary" \
       '.domains[$domain].primary = $new_primary | 
        if .domains[$domain].backup then 
          .domains[$domain].backup = ([.domains[$domain].backup[] | select(. != $new_primary)] + [$current]) | 
          .domains[$domain].backup = .domains[$domain].backup[0:3] 
        else 
          .domains[$domain].backup = [$current] 
        end' \
       "$FINGERPRINTS_FILE" > "$temp_file"
  else
    # No current primary, just set the new one
    jq --arg domain "$domain" \
       --arg new_primary "$new_fingerprint" \
       '.domains[$domain].primary = $new_primary' \
       "$FINGERPRINTS_FILE" > "$temp_file"
  fi
  
  # Update the rotation date
  local rotation_date=$(date +"%Y-%m-%d")
  jq --arg domain "$domain" \
     --arg date "$rotation_date" \
     '.domains[$domain].rotation_date = $date' \
     "$temp_file" > "${temp_file}.2"
  
  # Replace the original file with the updated one
  mv "${temp_file}.2" "$FINGERPRINTS_FILE"
  rm -f "$temp_file"
  
  log "Successfully updated fingerprint for $domain"
  log "  - New primary: $new_fingerprint"
  log "  - Previous primary moved to backup"
  log "  - Rotation date set to $rotation_date"
  
  return 0
}

# Function to verify the updated fingerprints
verify_fingerprints() {
  local domain=$1
  local expected_fingerprint=$2
  
  log "Verifying fingerprint for $domain"
  
  # Get the primary fingerprint from the updated file
  local primary=$(jq -r ".domains[\"$domain\"].primary // \"\"" "$FINGERPRINTS_FILE")
  
  if [ "$primary" != "$expected_fingerprint" ]; then
    log "ERROR: Verification failed for $domain"
    log "  - Expected: $expected_fingerprint"
    log "  - Found: $primary"
    return 1
  fi
  
  log "Verification successful for $domain"
  return 0
}

# Function to update rollout configuration for phased deployment
update_rollout_config() {
  log "Updating rollout configuration for phased deployment"
  
  if [ ! -f "$ROLLOUT_CONFIG" ]; then
    # Create a default rollout config if it doesn't exist
    cat > "$ROLLOUT_CONFIG" << EOF
{
  "certificate_update": {
    "phase1_percentage": 10,
    "phase2_percentage": 50,
    "phase3_percentage": 100,
    "phase1_duration_days": 1,
    "phase2_duration_days": 2,
    "phase3_duration_days": 4,
    "rollback_threshold_percentage": 5
  }
}
EOF
    log "Created default rollout configuration"
  fi
  
  # Update the last_update timestamp in the rollout config
  local temp_file=$(mktemp)
  jq --arg date "$(date +"%Y-%m-%d")" \
     '.certificate_update.last_update = $date' \
     "$ROLLOUT_CONFIG" > "$temp_file"
  
  mv "$temp_file" "$ROLLOUT_CONFIG"
  log "Updated rollout configuration with new timestamp"
}

# Function to send notification
send_notification() {
  local subject="$1"
  local message="$2"
  
  log "Sending notification: $subject"
  
  # This is a placeholder. Replace with your actual notification mechanism
  # (email, Slack, etc.)
  if [ -n "$NOTIFICATION_EMAIL" ]; then
    echo "$message" | mail -s "$subject" "$NOTIFICATION_EMAIL" || true
  fi
  
  # For CI/CD integration, you might want to output to console as well
  echo "NOTIFICATION: $subject"
  echo "$message"
}

# Main execution
log "Starting certificate fingerprint rotation process"

# Create a backup of the current fingerprints file
backup_file=$(backup_fingerprints)

# Process each domain
for domain in "${API_DOMAINS[@]}"; do
  log "Processing domain: $domain"
  
  # Get the new certificate fingerprint
  new_fingerprint=$(get_certificate_fingerprint "$domain")
  if [ $? -ne 0 ]; then
    log "Skipping $domain due to fingerprint retrieval failure"
    continue
  fi
  
  # Update the fingerprints file
  update_fingerprints "$domain" "$new_fingerprint" "$backup_file"
  if [ $? -ne 0 ]; then
    log "Failed to update fingerprints for $domain"
    continue
  fi
  
  # Verify the update
  verify_fingerprints "$domain" "$new_fingerprint"
  if [ $? -ne 0 ]; then
    log "Verification failed for $domain, restoring backup"
    cp "$backup_file" "$FINGERPRINTS_FILE"
    continue
  fi
done

# Update rollout configuration
update_rollout_config

# Send notification
send_notification "Certificate Fingerprints Updated" \
                 "Certificate fingerprints have been updated for the following domains:\n$(printf "%s\n" "${API_DOMAINS[@]}")\n\nA backup of the previous configuration has been saved at $backup_file\n\nPlease follow the phased rollout plan for deployment."

log "Certificate fingerprint rotation process completed successfully"

# For CI/CD integration, indicate success
exit 0