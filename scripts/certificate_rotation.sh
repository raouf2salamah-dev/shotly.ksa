#!/bin/bash

# Certificate Rotation Script
# This script helps automate the certificate rotation process

set -e

echo "===== Certificate Rotation Helper ====="
echo "This script helps automate the certificate rotation process"

# Define variables
API_DOMAIN="api.yourdomain.com" # Your actual API domain
CERTS_DIR="./certs"
APP_DIR="../lib"
CERT_PINNING_FILE="../lib/security/certificate_pinning_service.dart"
SECURITY_BOOTSTRAP_FILE="../lib/bootstrap/security_bootstrap.dart"
ROTATION_DATE=$(date -u +"%Y-%m-%d")
ROTATION_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create necessary directories
mkdir -p "$CERTS_DIR"

# Function to display help
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --domain DOMAIN       Specify the API domain (default: $API_DOMAIN)"
    echo "  --check               Check current certificate status"
    echo "  --rotate              Perform certificate rotation"
    echo "  --help                Display this help message"
    echo ""
    exit 0
}

# Function to check certificate status
check_certificate() {
    local domain=$1
    
    echo "Checking certificate for $domain..."
    
    # Fetch the server certificate
    openssl s_client -connect "$domain":443 -servername "$domain" </dev/null 2>/dev/null | \
        openssl x509 -outform PEM > "$CERTS_DIR/server_cert.pem"
    
    # Check if certificate was successfully retrieved
    if [ ! -s "$CERTS_DIR/server_cert.pem" ]; then
        echo "❌ ERROR: Could not retrieve server certificate."
        exit 1
    fi
    
    # Get certificate details
    CERT_SUBJECT=$(openssl x509 -in "$CERTS_DIR/server_cert.pem" -noout -subject | sed 's/^subject=//g')
    CERT_ISSUER=$(openssl x509 -in "$CERTS_DIR/server_cert.pem" -noout -issuer | sed 's/^issuer=//g')
    CERT_START_DATE=$(openssl x509 -in "$CERTS_DIR/server_cert.pem" -noout -startdate | cut -d'=' -f2)
    CERT_END_DATE=$(openssl x509 -in "$CERTS_DIR/server_cert.pem" -noout -enddate | cut -d'=' -f2)
    CERT_FINGERPRINT=$(openssl x509 -in "$CERTS_DIR/server_cert.pem" -noout -fingerprint -sha256 | cut -d'=' -f2)
    
    # Calculate days until expiry
    CERT_EXPIRY_SECONDS=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$CERT_END_DATE" +%s 2>/dev/null || date -d "$CERT_END_DATE" +%s 2>/dev/null)
    CURRENT_SECONDS=$(date +%s)
    SECONDS_REMAINING=$((CERT_EXPIRY_SECONDS - CURRENT_SECONDS))
    DAYS_REMAINING=$((SECONDS_REMAINING / 86400))
    
    echo "Certificate Information:"
    echo "  Subject: $CERT_SUBJECT"
    echo "  Issuer: $CERT_ISSUER"
    echo "  Valid From: $CERT_START_DATE"
    echo "  Valid Until: $CERT_END_DATE"
    echo "  SHA-256 Fingerprint: $CERT_FINGERPRINT"
    echo "  Days Until Expiry: $DAYS_REMAINING"
    
    # Check if certificate is in code
    if grep -q "$CERT_FINGERPRINT" "$CERT_PINNING_FILE"; then
        echo "✅ Certificate fingerprint found in CertificatePinningService class"
        
        # Check if it's set as primary or backup
        if grep -A 5 "$CERT_FINGERPRINT" "$CERT_PINNING_FILE" | grep -q "isPrimary: true"; then
            echo "  ℹ️ This is currently set as a PRIMARY certificate"
        elif grep -A 5 "$CERT_FINGERPRINT" "$CERT_PINNING_FILE" | grep -q "isPrimary: false"; then
            echo "  ℹ️ This is currently set as a BACKUP certificate"
        fi
    else
        echo "❌ Certificate fingerprint NOT found in CertificatePinningService class"
        echo "  You should add this certificate to your app before it's deployed"
    fi
    
    # Rotation recommendation
    if [ $DAYS_REMAINING -lt 30 ]; then
        echo "⚠️ WARNING: Certificate expires in less than 30 days!"
        echo "  You should rotate certificates immediately."
    elif [ $DAYS_REMAINING -lt 60 ]; then
        echo "⚠️ WARNING: Certificate expires in less than 60 days!"
        echo "  You should plan certificate rotation soon."
    else
        echo "✅ Certificate is valid for $DAYS_REMAINING more days."
    fi
}

