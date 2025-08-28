#!/bin/bash

# Gradual Rollout Script for Certificate Updates
# This script manages the phased rollout of certificate fingerprint updates
# through app stores (Apple App Store and Google Play Store)

set -e  # Exit immediately if a command exits with a non-zero status

# Configuration
ROLLOUT_CONFIG="../deployment/rollout_config.json"  # Rollout configuration file
FINGERPRINTS_FILE="../lib/security/certificate_fingerprints.json"  # Path to fingerprints file
LOG_FILE="gradual_rollout.log"  # Log file for rollout operations
NOTIFICATION_EMAIL="security@yourdomain.com"  # Email for notifications

# App Store credentials and configuration
APPLE_APP_ID="com.yourdomain.app"  # Your App Store app ID
GOOGLE_PACKAGE_NAME="com.yourdomain.app"  # Your Play Store package name

# Create log file if it doesn't exist
touch "$LOG_FILE"

# Log function
log() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Function to create default rollout configuration if it doesn't exist
create_default_rollout_config() {
  log "Creating default rollout configuration"
  
  mkdir -p "$(dirname "$ROLLOUT_CONFIG")"
  
  cat > "$ROLLOUT_CONFIG" << EOF
{
  "certificate_update": {
    "phase1_percentage": 10,
    "phase2_percentage": 50,
    "phase3_percentage": 100,
    "phase1_duration_days": 1,
    "phase2_duration_days": 2,
    "phase3_duration_days": 4,
    "rollback_threshold_percentage": 5,
    "last_update": null,
    "last_rollback": null,
    "rollback_reason": null,
    "current_phase": 0,
    "phase_start_dates": [],
    "monitoring_metrics": {
      "connection_errors": 0,
      "certificate_errors": 0,
      "total_connections": 0
    }
  },
  "app_store": {
    "app_id": "$APPLE_APP_ID",
    "current_version": "1.0.0",
    "phased_release_enabled": true
  },
  "play_store": {
    "package_name": "$GOOGLE_PACKAGE_NAME",
    "current_version": "1.0.0",
    "phased_release_enabled": true
  }
}
EOF

  log "Default rollout configuration created at $ROLLOUT_CONFIG"
}

# Function to load rollout configuration
load_rollout_config() {
  log "Loading rollout configuration"
  
  if [ ! -f "$ROLLOUT_CONFIG" ]; then
    log "Rollout configuration not found, creating default"
    create_default_rollout_config
  fi
  
  # Check if jq is installed
  if ! command -v jq &> /dev/null; then
    log "ERROR: jq is required but not installed. Please install jq."
    exit 1
  fi
  
  # Load configuration values
  phase1_percentage=$(jq -r '.certificate_update.phase1_percentage // 10' "$ROLLOUT_CONFIG")
  phase2_percentage=$(jq -r '.certificate_update.phase2_percentage // 50' "$ROLLOUT_CONFIG")
  phase3_percentage=$(jq -r '.certificate_update.phase3_percentage // 100' "$ROLLOUT_CONFIG")
  
  phase1_duration_days=$(jq -r '.certificate_update.phase1_duration_days // 1' "$ROLLOUT_CONFIG")
  phase2_duration_days=$(jq -r '.certificate_update.phase2_duration_days // 2' "$ROLLOUT_CONFIG")
  phase3_duration_days=$(jq -r '.certificate_update.phase3_duration_days // 4' "$ROLLOUT_CONFIG")
  
  rollback_threshold=$(jq -r '.certificate_update.rollback_threshold_percentage // 5' "$ROLLOUT_CONFIG")
  current_phase=$(jq -r '.certificate_update.current_phase // 0' "$ROLLOUT_CONFIG")
  
  last_update=$(jq -r '.certificate_update.last_update // null' "$ROLLOUT_CONFIG")
  last_rollback=$(jq -r '.certificate_update.last_rollback // null' "$ROLLOUT_CONFIG")
  
  # Load phase start dates
  phase_start_dates=$(jq -r '.certificate_update.phase_start_dates // []' "$ROLLOUT_CONFIG")
  
  # Load app store configuration
  apple_app_id=$(jq -r '.app_store.app_id // "'"$APPLE_APP_ID"'"' "$ROLLOUT_CONFIG")
  apple_current_version=$(jq -r '.app_store.current_version // "1.0.0"' "$ROLLOUT_CONFIG")
  apple_phased_release=$(jq -r '.app_store.phased_release_enabled // true' "$ROLLOUT_CONFIG")
  
  # Load play store configuration
  google_package_name=$(jq -r '.play_store.package_name // "'"$GOOGLE_PACKAGE_NAME"'"' "$ROLLOUT_CONFIG")
  google_current_version=$(jq -r '.play_store.current_version // "1.0.0"' "$ROLLOUT_CONFIG")
  google_phased_release=$(jq -r '.play_store.phased_release_enabled // true' "$ROLLOUT_CONFIG")
  
  log "Rollout configuration loaded successfully"
}

