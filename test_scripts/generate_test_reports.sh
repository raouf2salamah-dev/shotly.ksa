#!/bin/bash

# Script to generate and merge test reports from Flutter tests and security tests
# and upload them to a central location

set -e

# Define variables
REPORTS_DIR="../reports"
SECURITY_REPORTS_DIR="$REPORTS_DIR/security"
FLUTTER_REPORTS_DIR="$REPORTS_DIR/flutter"
MERGED_REPORTS_DIR="$REPORTS_DIR/merged"
LCOV_REPORT="$FLUTTER_REPORTS_DIR/lcov.info"
MERGED_LCOV_REPORT="$MERGED_REPORTS_DIR/merged_lcov.info"
HTML_REPORT_DIR="$MERGED_REPORTS_DIR/html"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Parse command line arguments
UPLOAD_TARGET=""
CI_MODE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --upload-to)
      UPLOAD_TARGET="$2"
      shift 2
      ;;
    --ci-mode)
      CI_MODE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Create necessary directories
mkdir -p "$REPORTS_DIR"
mkdir -p "$SECURITY_REPORTS_DIR"
mkdir -p "$FLUTTER_REPORTS_DIR"
mkdir -p "$MERGED_REPORTS_DIR"
mkdir -p "$HTML_REPORT_DIR"

echo "Generating test reports..."

# Run Flutter tests with coverage
echo "Running Flutter tests with coverage..."
cd ..
flutter test --coverage

# Check if lcov.info was generated
if [ -f "coverage/lcov.info" ]; then
  cp coverage/lcov.info "$LCOV_REPORT"
  echo "Flutter test coverage report generated at $LCOV_REPORT"
else
  echo "Warning: Flutter test coverage report not found"
fi

# Run security tests if not already run
cd test_scripts
if [ ! -f "$SECURITY_REPORTS_DIR/ci_certificate_pinning_test.json" ]; then
  echo "Running certificate pinning test..."
  ./ci_certificate_pinning_test.sh --ci-mode
fi

# Create a merged report index
cat > "$MERGED_REPORTS_DIR/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
  <title>Test Reports</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    .container { border: 1px solid #ddd; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
    h1, h2 { color: #333; }
    .report-link { margin: 10px 0; }
    .timestamp { color: #666; font-size: 0.9em; }
  </style>
</head>
<body>
  <h1>Test Reports</h1>
  <div class="timestamp">Generated on: $TIMESTAMP</div>
  
  <div class="container">
    <h2>Security Tests</h2>
    <div class="report-link">
      <a href="../security/ci_certificate_pinning_test.html">Certificate Pinning Test Report</a>
    </div>
  </div>
  
  <div class="container">
    <h2>Flutter Tests</h2>
    <div class="report-link">
      <a href="html/index.html">Coverage Report</a>
    </div>
  </div>
</body>
</html>
EOF

# Generate HTML report from LCOV data if lcov is installed
if command -v genhtml >/dev/null 2>&1; then
  if [ -f "$LCOV_REPORT" ]; then
    echo "Generating HTML coverage report..."
    genhtml "$LCOV_REPORT" -o "$HTML_REPORT_DIR" --title="Flutter Test Coverage"
    echo "HTML coverage report generated at $HTML_REPORT_DIR"
  fi
else
  echo "Warning: genhtml command not found. Install lcov to generate HTML reports."
fi

# Upload reports if requested
if [ -n "$UPLOAD_TARGET" ]; then
  echo "Uploading reports to $UPLOAD_TARGET..."
  
  case "$UPLOAD_TARGET" in
    s3://*)  # AWS S3
      if command -v aws >/dev/null 2>&1; then
        aws s3 sync "$REPORTS_DIR" "$UPLOAD_TARGET" --delete
        echo "Reports uploaded to AWS S3: $UPLOAD_TARGET"
      else
        echo "Error: AWS CLI not installed. Cannot upload to S3."
        [ "$CI_MODE" = true ] && exit 1
      fi
      ;;
      
    gs://*)  # Google Cloud Storage
      if command -v gsutil >/dev/null 2>&1; then
        gsutil -m rsync -r "$REPORTS_DIR" "$UPLOAD_TARGET"
        echo "Reports uploaded to Google Cloud Storage: $UPLOAD_TARGET"
      else
        echo "Error: gsutil not installed. Cannot upload to Google Cloud Storage."
        [ "$CI_MODE" = true ] && exit 1
      fi
      ;;
      
    *)  # Default to local directory
      echo "Unknown upload target format: $UPLOAD_TARGET"
      echo "Supported formats: s3://<bucket-name>, gs://<bucket-name>"
      [ "$CI_MODE" = true ] && exit 1
      ;;
  esac
fi

echo "Test report generation completed."
echo "Reports available at: $REPORTS_DIR"

exit 0