# Function to perform certificate rotation
rotate_certificate() {
    local domain=$1
    
    echo "Performing certificate rotation for $domain..."
    
    # Fetch the server certificate
    openssl s_client -connect "$domain":443 -servername "$domain" </dev/null 2>/dev/null | \
        openssl x509 -outform PEM > "$CERTS_DIR/server_cert.pem"
    
    # Check if certificate was successfully retrieved
    if [ ! -s "$CERTS_DIR/server_cert.pem" ]; then
        echo "❌ ERROR: Could not retrieve server certificate."
        exit 1
    fi
    
    # Get certificate fingerprint
    CERT_FINGERPRINT=$(openssl x509 -in "$CERTS_DIR/server_cert.pem" -noout -fingerprint -sha256 | cut -d'=' -f2)
    CERT_END_DATE=$(openssl x509 -in "$CERTS_DIR/server_cert.pem" -noout -enddate | cut -d'=' -f2)
    
    echo "Certificate SHA-256 Fingerprint: $CERT_FINGERPRINT"
    echo "Certificate Expiry Date: $CERT_END_DATE"
    
    # Check if this is already the primary certificate
    if grep -A 5 "$CERT_FINGERPRINT" "$CERT_PINNING_FILE" | grep -q "isPrimary: true"; then
        echo "ℹ️ This certificate is already set as the PRIMARY certificate."
        echo "No rotation needed."
        exit 0
    fi
    
    # Check if this is already the backup certificate
    if grep -A 5 "$CERT_FINGERPRINT" "$CERT_PINNING_FILE" | grep -q "isPrimary: false"; then
        echo "ℹ️ This certificate is already set as the BACKUP certificate."
        echo "Promoting backup certificate to primary..."
        
        # Find the current primary certificate
        CURRENT_PRIMARY=$(grep -A 5 "isPrimary: true" "$CERT_PINNING_FILE" | grep -o "[A-F0-9]\{2\}:[A-F0-9]\{2\}:[A-F0-9]\{2\}:[A-F0-9]\{2\}:[A-F0-9]\{2\}:[A-F0-9]\{2\}:[A-F0-9]\{2\}:[A-F0-9]\{2\}:[A-F0-9]\{2\}:[A-F0-9]\{2\}:[A-F0-9]\{2\}:[A-F0-9]\{2\}:[A-F0-9]\{2\}:[A-F0-9]\{2\}:[A-F0-9]\{2\}:[A-F0-9]\{2\}" | head -1)
        
        if [ -n "$CURRENT_PRIMARY" ]; then
            echo "Current primary certificate: $CURRENT_PRIMARY"
            echo "This will be removed during rotation."
        fi
        
        # Create a backup of the files before modifying
        cp "$CERT_PINNING_FILE" "${CERT_PINNING_FILE}.bak"
        cp "$SECURITY_BOOTSTRAP_FILE" "${SECURITY_BOOTSTRAP_FILE}.bak"
        
        echo "Files backed up before modification."
        echo "Please manually update the CertificatePinningService class to promote the backup certificate to primary."
        echo "Then add a new backup certificate if available."
        
        # Open the files for editing
        echo "Opening files for editing..."
        echo "Please follow the certificate rotation guide for detailed steps."
        
        # You can uncomment these lines if you want to automatically open the files
        # open "$CERT_PINNING_FILE"
        # open "$SECURITY_BOOTSTRAP_FILE"
        
        echo "After editing, run your tests to ensure certificate pinning still works."
    else
        echo "❌ This certificate is not configured in your app yet."
        echo "Please add it as a backup certificate first, then perform rotation."
        
        # Suggest code to add
        echo ""
        echo "Suggested code to add to SecurityBootstrap.addCertificateFingerprint call:"
        echo ""
        echo "SecurityBootstrap.addCertificateFingerprint("
        echo "  \"$domain\","
        echo "  \"$CERT_FINGERPRINT\","
        echo "  isPrimary: false,"
        echo "  rotationDate: \"$ROTATION_DATE\","
        echo ");"
        echo ""
    fi
}

# Parse command line arguments
CHECK_MODE=false
ROTATE_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --domain)
            API_DOMAIN="$2"
            shift 2
            ;;
        --check)
            CHECK_MODE=true
            shift
            ;;
        --rotate)
            ROTATE_MODE=true
            shift
            ;;
        --help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

# Execute requested operation
if [ "$CHECK_MODE" = true ]; then
    check_certificate "$API_DOMAIN"
elif [ "$ROTATE_MODE" = true ]; then
    rotate_certificate "$API_DOMAIN"
else
    echo "No operation specified. Use --check or --rotate."
    show_help
fi

echo "Done."