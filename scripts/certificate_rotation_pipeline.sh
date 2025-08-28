#!/bin/bash
# Certificate Rotation Pipeline Script
# This script automates the process of updating certificate fingerprints in the mobile app

set -e

# Configuration
DOMAINS=("api.yourdomain.com" "auth.yourdomain.com" "cdn.yourdomain.com")
IOS_CONFIG_PATH="ios/Runner/Info.plist"
ANDROID_CONFIG_PATH="android/app/src/main/res/xml/network_security_config.xml"
BACKUP_DIR="./backup_configs/$(date +%Y%m%d_%H%M%S)"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to extract certificate fingerprints
extract_fingerprint() {
  local domain=$1
  echo "Extracting fingerprint for $domain..."
  
  # Connect to the server and extract the SHA-256 fingerprint
  fingerprint=$(openssl s_client -servername "$domain" -connect "$domain":443 < /dev/null 2>/dev/null | 
    openssl x509 -pubkey -noout | 
    openssl pkey -pubin -outform der | 
    openssl dgst -sha256 -binary | 
    openssl enc -base64)
  
  if [ -z "$fingerprint" ]; then
    echo "Error: Could not extract fingerprint for $domain"
    exit 1
  fi
  
  echo "$fingerprint"
}

# Backup current configuration files
backup_configs() {
  echo "Creating backups of current configuration files..."
  
  if [ -f "$IOS_CONFIG_PATH" ]; then
    cp "$IOS_CONFIG_PATH" "$BACKUP_DIR/$(basename "$IOS_CONFIG_PATH")"
  else
    echo "Warning: iOS config file not found at $IOS_CONFIG_PATH"
  fi
  
  if [ -f "$ANDROID_CONFIG_PATH" ]; then
    cp "$ANDROID_CONFIG_PATH" "$BACKUP_DIR/$(basename "$ANDROID_CONFIG_PATH")"
  else
    echo "Warning: Android config file not found at $ANDROID_CONFIG_PATH"
  fi
}

# Update iOS configuration
update_ios_config() {
  echo "Updating iOS certificate pinning configuration..."
  
  # Create temporary file for modifications
  local temp_file=$(mktemp)
  
  # Start with existing content
  cat "$IOS_CONFIG_PATH" > "$temp_file"
  
  # Check if NSPinnedDomains exists
  if ! grep -q "<key>NSPinnedDomains</key>" "$temp_file"; then
    # Add NSPinnedDomains if it doesn't exist
    sed -i '' 's/<\/dict>/\t<key>NSPinnedDomains<\/key>\n\t<dict>\n\t<\/dict>\n<\/dict>/g' "$temp_file"
  fi
  
  # Update each domain
  for domain in "${DOMAINS[@]}"; do
    fingerprint=$(extract_fingerprint "$domain")
    domain_escaped=$(echo "$domain" | sed 's/\./\\./g')
    
    # Check if domain already exists in config
    if grep -q "<key>$domain</key>" "$temp_file"; then
      # Update existing domain
      sed -i '' "/<key>$domain<\/key>/,/<\/dict>/c\\
      <key>$domain</key>\\
      <dict>\\
        <key>NSIncludesSubdomains</key>\\
        <true/>\\
        <key>NSPinnedCAIdentities</key>\\
        <array>\\
          <dict>\\
            <key>SPKI-SHA256-BASE64</key>\\
            <string>$fingerprint</string>\\
          </dict>\\
        </array>\\
      </dict>" "$temp_file"
    else
      # Add new domain
      sed -i '' "/<key>NSPinnedDomains<\/key>/,/<\/dict>/s/<\/dict>/\\
      <key>$domain<\/key>\\
      <dict>\\
        <key>NSIncludesSubdomains<\/key>\\
        <true\/>\\
        <key>NSPinnedCAIdentities<\/key>\\
        <array>\\
          <dict>\\
            <key>SPKI-SHA256-BASE64<\/key>\\
            <string>$fingerprint<\/string>\\
          <\/dict>\\
        <\/array>\\
      <\/dict>\\
    <\/dict>/" "$temp_file"
    fi
  done
  
  # Replace original file with modified version
  mv "$temp_file" "$IOS_CONFIG_PATH"
  echo "iOS configuration updated successfully"
}

