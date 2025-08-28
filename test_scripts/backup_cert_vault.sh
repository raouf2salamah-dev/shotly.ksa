#!/bin/bash

# Backup Certificate Storage in HashiCorp Vault
# This script demonstrates how to store backup certificate fingerprints in HashiCorp Vault
# It can be adapted for other secret managers like AWS Secrets Manager

set -e

# Configuration
VAULT_ADDR="https://vault.example.com:8200"
VAULT_TOKEN="your-vault-token" # In production, use environment variables or vault login
SECRET_PATH="secret/certificate-fingerprints"

# Check if jq is installed (needed for JSON processing)
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: brew install jq (macOS) or apt-get install jq (Ubuntu)"
    exit 1
fi

# Check if vault CLI is installed
if ! command -v vault &> /dev/null; then
    echo "Error: HashiCorp Vault CLI is required but not installed."
    echo "Install from: https://www.vaultproject.io/downloads"
    exit 1
fi

# Function to store a certificate fingerprint in Vault
store_fingerprint() {
    local domain=$1
    local fingerprint_type=$2 # primary or backup
    local fingerprint=$3
    local rotation_date=$4
    
    # Create JSON payload
    local json_payload='{"fingerprint":"'"$fingerprint"'", "rotation_date":"'"$rotation_date"'"}'
    
    # Store in Vault
    echo "Storing $fingerprint_type fingerprint for $domain in Vault..."
    vault kv put "$SECRET_PATH/$domain/$fingerprint_type" value="$json_payload"
    
    echo "Successfully stored $fingerprint_type fingerprint for $domain"
}

# Function to retrieve a certificate fingerprint from Vault
retrieve_fingerprint() {
    local domain=$1
    local fingerprint_type=$2 # primary or backup
    
    echo "Retrieving $fingerprint_type fingerprint for $domain from Vault..."
    vault kv get -format=json "$SECRET_PATH/$domain/$fingerprint_type" | jq -r '.data.data.value'
}

# Function to list all domains with stored fingerprints
list_domains() {
    echo "Listing all domains with stored fingerprints in Vault..."
    vault kv list -format=json "$SECRET_PATH/" | jq -r '.[]'
}

# Function to export all fingerprints to a JSON file
export_fingerprints() {
    local output_file=$1
    local temp_file=$(mktemp)
    
    echo "Exporting all fingerprints to $output_file..."
    echo "{" > "$temp_file"
    
    # Get all domains
    local domains=$(vault kv list -format=json "$SECRET_PATH/" | jq -r '.[]')
    local first_domain=true
    
    for domain in $domains; do
        # Add comma for all but the first domain
        if [ "$first_domain" = false ]; then
            echo "," >> "$temp_file"
        fi
        first_domain=false
        
        echo "  \"$domain\": {" >> "$temp_file"
        
        # Get primary fingerprint
        local primary_data=$(vault kv get -format=json "$SECRET_PATH/$domain/primary" 2>/dev/null || echo '{"data":{"data":{"value":"{\"fingerprint\":\"\",\"rotation_date\":\"\"}"}}}' )
        local primary_json=$(echo "$primary_data" | jq -r '.data.data.value')
        local primary_fingerprint=$(echo "$primary_json" | jq -r '.fingerprint')
        local primary_rotation_date=$(echo "$primary_json" | jq -r '.rotation_date')
        
        # Get backup fingerprint
        local backup_data=$(vault kv get -format=json "$SECRET_PATH/$domain/backup" 2>/dev/null || echo '{"data":{"data":{"value":"{\"fingerprint\":\"\",\"rotation_date\":\"\"}"}}}' )
        local backup_json=$(echo "$backup_data" | jq -r '.data.data.value')
        local backup_fingerprint=$(echo "$backup_json" | jq -r '.fingerprint')
        
        echo "    \"primary\": \"$primary_fingerprint\"," >> "$temp_file"
        echo "    \"backup\": \"$backup_fingerprint\"," >> "$temp_file"
        echo "    \"rotation_date\": \"$primary_rotation_date\"" >> "$temp_file"
        echo "  }" >> "$temp_file"
    done
    
    echo "}" >> "$temp_file"
    
    # Format the JSON nicely
    jq '.' "$temp_file" > "$output_file"
    rm "$temp_file"
    
    echo "Successfully exported all fingerprints to $output_file"
}

# Function to import fingerprints from a JSON file
import_fingerprints() {
    local input_file=$1
    
    echo "Importing fingerprints from $input_file..."
    
    # Check if the file exists
    if [ ! -f "$input_file" ]; then
        echo "Error: File $input_file does not exist"
        exit 1
    fi
    
    # Read the JSON file
    local domains=$(jq -r 'keys[]' "$input_file")
    
    for domain in $domains; do
        local primary_fingerprint=$(jq -r ".[\"$domain\"].primary" "$input_file")
        local backup_fingerprint=$(jq -r ".[\"$domain\"].backup" "$input_file")
        local rotation_date=$(jq -r ".[\"$domain\"].rotation_date" "$input_file")
        
        # Store the fingerprints in Vault
        if [ "$primary_fingerprint" != "null" ] && [ "$primary_fingerprint" != "" ]; then
            store_fingerprint "$domain" "primary" "$primary_fingerprint" "$rotation_date"
        fi
        
        if [ "$backup_fingerprint" != "null" ] && [ "$backup_fingerprint" != "" ]; then
            store_fingerprint "$domain" "backup" "$backup_fingerprint" "$rotation_date"
        fi
    done
    
    echo "Successfully imported fingerprints from $input_file"
}

