#!/bin/bash

# Set JAVA_HOME to OpenJDK 17
export JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.16/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"

# Verify Java version
java -version

echo "JAVA_HOME is now set to: $JAVA_HOME"
echo "You can now run Flutter commands with Java 17"