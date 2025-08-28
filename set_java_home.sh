#!/bin/bash

# Set JAVA_HOME to JDK 17 installed by Homebrew
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH=$JAVA_HOME/bin:$PATH

# Print Java version to verify
java -version
javac -version

echo "JAVA_HOME set to $JAVA_HOME"