# Function to rotate a certificate fingerprint
rotate_fingerprint() {
    local domain=$1
    local new_primary_fingerprint=$2
    local new_rotation_date=$3
    
    echo "Rotating certificate fingerprint for $domain..."
    
    # Get the current primary fingerprint
    local primary_data=$(vault kv get -format=json "$SECRET_PATH/$domain/primary" 2>/dev/null || echo '{"data":{"data":{"value":"{\"fingerprint\":\"\",\"rotation_date\":\"\"}"}}}' )
    local primary_json=$(echo "$primary_data" | jq -r '.data.data.value')
    local old_primary_fingerprint=$(echo "$primary_json" | jq -r '.fingerprint')
    
    # Move the current primary to backup if it exists
    if [ "$old_primary_fingerprint" != "" ] && [ "$old_primary_fingerprint" != "null" ]; then
        echo "Moving current primary fingerprint to backup..."
        store_fingerprint "$domain" "backup" "$old_primary_fingerprint" ""
    fi
    
    # Store the new primary fingerprint
    store_fingerprint "$domain" "primary" "$new_primary_fingerprint" "$new_rotation_date"
    
    echo "Successfully rotated certificate fingerprint for $domain"
}

# Main script

# Set Vault address and token
export VAULT_ADDR="$VAULT_ADDR"
export VAULT_TOKEN="$VAULT_TOKEN"

# Display usage if no arguments are provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [command] [arguments]"
    echo ""
    echo "Commands:"
    echo "  store [domain] [primary|backup] [fingerprint] [rotation_date]  Store a certificate fingerprint"
    echo "  retrieve [domain] [primary|backup]                           Retrieve a certificate fingerprint"
    echo "  list                                                        List all domains with stored fingerprints"
    echo "  export [output_file]                                        Export all fingerprints to a JSON file"
    echo "  import [input_file]                                         Import fingerprints from a JSON file"
    echo "  rotate [domain] [new_fingerprint] [new_rotation_date]       Rotate a certificate fingerprint"
    echo ""
    echo "Examples:"
    echo "  $0 store api.example.com primary 'AA:BB:CC:DD:EE:FF' '2023-12-31'"
    echo "  $0 retrieve api.example.com backup"
    echo "  $0 list"
    echo "  $0 export fingerprints.json"
    echo "  $0 import fingerprints.json"
    echo "  $0 rotate api.example.com 'AA:BB:CC:DD:EE:FF' '2023-12-31'"
    exit 0
fi

# Parse command
command=$1
shift

case "$command" in
    store)
        if [ $# -lt 3 ]; then
            echo "Error: Not enough arguments for store command"
            echo "Usage: $0 store [domain] [primary|backup] [fingerprint] [rotation_date]"
            exit 1
        fi
        domain=$1
        fingerprint_type=$2
        fingerprint=$3
        rotation_date=${4:-""}
        store_fingerprint "$domain" "$fingerprint_type" "$fingerprint" "$rotation_date"
        ;;
    retrieve)
        if [ $# -lt 2 ]; then
            echo "Error: Not enough arguments for retrieve command"
            echo "Usage: $0 retrieve [domain] [primary|backup]"
            exit 1
        fi
        domain=$1
        fingerprint_type=$2
        retrieve_fingerprint "$domain" "$fingerprint_type"
        ;;
    list)
        list_domains
        ;;
    export)
        if [ $# -lt 1 ]; then
            echo "Error: Not enough arguments for export command"
            echo "Usage: $0 export [output_file]"
            exit 1
        fi
        output_file=$1
        export_fingerprints "$output_file"
        ;;
    import)
        if [ $# -lt 1 ]; then
            echo "Error: Not enough arguments for import command"
            echo "Usage: $0 import [input_file]"
            exit 1
        fi
        input_file=$1
        import_fingerprints "$input_file"
        ;;
    rotate)
        if [ $# -lt 3 ]; then
            echo "Error: Not enough arguments for rotate command"
            echo "Usage: $0 rotate [domain] [new_fingerprint] [new_rotation_date]"
            exit 1
        fi
        domain=$1
        new_fingerprint=$2
        new_rotation_date=$3
        rotate_fingerprint "$domain" "$new_fingerprint" "$new_rotation_date"
        ;;
    *)
        echo "Error: Unknown command $command"
        echo "Usage: $0 [command] [arguments]"
        exit 1
        ;;
esac

exit 0