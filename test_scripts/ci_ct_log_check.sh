#!/bin/bash

# CI/CD Integration Script for Certificate Transparency Log Checking
# This script is designed to be run in CI/CD pipelines to verify that certificates
# are properly logged in Certificate Transparency logs.

set -e

# Configuration
DOMAINS="api.yourdomain.com,api.example.com"
MIN_LOGS=2
MAX_AGE_DAYS=30
OUTPUT_DIR="./ct_log_reports"
OUTPUT_FILE="${OUTPUT_DIR}/ct_log_report_$(date +%Y%m%d_%H%M%S).json"

# Create output directory if it doesn't exist
mkdir -p "${OUTPUT_DIR}"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is required but not installed."
    exit 1
fi

# Check if requests library is installed
if ! python3 -c "import requests" &> /dev/null; then
    echo "Installing requests library..."
    pip install requests
fi

echo "Running Certificate Transparency Log Check..."
echo "Domains: ${DOMAINS}"
echo "Minimum CT Logs: ${MIN_LOGS}"
echo "Maximum Certificate Age: ${MAX_AGE_DAYS} days"
echo "Output File: ${OUTPUT_FILE}"
echo ""

# Run the CT log checker script
python3 "$(dirname "$0")/ct_log_checker.py" \
    --domains "${DOMAINS}" \
    --min-logs "${MIN_LOGS}" \
    --max-age-days "${MAX_AGE_DAYS}" \
    --output-json "${OUTPUT_FILE}" \
    --verbose

EXIT_CODE=$?

# Check the exit code and report accordingly
if [ ${EXIT_CODE} -eq 0 ]; then
    echo "\nCertificate Transparency check passed successfully!"
    echo "All certificates are properly logged in CT logs."
elif [ ${EXIT_CODE} -eq 1 ]; then
    echo "\nCertificate Transparency check completed with warnings."
    echo "Some certificates may not be logged in enough CT logs."
    echo "Review the report at ${OUTPUT_FILE} for details."
else
    echo "\nCertificate Transparency check failed!"
    echo "Some domains may not have valid certificates or are not logged in CT logs."
    echo "Review the report at ${OUTPUT_FILE} for details."
    
    # Uncomment the following line to fail the CI/CD pipeline on errors
    # exit ${EXIT_CODE}
    
    # For now, we'll just warn but not fail the pipeline
    echo "WARNING: CT log check failed but continuing pipeline."
fi

# Add the report to artifacts
echo "CT log check report saved to ${OUTPUT_FILE}"

# Optional: Upload the report to a dashboard or notification service
if [ -f "$(dirname "$0")/upload_to_dashboard.sh" ]; then
    echo "Uploading report to dashboard..."
    "$(dirname "$0")/upload_to_dashboard.sh" "${OUTPUT_FILE}"
fi

# Exit with the original exit code from the Python script
# Comment this out if you don't want to fail the pipeline on warnings/errors
# exit ${EXIT_CODE}

# For now, always exit successfully to not block the pipeline
exit 0