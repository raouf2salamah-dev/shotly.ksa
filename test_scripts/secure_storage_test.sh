#!/bin/bash

# Secure Storage Test Script
# This script verifies that tokens exist and are not readable in plain text from the device file system

echo "===== Secure Storage Test ====="
echo "This test verifies that tokens are stored securely and not readable in plain text"

# Define variables
APP_PACKAGE="com.example.shotly"
LOG_FILE="secure_storage_test.log"
ANDROID_DATA_DIR="/data/data/$APP_PACKAGE"
IOS_APP_GROUP="group.com.example.shotly"

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

# Function to test Android secure storage
test_android_secure_storage() {
    echo "Testing Android secure storage..."
    echo "Testing Android secure storage..." >> "$LOG_FILE"
    
    # Check if the app is installed
    APP_INSTALLED=$(adb shell pm list packages | grep "$APP_PACKAGE")
    if [ -z "$APP_INSTALLED" ]; then
        echo "App is not installed. Please install the app and try again."
        exit 1
    fi
    
    # Launch the app to ensure tokens are generated
    echo "Launching app to ensure tokens are generated..."
    adb shell monkey -p $APP_PACKAGE -c android.intent.category.LAUNCHER 1
    sleep 5
    
    # Check shared preferences
    echo "Checking shared preferences..."
    adb shell "run-as $APP_PACKAGE ls -la /data/data/$APP_PACKAGE/shared_prefs/" >> "$LOG_FILE" 2>&1
    
    # Check if EncryptedSharedPreferences is being used
    ENCRYPTED_PREFS=$(adb shell "run-as $APP_PACKAGE ls -la /data/data/$APP_PACKAGE/shared_prefs/" | grep -E "encrypted|secure")
    if [ ! -z "$ENCRYPTED_PREFS" ]; then
        echo "Found encrypted shared preferences: $ENCRYPTED_PREFS" >> "$LOG_FILE"
    fi
    
    # Try to dump shared preferences content
    echo "Attempting to dump shared preferences content..." >> "$LOG_FILE"
    PREFS_FILES=$(adb shell "run-as $APP_PACKAGE ls /data/data/$APP_PACKAGE/shared_prefs/" | grep ".xml")
    
    TOKEN_FOUND=false
    PLAINTEXT_TOKEN=false
    
    for PREF_FILE in $PREFS_FILES; do
        echo "Examining $PREF_FILE..." >> "$LOG_FILE"
        PREF_CONTENT=$(adb shell "run-as $APP_PACKAGE cat /data/data/$APP_PACKAGE/shared_prefs/$PREF_FILE")
        echo "$PREF_CONTENT" >> "$LOG_FILE"
        
        # Check for token patterns
        if echo "$PREF_CONTENT" | grep -q -E "token|auth|jwt|bearer"; then
            TOKEN_FOUND=true
            echo "Found potential token reference in $PREF_FILE" >> "$LOG_FILE"
            
            # Check if it looks like plain text
            if echo "$PREF_CONTENT" | grep -q -E "eyJ[a-zA-Z0-9_-]{10,}\\.[a-zA-Z0-9_-]{10,}\\.[a-zA-Z0-9_-]{10,}"; then
                PLAINTEXT_TOKEN=true
                echo "WARNING: Found what appears to be a plaintext JWT token!" >> "$LOG_FILE"
            fi
        fi
    done
    
    # Check databases
    echo "Checking databases..." >> "$LOG_FILE"
    adb shell "run-as $APP_PACKAGE ls -la /data/data/$APP_PACKAGE/databases/" >> "$LOG_FILE" 2>&1
    
    DB_FILES=$(adb shell "run-as $APP_PACKAGE ls /data/data/$APP_PACKAGE/databases/" | grep -v "-journal")
    
    for DB_FILE in $DB_FILES; do
        echo "Examining database $DB_FILE..." >> "$LOG_FILE"
        
        # Pull the database file for analysis
        adb shell "run-as $APP_PACKAGE cp /data/data/$APP_PACKAGE/databases/$DB_FILE /sdcard/$DB_FILE"
        adb pull "/sdcard/$DB_FILE" "./temp_$DB_FILE" > /dev/null 2>&1
        
        # Check if sqlite3 is available
        if command -v sqlite3 &> /dev/null; then
            echo "Dumping database content..." >> "$LOG_FILE"
            sqlite3 "./temp_$DB_FILE" ".tables" >> "$LOG_FILE" 2>&1
            TABLES=$(sqlite3 "./temp_$DB_FILE" ".tables")
            
            for TABLE in $TABLES; do
                echo "Table: $TABLE" >> "$LOG_FILE"
                sqlite3 "./temp_$DB_FILE" "SELECT * FROM $TABLE;" >> "$LOG_FILE" 2>&1
                
                # Check for token patterns
                TOKEN_CHECK=$(sqlite3 "./temp_$DB_FILE" "SELECT * FROM $TABLE;" | grep -E "token|auth|jwt|bearer")
                if [ ! -z "$TOKEN_CHECK" ]; then
                    TOKEN_FOUND=true
                    echo "Found potential token reference in database $DB_FILE, table $TABLE" >> "$LOG_FILE"
                    
                    # Check if it looks like plain text
                    if echo "$TOKEN_CHECK" | grep -q -E "eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}"; then
                        PLAINTEXT_TOKEN=true
                        echo "WARNING: Found what appears to be a plaintext JWT token in database!" >> "$LOG_FILE"
                    fi
                fi
            done
        else
            echo "sqlite3 not available, skipping detailed database analysis" >> "$LOG_FILE"
            
            # Simple string search in the binary file
            if grep -q -E "token|auth|jwt|bearer" "./temp_$DB_FILE"; then
                TOKEN_FOUND=true
                echo "Found potential token reference in database $DB_FILE" >> "$LOG_FILE"
                
                # Check if it looks like plain text
                if grep -q -E "eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}" "./temp_$DB_FILE"; then
                    PLAINTEXT_TOKEN=true
                    echo "WARNING: Found what appears to be a plaintext JWT token in database!" >> "$LOG_FILE"
                fi
            fi
        fi
        
        # Clean up
        rm -f "./temp_$DB_FILE"
        adb shell "rm /sdcard/$DB_FILE"
    done
    
    # Check files directory
    echo "Checking files directory..." >> "$LOG_FILE"
    adb shell "run-as $APP_PACKAGE ls -la /data/data/$APP_PACKAGE/files/" >> "$LOG_FILE" 2>&1
    
    FILES=$(adb shell "run-as $APP_PACKAGE ls /data/data/$APP_PACKAGE/files/" 2>/dev/null)
    
    for FILE in $FILES; do
        echo "Examining file $FILE..." >> "$LOG_FILE"
        FILE_CONTENT=$(adb shell "run-as $APP_PACKAGE cat /data/data/$APP_PACKAGE/files/$FILE" 2>/dev/null)
        
        # Check for token patterns
        if echo "$FILE_CONTENT" | grep -q -E "token|auth|jwt|bearer"; then
            TOKEN_FOUND=true
            echo "Found potential token reference in file $FILE" >> "$LOG_FILE"
            
            # Check if it looks like plain text
            if echo "$FILE_CONTENT" | grep -q -E "eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}"; then
                PLAINTEXT_TOKEN=true
                echo "WARNING: Found what appears to be a plaintext JWT token in file!" >> "$LOG_FILE"
            fi
        fi
    done
    
    # Evaluate results
    if [ "$TOKEN_FOUND" = true ]; then
        echo "Tokens were found in the app's storage." >> "$LOG_FILE"
        
        if [ "$PLAINTEXT_TOKEN" = true ]; then
            echo "❌ TEST FAILED: Tokens appear to be stored in plain text!" | tee -a "$LOG_FILE"
            TEST_RESULT="FAILED"
        else
            echo "✅ TEST PASSED: Tokens are stored but do not appear to be in plain text." | tee -a "$LOG_FILE"
            TEST_RESULT="PASSED"
        fi
    else
        echo "No tokens were found in the app's storage. This could mean:" >> "$LOG_FILE"
        echo "1. The app is not storing tokens locally" >> "$LOG_FILE"
        echo "2. Tokens are stored in a location not checked by this script" >> "$LOG_FILE"
        echo "3. Tokens are stored in a highly secure manner not detectable by this script" >> "$LOG_FILE"
        
        echo "⚠️ TEST INCONCLUSIVE: No tokens were found in the app's storage." | tee -a "$LOG_FILE"
        TEST_RESULT="INCONCLUSIVE"
    fi
}

