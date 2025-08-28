# Security Features Documentation

## Security Goals

### Prevent Screenshots and Screen Recording

Our application implements robust protection mechanisms to prevent unauthorized capture of sensitive content:

- **Android**: Uses `FLAG_SECURE` to block screenshots and screen recordings at the OS level
- **iOS**: Implements custom overlay protection to prevent sensitive content from appearing in the app switcher
- **Both Platforms**: Detects screenshot attempts and triggers appropriate security responses

### Protect Sensitive Screens

Sensitive screens containing confidential information are protected through multiple layers:

- **Content Protection**: Sensitive widgets are wrapped with protection that hides content when the app goes to background
- **Overlay Protection**: Black overlays are applied when the app enters the background to prevent content from being visible in app switchers
- **Visibility Detection**: The app tracks when sensitive content becomes visible or hidden to dynamically apply protection

### Enforce Timeouts

To prevent unauthorized access after periods of inactivity:

- **Background Timeout**: Configurable timeout that triggers lock screen when the app returns from background after the specified period
- **Biometric Re-authentication**: Forces users to re-authenticate with biometrics after timeout periods
- **Sensitive Data Clearing**: Automatically clears sensitive data from memory when the app goes to background

## Architecture Overview

The security system consists of several interconnected components:

### Core Components

1. **SecurityService**: Central service that coordinates all security features
   - Manages platform-specific security implementations
   - Handles screenshot detection and prevention
   - Controls overlay protection for app switching

2. **SensitiveDataManager**: Manages sensitive data protection during app lifecycle changes
   - Monitors app state (foreground/background)
   - Clears sensitive data when app enters background
   - Triggers lock screen after timeout periods

3. **Native Platform Implementations**:
   - **Android**: Uses `FlutterWindowManager` to set `FLAG_SECURE`
   - **iOS**: Uses method channel to communicate with Swift implementation for overlay protection

### Communication Flow

The security components communicate through a well-defined flow:

1. Flutter UI components use `SecurityService` to protect sensitive content
2. `SecurityService` communicates with native code via method channels
3. `SensitiveDataManager` observes app lifecycle changes and triggers appropriate actions
4. Native implementations handle platform-specific security features

## Features

### 1. Screenshot Detection

**Supported Platforms:** iOS, Android

Detects when a user takes a screenshot of the app and triggers a callback that can be used to log the event, show a warning, or take other actions.

**Implementation:**
- iOS: Uses `UIApplication.userDidTakeScreenshotNotification` via method channel
- Android: Uses broadcast receiver for `ACTION_SCREENSHOT`

### 2. Screenshot Prevention

**Supported Platforms:** Android

Prevents screenshots from being taken while using the app.

**Implementation:**
- Android: Uses `FLAG_SECURE` window flag via the `flutter_windowmanager` package

### 3. App Switcher Content Protection

**Supported Platforms:** iOS

Hides sensitive content when the app appears in the app switcher (multitasking view).

**Implementation:**
- iOS: Uses app lifecycle notifications to add a single opaque black overlay only when sensitive content is visible
- Optimized to avoid animations and multiple layers for better performance
- Only activates when sensitive content (images/videos) is displayed

### 4. Sensitive Data Protection

**Supported Platforms:** iOS, Android

Automatically clears sensitive data from memory when the app enters the background to prevent data leakage.

**Implementation:**
- Uses Flutter's `WidgetsBindingObserver` to detect app lifecycle changes
- Clears in-memory caches, text controllers, and temporary storage when app enters background
- Integrates with App Switcher Protection on iOS for comprehensive security

### 5. Inactivity Timeout

**Supported Platforms:** iOS, Android

Automatically locks the app or requires re-authentication after a period of inactivity (when the app has been in the background for a specified time).

**Implementation:**
- Uses Flutter's `WidgetsBindingObserver` to track app lifecycle state changes
- Records timestamp when app enters background state
- Compares elapsed time when app returns to foreground
- Shows lock screen if inactivity period exceeds threshold (default: 5 minutes)

## Usage

### Security Service

The `SecurityService` class provides a unified API for all security features:

