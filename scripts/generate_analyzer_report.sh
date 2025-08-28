#!/bin/bash

# Script to generate Flutter analyzer report for SonarQube integration

echo "Generating Flutter analyzer report for SonarQube..."

# Create directory for the report if it doesn't exist
mkdir -p reports

# Run Flutter analyze with custom format
flutter analyze --write=reports/analyze-report.json

# Check if the report was generated successfully
if [ -f "reports/analyze-report.json" ]; then
    echo "✅ Flutter analyzer report generated successfully at reports/analyze-report.json"
    # Copy to project root for SonarQube to find it
    cp reports/analyze-report.json analyze-report.json
    echo "✅ Report copied to project root for SonarQube"
    exit 0
else
    echo "❌ Failed to generate Flutter analyzer report"
    exit 1
fi