# Function to update rollout configuration
update_rollout_config() {
  local field=$1
  local value=$2
  
  log "Updating rollout configuration: $field = $value"
  
  local temp_file=$(mktemp)
  
  # Update the specified field
  jq --arg field "$field" --arg value "$value" \
     'reduce ([$field] | map(split(".")) | .[] ) as $path (.; setpath($path; $value))' \
     "$ROLLOUT_CONFIG" > "$temp_file"
  
  mv "$temp_file" "$ROLLOUT_CONFIG"
  
  log "Rollout configuration updated successfully"
}

# Function to update phase start dates
update_phase_start_dates() {
  local phase=$1
  local date=$2
  
  log "Updating phase $phase start date to $date"
  
  local temp_file=$(mktemp)
  
  # Update the phase start date
  jq --argjson phase "$phase" --arg date "$date" \
     '.certificate_update.phase_start_dates[$phase - 1] = $date' \
     "$ROLLOUT_CONFIG" > "$temp_file"
  
  mv "$temp_file" "$ROLLOUT_CONFIG"
  
  log "Phase start date updated successfully"
}

# Function to check if it's time to advance to the next phase
check_phase_advancement() {
  log "Checking if it's time to advance to the next phase"
  
  if [ "$current_phase" -eq 0 ]; then
    log "No active rollout in progress (phase = 0)"
    return 1
  fi
  
  if [ "$current_phase" -ge 3 ]; then
    log "Rollout already completed (phase = $current_phase)"
    return 1
  fi
  
  # Get the start date of the current phase
  local phase_start=$(echo "$phase_start_dates" | jq -r ".[$((current_phase-1))] // null")
  
  if [ "$phase_start" = "null" ]; then
    log "ERROR: No start date found for phase $current_phase"
    return 1
  fi
  
  # Calculate days since phase start
  local phase_start_seconds=$(date -j -f "%Y-%m-%d" "$phase_start" +%s 2>/dev/null)
  if [ $? -ne 0 ]; then
    # Try alternative format for Linux
    phase_start_seconds=$(date -d "$phase_start" +%s 2>/dev/null)
    if [ $? -ne 0 ]; then
      log "ERROR: Failed to parse phase start date: $phase_start"
      return 1
    fi
  fi
  
  local current_seconds=$(date +%s)
  local diff_seconds=$((current_seconds - phase_start_seconds))
  local days_since_phase_start=$((diff_seconds / 86400))
  
  # Determine the duration of the current phase
  local phase_duration=0
  if [ "$current_phase" -eq 1 ]; then
    phase_duration=$phase1_duration_days
  elif [ "$current_phase" -eq 2 ]; then
    phase_duration=$phase2_duration_days
  elif [ "$current_phase" -eq 3 ]; then
    phase_duration=$phase3_duration_days
  fi
  
  log "Current phase: $current_phase, Days since phase start: $days_since_phase_start, Phase duration: $phase_duration"
  
  # Check if it's time to advance to the next phase
  if [ "$days_since_phase_start" -ge "$phase_duration" ]; then
    log "Time to advance to the next phase"
    return 0
  else
    log "Not yet time to advance to the next phase"
    return 1
  fi
}