```dart
// Initialize security features
final securityService = SecurityService();
await securityService.initialize();

// Set callback for screenshot detection
securityService.setScreenshotCallback(() {
  print('Screenshot detected!');
});

// Set callback for clearing sensitive data when app enters background
securityService.setSensitiveDataCallback(() {
  // Clear sensitive data from memory
  textController.clear();
  cachedImages.clear();
  temporaryStorage.clear();
});

// Set callback for showing lock screen after inactivity timeout
securityService.setLockScreenCallback(() {
  // Show lock screen or authentication dialog
  Navigator.of(context).pushNamed('/auth-screen');
  // Or use a custom implementation
  showLockScreen(context);
});

// Check platform support
if (securityService.supportsScreenshotPrevention) {
  // Enable/disable secure screen (Android)
  await securityService.enableSecureScreen();
  // or
  await securityService.disableSecureScreen();
}

// Apply app switcher protection (iOS)
if (securityService.supportsAppSwitcherHiding) {
  // Enable protection when sensitive content is visible
  await securityService.setupIOSAppSwitcherProtection();
  
  // Disable protection when sensitive content is no longer visible
  await securityService.disableIOSAppSwitcherProtection();
  
  // Wrap sensitive widgets
  Widget protectedWidget = securityService.applyContentProtection(
    mySensitiveWidget
  );
}
```

### Direct Usage of SensitiveDataManager

For more granular control, you can use the `SensitiveDataManager` directly:

```dart
// Create a manager with custom callbacks
final sensitiveDataManager = SensitiveDataManager(
  securityService: securityService,
  onClearSensitiveData: () {
    // Custom logic to clear sensitive data
    mySecureCache.clear();
    passwordController.clear();
  },
  onShowLockScreen: () {
    // Custom logic to show lock screen after inactivity
    Navigator.of(context).pushNamed('/auth-screen');
  },
);

// Initialize in your widget's initState
@override
void initState() {
  super.initState();
  sensitiveDataManager.init();
}

// Dispose in your widget's dispose method
@override
void dispose() {
  sensitiveDataManager.dispose();
  super.dispose();
}

// You can also manually trigger the lock screen if needed
sensitiveDataManager.showLockScreen();
```

## Native Implementation

### iOS App Switcher Protection

The iOS implementation uses `SceneDelegate` lifecycle methods to add and remove a black overlay when the app enters or leaves the app switcher:

```swift
// Called when the app is about to enter background or App Switcher
@objc private func appWillResignActive(_ notification: Notification) {
    // Only add overlay if sensitive content is visible
    if hasSensitiveContent, let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
        // Create a single opaque black overlay without animations
        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = .black
        overlay.layer.speed = 0 // Disable animations
        window.addSubview(overlay)
        self.overlayView = overlay
    }
}

// Called when the app becomes active again
@objc private func appDidBecomeActive(_ notification: Notification) {
    // Remove overlay
    overlayView?.removeFromSuperview()
    overlayView = nil
}
```

## How Each Feature Works

### Overlay Protection

The overlay protection feature prevents sensitive content from appearing in the app switcher:

1. **Activation**: When sensitive content becomes visible, `applyContentProtection()` is called
2. **Detection**: `VisibilityDetector` monitors when protected content is visible
3. **Protection**: When app enters background, a black overlay is added via native code
4. **iOS Implementation**:
   - Swift code adds a `UIView` with black background to the app's window
   - Handles edge cases like memory limitations and existing overlays
5. **Error Handling**: Manages exceptions like `OVERLAY_ALREADY_ADDED` and `OVERLAY_FAILED_TO_ADD`

**Code Flow**:
```
User views sensitive content → VisibilityDetector triggers → setupIOSAppSwitcherProtection() → enableOverlayProtection() → Native method channel → Swift implementation adds black UIView
```

### Biometric Re-authentication

The biometric re-authentication feature ensures that only authorized users can access sensitive content after periods of inactivity:

1. **Configuration**: Security settings define whether biometrics are required
2. **Trigger**: When app returns from background after timeout period
3. **Lock Screen**: App shows lock screen requiring biometric authentication
4. **Verification**: User must authenticate with biometrics to continue using the app

**Code Flow**:
```
App goes to background → SensitiveDataManager records time → App returns to foreground → SensitiveDataManager checks elapsed time → If timeout exceeded, showLockScreen() → User authenticates with biometrics
```

### Timeout Enforcement

Timeout enforcement automatically secures the app after periods of inactivity:

1. **Configuration**: Security settings define timeout duration (default: 5 minutes)
2. **Monitoring**: `SensitiveDataManager` tracks when app enters background
3. **Time Tracking**: Records timestamp when app goes to background
4. **Verification**: When app returns to foreground, checks if timeout period has elapsed
5. **Action**: If timeout exceeded, triggers lock screen and requires re-authentication

**Code Flow**:
```
App goes to background → didChangeAppLifecycleState(AppLifecycleState.paused) → Record background time → App returns to foreground → didChangeAppLifecycleState(AppLifecycleState.resumed) → Check elapsed time → If timeout exceeded, showLockScreen()
```

