#!/bin/bash

# BrowserStack App Automate Upload Script
# This script builds and uploads your app to BrowserStack for testing

# Configuration
BS_USERNAME="abdulraoufsalamah"
BS_ACCESS_KEY="your_access_key"
APP_DISPLAY_NAME="Pro App"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Building and uploading app to BrowserStack...${NC}"

# Check if credentials are set
if [ "$BS_USERNAME" = "YOUR_BROWSERSTACK_USERNAME" ] || [ "$BS_ACCESS_KEY" = "YOUR_BROWSERSTACK_ACCESS_KEY" ]; then
  echo -e "${RED}Error: Please set your BrowserStack credentials in this script${NC}"
  exit 1
fi

# Build the app for Android
echo -e "${YELLOW}Building Android APK...${NC}"
flutter build apk --release

# Check if build was successful
if [ $? -ne 0 ]; then
  echo -e "${RED}Android build failed!${NC}"
  exit 1
fi

ANDROID_PATH="build/app/outputs/flutter-apk/app-release.apk"

# Check if APK exists
if [ ! -f "$ANDROID_PATH" ]; then
  echo -e "${RED}APK not found at $ANDROID_PATH${NC}"
  exit 1
fi

# Upload Android app to BrowserStack
echo -e "${YELLOW}Uploading Android app to BrowserStack...${NC}"
ANDROID_RESPONSE=$(curl -u "$BS_USERNAME:$BS_ACCESS_KEY" \
  -X POST "https://api-cloud.browserstack.com/app-automate/upload" \
  -F "file=@$ANDROID_PATH" \
  -F "custom_id=pro_android")

ANDROID_APP_URL=$(echo $ANDROID_RESPONSE | grep -o 'bs://[a-zA-Z0-9]*')

if [ -z "$ANDROID_APP_URL" ]; then
  echo -e "${RED}Failed to upload Android app to BrowserStack${NC}"
  echo "Response: $ANDROID_RESPONSE"
else
  echo -e "${GREEN}Android app uploaded successfully!${NC}"
  echo -e "App URL: ${YELLOW}$ANDROID_APP_URL${NC}"
fi

# Build the app for iOS
echo -e "${YELLOW}Building iOS app...${NC}"
flutter build ios --release --no-codesign

# Check if build was successful
if [ $? -ne 0 ]; then
  echo -e "${RED}iOS build failed!${NC}"
  exit 1
fi

# Create IPA file
echo -e "${YELLOW}Creating IPA file...${NC}"
mkdir -p Payload
cp -r build/ios/iphoneos/Runner.app Payload/
zip -r app.ipa Payload
rm -rf Payload

# Check if IPA exists
if [ ! -f "app.ipa" ]; then
  echo -e "${RED}IPA not found${NC}"
  exit 1
fi

# Upload iOS app to BrowserStack
echo -e "${YELLOW}Uploading iOS app to BrowserStack...${NC}"
IOS_RESPONSE=$(curl -u "$BS_USERNAME:$BS_ACCESS_KEY" \
  -X POST "https://api-cloud.browserstack.com/app-automate/upload" \
  -F "file=@app.ipa" \
  -F "custom_id=pro_ios")

IOS_APP_URL=$(echo $IOS_RESPONSE | grep -o 'bs://[a-zA-Z0-9]*')

if [ -z "$IOS_APP_URL" ]; then
  echo -e "${RED}Failed to upload iOS app to BrowserStack${NC}"
  echo "Response: $IOS_RESPONSE"
else
  echo -e "${GREEN}iOS app uploaded successfully!${NC}"
  echo -e "App URL: ${YELLOW}$IOS_APP_URL${NC}"
fi

# Clean up
rm -f app.ipa

echo -e "${GREEN}Upload process completed!${NC}"
echo -e "${YELLOW}You can now run tests on BrowserStack using these app URLs${NC}"
echo -e "${YELLOW}Android: $ANDROID_APP_URL${NC}"
echo -e "${YELLOW}iOS: $IOS_APP_URL${NC}"
echo -e "${YELLOW}Visit https://app-automate.browserstack.com/ to manage your tests${NC}"

# Log security event
echo "SecurityLogger.log('AppUploaded', detail: 'BrowserStack upload for testing');" > /tmp/security_log.txt