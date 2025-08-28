#!/bin/bash

# This script contains curl commands to test the signed API endpoints
# It demonstrates both valid and invalid signature scenarios

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m" # No Color

# Configuration
API_URL="https://api.example.com"
ENDPOINT="/protected-resource"
DEVICE_ID="device-123"
SIGNING_KEY="a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"

echo -e "${YELLOW}=== HMAC-SHA256 Signed API Testing ===${NC}"
echo -e "API URL: $API_URL"
echo -e "Endpoint: $ENDPOINT"
echo -e "Device ID: $DEVICE_ID"
echo -e "Signing Key: $SIGNING_KEY\n"

# Function to generate HMAC-SHA256 signature
generate_signature() {
    local path=$1
    local body=$2
    local timestamp=$3
    
    # Create payload with pipe delimiter
    local payload="${path}|${body}|${timestamp}"
    
    # Generate signature using OpenSSL
    local signature=$(echo -n "$payload" | openssl dgst -sha256 -hmac "$SIGNING_KEY" -binary | base64)
    
    echo $signature
}

# Test 1: Valid request
test_valid_request() {
    echo -e "\n${YELLOW}=== Test 1: Valid Request ===${NC}"
    
    local path="$ENDPOINT"
    local body='{"test":"data"}'
    local timestamp=$(date +%s000) # Current time in milliseconds
    
    # Generate signature
    local signature=$(generate_signature "$path" "$body" "$timestamp")
    
    echo -e "Path: $path"
    echo -e "Body: $body"
    echo -e "Timestamp: $timestamp"
    echo -e "Signature: $signature\n"
    
    # Make the request
    echo -e "${GREEN}Making request...${NC}"
    curl -s -X POST "$API_URL$path" \
        -H "Content-Type: application/json" \
        -H "X-Device-Id: $DEVICE_ID" \
        -H "X-Timestamp: $timestamp" \
        -H "X-Signature: $signature" \
        -d "$body" | jq .
}

# Test 2: Tampered path
test_tampered_path() {
    echo -e "\n${YELLOW}=== Test 2: Tampered Path ===${NC}"
    
    local path="$ENDPOINT"
    local tampered_path="/hacked-resource" # This is different from what was signed
    local body='{"test":"data"}'
    local timestamp=$(date +%s000)
    
    # Generate signature for the original path
    local signature=$(generate_signature "$path" "$body" "$timestamp")
    
    echo -e "Original Path: $path"
    echo -e "Tampered Path: $tampered_path"
    echo -e "Body: $body"
    echo -e "Timestamp: $timestamp"
    echo -e "Signature (for original path): $signature\n"
    
    # Make the request with tampered path
    echo -e "${RED}Making request with tampered path...${NC}"
    curl -s -X POST "$API_URL$tampered_path" \
        -H "Content-Type: application/json" \
        -H "X-Device-Id: $DEVICE_ID" \
        -H "X-Timestamp: $timestamp" \
        -H "X-Signature: $signature" \
        -d "$body" | jq .
}

# Test 3: Tampered body
test_tampered_body() {
    echo -e "\n${YELLOW}=== Test 3: Tampered Body ===${NC}"
    
    local path="$ENDPOINT"
    local body='{"test":"data"}'
    local tampered_body='{"test":"hacked"}' # This is different from what was signed
    local timestamp=$(date +%s000)
    
    # Generate signature for the original body
    local signature=$(generate_signature "$path" "$body" "$timestamp")
    
    echo -e "Path: $path"
    echo -e "Original Body: $body"
    echo -e "Tampered Body: $tampered_body"
    echo -e "Timestamp: $timestamp"
    echo -e "Signature (for original body): $signature\n"
    
    # Make the request with tampered body
    echo -e "${RED}Making request with tampered body...${NC}"
    curl -s -X POST "$API_URL$path" \
        -H "Content-Type: application/json" \
        -H "X-Device-Id: $DEVICE_ID" \
        -H "X-Timestamp: $timestamp" \
        -H "X-Signature: $signature" \
        -d "$tampered_body" | jq .
}

# Test 4: Expired timestamp
test_expired_timestamp() {
    echo -e "\n${YELLOW}=== Test 4: Expired Timestamp ===${NC}"
    
    local path="$ENDPOINT"
    local body='{"test":"data"}'
    local timestamp=$(($(date +%s000) - 3600000)) # 1 hour ago in milliseconds
    
    # Generate signature
    local signature=$(generate_signature "$path" "$body" "$timestamp")
    
    echo -e "Path: $path"
    echo -e "Body: $body"
    echo -e "Timestamp: $timestamp (1 hour ago)"
    echo -e "Signature: $signature\n"
    
    # Make the request with expired timestamp
    echo -e "${RED}Making request with expired timestamp...${NC}"
    curl -s -X POST "$API_URL$path" \
        -H "Content-Type: application/json" \
        -H "X-Device-Id: $DEVICE_ID" \
        -H "X-Timestamp: $timestamp" \
        -H "X-Signature: $signature" \
        -d "$body" | jq .
}

# Test 5: Replay attack (reusing a valid signature)
test_replay_attack() {
    echo -e "\n${YELLOW}=== Test 5: Replay Attack ===${NC}"
    
    local path="$ENDPOINT"
    local body='{"test":"data"}'
    local timestamp=$(date +%s000)
    
    # Generate signature
    local signature=$(generate_signature "$path" "$body" "$timestamp")
    
    echo -e "Path: $path"
    echo -e "Body: $body"
    echo -e "Timestamp: $timestamp"
    echo -e "Signature: $signature\n"
    
    # Make the first request (should succeed)
    echo -e "${GREEN}Making first request...${NC}"
    curl -s -X POST "$API_URL$path" \
        -H "Content-Type: application/json" \
        -H "X-Device-Id: $DEVICE_ID" \
        -H "X-Timestamp: $timestamp" \
        -H "X-Signature: $signature" \
        -d "$body" | jq .
    
    echo -e "\n${RED}Making replay request with same signature...${NC}"
    # Make the second request with the same signature (should fail if server tracks nonces)
    curl -s -X POST "$API_URL$path" \
        -H "Content-Type: application/json" \
        -H "X-Device-Id: $DEVICE_ID" \
        -H "X-Timestamp: $timestamp" \
        -H "X-Signature: $signature" \
        -d "$body" | jq .
}

# Test 6: Missing signature
test_missing_signature() {
    echo -e "\n${YELLOW}=== Test 6: Missing Signature ===${NC}"
    
    local path="$ENDPOINT"
    local body='{"test":"data"}'
    local timestamp=$(date +%s000)
    
    echo -e "Path: $path"
    echo -e "Body: $body"
    echo -e "Timestamp: $timestamp"
    echo -e "Signature: [MISSING]\n"
    
    # Make the request without signature
    echo -e "${RED}Making request without signature...${NC}"
    curl -s -X POST "$API_URL$path" \
        -H "Content-Type: application/json" \
        -H "X-Device-Id: $DEVICE_ID" \
        -H "X-Timestamp: $timestamp" \
        -d "$body" | jq .
}

# Run all tests
echo -e "\n${YELLOW}Running all tests...${NC}"
echo -e "${RED}Note: These tests expect a server that validates HMAC-SHA256 signatures${NC}"
echo -e "${RED}If the server is not running, you will see connection errors${NC}\n"

# Uncomment the tests you want to run
test_valid_request
test_tampered_path
test_tampered_body
test_expired_timestamp
test_replay_attack
test_missing_signature

echo -e "\n${GREEN}All tests completed!${NC}"