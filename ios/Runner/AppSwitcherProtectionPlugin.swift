import Flutter
import UIKit

public class AppSwitcherProtectionPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.shotly.app/screenshot", binaryMessenger: registrar.messenger())
        let instance = AppSwitcherProtectionPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setupAppSwitcherProtection":
            AppSwitcherProtection.shared.setupProtection()
            result(nil)
        case "disableAppSwitcherProtection":
            AppSwitcherProtection.shared.disableProtection()
            result(nil)
        case "enableOverlayProtection":
            do {
                try AppSwitcherProtection.shared.enableOverlayProtection()
                result(nil)
            } catch let error as OverlayError {
                switch error {
                case .alreadyAdded:
                    result(FlutterError(code: "OVERLAY_ALREADY_ADDED", 
                                       message: "Overlay already exists. No action needed.", 
                                       details: nil))
                case .failedToAdd:
                    result(FlutterError(code: "OVERLAY_FAILED_TO_ADD", 
                                       message: "Failed to add overlay. Check memory and view hierarchy.", 
                                       details: nil))
                }
            } catch {
                result(FlutterError(code: "UNEXPECTED_ERROR", 
                                   message: "Unexpected error: \(error.localizedDescription)", 
                                   details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}