## Deferred Loading Strategy for Media Packages

To enhance security and performance, our app implements deferred loading for media-related packages:

### Why Deferred Loading?

1. **Security**: Media packages often require additional permissions and access to sensitive device features
2. **Performance**: Media libraries are typically large and can slow down app startup
3. **Memory Optimization**: Loading only when needed reduces memory footprint
4. **User Experience**: Faster initial load times and smoother operation

### Implementation

We use Dart's deferred loading capability with our custom `DeferredLoader` utility:

```dart
// Import with deferred keyword
import 'package:image_picker/image_picker.dart' deferred as image_picker;
import '../utils/deferred_loader.dart';

// Create a loader
final _imagePickerLoader = DeferredLoader(image_picker.loadLibrary);

// Use it when needed
await _imagePickerLoader.ensureLoaded();
// Now you can use image_picker
final picker = image_picker.ImagePicker();
```

The `DeferredLoader` class ensures each library is loaded only once, even when called concurrently from multiple places in the code.

### Deferred Packages

We apply deferred loading to these security-sensitive packages:

1. **image_picker**: For accessing device camera and gallery
2. **file_picker**: For accessing device file system
3. **video_player**: For playing video content
4. **camera**: For accessing device cameras

### Security Benefits

- **Reduced Attack Surface**: Sensitive APIs are only loaded when explicitly needed
- **Permission Isolation**: Permissions are only requested when features are used
- **Resource Protection**: Media resources are loaded in a controlled manner

## Best Practices for Adding New Protected Screens

When adding new screens that contain sensitive information, follow these best practices:

### 1. Identify Sensitive Content

- Determine which parts of the screen contain sensitive information
- Consider both obvious (account numbers) and non-obvious (transaction patterns) sensitive data
- Document security requirements for the screen

### 2. Apply Content Protection

```dart
// Wrap sensitive widgets with content protection
SecurityService().applyContentProtection(
  child: SensitiveWidget(),
  isProtected: true,
);
```

### 3. Handle App Lifecycle

- Ensure the screen responds appropriately to app lifecycle changes
- Clear sensitive data when the screen is not visible
- Re-authenticate users when returning to sensitive screens after timeout

### 4. Implement Screenshot Detection

```dart
// Set up screenshot detection callback
SecurityService().setScreenshotCallback(() {
  // Handle screenshot attempt
  showSecurityAlert();
  clearSensitiveData();
});
```

### 5. Use Deferred Loading for Media

- Use deferred loading for any media-related functionality
- Follow the established pattern with `DeferredLoader`
- Show appropriate loading states during library loading

### 6. Test Security Features

- Verify screenshot prevention works on both platforms
- Test app switcher protection on iOS
- Confirm timeout and re-authentication function correctly
- Validate that sensitive data is cleared when app goes to background

### 7. Security Review Checklist

Before releasing a new protected screen, verify:

- [ ] All sensitive content is wrapped with protection
- [ ] Screenshot prevention is active
- [ ] App switcher protection is implemented
- [ ] Timeout enforcement is working
- [ ] Biometric re-authentication is triggered when required
- [ ] Sensitive data is cleared when app goes to background
- [ ] Deferred loading is used for media packages

## App Lifecycle and Overlay Activation Flow

The diagram below illustrates how security features interact with the app lifecycle:

```
App Active → Entering Background → In Background → Returning to Foreground
    ↓               ↓                    ↓                ↓
Monitoring     Clear Data          Overlay Active    Check Timeout
    ↓          Add Overlay             ↓                ↓
Protection    Record Time                         Show Lock Screen
                                                  (if needed)
```

1. **App Active**: Normal operation, security monitoring active
2. **Entering Background**:
   - `didChangeAppLifecycleState(AppLifecycleState.paused)` triggered
   - `clearSensitiveData()` called to remove sensitive data from memory
   - `enableOverlayProtection()` called to add black overlay (iOS)
   - Background timestamp recorded
3. **In Background**: Overlay active, sensitive data cleared
4. **Returning to Foreground**:
   - `didChangeAppLifecycleState(AppLifecycleState.resumed)` triggered
   - Time in background calculated and compared to timeout setting
   - If timeout exceeded, lock screen shown and biometric authentication required
   - If timeout not exceeded, normal operation resumes

This flow ensures that sensitive content is protected throughout the entire app lifecycle, with appropriate security measures applied at each stage.

## Security Considerations

- These features provide a robust level of protection but are not foolproof
- Users with rooted/jailbroken devices may bypass some protections
- External cameras can still capture screen content
- Consider additional encryption for highly sensitive data
- Regularly review and update security implementations as platform security features evolve