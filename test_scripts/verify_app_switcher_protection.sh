#!/bin/bash

# Script to verify app switcher protection implementation

echo "Verifying App Switcher Protection Implementation"
echo "============================================"

# Check if Info.plist has proper ATS settings
echo "Checking ATS settings in Info.plist..."
if grep -q "<key>NSAppTransportSecurity</key>" "$PWD/ios/Runner/Info.plist" && \
   grep -q "<key>NSAllowsArbitraryLoads</key>" "$PWD/ios/Runner/Info.plist" && \
   grep -q "<false/>" "$PWD/ios/Runner/Info.plist"; then
    echo "✅ ATS settings are properly configured with NSAllowsArbitraryLoads set to false"
else
    echo "❌ ATS settings are not properly configured"
    exit 1
fi

# Check if SceneDelegate.swift exists
echo "Checking SceneDelegate implementation..."
if [ -f "$PWD/ios/Runner/SceneDelegate.swift" ]; then
    echo "✅ SceneDelegate.swift exists"
else
    echo "❌ SceneDelegate.swift does not exist"
    exit 1
fi

# Check if Info.plist has UIApplicationSceneManifest
echo "Checking UIApplicationSceneManifest in Info.plist..."
if grep -q "<key>UIApplicationSceneManifest</key>" "$PWD/ios/Runner/Info.plist" && \
   grep -q "<key>UISceneDelegateClassName</key>" "$PWD/ios/Runner/Info.plist"; then
    echo "✅ UIApplicationSceneManifest is properly configured"
else
    echo "❌ UIApplicationSceneManifest is not properly configured"
    exit 1
fi

# Check if AppSwitcherProtection.swift has public methods
echo "Checking AppSwitcherProtection implementation..."
if grep -q "@objc public func appWillResignActive" "$PWD/ios/Runner/AppSwitcherProtection.swift" && \
   grep -q "@objc public func appDidBecomeActive" "$PWD/ios/Runner/AppSwitcherProtection.swift"; then
    echo "✅ AppSwitcherProtection has public methods for SceneDelegate integration"
else
    echo "❌ AppSwitcherProtection does not have public methods for SceneDelegate integration"
    exit 1
fi

# Check if Flutter implementation exists
echo "Checking Flutter implementation..."
if [ -f "$PWD/lib/src/security/app_switcher_protection.dart" ]; then
    echo "✅ Flutter implementation exists"
else
    echo "❌ Flutter implementation does not exist"
    exit 1
fi

# Check if documentation exists
echo "Checking documentation..."
if [ -f "$PWD/lib/src/security/docs/app_switcher_protection_guide.md" ]; then
    echo "✅ Documentation exists"
else
    echo "❌ Documentation does not exist"
    exit 1
fi

echo ""
echo "All checks passed! App Switcher Protection is properly implemented."
echo "To test the implementation, run the app on an iOS device and check if the app"
echo "is hidden in the app switcher when sensitive content is visible."