#!/bin/bash

# Request Signing Test Script
# This script tests that the server rejects requests with wrong signature/timestamp

echo "===== Request Signing Test ====="
echo "This test verifies that the server rejects requests with incorrect signatures or timestamps"

# Define variables
API_BASE_URL="https://api.example.com"
LOG_FILE="request_signing_test.log"

# Clear previous log file
rm -f "$LOG_FILE"
touch "$LOG_FILE"

# Test credentials (replace with test account credentials)
TEST_USERNAME="test@example.com"
TEST_PASSWORD="testpassword"
API_KEY="your_api_key_here"
API_SECRET="your_api_secret_here"

# Function to generate HMAC signature
generate_signature() {
    local method=$1
    local endpoint=$2
    local timestamp=$3
    local body=$4
    
    # Create string to sign
    local string_to_sign="${method}${endpoint}${timestamp}"
    if [ ! -z "$body" ]; then
        string_to_sign="${string_to_sign}${body}"
    fi
    
    echo "String to sign: $string_to_sign" >> "$LOG_FILE"
    
    # Generate HMAC-SHA256 signature
    echo -n "$string_to_sign" | openssl dgst -sha256 -hmac "$API_SECRET" -binary | base64
}

# Function to make API requests with signature
make_signed_request() {
    local endpoint=$1
    local method=${2:-"GET"}
    local body=$3
    local timestamp=$(date +%s)
    local tamper_signature=${4:-false}
    local tamper_timestamp=${5:-false}
    
    # Tamper with timestamp if requested
    if [ "$tamper_timestamp" = true ]; then
        timestamp=$((timestamp - 3600))  # Use timestamp from 1 hour ago
        echo "Using tampered timestamp: $timestamp" >> "$LOG_FILE"
    fi
    
    # Generate signature
    local signature=$(generate_signature "$method" "$endpoint" "$timestamp" "$body")
    
    # Tamper with signature if requested
    if [ "$tamper_signature" = true ]; then
        signature="${signature:0:10}X${signature:11}"  # Modify a character in the signature
        echo "Using tampered signature: $signature" >> "$LOG_FILE"
    fi
    
    echo "Request details:" >> "$LOG_FILE"
    echo "Method: $method" >> "$LOG_FILE"
    echo "Endpoint: $endpoint" >> "$LOG_FILE"
    echo "Timestamp: $timestamp" >> "$LOG_FILE"
    echo "Signature: $signature" >> "$LOG_FILE"
    
    # Make the request
    if [ -z "$body" ]; then
        curl -s -X "$method" \
            -H "X-Api-Key: $API_KEY" \
            -H "X-Timestamp: $timestamp" \
            -H "X-Signature: $signature" \
            -H "Content-Type: application/json" \
            "$API_BASE_URL$endpoint"
    else
        curl -s -X "$method" \
            -H "X-Api-Key: $API_KEY" \
            -H "X-Timestamp: $timestamp" \
            -H "X-Signature: $signature" \
            -H "Content-Type: application/json" \
            -d "$body" \
            "$API_BASE_URL$endpoint"
    fi
}

# Function to login and get tokens
login() {
    echo "Logging in to get access token..."
    echo "Logging in to get access token..." >> "$LOG_FILE"
    
    local timestamp=$(date +%s)
    local login_data='{"email":"'"$TEST_USERNAME"'","password":"'"$TEST_PASSWORD"'"}'
    local signature=$(generate_signature "POST" "/auth/login" "$timestamp" "$login_data")
    
    local login_response=$(curl -s -X POST \
        -H "X-Api-Key: $API_KEY" \
        -H "X-Timestamp: $timestamp" \
        -H "X-Signature: $signature" \
        -H "Content-Type: application/json" \
        -d "$login_data" \
        "$API_BASE_URL/auth/login")
    
    echo "Login response: $login_response" >> "$LOG_FILE"
    
    # Extract token from response
    ACCESS_TOKEN=$(echo "$login_response" | grep -o '"access_token":"[^"]*"' | cut -d '"' -f 4)
    
    if [ -z "$ACCESS_TOKEN" ]; then
        echo "❌ Failed to obtain access token. Check credentials and API endpoint."
        exit 1
    fi
    
    echo "Successfully obtained access token." >> "$LOG_FILE"
    echo "Access Token: ${ACCESS_TOKEN:0:10}..." >> "$LOG_FILE"
}

