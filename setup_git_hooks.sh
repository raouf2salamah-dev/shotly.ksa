#!/bin/bash

# Script to set up git hooks for the project

echo "Setting up git hooks..."

# Create .githooks directory if it doesn't exist
mkdir -p .githooks

# Make sure the pre-commit hook is executable
chmod +x .githooks/pre-commit

# Configure git to use the hooks from .githooks directory
git config core.hooksPath .githooks

echo "✅ Git hooks set up successfully."
echo "Pre-commit hook will now run security checks before each commit."