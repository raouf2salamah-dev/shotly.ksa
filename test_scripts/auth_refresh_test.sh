#!/bin/bash

# Auth Token Refresh Test Script
# This script tests token expiry and refresh flows

echo "===== Auth Token Refresh Test ====="
echo "This test verifies that token expiry and refresh flows work correctly"

# Define variables
API_BASE_URL="https://api.example.com"
LOG_FILE="auth_refresh_test.log"

# Clear previous log file
rm -f "$LOG_FILE"
touch "$LOG_FILE"

# Test credentials (replace with test account credentials)
TEST_USERNAME="test@example.com"
TEST_PASSWORD="testpassword"

# Function to make API requests
make_request() {
    local endpoint=$1
    local token=$2
    local method=${3:-"GET"}
    local data=$4
    
    if [ -z "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            "$API_BASE_URL$endpoint"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$API_BASE_URL$endpoint"
    fi
}

# Function to login and get tokens
login() {
    echo "Logging in to get initial tokens..."
    echo "Logging in to get initial tokens..." >> "$LOG_FILE"
    
    local login_data='{"email":"'"$TEST_USERNAME"'","password":"'"$TEST_PASSWORD"'"}'
    local login_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$login_data" \
        "$API_BASE_URL/auth/login")
    
    echo "Login response: $login_response" >> "$LOG_FILE"
    
    # Extract tokens from response
    ACCESS_TOKEN=$(echo "$login_response" | grep -o '"access_token":"[^"]*"' | cut -d '"' -f 4)
    REFRESH_TOKEN=$(echo "$login_response" | grep -o '"refresh_token":"[^"]*"' | cut -d '"' -f 4)
    
    if [ -z "$ACCESS_TOKEN" ] || [ -z "$REFRESH_TOKEN" ]; then
        echo "❌ Failed to obtain tokens. Check credentials and API endpoint."
        exit 1
    fi
    
    echo "Successfully obtained tokens." >> "$LOG_FILE"
    echo "Access Token: ${ACCESS_TOKEN:0:10}..." >> "$LOG_FILE"
    echo "Refresh Token: ${REFRESH_TOKEN:0:10}..." >> "$LOG_FILE"
}

# Function to refresh token
refresh_token() {
    echo "Attempting to refresh token..."
    echo "Attempting to refresh token..." >> "$LOG_FILE"
    
    local refresh_data='{"refresh_token":"'"$REFRESH_TOKEN"'"}'
    local refresh_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$refresh_data" \
        "$API_BASE_URL/auth/refresh")
    
    echo "Refresh response: $refresh_response" >> "$LOG_FILE"
    
    # Extract new access token
    NEW_ACCESS_TOKEN=$(echo "$refresh_response" | grep -o '"access_token":"[^"]*"' | cut -d '"' -f 4)
    
    if [ -z "$NEW_ACCESS_TOKEN" ]; then
        echo "❌ Failed to refresh token." | tee -a "$LOG_FILE"
        return 1
    fi
    
    echo "Successfully refreshed token." >> "$LOG_FILE"
    echo "New Access Token: ${NEW_ACCESS_TOKEN:0:10}..." >> "$LOG_FILE"
    
    # Update the access token
    ACCESS_TOKEN="$NEW_ACCESS_TOKEN"
    return 0
}

# Function to test with expired token
test_expired_token() {
    echo "Testing with expired/invalid token..."
    echo "Testing with expired/invalid token..." >> "$LOG_FILE"
    
    # Create an invalid token by modifying a character
    local invalid_token="${ACCESS_TOKEN:0:10}X${ACCESS_TOKEN:11}"
    
    echo "Using invalid token: ${invalid_token:0:10}..." >> "$LOG_FILE"
    
    # Make request with invalid token
    local response=$(make_request "/api/user/profile" "$invalid_token")
    echo "Response with invalid token: $response" >> "$LOG_FILE"
    
    # Check if response indicates authentication failure
    if echo "$response" | grep -q -E "unauthorized|invalid token|expired|authentication failed"; then
        echo "✅ Server correctly rejected invalid token." | tee -a "$LOG_FILE"
        return 0
    else
        echo "❌ Server accepted invalid token or returned unexpected response." | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to test token refresh flow
test_refresh_flow() {
    echo "Testing token refresh flow..."
    echo "Testing token refresh flow..." >> "$LOG_FILE"
    
    # 1. Make a request with valid token
    echo "1. Making request with valid token..." >> "$LOG_FILE"
    local initial_response=$(make_request "/api/user/profile" "$ACCESS_TOKEN")
    echo "Initial response: $initial_response" >> "$LOG_FILE"
    
    # Check if initial request was successful
    if ! echo "$initial_response" | grep -q -E "unauthorized|invalid token|expired|authentication failed"; then
        echo "✅ Initial request with valid token successful." | tee -a "$LOG_FILE"
    else
        echo "❌ Initial request failed unexpectedly." | tee -a "$LOG_FILE"
        return 1
    fi
    
    # 2. Simulate token expiry (we'll use an invalid token)
    echo "2. Simulating token expiry..." >> "$LOG_FILE"
    local expired_token="${ACCESS_TOKEN:0:10}X${ACCESS_TOKEN:11}"
    local expired_response=$(make_request "/api/user/profile" "$expired_token")
    echo "Response with expired token: $expired_response" >> "$LOG_FILE"
    
    # 3. Refresh the token
    echo "3. Refreshing token..." >> "$LOG_FILE"
    if ! refresh_token; then
        echo "❌ Token refresh failed." | tee -a "$LOG_FILE"
        return 1
    fi
    
    # 4. Make another request with the new token
    echo "4. Making request with new token..." >> "$LOG_FILE"
    local new_response=$(make_request "/api/user/profile" "$ACCESS_TOKEN")
    echo "Response with new token: $new_response" >> "$LOG_FILE"
    
    # Check if request with new token was successful
    if ! echo "$new_response" | grep -q -E "unauthorized|invalid token|expired|authentication failed"; then
        echo "✅ Request with refreshed token successful." | tee -a "$LOG_FILE"
        return 0
    else
        echo "❌ Request with refreshed token failed." | tee -a "$LOG_FILE"
        return 1
    fi
}

# Main test execution
echo "Starting auth token refresh tests..."

# Login to get initial tokens
login

# Test with expired token
if test_expired_token; then
    echo "Expired token test passed." >> "$LOG_FILE"
else
    echo "Expired token test failed." >> "$LOG_FILE"
    TEST_RESULT="FAILED"
fi

# Test token refresh flow
if test_refresh_flow; then
    echo "Token refresh flow test passed." >> "$LOG_FILE"
    TEST_RESULT="PASSED"
else
    echo "Token refresh flow test failed." >> "$LOG_FILE"
    TEST_RESULT="FAILED"
fi

# Add summary to log file
echo "\n===== Test Summary =====" >> "$LOG_FILE"
echo "Test Result: $TEST_RESULT" >> "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"

if [ "$TEST_RESULT" = "PASSED" ]; then
    echo "✅ TEST PASSED: Auth token refresh flow is working correctly."
else
    echo "❌ TEST FAILED: Auth token refresh flow is not working correctly."
fi

echo "Test completed. See $LOG_FILE for details."