# App Switcher Protection Guide

## Overview

App Switcher Protection is a security feature that prevents sensitive content from being visible in the iOS app switcher. When a user double-presses the home button or swipes up from the bottom of the screen (on devices without a home button), iOS displays a preview of all running apps. This feature adds a black overlay to your app's window when it enters the background, ensuring that sensitive information is not visible in these previews.

## Implementation Details

The implementation consists of several components:

1. **SceneDelegate Integration**: Uses iOS 13+ scene lifecycle methods to detect when the app enters or leaves the app switcher.
2. **Native Swift Code**: Adds and removes a black overlay view when the app transitions between states.
3. **Flutter Platform Channel**: Provides a Dart API for controlling the protection from Flutter code.

## How to Use

### Basic Usage

```dart
import 'package:shotly/src/security/app_switcher_protection.dart';

// Get the singleton instance
final appSwitcherProtection = AppSwitcherProtection();

// Check if the feature is supported on the current platform
if (appSwitcherProtection.isSupported) {
  // Enable protection
  await appSwitcherProtection.enableProtection();
  
  // Disable protection when no longer needed
  await appSwitcherProtection.disableProtection();
}
```

### With Error Handling

```dart
try {
  await appSwitcherProtection.enableProtectionWithErrorHandling();
} catch (error) {
  if (error.toString().contains('OverlayError.alreadyAdded')) {
    print("Overlay already exists. No action needed.");
  } else if (error.toString().contains('OverlayError.failedToAdd')) {
    print("Failed to add overlay. Check memory and view hierarchy.");
  } else {
    print("Unexpected error: ${error.toString()}");
  }
}
```

## Integration with SecurityService

The `SecurityService` class provides a higher-level API for using app switcher protection:

```dart
// Check if app switcher protection is supported
if (securityService.supportsAppSwitcherHiding) {
  // Enable protection
  await securityService.setupIOSAppSwitcherProtection();
  
  // Or with error handling
  await securityService.setupIOSAppSwitcherProtectionWithErrorHandling();
  
  // Disable protection
  await securityService.disableIOSAppSwitcherProtection();
}
```

## Protecting Specific Content

You can use the `applyContentProtection` method to automatically enable app switcher protection when specific content is visible:

```dart
// Wrap sensitive content with protection
Widget protectedContent = securityService.applyContentProtection(
  mySensitiveWidget,
  isProtected: true,
);
```

This will automatically enable app switcher protection when the content becomes visible and disable it when the content is hidden.

## Technical Implementation

### iOS Native Code

The implementation uses the following components:

1. **SceneDelegate.swift**: Implements the UIWindowSceneDelegate protocol to handle scene lifecycle events.
2. **AppSwitcherProtection.swift**: Contains the core logic for adding and removing the overlay.
3. **AppSwitcherProtectionPlugin.swift**: Provides the platform channel implementation for communicating with Flutter.

### Flutter Code

1. **app_switcher_protection.dart**: Provides a Dart API for controlling the protection.
2. **security_service.dart**: Integrates app switcher protection with other security features.

## Best Practices

1. **Selective Protection**: Only enable protection when sensitive content is visible.
2. **User Control**: Consider providing a setting for users to enable/disable this feature.
3. **Testing**: Test the feature on different iOS versions and device types.
4. **Error Handling**: Always handle potential errors when enabling or disabling protection.

## Limitations

1. **iOS Only**: This feature is only available on iOS devices.
2. **iOS 13+**: Scene-based implementation requires iOS 13 or later.
3. **Memory Usage**: Adding overlays consumes additional memory.

## Troubleshooting

### Common Issues

1. **Overlay Not Appearing**: Ensure that `hasSensitiveContent` is set to true before the app enters the background.
2. **Multiple Overlays**: Check for existing overlays before adding new ones to prevent stacking.
3. **Performance Issues**: Disable animations on the overlay to prevent performance degradation.

### Debugging

The implementation includes debug logging that can help identify issues:

```
App will resign active – entering App Switcher or background
App did become active – remove overlay
```

Check the Xcode console for these messages when testing the feature.