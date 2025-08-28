#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo "${YELLOW}=== Running Flutter pub get ===${NC}"
flutter pub get

echo "${YELLOW}=== Generating mock classes ===${NC}"
flutter pub run build_runner build --delete-conflicting-outputs

echo "${YELLOW}=== Running widget tests ===${NC}"
flutter test --coverage

echo "${YELLOW}=== Running integration tests ===${NC}"
flutter test integration_test/app_test.dart

echo "${YELLOW}=== Generating coverage report ===${NC}"
if command -v lcov >/dev/null 2>&1; then
  genhtml coverage/lcov.info -o coverage/html
  echo "${GREEN}Coverage report generated at coverage/html/index.html${NC}"
  
  # Open coverage report if on macOS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    open coverage/html/index.html
  fi
else
  echo "${RED}lcov not installed. Cannot generate HTML coverage report.${NC}"
  echo "${YELLOW}Install lcov with: brew install lcov (macOS) or apt-get install lcov (Linux)${NC}"
fi

echo "${GREEN}=== All tests completed! ===${NC}"