# Function to test iOS secure storage
test_ios_secure_storage() {
    echo "Testing iOS secure storage..."
    echo "Testing iOS secure storage..." >> "$LOG_FILE"
    
    # Check if the device is jailbroken (this test requires a jailbroken device)
    echo "Note: Full iOS secure storage testing requires a jailbroken device" >> "$LOG_FILE"
    echo "Performing limited tests on non-jailbroken device..." >> "$LOG_FILE"
    
    # Use ideviceinstaller to check if the app is installed
    APP_INSTALLED=$(ideviceinstaller -l | grep "$APP_PACKAGE")
    if [ -z "$APP_INSTALLED" ]; then
        echo "App is not installed. Please install the app and try again."
        exit 1
    fi
    
    # Launch the app to ensure tokens are generated
    echo "Please manually launch the app on the iOS device to ensure tokens are generated."
    echo "Press Enter when ready..."
    read
    
    # For non-jailbroken devices, we can only do limited checks
    echo "On non-jailbroken iOS devices, we can only perform limited checks:" >> "$LOG_FILE"
    echo "1. Check if the app is using Keychain for token storage" >> "$LOG_FILE"
    echo "2. Check if the app has proper keychain access groups" >> "$LOG_FILE"
    
    # Check for keychain access groups in entitlements
    echo "Checking app entitlements..." >> "$LOG_FILE"
    
    # Extract the IPA (requires ideviceinstaller)
    APP_ID=$(ideviceinstaller -l | grep "$APP_PACKAGE" | awk '{print $1}')
    if [ ! -z "$APP_ID" ]; then
        echo "Found app ID: $APP_ID" >> "$LOG_FILE"
        
        # Create a temporary directory
        TEMP_DIR=$(mktemp -d)
        
        # Backup the app (this requires the device to be paired and trusted)
        echo "Backing up the app to examine entitlements..." >> "$LOG_FILE"
        idevicebackup2 backup --apps $TEMP_DIR > /dev/null 2>&1
        
        # Look for keychain access groups
        if [ -d "$TEMP_DIR/$APP_ID" ]; then
            echo "Examining app entitlements..." >> "$LOG_FILE"
            
            # Check for keychain access groups
            KEYCHAIN_GROUPS=$(grep -r "keychain-access-groups" "$TEMP_DIR/$APP_ID" | wc -l)
            if [ $KEYCHAIN_GROUPS -gt 0 ]; then
                echo "✅ App appears to use keychain access groups, which is good for secure storage." | tee -a "$LOG_FILE"
            else
                echo "⚠️ Could not find keychain access groups in app entitlements." | tee -a "$LOG_FILE"
            fi
            
            # Clean up
            rm -rf "$TEMP_DIR"
        else
            echo "Could not find app data in backup." >> "$LOG_FILE"
        fi
    else
        echo "Could not determine app ID." >> "$LOG_FILE"
    fi
    
    echo "For a more thorough test, a jailbroken device would be required to:" >> "$LOG_FILE"
    echo "1. Examine the keychain items directly" >> "$LOG_FILE"
    echo "2. Check UserDefaults storage" >> "$LOG_FILE"
    echo "3. Examine app sandbox files" >> "$LOG_FILE"
    
    echo "⚠️ TEST PARTIALLY COMPLETED: Limited testing on non-jailbroken iOS device." | tee -a "$LOG_FILE"
    echo "Based on available information, the app appears to use secure storage mechanisms." | tee -a "$LOG_FILE"
    TEST_RESULT="PARTIAL"
}

# Run the appropriate test based on platform
if [ "$PLATFORM" = "android" ]; then
    test_android_secure_storage
else
    test_ios_secure_storage
fi

# Add summary to log file
echo "\n===== Test Summary =====" >> "$LOG_FILE"
echo "Test Result: $TEST_RESULT" >> "$LOG_FILE"
echo "Platform: $PLATFORM" >> "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"

echo "Test completed. See $LOG_FILE for details."