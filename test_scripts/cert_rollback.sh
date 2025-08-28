#!/bin/bash

# Certificate Rollback Script
# This script provides a mechanism to rollback certificate fingerprint changes
# if issues are detected after deployment

set -e  # Exit immediately if a command exits with a non-zero status

# Configuration
FINGERPRINTS_FILE="../lib/security/certificate_fingerprints.json"  # Path to fingerprints file relative to script
BACKUP_DIR="../backups/certificate_fingerprints"  # Directory where backups are stored
LOG_FILE="certificate_rollback.log"  # Log file for rollback operations
NOTIFICATION_EMAIL="security@yourdomain.com"  # Email for notifications

# Create log file if it doesn't exist
touch "$LOG_FILE"

# Log function
log() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Function to list available backups
list_backups() {
  log "Listing available backups"
  
  if [ ! -d "$BACKUP_DIR" ]; then
    log "ERROR: Backup directory not found at $BACKUP_DIR"
    return 1
  fi
  
  local backups=($(ls -1t "$BACKUP_DIR" 2>/dev/null | grep -E '^fingerprints_[0-9]{8}_[0-9]{6}\.json$'))
  
  if [ ${#backups[@]} -eq 0 ]; then
    log "No backups found in $BACKUP_DIR"
    return 1
  fi
  
  echo "Available backups:"
  for i in "${!backups[@]}"; do
    local backup_file="${backups[$i]}"
    local backup_date=$(echo "$backup_file" | sed -E 's/fingerprints_([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})\.json/\1-\2-\3 \4:\5:\6/')
    echo "$((i+1)). $backup_file ($backup_date)"
  done
  
  # Return the list of backups
  printf "%s\n" "${backups[@]}"
}

# Function to restore a backup
restore_backup() {
  local backup_file="$1"
  local full_backup_path="$BACKUP_DIR/$backup_file"
  
  log "Restoring backup from $backup_file"
  
  if [ ! -f "$full_backup_path" ]; then
    log "ERROR: Backup file not found at $full_backup_path"
    return 1
  fi
  
  # Create a backup of the current state before restoring
  local current_backup="$BACKUP_DIR/pre_rollback_$(date +"%Y%m%d_%H%M%S").json"
  if [ -f "$FINGERPRINTS_FILE" ]; then
    cp "$FINGERPRINTS_FILE" "$current_backup"
    log "Created backup of current state at $current_backup"
  fi
  
  # Restore the backup
  cp "$full_backup_path" "$FINGERPRINTS_FILE"
  
  if [ $? -eq 0 ]; then
    log "Successfully restored backup from $backup_file"
    return 0
  else
    log "ERROR: Failed to restore backup from $backup_file"
    return 1
  fi
}

# Function to compare backups
compare_backups() {
  local backup_file="$1"
  local full_backup_path="$BACKUP_DIR/$backup_file"
  
  log "Comparing current fingerprints with backup $backup_file"
  
  if [ ! -f "$full_backup_path" ]; then
    log "ERROR: Backup file not found at $full_backup_path"
    return 1
  fi
  
  if [ ! -f "$FINGERPRINTS_FILE" ]; then
    log "ERROR: Current fingerprints file not found at $FINGERPRINTS_FILE"
    return 1
  fi
  
  # Check if jq is installed
  if ! command -v jq &> /dev/null; then
    log "ERROR: jq is required but not installed. Please install jq."
    return 1
  fi
  
  # Get domains from both files
  local current_domains=$(jq -r '.domains | keys[]' "$FINGERPRINTS_FILE" 2>/dev/null)
  local backup_domains=$(jq -r '.domains | keys[]' "$full_backup_path" 2>/dev/null)
  
  if [ -z "$current_domains" ] && [ -z "$backup_domains" ]; then
    log "ERROR: Failed to parse domains from fingerprints files"
    return 1
  fi
  
  # Combine and deduplicate domains
  local all_domains=($(echo "$current_domains $backup_domains" | tr ' ' '\n' | sort -u))
  
  echo "Comparison between current fingerprints and backup $backup_file:"
  echo "--------------------------------------------------------------"
  
  local differences_found=0
  
  for domain in "${all_domains[@]}"; do
    echo "Domain: $domain"
    
    # Get primary fingerprints
    local current_primary=$(jq -r ".domains[\"$domain\"].primary // \"Not present\"" "$FINGERPRINTS_FILE")
    local backup_primary=$(jq -r ".domains[\"$domain\"].primary // \"Not present\"" "$full_backup_path")
    
    # Get backup fingerprints as arrays
    local current_backups=$(jq -r ".domains[\"$domain\"].backup // [] | join(\" \")" "$FINGERPRINTS_FILE")
    local backup_backups=$(jq -r ".domains[\"$domain\"].backup // [] | join(\" \")" "$full_backup_path")
    
    # Get rotation dates
    local current_rotation=$(jq -r ".domains[\"$domain\"].rotation_date // \"Unknown\"" "$FINGERPRINTS_FILE")
    local backup_rotation=$(jq -r ".domains[\"$domain\"].rotation_date // \"Unknown\"" "$full_backup_path")
    
    # Compare primary fingerprints
    if [ "$current_primary" != "$backup_primary" ]; then
      echo "  Primary fingerprint changed:"
      echo "    Current: $current_primary"
      echo "    Backup:  $backup_primary"
      differences_found=1
    else
      echo "  Primary fingerprint: Unchanged"
    fi
    
    # Compare backup fingerprints
    if [ "$current_backups" != "$backup_backups" ]; then
      echo "  Backup fingerprints changed:"
      echo "    Current: $current_backups"
      echo "    Backup:  $backup_backups"
      differences_found=1
    else
      echo "  Backup fingerprints: Unchanged"
    fi
    
    # Compare rotation dates
    if [ "$current_rotation" != "$backup_rotation" ]; then
      echo "  Rotation date changed:"
      echo "    Current: $current_rotation"
      echo "    Backup:  $backup_rotation"
      differences_found=1
    else
      echo "  Rotation date: Unchanged"
    fi
    
    echo ""
  done
  
  if [ $differences_found -eq 0 ]; then
    echo "No differences found between current fingerprints and backup."
  fi
  
  return $differences_found
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

# Function to update rollout configuration for rollback
update_rollout_config() {
  local rollout_config="../deployment/rollout_config.json"
  
  log "Updating rollout configuration for rollback"
  
  if [ ! -f "$rollout_config" ]; then
    log "WARNING: Rollout configuration not found at $rollout_config"
    return 1
  fi
  
  # Update the rollout config to indicate a rollback
  local temp_file=$(mktemp)
  jq --arg date "$(date +"%Y-%m-%d")" \
     --arg reason "$1" \
     '.certificate_update.last_rollback = $date | .certificate_update.rollback_reason = $reason' \
     "$rollout_config" > "$temp_file"
  
  mv "$temp_file" "$rollout_config"
  log "Updated rollout configuration with rollback information"
}

# Interactive mode function
interactive_mode() {
  echo "Certificate Rollback Tool - Interactive Mode"
  echo "------------------------------------------"
  
  # List available backups
  local backups=($(list_backups))
  if [ $? -ne 0 ]; then
    echo "No backups available for rollback."
    exit 1
  fi
  
  # Prompt for backup selection
  echo ""
  echo "Enter the number of the backup to restore (or 'q' to quit):"
  read -r selection
  
  if [[ "$selection" == "q" ]]; then
    echo "Rollback cancelled."
    exit 0
  fi
  
  # Validate selection
  if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#backups[@]}" ]; then
    echo "Invalid selection. Please enter a number between 1 and ${#backups[@]}."
    exit 1
  fi
  
  # Get selected backup
  local selected_backup="${backups[$((selection-1))]}"
  
  # Compare with current fingerprints
  echo ""
  echo "Comparing current fingerprints with selected backup..."
  compare_backups "$selected_backup"
  
  # Prompt for confirmation
  echo ""
  echo "Are you sure you want to restore this backup? (y/n)"
  read -r confirm
  
  if [[ "$confirm" != "y" ]]; then
    echo "Rollback cancelled."
    exit 0
  fi
  
  # Prompt for rollback reason
  echo ""
  echo "Please enter a reason for this rollback (for audit purposes):"
  read -r reason
  
  # Restore the backup
  echo ""
  echo "Restoring backup..."
  restore_backup "$selected_backup"
  if [ $? -ne 0 ]; then
    echo "Failed to restore backup."
    exit 1
  fi
  
  # Update rollout configuration
  update_rollout_config "$reason"
  
  # Send notification
  send_notification "Certificate Fingerprints Rolled Back" \
                   "Certificate fingerprints have been rolled back to backup $selected_backup.\n\nReason: $reason\n\nPlease ensure that the appropriate app version is deployed with these fingerprints."
  
  echo ""
  echo "Rollback completed successfully."
}

# Non-interactive mode function
noninteractive_mode() {
  local backup_file="$1"
  local reason="$2"
  
  log "Starting non-interactive rollback to $backup_file"
  
  if [ -z "$backup_file" ]; then
    log "ERROR: No backup file specified"
    echo "ERROR: No backup file specified. Use -b to specify a backup file."
    exit 1
  fi
  
  # Check if the backup file exists
  if [ ! -f "$BACKUP_DIR/$backup_file" ]; then
    log "ERROR: Backup file not found at $BACKUP_DIR/$backup_file"
    echo "ERROR: Backup file not found at $BACKUP_DIR/$backup_file"
    exit 1
  fi
  
  # Restore the backup
  restore_backup "$backup_file"
  if [ $? -ne 0 ]; then
    log "Failed to restore backup"
    echo "Failed to restore backup."
    exit 1
  fi
  
  # Update rollout configuration
  update_rollout_config "$reason"
  
  # Send notification
  send_notification "Certificate Fingerprints Rolled Back" \
                   "Certificate fingerprints have been rolled back to backup $backup_file.\n\nReason: $reason\n\nPlease ensure that the appropriate app version is deployed with these fingerprints."
  
  log "Rollback completed successfully"
  echo "Rollback completed successfully."
}

# Main execution

# Parse command line arguments
interactive=true
backup_file=""
reason="Automated rollback due to issues detected in production"

while getopts ":b:r:i" opt; do
  case $opt in
    b)
      backup_file="$OPTARG"
      ;;
    r)
      reason="$OPTARG"
      ;;
    i)
      interactive=false
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument."
      exit 1
      ;;
  esac
done

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
  log "ERROR: Backup directory not found at $BACKUP_DIR"
  echo "ERROR: Backup directory not found at $BACKUP_DIR"
  exit 1
fi

# Run in interactive or non-interactive mode
if [ "$interactive" = true ]; then
  interactive_mode
else
  noninteractive_mode "$backup_file" "$reason"
fi

# For CI/CD integration, indicate success
exit 0