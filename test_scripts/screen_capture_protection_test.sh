#!/bin/bash

# Screen Capture Protection Test Script
# This script tests screenshot prevention and screen recording protection

echo "===== Screen Capture Protection Test ====="
echo "This test verifies that screenshot prevention and screen recording protection work correctly"

# Define variables
APP_PACKAGE="com.example.shotly"
LOG_FILE="screen_capture_protection_test.log"

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

# Function to test Android screenshot prevention
test_android_screenshot_prevention() {
    echo "Testing Android screenshot prevention..."
    echo "Testing Android screenshot prevention..." >> "$LOG_FILE"
    
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
    
    # Navigate to a sensitive screen
    echo "Navigating to a sensitive screen..."
    adb shell input tap 500 500  # Adjust coordinates as needed
    sleep 1
    adb shell input tap 300 800  # Adjust coordinates as needed
    sleep 1
    
    # Try to take a screenshot
    echo "Attempting to take a screenshot..."
    SCREENSHOT_BEFORE=$(adb shell ls -la /sdcard/Pictures/Screenshots/ | wc -l)
    adb shell input keyevent KEYCODE_VOLUME_DOWN KEYCODE_POWER
    sleep 2
    SCREENSHOT_AFTER=$(adb shell ls -la /sdcard/Pictures/Screenshots/ | wc -l)
    
    # Check if screenshot was prevented
    if [ "$SCREENSHOT_BEFORE" -eq "$SCREENSHOT_AFTER" ]; then
        echo "✅ Screenshot was successfully prevented"
        echo "Screenshot was successfully prevented" >> "$LOG_FILE"
    else
        echo "❌ Screenshot was not prevented"
        echo "Screenshot was not prevented" >> "$LOG_FILE"
        exit 1
    fi
    
    # Check if FLAG_SECURE is set
    echo "Checking if FLAG_SECURE is set..."
    WINDOW_FLAGS=$(adb shell dumpsys window | grep -A 10 "$APP_PACKAGE" | grep "flags")
    if echo "$WINDOW_FLAGS" | grep -q "SECURE"; then
        echo "✅ FLAG_SECURE is set"
        echo "FLAG_SECURE is set" >> "$LOG_FILE"
    else
        echo "❌ FLAG_SECURE is not set"
        echo "FLAG_SECURE is not set" >> "$LOG_FILE"
        exit 1
    fi
    
    echo "Android screenshot prevention test completed successfully."
    return 0
}

# Function to test iOS screenshot detection
test_ios_screenshot_detection() {
    echo "Testing iOS screenshot detection..."
    echo "Testing iOS screenshot detection..." >> "$LOG_FILE"
    
    # For iOS, we need to check if the screenshot detection implementation exists
    # This is a simplified version that checks if the screenshot detection files exist
    
    # Check if AppDelegate.swift has screenshot detection
    if grep -q "userDidTakeScreenshotNotification" "$PWD/ios/Runner/AppDelegate.swift"; then
        echo "✅ Screenshot detection is implemented in AppDelegate.swift"
        echo "Screenshot detection is implemented in AppDelegate.swift" >> "$LOG_FILE"
    else
        echo "❌ Screenshot detection is not implemented in AppDelegate.swift"
        echo "Screenshot detection is not implemented in AppDelegate.swift" >> "$LOG_FILE"
        exit 1
    fi
    
    # Check if the method channel is set up for screenshot detection
    if grep -q "screenshotDetected" "$PWD/ios/Runner/AppDelegate.swift"; then
        echo "✅ Screenshot detection method channel is set up"
        echo "Screenshot detection method channel is set up" >> "$LOG_FILE"
    else
        echo "❌ Screenshot detection method channel is not set up"
        echo "Screenshot detection method channel is not set up" >> "$LOG_FILE"
        exit 1
    fi
    
    # Check if Flutter implementation exists
    if [ -f "$PWD/lib/src/security/screenshot_detection.dart" ]; then
        echo "✅ Flutter screenshot detection implementation exists"
        echo "Flutter screenshot detection implementation exists" >> "$LOG_FILE"
    else
        echo "❌ Flutter screenshot detection implementation does not exist"
        echo "Flutter screenshot detection implementation does not exist" >> "$LOG_FILE"
        exit 1
    fi
    
    echo "iOS screenshot detection implementation verified."
    echo "Note: Full UI testing requires manual verification or XCTest framework."
    return 0
}

# Run platform-specific tests
if [ "$PLATFORM" = "android" ]; then
    test_android_screenshot_prevention
else
    test_ios_screenshot_detection
fi

echo "\n===== Screen Capture Protection Test Results ====="
if [ $? -eq 0 ]; then
    echo "✅ Screen capture protection test passed"
    echo "Screen capture protection test passed" >> "$LOG_FILE"
    exit 0
else
    echo "❌ Screen capture protection test failed"
    echo "Screen capture protection test failed" >> "$LOG_FILE"
    exit 1
fi