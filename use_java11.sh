#!/bin/bash

# Set JAVA_HOME to OpenJDK 11
export JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-11.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"

# Verify Java version
java -version

echo "JAVA_HOME is now set to: $JAVA_HOME"
echo "You can now run Flutter commands with Java 11"