#!/bin/bash

# Master Security Test Script
# This script runs all security tests in sequence

echo "===== Running All Security Tests ====="
echo "This script will run all security tests in sequence"

# Define variables
LOG_DIR="security_test_logs"
MASTER_LOG="${LOG_DIR}/master_security_test.log"
TEST_SUMMARY="${LOG_DIR}/test_summary.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Clear previous logs
rm -f "$MASTER_LOG"
rm -f "$TEST_SUMMARY"
touch "$MASTER_LOG"
touch "$TEST_SUMMARY"

echo "Starting security tests at $(date)" | tee -a "$MASTER_LOG"
echo "===== Security Test Summary =====" >> "$TEST_SUMMARY"
echo "Test run started at: $(date)" >> "$TEST_SUMMARY"
echo "" >> "$TEST_SUMMARY"

# Function to run a test and log results
run_test() {
    local test_script=$1
    local test_name=$2
    
    echo "\n===== Running $test_name ====="
    echo "\n===== Running $test_name =====" >> "$MASTER_LOG"
    
    # Check if the test script exists
    if [ ! -f "$test_script" ]; then
        echo "❌ Test script $test_script not found!" | tee -a "$MASTER_LOG"
        echo "$test_name: SKIPPED (script not found)" >> "$TEST_SUMMARY"
        return 1
    fi
    
    # Check if the test script is executable
    if [ ! -x "$test_script" ]; then
        echo "Making $test_script executable..."
        chmod +x "$test_script"
    fi
    
    # Run the test script
    echo "Running $test_script..."
    $test_script | tee -a "$MASTER_LOG"
    TEST_RESULT=${PIPESTATUS[0]}
    
    # Check the test result
    if [ $TEST_RESULT -eq 0 ]; then
        echo "$test_name: PASSED" >> "$TEST_SUMMARY"
    else
        echo "$test_name: FAILED" >> "$TEST_SUMMARY"
    fi
    
    # Move test-specific logs to log directory
    if [ -f "${test_script%.sh}.log" ]; then
        mv "${test_script%.sh}.log" "${LOG_DIR}/"
    fi
    
    return $TEST_RESULT
}

# Run each test
echo "Step 1: Certificate Pinning Test"
run_test "./certificate_pinning_test.sh" "Certificate Pinning Test"
CERT_PINNING_RESULT=$?

echo "\nStep 2: Secure Storage Test"
run_test "./secure_storage_test.sh" "Secure Storage Test"
SECURE_STORAGE_RESULT=$?

echo "\nStep 3: Auth Token Refresh Test"
run_test "./auth_refresh_test.sh" "Auth Token Refresh Test"
AUTH_REFRESH_RESULT=$?

echo "\nStep 4: Request Signing Test"
run_test "./request_signing_test.sh" "Request Signing Test"
REQUEST_SIGNING_RESULT=$?

echo "\nStep 5: Biometric Authentication Test"
run_test "./biometric_auth_test.sh" "Biometric Authentication Test"
BIOMETRIC_AUTH_RESULT=$?

echo "\nStep 6: Screen Capture Protection Test"
run_test "./screen_capture_protection_test.sh" "Screen Capture Protection Test"
SCREEN_CAPTURE_RESULT=$?

echo "\nStep 7: Regression Test"
run_test "./regression_test.sh" "Regression Test"
REGRESSION_RESULT=$?

# Calculate overall result
if [ $CERT_PINNING_RESULT -eq 0 ] && 
   [ $SECURE_STORAGE_RESULT -eq 0 ] && 
   [ $AUTH_REFRESH_RESULT -eq 0 ] && 
   [ $REQUEST_SIGNING_RESULT -eq 0 ] && 
   [ $BIOMETRIC_AUTH_RESULT -eq 0 ] && 
   [ $SCREEN_CAPTURE_RESULT -eq 0 ] && 
   [ $REGRESSION_RESULT -eq 0 ]; then
    OVERALL_RESULT="PASSED"
else
    OVERALL_RESULT="FAILED"
fi

# Add overall result to summary
echo "\n===== Overall Result =====" >> "$TEST_SUMMARY"
echo "Overall Security Test Result: $OVERALL_RESULT" >> "$TEST_SUMMARY"
echo "Test run completed at: $(date)" >> "$TEST_SUMMARY"

# Display summary
echo "\n===== Security Test Summary ====="
cat "$TEST_SUMMARY"

echo "\nAll security tests completed. Logs are available in the $LOG_DIR directory."
echo "Master log: $MASTER_LOG"
echo "Test summary: $TEST_SUMMARY"

# Exit with appropriate status code
if [ "$OVERALL_RESULT" = "PASSED" ]; then
    exit 0
else
    exit 1
fi