# Function to advance to the next phase
advance_to_next_phase() {
  local next_phase=$((current_phase + 1))
  
  log "Advancing from phase $current_phase to phase $next_phase"
  
  # Update current phase
  update_rollout_config "certificate_update.current_phase" "$next_phase"
  
  # Set the start date for the new phase
  local today=$(date +"%Y-%m-%d")
  update_phase_start_dates "$next_phase" "$today"
  
  # Determine the percentage for the new phase
  local percentage=0
  if [ "$next_phase" -eq 1 ]; then
    percentage=$phase1_percentage
  elif [ "$next_phase" -eq 2 ]; then
    percentage=$phase2_percentage
  elif [ "$next_phase" -eq 3 ]; then
    percentage=$phase3_percentage
  fi
  
  log "New phase $next_phase with rollout percentage: $percentage%"
  
  # Update app store rollout percentages
  update_app_store_rollout "$percentage"
  update_play_store_rollout "$percentage"
  
  # Send notification
  send_notification "Certificate Rollout Advanced to Phase $next_phase" \
                   "The certificate fingerprint rollout has advanced to phase $next_phase with a rollout percentage of $percentage%.\n\nPlease monitor the application for any issues."
  
  return 0
}

# Function to start a new rollout
start_new_rollout() {
  log "Starting new certificate rollout"
  
  # Check if there's already an active rollout
  if [ "$current_phase" -ne 0 ]; then
    log "ERROR: There is already an active rollout in progress (phase $current_phase)"
    echo "ERROR: There is already an active rollout in progress (phase $current_phase)"
    return 1
  fi
  
  # Check if there was a recent rollback
  if [ "$last_rollback" != "null" ]; then
    log "WARNING: There was a recent rollback on $last_rollback"
    echo "WARNING: There was a recent rollback on $last_rollback. Reason: $(jq -r '.certificate_update.rollback_reason // "Unknown"' "$ROLLOUT_CONFIG")"
    echo "Are you sure you want to start a new rollout? (y/n)"
    read -r confirm
    if [[ "$confirm" != "y" ]]; then
      log "Rollout cancelled by user"
      echo "Rollout cancelled."
      return 1
    fi
  fi
  
  # Set current phase to 1
  update_rollout_config "certificate_update.current_phase" "1"
  
  # Reset phase start dates
  local today=$(date +"%Y-%m-%d")
  local temp_file=$(mktemp)
  jq --arg today "$today" \
     '.certificate_update.phase_start_dates = [$today, null, null]' \
     "$ROLLOUT_CONFIG" > "$temp_file"
  mv "$temp_file" "$ROLLOUT_CONFIG"
  
  # Reset monitoring metrics
  local temp_file=$(mktemp)
  jq '.certificate_update.monitoring_metrics = {"connection_errors": 0, "certificate_errors": 0, "total_connections": 0}' \
     "$ROLLOUT_CONFIG" > "$temp_file"
  mv "$temp_file" "$ROLLOUT_CONFIG"
  
  # Update last_update timestamp
  update_rollout_config "certificate_update.last_update" "$today"
  
  # Set initial rollout percentage
  update_app_store_rollout "$phase1_percentage"
  update_play_store_rollout "$phase1_percentage"
  
  log "New rollout started with phase 1 ($phase1_percentage%)"
  
  # Send notification
  send_notification "Certificate Rollout Started" \
                   "A new certificate fingerprint rollout has been started with phase 1 ($phase1_percentage%).\n\nPlease monitor the application for any issues."
  
  return 0
}

# Function to update App Store rollout percentage
update_app_store_rollout() {
  local percentage=$1
  
  log "Updating App Store rollout percentage to $percentage%"
  
  # This is a placeholder. In a real implementation, you would use the App Store Connect API
  # to update the phased release percentage for your app.
  # 
  # Example using App Store Connect API (requires appropriate authentication):
  # curl -X PATCH \
  #   "https://api.appstoreconnect.apple.com/v1/apps/$apple_app_id/appStoreVersions/latest" \
  #   -H "Authorization: Bearer $AUTH_TOKEN" \
  #   -H "Content-Type: application/json" \
  #   -d '{"data":{"attributes":{"phasedReleaseState":"ACTIVE","phasedReleasePercentage":"'$percentage'"},"type":"appStoreVersions"}}'
  
  echo "[PLACEHOLDER] Updated App Store rollout percentage to $percentage% for app $apple_app_id version $apple_current_version"
  
  # Update the configuration
  local temp_file=$(mktemp)
  jq --arg percentage "$percentage" \
     '.app_store.current_percentage = $percentage' \
     "$ROLLOUT_CONFIG" > "$temp_file"
  mv "$temp_file" "$ROLLOUT_CONFIG"
  
  log "App Store rollout percentage updated successfully"
}

