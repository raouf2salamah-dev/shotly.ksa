#!/bin/bash

# Certificate Pinning Test Script
# This script tests if the app correctly rejects connections when a MITM attack is attempted using mitmproxy

echo "===== Certificate Pinning Test ====="
echo "This test verifies that the app rejects connections when a MITM attack is attempted"

# Check if mitmproxy is installed
if ! command -v mitmproxy &> /dev/null; then
    echo "Error: mitmproxy is not installed. Please install it first."
    echo "You can install it using: pip install mitmproxy"
    exit 1
fi

# Define variables
APP_PACKAGE="com.example.shotly"
LOG_FILE="certificate_pinning_test.log"
MITM_PORT=8080

# Clear previous log file
rm -f "$LOG_FILE"
touch "$LOG_FILE"

echo "Starting mitmproxy on port $MITM_PORT..."
echo "Starting mitmproxy..." >> "$LOG_FILE"

# Start mitmproxy in the background
mitmproxy --listen-port $MITM_PORT &
MITM_PID=$!

# Give mitmproxy time to start
sleep 2

echo "Checking for connected devices..."

# Check if any device is connected
DEVICES=$(adb devices | grep -v "List" | grep "device")
if [ -z "$DEVICES" ]; then
    echo "No devices connected. Please connect a device and try again."
    kill $MITM_PID
    exit 1
fi

echo "Setting up proxy on device..."
echo "Setting up proxy on device..." >> "$LOG_FILE"

# Get the host IP address
HOST_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1)

if [ -z "$HOST_IP" ]; then
    echo "Could not determine host IP address."
    kill $MITM_PID
    exit 1
fi

echo "Host IP: $HOST_IP"

# Configure device to use proxy
adb shell settings put global http_proxy "$HOST_IP:$MITM_PORT"

echo "Proxy set to $HOST_IP:$MITM_PORT"
echo "Proxy set to $HOST_IP:$MITM_PORT" >> "$LOG_FILE"

# Clear app data to ensure a fresh start
echo "Clearing app data..."
adb shell pm clear $APP_PACKAGE

# Start the app
echo "Starting the app..."
adb shell monkey -p $APP_PACKAGE -c android.intent.category.LAUNCHER 1

# Wait for the app to start and attempt network connections
echo "Waiting for app to start and attempt network connections..."
sleep 10

# Capture logs
echo "Capturing logs..."
adb logcat -d | grep -E "$APP_PACKAGE|SSL|TLS|Certificate|CERTIFICATE|Pinning" >> "$LOG_FILE"

# Check for certificate validation errors in the logs
if grep -q -E "CertPathValidatorException|SSLHandshakeException|CertificateException|SSL handshake|certificate pinning|Trust anchor|CERTIFICATE_VERIFY_FAILED" "$LOG_FILE"; then
    echo "✅ TEST PASSED: Certificate pinning is working correctly."
    echo "The app rejected the connection when a MITM attack was attempted."
    echo "See $LOG_FILE for details."
    TEST_RESULT="PASSED"
else
    echo "❌ TEST FAILED: Certificate pinning may not be working correctly."
    echo "The app did not reject the connection when a MITM attack was attempted."
    echo "See $LOG_FILE for details."
    TEST_RESULT="FAILED"
fi

# Clean up
echo "Cleaning up..."

# Remove proxy settings
adb shell settings put global http_proxy :0

# Kill mitmproxy
kill $MITM_PID

# Add summary to log file
echo "\n===== Test Summary =====" >> "$LOG_FILE"
echo "Test Result: $TEST_RESULT" >> "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"

echo "Test completed. Proxy settings removed."