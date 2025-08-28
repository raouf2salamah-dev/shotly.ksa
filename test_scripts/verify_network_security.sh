#!/bin/bash

# Test script to verify network security configuration in Android app
# This script tests if cleartext traffic is properly blocked

echo "===== Network Security Configuration Verification ====="
echo "This script will test if the app properly blocks cleartext traffic"
echo ""

# Check if Android device is connected
echo "Checking for connected Android devices..."
devices=$(adb devices | grep -v "List" | grep "device")
if [ -z "$devices" ]; then
  echo "❌ No Android devices connected. Please connect a device or start an emulator."
  exit 1
fi
echo "✅ Android device found"
echo ""

# Install the app if it's not already installed
app_package="com.example.shotly" # Replace with your actual package name
echo "Checking if app is installed..."
app_installed=$(adb shell pm list packages | grep $app_package)
if [ -z "$app_installed" ]; then
  echo "App not installed. Installing from local build..."
  adb install -r "../build/app/outputs/flutter-apk/app-debug.apk"
  if [ $? -ne 0 ]; then
    echo "❌ Failed to install app. Make sure you've built the app first."
    exit 1
  fi
fi
echo "✅ App is installed"
echo ""

# Test 1: Attempt cleartext HTTP request
echo "Test 1: Attempting cleartext HTTP request (should fail)..."
echo "Starting app with test flag..."
adb shell am start -n "$app_package/$app_package.MainActivity" --ez "TEST_CLEARTEXT" "true"

# Wait for logs
sleep 3
echo "Checking logs for cleartext blocking..."
blocked_logs=$(adb logcat -d | grep -E "(CLEARTEXT.*not permitted|CleartextTraffic.*blocked)" | tail -n 5)

if [ -n "$blocked_logs" ]; then
  echo "✅ Test passed! Cleartext traffic was properly blocked:"
  echo "$blocked_logs"
else
  echo "❌ Test failed! Cleartext traffic might not be blocked properly."
  echo "Check your network security configuration."
fi
echo ""

# Test 2: Verify HTTPS works
echo "Test 2: Verifying HTTPS requests work properly..."
echo "Starting app with secure test flag..."
adb shell am start -n "$app_package/$app_package.MainActivity" --ez "TEST_HTTPS" "true"

# Wait for logs
sleep 3
echo "Checking logs for successful HTTPS connections..."
success_logs=$(adb logcat -d | grep -E "(HTTPS.*success|Secure connection successful)" | tail -n 5)

if [ -n "$success_logs" ]; then
  echo "✅ Test passed! HTTPS connections work properly:"
  echo "$success_logs"
else
  echo "⚠️ Could not verify HTTPS connections."
  echo "This might be normal if your app doesn't log successful connections."
fi
echo ""

echo "===== Network Security Tests Complete ====="
echo "Remember to implement test hooks in your app to fully utilize this script."
echo "See the network_security_config_guide.md for more information."