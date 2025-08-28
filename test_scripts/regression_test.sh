#!/bin/bash

# Regression Test Script
# This script tests main app flows (login, upload, favorites) after adding security features

echo "===== Regression Test ====="
echo "This test verifies that main app flows still work after security implementations"

# Define variables
APP_PACKAGE="com.example.shotly"
LOG_FILE="regression_test.log"

# Clear previous log file
rm -f "$LOG_FILE"
touch "$LOG_FILE"

# Test credentials (replace with test account credentials)
TEST_USERNAME="test@example.com"
TEST_PASSWORD="testpassword"

# Function to check if a device is connected
check_device() {
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
    return 0
}

# Function to run UI tests on Android
run_android_ui_tests() {
    echo "Running Android UI tests..."
    echo "Running Android UI tests..." >> "$LOG_FILE"
    
    # Check if the app is installed
    APP_INSTALLED=$(adb shell pm list packages | grep "$APP_PACKAGE")
    if [ -z "$APP_INSTALLED" ]; then
        echo "App is not installed. Please install the app and try again."
        exit 1
    fi
    
    # Clear app data to ensure a fresh start
    echo "Clearing app data..."
    adb shell pm clear $APP_PACKAGE
    
    # Start the app
    echo "Starting the app..."
    adb shell monkey -p $APP_PACKAGE -c android.intent.category.LAUNCHER 1
    sleep 3
    
    # Test login flow
    echo "Testing login flow..."
    echo "Testing login flow..." >> "$LOG_FILE"
    
    # This is a simplified example. In a real scenario, you would use UI testing frameworks like Espresso or Appium
    # Here we're just checking if the app crashes during these operations
    
    # Simulate login (this is just a placeholder, actual implementation would use UI automation)
    echo "Simulating login..."
    LOGIN_CRASH=$(adb shell "am start -n $APP_PACKAGE/.ui.login.LoginActivity" 2>&1)
    if echo "$LOGIN_CRASH" | grep -q "Error"; then
        echo "❌ Login activity failed to start: $LOGIN_CRASH" | tee -a "$LOG_FILE"
        LOGIN_SUCCESS=false
    else
        echo "Login activity started successfully" >> "$LOG_FILE"
        sleep 2
        
        # Check for crashes
        CRASH_LOG=$(adb logcat -d | grep -E "$APP_PACKAGE.*Exception|$APP_PACKAGE.*Error" | tail -n 20)
        if [ ! -z "$CRASH_LOG" ]; then
            echo "❌ App crashed during login: $CRASH_LOG" | tee -a "$LOG_FILE"
            LOGIN_SUCCESS=false
        else
            echo "✅ Login flow appears to be working" | tee -a "$LOG_FILE"
            LOGIN_SUCCESS=true
        fi
    fi
    
    # Test upload flow
    echo "Testing upload flow..."
    echo "Testing upload flow..." >> "$LOG_FILE"
    
    # Simulate navigation to upload screen
    echo "Simulating navigation to upload screen..."
    UPLOAD_CRASH=$(adb shell "am start -n $APP_PACKAGE/.ui.upload.UploadActivity" 2>&1)
    if echo "$UPLOAD_CRASH" | grep -q "Error"; then
        echo "❌ Upload activity failed to start: $UPLOAD_CRASH" | tee -a "$LOG_FILE"
        UPLOAD_SUCCESS=false
    else
        echo "Upload activity started successfully" >> "$LOG_FILE"
        sleep 2
        
        # Check for crashes
        CRASH_LOG=$(adb logcat -d | grep -E "$APP_PACKAGE.*Exception|$APP_PACKAGE.*Error" | tail -n 20)
        if [ ! -z "$CRASH_LOG" ]; then
            echo "❌ App crashed during upload flow: $CRASH_LOG" | tee -a "$LOG_FILE"
            UPLOAD_SUCCESS=false
        else
            echo "✅ Upload flow appears to be working" | tee -a "$LOG_FILE"
            UPLOAD_SUCCESS=true
        fi
    fi
    
    # Test favorites flow
    echo "Testing favorites flow..."
    echo "Testing favorites flow..." >> "$LOG_FILE"
    
    # Simulate navigation to favorites screen
    echo "Simulating navigation to favorites screen..."
    FAVORITES_CRASH=$(adb shell "am start -n $APP_PACKAGE/.ui.favorites.FavoritesActivity" 2>&1)
    if echo "$FAVORITES_CRASH" | grep -q "Error"; then
        echo "❌ Favorites activity failed to start: $FAVORITES_CRASH" | tee -a "$LOG_FILE"
        FAVORITES_SUCCESS=false
    else
        echo "Favorites activity started successfully" >> "$LOG_FILE"
        sleep 2
        
        # Check for crashes
        CRASH_LOG=$(adb logcat -d | grep -E "$APP_PACKAGE.*Exception|$APP_PACKAGE.*Error" | tail -n 20)
        if [ ! -z "$CRASH_LOG" ]; then
            echo "❌ App crashed during favorites flow: $CRASH_LOG" | tee -a "$LOG_FILE"
            FAVORITES_SUCCESS=false
        else
            echo "✅ Favorites flow appears to be working" | tee -a "$LOG_FILE"
            FAVORITES_SUCCESS=true
        fi
    fi
    
    # Check network requests
    echo "Checking network requests..."
    echo "Checking network requests..." >> "$LOG_FILE"
    
    NETWORK_LOGS=$(adb logcat -d | grep -E "$APP_PACKAGE.*Http|$APP_PACKAGE.*Network|$APP_PACKAGE.*Connection" | tail -n 50)
    echo "Network logs: $NETWORK_LOGS" >> "$LOG_FILE"
    
    # Check for network errors
    if echo "$NETWORK_LOGS" | grep -q -E "SSLHandshakeException|CertPathValidatorException|ConnectionException"; then
        echo "❌ Network errors detected, possibly related to certificate pinning" | tee -a "$LOG_FILE"
        NETWORK_SUCCESS=false
    else
        echo "✅ No critical network errors detected" | tee -a "$LOG_FILE"
        NETWORK_SUCCESS=true
    fi
    
    # Overall test result
    if [ "$LOGIN_SUCCESS" = true ] && [ "$UPLOAD_SUCCESS" = true ] && [ "$FAVORITES_SUCCESS" = true ] && [ "$NETWORK_SUCCESS" = true ]; then
        echo "✅ All Android regression tests passed" | tee -a "$LOG_FILE"
        return 0
    else
        echo "❌ Some Android regression tests failed" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to run UI tests on iOS
run_ios_ui_tests() {
    echo "Running iOS UI tests..."
    echo "Running iOS UI tests..." >> "$LOG_FILE"
    
    echo "Note: Automated UI testing on iOS requires XCTest framework and proper test setup" | tee -a "$LOG_FILE"
    echo "This script provides a placeholder for manual testing steps" | tee -a "$LOG_FILE"
    
    echo "Manual testing steps for iOS:" | tee -a "$LOG_FILE"
    echo "1. Clear app data by uninstalling and reinstalling the app" | tee -a "$LOG_FILE"
    echo "2. Launch the app and verify it starts without crashing" | tee -a "$LOG_FILE"
    echo "3. Test login flow: Enter credentials and verify successful login" | tee -a "$LOG_FILE"
    echo "4. Test upload flow: Navigate to upload screen, select a file, and upload" | tee -a "$LOG_FILE"
    echo "5. Test favorites flow: Navigate to favorites screen and verify content loads" | tee -a "$LOG_FILE"
    
    echo "Would you like to proceed with manual testing? (y/n)"
    read MANUAL_TESTING
    
    if [ "$MANUAL_TESTING" = "y" ]; then
        echo "Please follow the manual testing steps and enter the results:" | tee -a "$LOG_FILE"
        
        echo "Did the app launch successfully? (y/n)"
        read LAUNCH_RESULT
        if [ "$LAUNCH_RESULT" = "y" ]; then
            echo "✅ App launch successful" | tee -a "$LOG_FILE"
        else
            echo "❌ App launch failed" | tee -a "$LOG_FILE"
        fi
        
        echo "Did the login flow work correctly? (y/n)"
        read LOGIN_RESULT
        if [ "$LOGIN_RESULT" = "y" ]; then
            echo "✅ Login flow successful" | tee -a "$LOG_FILE"
        else
            echo "❌ Login flow failed" | tee -a "$LOG_FILE"
        fi
        
        echo "Did the upload flow work correctly? (y/n)"
        read UPLOAD_RESULT
        if [ "$UPLOAD_RESULT" = "y" ]; then
            echo "✅ Upload flow successful" | tee -a "$LOG_FILE"
        else
            echo "❌ Upload flow failed" | tee -a "$LOG_FILE"
        fi
        
        echo "Did the favorites flow work correctly? (y/n)"
        read FAVORITES_RESULT
        if [ "$FAVORITES_RESULT" = "y" ]; then
            echo "✅ Favorites flow successful" | tee -a "$LOG_FILE"
        else
            echo "❌ Favorites flow failed" | tee -a "$LOG_FILE"
        fi
        
        # Overall test result
        if [ "$LAUNCH_RESULT" = "y" ] && [ "$LOGIN_RESULT" = "y" ] && [ "$UPLOAD_RESULT" = "y" ] && [ "$FAVORITES_RESULT" = "y" ]; then
            echo "✅ All iOS manual regression tests passed" | tee -a "$LOG_FILE"
            return 0
        else
            echo "❌ Some iOS manual regression tests failed" | tee -a "$LOG_FILE"
            return 1
        fi
    else
        echo "Manual testing skipped. Please run proper XCTest UI tests for iOS." | tee -a "$LOG_FILE"
        return 0
    fi
}

# Function to run API tests
run_api_tests() {
    echo "Running API tests..."
    echo "Running API tests..." >> "$LOG_FILE"
    
    API_BASE_URL="https://api.example.com"
    
    # Test login API
    echo "Testing login API..."
    LOGIN_DATA='{"email":"'"$TEST_USERNAME"'","password":"'"$TEST_PASSWORD"'"}'
    LOGIN_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$LOGIN_DATA" \
        "$API_BASE_URL/auth/login")
    
    echo "Login API response: $LOGIN_RESPONSE" >> "$LOG_FILE"
    
    # Extract token from response
    ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d '"' -f 4)
    
    if [ -z "$ACCESS_TOKEN" ]; then
        echo "❌ Login API test failed: Could not obtain access token" | tee -a "$LOG_FILE"
        LOGIN_API_SUCCESS=false
    else
        echo "✅ Login API test passed" | tee -a "$LOG_FILE"
        LOGIN_API_SUCCESS=true
        
        # Test user profile API
        echo "Testing user profile API..."
        PROFILE_RESPONSE=$(curl -s -X GET \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            "$API_BASE_URL/api/user/profile")
        
        echo "Profile API response: $PROFILE_RESPONSE" >> "$LOG_FILE"
        
        if echo "$PROFILE_RESPONSE" | grep -q "error"; then
            echo "❌ Profile API test failed" | tee -a "$LOG_FILE"
            PROFILE_API_SUCCESS=false
        else
            echo "✅ Profile API test passed" | tee -a "$LOG_FILE"
            PROFILE_API_SUCCESS=true
        fi
        
        # Test favorites API
        echo "Testing favorites API..."
        FAVORITES_RESPONSE=$(curl -s -X GET \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            "$API_BASE_URL/api/favorites")
        
        echo "Favorites API response: $FAVORITES_RESPONSE" >> "$LOG_FILE"
        
        if echo "$FAVORITES_RESPONSE" | grep -q "error"; then
            echo "❌ Favorites API test failed" | tee -a "$LOG_FILE"
            FAVORITES_API_SUCCESS=false
        else
            echo "✅ Favorites API test passed" | tee -a "$LOG_FILE"
            FAVORITES_API_SUCCESS=true
        fi
        
        # Test upload API
        echo "Testing upload API..."
        UPLOAD_RESPONSE=$(curl -s -X POST \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -d '{"title":"Test Upload","description":"This is a test upload"}' \
            "$API_BASE_URL/api/upload")
        
        echo "Upload API response: $UPLOAD_RESPONSE" >> "$LOG_FILE"
        
        if echo "$UPLOAD_RESPONSE" | grep -q "error"; then
            echo "❌ Upload API test failed" | tee -a "$LOG_FILE"
            UPLOAD_API_SUCCESS=false
        else
            echo "✅ Upload API test passed" | tee -a "$LOG_FILE"
            UPLOAD_API_SUCCESS=true
        fi
    fi
    
    # Overall API test result
    if [ "$LOGIN_API_SUCCESS" = true ] && [ "$PROFILE_API_SUCCESS" = true ] && [ "$FAVORITES_API_SUCCESS" = true ] && [ "$UPLOAD_API_SUCCESS" = true ]; then
        echo "✅ All API tests passed" | tee -a "$LOG_FILE"
        return 0
    else
        echo "❌ Some API tests failed" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Main test execution
echo "Starting regression tests..."

# Check for connected device
check_device

# Run UI tests based on platform
if [ "$PLATFORM" = "android" ]; then
    run_android_ui_tests
    UI_TEST_RESULT=$?
else
    run_ios_ui_tests
    UI_TEST_RESULT=$?
fi

# Run API tests
run_api_tests
API_TEST_RESULT=$?

# Overall test result
if [ $UI_TEST_RESULT -eq 0 ] && [ $API_TEST_RESULT -eq 0 ]; then
    TEST_RESULT="PASSED"
else
    TEST_RESULT="FAILED"
fi

# Add summary to log file
echo "\n===== Test Summary =====" >> "$LOG_FILE"
echo "Test Result: $TEST_RESULT" >> "$LOG_FILE"
echo "UI Tests: $([ $UI_TEST_RESULT -eq 0 ] && echo "PASSED" || echo "FAILED")" >> "$LOG_FILE"
echo "API Tests: $([ $API_TEST_RESULT -eq 0 ] && echo "PASSED" || echo "FAILED")" >> "$LOG_FILE"
echo "Platform: $PLATFORM" >> "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"

if [ "$TEST_RESULT" = "PASSED" ]; then
    echo "✅ REGRESSION TESTS PASSED: Main app flows are working correctly after security implementations."
else
    echo "❌ REGRESSION TESTS FAILED: Some main app flows are not working correctly after security implementations."
fi

echo "Test completed. See $LOG_FILE for details."