# Update Android configuration
update_android_config() {
  echo "Updating Android certificate pinning configuration..."
  
  # Create temporary file for modifications
  local temp_file=$(mktemp)
  
  # Check if file exists, if not create a basic template
  if [ ! -f "$ANDROID_CONFIG_PATH" ]; then
    mkdir -p "$(dirname "$ANDROID_CONFIG_PATH")"
    echo '<?xml version="1.0" encoding="utf-8"?>' > "$temp_file"
    echo '<network-security-config>' >> "$temp_file"
    echo '    <domain-config cleartextTrafficPermitted="false">' >> "$temp_file"
    echo '    </domain-config>' >> "$temp_file"
    echo '</network-security-config>' >> "$temp_file"
  else
    cat "$ANDROID_CONFIG_PATH" > "$temp_file"
  fi
  
  # Process each domain
  for domain in "${DOMAINS[@]}"; do
    fingerprint=$(extract_fingerprint "$domain")
    
    # Check if domain already exists in config
    if grep -q "<domain>$domain</domain>" "$temp_file"; then
      # Extract the domain-config block
      start_line=$(grep -n "<domain>$domain</domain>" "$temp_file" | cut -d: -f1)
      start_block=$(grep -n "<domain-config" "$temp_file" | awk -v line="$start_line" '$1 < line' | tail -1 | cut -d: -f1)
      end_block=$(tail -n +$start_block "$temp_file" | grep -n "</domain-config>" | head -1 | cut -d: -f1)
      end_block=$((start_block + end_block - 1))
      
      # Create updated block
      updated_block="    <domain-config cleartextTrafficPermitted=\"false\">\n"
      updated_block+="        <domain>$domain</domain>\n"
      updated_block+="        <pin-set>\n"
      updated_block+="            <pin digest=\"SHA-256\">$fingerprint</pin>\n"
      updated_block+="        </pin-set>\n"
      updated_block+="    </domain-config>"
      
      # Replace the block
      sed -i '' "${start_block},${end_block}c\\
$updated_block" "$temp_file"
    else
      # Add new domain config before closing tag
      sed -i '' "s|</network-security-config>|    <domain-config cleartextTrafficPermitted=\"false\">\n        <domain>$domain</domain>\n        <pin-set>\n            <pin digest=\"SHA-256\">$fingerprint</pin>\n        </pin-set>\n    </domain-config>\n</network-security-config>|" "$temp_file"
    fi
  done
  
  # Replace original file with modified version
  mv "$temp_file" "$ANDROID_CONFIG_PATH"
  echo "Android configuration updated successfully"
}

# Verify configurations
verify_configs() {
  echo "Verifying updated configurations..."
  
  # Check iOS config
  if [ -f "$IOS_CONFIG_PATH" ]; then
    if ! plutil -lint "$IOS_CONFIG_PATH"; then
      echo "Error: iOS configuration file is invalid"
      exit 1
    fi
  fi
  
  # Check Android config
  if [ -f "$ANDROID_CONFIG_PATH" ]; then
    if ! grep -q "<pin-set>" "$ANDROID_CONFIG_PATH"; then
      echo "Error: Android configuration does not contain pin-set"
      exit 1
    fi
  fi
  
  echo "Configuration verification passed"
}

# Main execution
echo "Starting certificate rotation pipeline..."
backup_configs
update_ios_config
update_android_config
verify_configs

echo "Certificate rotation completed successfully"
echo "Backup files stored in: $BACKUP_DIR"

# Log the rotation for audit purposes
echo "$(date): Certificate rotation completed for domains: ${DOMAINS[*]}" >> ./logs/security/certificate_rotations.log