import UIKit
import Flutter

// Define error types for overlay protection
@objc public enum OverlayError: Int, Error {
    case alreadyAdded = 0
    case failedToAdd = 1
}

@objc public class AppSwitcherProtection: NSObject {
    @objc public static let shared = AppSwitcherProtection()
    private var overlayView: UIView?
    private var hasSensitiveContent: Bool = false
    
    private override init() {
        super.init()
        // Register for app lifecycle notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIScene.willDeactivateNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIScene.didActivateNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Called when the app is about to enter background or App Switcher
    @objc public func appWillResignActive(_ notification: Notification) {
        print("App will resign active – entering App Switcher or background")
        
        // Only add overlay if sensitive content is visible
        if hasSensitiveContent, let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            // Create a single opaque black overlay without animations
            let overlay = UIView(frame: window.bounds)
            overlay.backgroundColor = .black
            overlay.tag = 999
            overlay.layer.speed = 0 // Disable animations
            window.addSubview(overlay)
            self.overlayView = overlay
        }
    }
    
    // Called when the app becomes active again
    @objc public func appDidBecomeActive(_ notification: Notification) {
        print("App did become active – remove overlay")
        
        // Remove overlay
        overlayView?.removeFromSuperview()
        overlayView = nil
    }
    
    // Method to be called from Flutter
    @objc public func setupProtection() {
        print("App switcher protection setup from Flutter")
        self.hasSensitiveContent = true
    }
    
    // Enable overlay protection with error handling
    @objc public func enableOverlayProtection() throws {
        print("Enabling overlay protection with error handling")
        
        // Check if overlay already exists
        if self.overlayView != nil {
            print("Overlay already exists. No action needed.")
            throw OverlayError.alreadyAdded
        }
        
        // Try to add overlay immediately for testing purposes
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            print("Failed to find key window. Check memory and view hierarchy.")
            throw OverlayError.failedToAdd
        }
        
        // Set sensitive content flag
        self.hasSensitiveContent = true
        
        return
    }
    
    // Method to disable protection when no sensitive content is visible
    @objc public func disableProtection() {
        print("App switcher protection disabled from Flutter")
        self.hasSensitiveContent = false
    }
}