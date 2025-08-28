import UIKit
import Flutter

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        window = UIWindow(windowScene: windowScene)
        let flutterViewController = FlutterViewController()
        window?.rootViewController = flutterViewController
        window?.makeKeyAndVisible()
        
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
        
        // Register Flutter plugins
        GeneratedPluginRegistrant.register(with: flutterViewController)
    }
    
    // Called when the app is about to enter background or App Switcher
    @objc private func appWillResignActive(_ notification: Notification) {
        // Delegate to AppSwitcherProtection
        AppSwitcherProtection.shared.appWillResignActive(notification)
    }
    
    // Called when the app becomes active again
    @objc private func appDidBecomeActive(_ notification: Notification) {
        // Delegate to AppSwitcherProtection
        AppSwitcherProtection.shared.appDidBecomeActive(notification)
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called when the scene is being released by the system
        NotificationCenter.default.removeObserver(self)
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called when the scene transitions from the background to the foreground
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called when the scene transitions from the foreground to the background
    }
}