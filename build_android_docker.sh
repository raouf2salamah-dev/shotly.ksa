#!/bin/bash

# Script to build Android APK using Docker with correct Java version
# This bypasses local Java version incompatibility issues

echo "Starting Android build with Docker..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    echo "Visit https://docs.docker.com/get-docker/ for installation instructions."
    exit 1
fi

# Create a temporary Dockerfile
cat > Dockerfile.temp << 'EOF'
FROM openjdk:17-slim

# Install Flutter dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    xz-utils \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:${PATH}"
RUN flutter doctor

WORKDIR /app
EOF

echo "Building Docker image..."
docker build -t flutter-android-builder -f Dockerfile.temp .
rm Dockerfile.temp

echo "Running Flutter build in Docker container..."
docker run --rm -v "$(pwd):/app" flutter-android-builder sh -c "flutter pub get && flutter build apk --release --obfuscate --split-debug-info=./symbols"

# Check if build was successful
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "\n✅ Build successful! APK is available at: build/app/outputs/flutter-apk/app-release.apk"
    
    # Provide instructions for installation
    echo "\nTo install on a connected device:"
    echo "adb install build/app/outputs/flutter-apk/app-release.apk"
    
    # Provide file size information
    APK_SIZE=$(du -h "build/app/outputs/flutter-apk/app-release.apk" | cut -f1)
    echo "\nAPK size: $APK_SIZE"
else
    echo "\n❌ Build failed. Check the logs above for errors."
fi