# Function to test with correct signature
test_correct_signature() {
    echo "Testing with correct signature..."
    echo "Testing with correct signature..." >> "$LOG_FILE"
    
    local endpoint="/api/user/profile"
    local response=$(make_signed_request "$endpoint")
    
    echo "Response with correct signature: $response" >> "$LOG_FILE"
    
    # Check if response indicates success
    if ! echo "$response" | grep -q -E "unauthorized|invalid signature|signature mismatch|authentication failed"; then
        echo "✅ Request with correct signature was accepted." | tee -a "$LOG_FILE"
        return 0
    else
        echo "❌ Request with correct signature was rejected." | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to test with incorrect signature
test_incorrect_signature() {
    echo "Testing with incorrect signature..."
    echo "Testing with incorrect signature..." >> "$LOG_FILE"
    
    local endpoint="/api/user/profile"
    local response=$(make_signed_request "$endpoint" "GET" "" true false)
    
    echo "Response with incorrect signature: $response" >> "$LOG_FILE"
    
    # Check if response indicates authentication failure
    if echo "$response" | grep -q -E "unauthorized|invalid signature|signature mismatch|authentication failed"; then
        echo "✅ Server correctly rejected request with incorrect signature." | tee -a "$LOG_FILE"
        return 0
    else
        echo "❌ Server accepted request with incorrect signature." | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to test with incorrect timestamp
test_incorrect_timestamp() {
    echo "Testing with incorrect timestamp..."
    echo "Testing with incorrect timestamp..." >> "$LOG_FILE"
    
    local endpoint="/api/user/profile"
    local response=$(make_signed_request "$endpoint" "GET" "" false true)
    
    echo "Response with incorrect timestamp: $response" >> "$LOG_FILE"
    
    # Check if response indicates authentication failure
    if echo "$response" | grep -q -E "unauthorized|invalid timestamp|timestamp expired|authentication failed"; then
        echo "✅ Server correctly rejected request with incorrect timestamp." | tee -a "$LOG_FILE"
        return 0
    else
        echo "❌ Server accepted request with incorrect timestamp." | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to test with POST request
test_post_request_signing() {
    echo "Testing POST request signing..."
    echo "Testing POST request signing..." >> "$LOG_FILE"
    
    local endpoint="/api/user/update"
    local body='{"name":"Test User","bio":"This is a test bio"}'
    
    # Test with correct signature
    echo "Testing POST with correct signature..." >> "$LOG_FILE"
    local correct_response=$(make_signed_request "$endpoint" "POST" "$body")
    
    echo "Response with correct signature: $correct_response" >> "$LOG_FILE"
    
    # Check if response indicates success
    if ! echo "$correct_response" | grep -q -E "unauthorized|invalid signature|signature mismatch|authentication failed"; then
        echo "✅ POST request with correct signature was accepted." | tee -a "$LOG_FILE"
        post_correct=0
    else
        echo "❌ POST request with correct signature was rejected." | tee -a "$LOG_FILE"
        post_correct=1
    fi
    
    # Test with incorrect signature
    echo "Testing POST with incorrect signature..." >> "$LOG_FILE"
    local incorrect_response=$(make_signed_request "$endpoint" "POST" "$body" true false)
    
    echo "Response with incorrect signature: $incorrect_response" >> "$LOG_FILE"
    
    # Check if response indicates authentication failure
    if echo "$incorrect_response" | grep -q -E "unauthorized|invalid signature|signature mismatch|authentication failed"; then
        echo "✅ Server correctly rejected POST request with incorrect signature." | tee -a "$LOG_FILE"
        post_incorrect=0
    else
        echo "❌ Server accepted POST request with incorrect signature." | tee -a "$LOG_FILE"
        post_incorrect=1
    fi
    
    return $((post_correct + post_incorrect))
}

# Main test execution
echo "Starting request signing tests..."

# Login to get access token (if needed)
# login

# Test with correct signature
if test_correct_signature; then
    echo "Correct signature test passed." >> "$LOG_FILE"
else
    echo "Correct signature test failed." >> "$LOG_FILE"
    TEST_RESULT="FAILED"
fi

# Test with incorrect signature
if test_incorrect_signature; then
    echo "Incorrect signature test passed." >> "$LOG_FILE"
else
    echo "Incorrect signature test failed." >> "$LOG_FILE"
    TEST_RESULT="FAILED"
fi

# Test with incorrect timestamp
if test_incorrect_timestamp; then
    echo "Incorrect timestamp test passed." >> "$LOG_FILE"
else
    echo "Incorrect timestamp test failed." >> "$LOG_FILE"
    TEST_RESULT="FAILED"
fi

# Test POST request signing
if test_post_request_signing; then
    echo "POST request signing test passed." >> "$LOG_FILE"
    if [ -z "$TEST_RESULT" ]; then
        TEST_RESULT="PASSED"
    fi
else
    echo "POST request signing test failed." >> "$LOG_FILE"
    TEST_RESULT="FAILED"
fi

# Add summary to log file
echo "\n===== Test Summary =====" >> "$LOG_FILE"
echo "Test Result: $TEST_RESULT" >> "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"

if [ "$TEST_RESULT" = "PASSED" ]; then
    echo "✅ TEST PASSED: Request signing verification is working correctly."
else
    echo "❌ TEST FAILED: Request signing verification is not working correctly."
fi

echo "Test completed. See $LOG_FILE for details."