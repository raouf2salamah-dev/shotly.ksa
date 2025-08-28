import UIKit
import Flutter
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
  // Channel for communicating with Flutter about screenshots
  private var screenshotChannel: FlutterMethodChannel?
  
  // Support for SceneDelegate in iOS 13+
  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let sceneConfig = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    sceneConfig.delegateClass = SceneDelegate.self
    return sceneConfig
  }
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    
    // Register app switcher protection plugin
    AppSwitcherProtectionPlugin.register(with: self.registrar(forPlugin: "AppSwitcherProtectionPlugin")!)
    
    // Set up method channel for screenshot detection
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    screenshotChannel = FlutterMethodChannel(name: "com.shotly.app/screenshot", binaryMessenger: controller.binaryMessenger)
    
    // Register for screenshot notifications
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didTakeScreenshot),
      name: UIApplication.userDidTakeScreenshotNotification,
      object: nil
    )
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  @objc func didTakeScreenshot() {
    // Notify Flutter about the screenshot
    screenshotChannel?.invokeMethod("onScreenshot", arguments: nil)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