# Function to update Play Store rollout percentage
update_play_store_rollout() {
  local percentage=$1
  
  log "Updating Play Store rollout percentage to $percentage%"
  
  # This is a placeholder. In a real implementation, you would use the Google Play Developer API
  # to update the phased release percentage for your app.
  # 
  # Example using Google Play Developer API (requires appropriate authentication):
  # curl -X PATCH \
  #   "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/$google_package_name/edits/$EDIT_ID/tracks/production" \
  #   -H "Authorization: Bearer $AUTH_TOKEN" \
  #   -H "Content-Type: application/json" \
  #   -d '{"releases":[{"userFraction":"'$(echo "scale=2; $percentage/100" | bc)'","versionCodes":["'$CURRENT_VERSION_CODE'"],"status":"inProgress"}]}'
  
  echo "[PLACEHOLDER] Updated Play Store rollout percentage to $percentage% for app $google_package_name version $google_current_version"
  
  # Update the configuration
  local temp_file=$(mktemp)
  jq --arg percentage "$percentage" \
     '.play_store.current_percentage = $percentage' \
     "$ROLLOUT_CONFIG" > "$temp_file"
  mv "$temp_file" "$ROLLOUT_CONFIG"
  
  log "Play Store rollout percentage updated successfully"
}

# Function to check for error metrics that might trigger a rollback
check_error_metrics() {
  log "Checking error metrics for potential rollback"
  
  # In a real implementation, you would fetch these metrics from your monitoring system
  # For this example, we'll use the values stored in the rollout configuration
  
  local connection_errors=$(jq -r '.certificate_update.monitoring_metrics.connection_errors // 0' "$ROLLOUT_CONFIG")
  local certificate_errors=$(jq -r '.certificate_update.monitoring_metrics.certificate_errors // 0' "$ROLLOUT_CONFIG")
  local total_connections=$(jq -r '.certificate_update.monitoring_metrics.total_connections // 0' "$ROLLOUT_CONFIG")
  
  log "Current metrics - Connection errors: $connection_errors, Certificate errors: $certificate_errors, Total connections: $total_connections"
  
  # Calculate error percentage
  local error_percentage=0
  if [ "$total_connections" -gt 0 ]; then
    error_percentage=$(echo "scale=2; 100 * ($connection_errors + $certificate_errors) / $total_connections" | bc)
  fi
  
  log "Error percentage: $error_percentage%, Rollback threshold: $rollback_threshold%"
  
  # Check if error percentage exceeds the rollback threshold
  if (( $(echo "$error_percentage > $rollback_threshold" | bc -l) )); then
    log "ERROR: Error percentage ($error_percentage%) exceeds rollback threshold ($rollback_threshold%)"
    return 0  # Return success (indicating rollback needed)
  else
    log "Error percentage is below the rollback threshold"
    return 1  # Return failure (indicating no rollback needed)
  fi
}

