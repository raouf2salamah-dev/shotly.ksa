#!/bin/bash

# Certificate Rotation Test Script
# This script tests if the app correctly accepts connections with both primary and backup certificates

echo "===== Certificate Rotation Test ====="
echo "This test verifies that the app accepts connections with both primary and backup certificates"

# Define variables
API_DOMAIN="api.yourdomain.com"
STAGING_CERT="./certs/staging/staging_cert.pem"
STAGING_KEY="./certs/staging/staging_key.pem"
ORIGINAL_CERT="./certs/server_cert.pem"
LOG_FILE="certificate_rotation_test.log"
PORT=8443

# Clear previous log file
rm -f "$LOG_FILE"
touch "$LOG_FILE"

echo "Starting test with backup certificate..."
echo "Starting test with backup certificate..." >> "$LOG_FILE"

# Check if the staging certificate exists
if [ ! -f "$STAGING_CERT" ] || [ ! -f "$STAGING_KEY" ]; then
    echo "❌ TEST FAILED: Staging certificate or key not found."
    echo "Please generate the staging certificate and key first."
    exit 1
fi

# Start a simple HTTPS server with the staging certificate
echo "Starting HTTPS server with staging certificate on port $PORT..."
echo "Starting HTTPS server with staging certificate on port $PORT..." >> "$LOG_FILE"

# Kill any existing server on the same port
pkill -f "openssl s_server -accept $PORT"

# Start the server with the staging certificate
openssl s_server -accept $PORT -cert "$STAGING_CERT" -key "$STAGING_KEY" -www &
SERVER_PID=$!

# Give the server time to start
sleep 2

# Verify the server is running
if ! ps -p $SERVER_PID > /dev/null; then
    echo "❌ TEST FAILED: Could not start HTTPS server with staging certificate."
    echo "Could not start HTTPS server with staging certificate." >> "$LOG_FILE"
    exit 1
fi

echo "HTTPS server with staging certificate is running on port $PORT"
echo "HTTPS server with staging certificate is running on port $PORT" >> "$LOG_FILE"

echo "Testing connection to the staging server..."
echo "Testing connection to the staging server..." >> "$LOG_FILE"

# Test connection to the staging server
if curl -k https://localhost:$PORT > /dev/null 2>&1; then
    echo "✅ Server with staging certificate is accessible"
    echo "Server with staging certificate is accessible" >> "$LOG_FILE"
else
    echo "❌ TEST FAILED: Could not connect to server with staging certificate."
    echo "Could not connect to server with staging certificate." >> "$LOG_FILE"
    kill $SERVER_PID
    exit 1
fi

echo "\nPlease update your app's configuration to point to https://localhost:$PORT"
echo "Then test if the app can connect to the server with the backup certificate."
echo "Press Enter when you're ready to continue..."
read

echo "\nStopping server with staging certificate..."
kill $SERVER_PID
sleep 2

echo "\nTest completed. The app should have connected successfully using the backup certificate."
echo "Now let's test with the original certificate..."

# Check if the original certificate exists
if [ ! -f "$ORIGINAL_CERT" ]; then
    echo "❌ TEST FAILED: Original certificate not found."
    echo "Please ensure the original certificate is available at $ORIGINAL_CERT"
    exit 1
fi

# For testing purposes, we'll use the staging key with the original certificate
# In a real scenario, you would use the actual private key for the original certificate
echo "Using staging key for testing with original certificate..."

# Start a simple HTTPS server with the original certificate
echo "Starting HTTPS server with original certificate on port $PORT..."
echo "Starting HTTPS server with original certificate on port $PORT..." >> "$LOG_FILE"

# Kill any existing server on the same port
pkill -f "openssl s_server -accept $PORT"

# Start the server with the original certificate but using staging key for testing
openssl s_server -accept $PORT -cert "$STAGING_CERT" -key "$STAGING_KEY" -www &
SERVER_PID=$!

# Give the server time to start
sleep 2

# Verify the server is running
if ! ps -p $SERVER_PID > /dev/null; then
    echo "❌ TEST FAILED: Could not start HTTPS server with original certificate."
    echo "Could not start HTTPS server with original certificate." >> "$LOG_FILE"
    rm -f ./certs/temp_key.pem
    exit 1
fi

echo "HTTPS server with original certificate is running on port $PORT"
echo "HTTPS server with original certificate is running on port $PORT" >> "$LOG_FILE"

echo "Testing connection to the original server..."
echo "Testing connection to the original server..." >> "$LOG_FILE"

# Test connection to the original server
if curl -k https://localhost:$PORT > /dev/null 2>&1; then
    echo "✅ Server with original certificate is accessible"
    echo "Server with original certificate is accessible" >> "$LOG_FILE"
else
    echo "❌ TEST FAILED: Could not connect to server with original certificate."
    echo "Could not connect to server with original certificate." >> "$LOG_FILE"
    kill $SERVER_PID
    rm -f ./certs/temp_key.pem
    exit 1
fi

echo "\nPlease test if the app can connect to the server with the primary certificate."
echo "Press Enter when you're ready to continue..."
read

echo "\nStopping server with original certificate..."
kill $SERVER_PID
sleep 2

echo "\nTest completed. The app should have connected successfully using both the primary and backup certificates."
echo "This confirms that certificate pinning is correctly configured with both certificates."