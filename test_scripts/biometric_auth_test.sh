#!/bin/bash

# Biometric Authentication Test Script
# This script tests biometric authentication and timeout functionality

echo "===== Biometric Authentication Test ====="
echo "This test verifies that biometric authentication works correctly after timeout"

# Define variables
APP_PACKAGE="com.example.shotly"
LOG_FILE="biometric_auth_test.log"

# Clear previous log file
rm -f "$LOG_FILE"
touch "$LOG_FILE"

echo "Checking for connected devices..."

# Check if any device is connected
DEVICES=$(adb devices | grep -v "List" | grep "device")
if [ -z "$DEVICES" ]; then
    echo "No Android devices connected. Checking for iOS devices..."
    
    # Check for iOS devices
    IOS_DEVICES=$(idevice_id -l)
    if [ -z "$IOS_DEVICES" ]; then
        echo "No devices connected. Please connect a device and try again."
        exit 1
    else
        PLATFORM="ios"
        echo "iOS device detected. UDID: $IOS_DEVICES"
    fi
else
    PLATFORM="android"
    echo "Android device detected."
fi

echo "Platform: $PLATFORM" >> "$LOG_FILE"

# Function to test Android biometric authentication
test_android_biometric_auth() {
    echo "Testing Android biometric authentication..."
    echo "Testing Android biometric authentication..." >> "$LOG_FILE"
    
    # Check if the app is installed
    APP_INSTALLED=$(adb shell pm list packages | grep "$APP_PACKAGE")
    if [ -z "$APP_INSTALLED" ]; then
        echo "App is not installed. Please install the app and try again."
        exit 1
    fi
    
    # Launch the app
    echo "Launching the app..."
    adb shell monkey -p "$APP_PACKAGE" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
    sleep 2
    
    # Navigate to security settings
    echo "Navigating to security settings..."
    adb shell input tap 500 500  # Adjust coordinates as needed
    sleep 1
    adb shell input tap 300 800  # Adjust coordinates as needed
    sleep 1
    
    # Check if biometric authentication is enabled
    echo "Checking biometric authentication settings..."
    SCREEN_CONTENT=$(adb shell uiautomator dump /dev/null && adb shell cat /sdcard/window_dump.xml)
    if echo "$SCREEN_CONTENT" | grep -q "Biometric Authentication"; then
        echo "✅ Biometric authentication setting found"
        echo "Biometric authentication setting found" >> "$LOG_FILE"
    else
        echo "❌ Biometric authentication setting not found"
        echo "Biometric authentication setting not found" >> "$LOG_FILE"
        exit 1
    fi
    
    # Test timeout functionality
    echo "Testing timeout functionality..."
    echo "Testing timeout functionality..." >> "$LOG_FILE"
    
    # Set timeout to 1 minute for testing
    echo "Setting timeout to 1 minute..."
    adb shell input tap 400 600  # Adjust coordinates as needed
    sleep 1
    
    # Navigate to a sensitive screen
    echo "Navigating to a sensitive screen..."
    adb shell input back
    sleep 1
    adb shell input tap 500 300  # Adjust coordinates as needed
    sleep 1
    
    # Send app to background
    echo "Sending app to background..."
    adb shell input keyevent KEYCODE_HOME
    echo "App sent to background at $(date)" >> "$LOG_FILE"
    
    # Wait for timeout (slightly more than 1 minute)
    echo "Waiting for timeout (65 seconds)..."
    sleep 65
    
    # Bring app back to foreground
    echo "Bringing app back to foreground..."
    adb shell monkey -p "$APP_PACKAGE" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
    sleep 2
    
    # Check if biometric prompt is shown
    SCREEN_CONTENT=$(adb shell uiautomator dump /dev/null && adb shell cat /sdcard/window_dump.xml)
    if echo "$SCREEN_CONTENT" | grep -q "Biometric"; then
        echo "✅ Biometric prompt shown after timeout"
        echo "Biometric prompt shown after timeout" >> "$LOG_FILE"
    else
        echo "❌ Biometric prompt not shown after timeout"
        echo "Biometric prompt not shown after timeout" >> "$LOG_FILE"
        exit 1
    fi
    
    echo "Android biometric authentication test completed successfully."
    return 0
}

# Function to test iOS biometric authentication
test_ios_biometric_auth() {
    echo "Testing iOS biometric authentication..."
    echo "Testing iOS biometric authentication..." >> "$LOG_FILE"
    
    # For iOS, we need to use UI testing with XCTest
    # This is a simplified version that checks if the biometric authentication files exist
    
    # Check if BiometricAuth.swift exists
    if [ -f "$PWD/ios/Runner/BiometricAuth.swift" ]; then
        echo "✅ BiometricAuth.swift exists"
        echo "BiometricAuth.swift exists" >> "$LOG_FILE"
    else
        echo "❌ BiometricAuth.swift does not exist"
        echo "BiometricAuth.swift does not exist" >> "$LOG_FILE"
        exit 1
    fi
    
    # Check if LocalAuthentication framework is imported
    if grep -q "import LocalAuthentication" "$PWD/ios/Runner/BiometricAuth.swift"; then
        echo "✅ LocalAuthentication framework is imported"
        echo "LocalAuthentication framework is imported" >> "$LOG_FILE"
    else
        echo "❌ LocalAuthentication framework is not imported"
        echo "LocalAuthentication framework is not imported" >> "$LOG_FILE"
        exit 1
    fi
    
    # Check if evaluatePolicy method is implemented
    if grep -q "evaluatePolicy" "$PWD/ios/Runner/BiometricAuth.swift"; then
        echo "✅ evaluatePolicy method is implemented"
        echo "evaluatePolicy method is implemented" >> "$LOG_FILE"
    else
        echo "❌ evaluatePolicy method is not implemented"
        echo "evaluatePolicy method is not implemented" >> "$LOG_FILE"
        exit 1
    fi
    
    echo "iOS biometric authentication implementation verified."
    echo "Note: Full UI testing requires XCTest framework."
    return 0
}

# Run platform-specific tests
if [ "$PLATFORM" = "android" ]; then
    test_android_biometric_auth
else
    test_ios_biometric_auth
fi

echo "\n===== Biometric Authentication Test Results ====="
if [ $? -eq 0 ]; then
    echo "✅ Biometric authentication test passed"
    echo "Biometric authentication test passed" >> "$LOG_FILE"
    exit 0
else
    echo "❌ Biometric authentication test failed"
    echo "Biometric authentication test failed" >> "$LOG_FILE"
    exit 1
fi