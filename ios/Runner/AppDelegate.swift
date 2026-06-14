import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let screenSecurityChannel = "omega/screen_security"
    private var isScreenSecurityEnabled = false

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Screen security MethodChannel
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: screenSecurityChannel,
                binaryMessenger: controller.binaryMessenger
            )
            channel.setMethodCallHandler { [weak self] call, result in
                switch call.method {
                case "enable":
                    self?.isScreenSecurityEnabled = true
                    result(nil)
                case "disable":
                    self?.isScreenSecurityEnabled = false
                    result(nil)
                case "isEnabled":
                    result(self?.isScreenSecurityEnabled ?? false)
                default:
                    result(FlutterMethodNotImplemented)
                }
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Block screenshots when screen security is enabled
    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        if isScreenSecurityEnabled {
            window?.isHidden = false
        }
    }

    override func applicationWillResignActive(_ application: UIApplication) {
        super.applicationWillResignActive(application)
        if isScreenSecurityEnabled {
            // Show a blank overlay in the app switcher
            window?.isHidden = true
        }
    }
}
