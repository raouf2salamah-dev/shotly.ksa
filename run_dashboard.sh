#!/bin/bash

# Script to run the security dashboard web app
echo "Starting Security Dashboard Web App..."

# Navigate to project directory
cd "$(dirname "$0")"

# Run the Flutter web app in debug mode
flutter run -d chrome --web-port=8080 --target=lib/dashboard/main_dashboard.dart