# Function to trigger a rollback
trigger_rollback() {
  local reason=$1
  
  log "Triggering rollback due to: $reason"
  
  # Call the rollback script
  local rollback_script="./cert_rollback.sh"
  
  if [ ! -f "$rollback_script" ]; then
    log "ERROR: Rollback script not found at $rollback_script"
    echo "ERROR: Rollback script not found at $rollback_script"
    return 1
  fi
  
  # Find the most recent backup before the rollout started
  local backup_dir="../backups/certificate_fingerprints"
  if [ ! -d "$backup_dir" ]; then
    log "ERROR: Backup directory not found at $backup_dir"
    echo "ERROR: Backup directory not found at $backup_dir"
    return 1
  fi
  
  # Get the date of the last update
  local last_update_date=$last_update
  if [ "$last_update_date" = "null" ]; then
    log "ERROR: No last update date found in rollout configuration"
    echo "ERROR: No last update date found in rollout configuration"
    return 1
  fi
  
  # Convert last update date to seconds
  local last_update_seconds=$(date -j -f "%Y-%m-%d" "$last_update_date" +%s 2>/dev/null)
  if [ $? -ne 0 ]; then
    # Try alternative format for Linux
    last_update_seconds=$(date -d "$last_update_date" +%s 2>/dev/null)
    if [ $? -ne 0 ]; then
      log "ERROR: Failed to parse last update date: $last_update_date"
      return 1
    fi
  fi
  
  # Find the most recent backup before the last update
  local backup_file=""
  for file in $(ls -1t "$backup_dir" 2>/dev/null | grep -E '^fingerprints_[0-9]{8}_[0-9]{6}\.json$'); do
    local backup_date=$(echo "$file" | sed -E 's/fingerprints_([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})\.json/\1-\2-\3/')
    
    # Convert backup date to seconds
    local backup_seconds=$(date -j -f "%Y-%m-%d" "$backup_date" +%s 2>/dev/null)
    if [ $? -ne 0 ]; then
      # Try alternative format for Linux
      backup_seconds=$(date -d "$backup_date" +%s 2>/dev/null)
      if [ $? -ne 0 ]; then
        log "WARNING: Failed to parse backup date: $backup_date, skipping"
        continue
      fi
    fi
    
    # Check if this backup is before the last update
    if [ "$backup_seconds" -lt "$last_update_seconds" ]; then
      backup_file="$file"
      break
    fi
  done
  
  if [ -z "$backup_file" ]; then
    log "ERROR: No suitable backup found before the last update ($last_update_date)"
    echo "ERROR: No suitable backup found before the last update ($last_update_date)"
    return 1
  fi
  
  log "Found suitable backup for rollback: $backup_file"
  
  # Execute the rollback script
  "$rollback_script" -i -b "$backup_file" -r "$reason"
  
  if [ $? -ne 0 ]; then
    log "ERROR: Rollback failed"
    echo "ERROR: Rollback failed"
    return 1
  fi
  
  # Reset the rollout phase
  update_rollout_config "certificate_update.current_phase" "0"
  
  # Reset app store rollout percentages
  update_app_store_rollout "0"
  update_play_store_rollout "0"
  
  log "Rollback completed successfully"
  
  # Send notification
  send_notification "Certificate Rollout Rolled Back" \
                   "The certificate fingerprint rollout has been rolled back due to: $reason\n\nThe app has been restored to the previous certificate fingerprints."
  
  return 0
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

# Function to display rollout status
display_status() {
  log "Displaying rollout status"
  
  echo "Certificate Rollout Status"
  echo "------------------------"
  echo "Current phase: $current_phase"
  
  if [ "$current_phase" -eq 0 ]; then
    echo "Status: No active rollout"
  else
    echo "Status: Active rollout in progress"
    
    # Get the start date of the current phase
    local phase_start=$(echo "$phase_start_dates" | jq -r ".[$((current_phase-1))] // \"Unknown\"")
    
    echo "Phase $current_phase started on: $phase_start"
    
    # Determine the percentage for the current phase
    local percentage=0
    if [ "$current_phase" -eq 1 ]; then
      percentage=$phase1_percentage
    elif [ "$current_phase" -eq 2 ]; then
      percentage=$phase2_percentage
    elif [ "$current_phase" -eq 3 ]; then
      percentage=$phase3_percentage
    fi
    
    echo "Current rollout percentage: $percentage%"
    
    # Calculate days since phase start
    if [ "$phase_start" != "Unknown" ] && [ "$phase_start" != "null" ]; then
      local phase_start_seconds=$(date -j -f "%Y-%m-%d" "$phase_start" +%s 2>/dev/null)
      if [ $? -ne 0 ]; then
        # Try alternative format for Linux
        phase_start_seconds=$(date -d "$phase_start" +%s 2>/dev/null)
        if [ $? -eq 0 ]; then
          local current_seconds=$(date +%s)
          local diff_seconds=$((current_seconds - phase_start_seconds))
          local days_since_phase_start=$((diff_seconds / 86400))
          
          echo "Days since phase start: $days_since_phase_start"
          
          # Determine the duration of the current phase
          local phase_duration=0
          if [ "$current_phase" -eq 1 ]; then
            phase_duration=$phase1_duration_days
          elif [ "$current_phase" -eq 2 ]; then
            phase_duration=$phase2_duration_days
          elif [ "$current_phase" -eq 3 ]; then
            phase_duration=$phase3_duration_days
          fi
          
          local days_remaining=$((phase_duration - days_since_phase_start))
          if [ "$days_remaining" -gt 0 ]; then
            echo "Days remaining in current phase: $days_remaining"
          else
            echo "Phase duration exceeded, ready for advancement"
          fi
        fi
      fi
    fi
  fi
  
  echo ""
  echo "App Store Status"
  echo "---------------"
  echo "App ID: $apple_app_id"
  echo "Current version: $apple_current_version"
  echo "Phased release enabled: $apple_phased_release"
  echo "Current percentage: $(jq -r '.app_store.current_percentage // "0"' "$ROLLOUT_CONFIG")%"
  
  echo ""
  echo "Play Store Status"
  echo "----------------"
  echo "Package name: $google_package_name"
  echo "Current version: $google_current_version"
  echo "Phased release enabled: $google_phased_release"
  echo "Current percentage: $(jq -r '.play_store.current_percentage // "0"' "$ROLLOUT_CONFIG")%"
  
  echo ""
  echo "Last update: $last_update"
  echo "Last rollback: $last_rollback"
  if [ "$last_rollback" != "null" ]; then
    echo "Rollback reason: $(jq -r '.certificate_update.rollback_reason // "Unknown"' "$ROLLOUT_CONFIG")"
  fi
  
  echo ""
  echo "Error Metrics"
  echo "-------------"
  local connection_errors=$(jq -r '.certificate_update.monitoring_metrics.connection_errors // 0' "$ROLLOUT_CONFIG")
  local certificate_errors=$(jq -r '.certificate_update.monitoring_metrics.certificate_errors // 0' "$ROLLOUT_CONFIG")
  local total_connections=$(jq -r '.certificate_update.monitoring_metrics.total_connections // 0' "$ROLLOUT_CONFIG")
  
  echo "Connection errors: $connection_errors"
  echo "Certificate errors: $certificate_errors"
  echo "Total connections: $total_connections"
  
  local error_percentage=0
  if [ "$total_connections" -gt 0 ]; then
    error_percentage=$(echo "scale=2; 100 * ($connection_errors + $certificate_errors) / $total_connections" | bc)
  fi
  
  echo "Error percentage: $error_percentage%"
  echo "Rollback threshold: $rollback_threshold%"
}

# Main execution

# Parse command line arguments
action="status"

while getopts ":a:r:" opt; do
  case $opt in
    a)
      action="$OPTARG"
      ;;
    r)
      rollback_reason="$OPTARG"
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

# Load rollout configuration
load_rollout_config

# Execute the requested action
case "$action" in
  "start")
    start_new_rollout
    ;;
  "advance")
    if check_phase_advancement; then
      advance_to_next_phase
    else
      echo "Not ready to advance to the next phase yet."
    fi
    ;;
  "check")
    if check_error_metrics; then
      echo "Error metrics exceed threshold. Rollback recommended."
      echo "Use -a rollback -r "reason" to initiate a rollback."
    else
      echo "Error metrics are within acceptable limits."
    fi
    ;;
  "rollback")
    if [ -z "$rollback_reason" ]; then
      rollback_reason="Manual rollback initiated"
    fi
    trigger_rollback "$rollback_reason"
    ;;
  "status")
    display_status
    ;;
  *)
    echo "Unknown action: $action"
    echo "Valid actions: start, advance, check, rollback, status"
    exit 1
    ;;
esac

# For CI/CD integration, indicate success
exit 0