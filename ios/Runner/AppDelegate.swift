import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if FirebaseApp.app() == nil {
      // If GoogleService-Info.plist is missing, FirebaseApp.configure()
      // can hard-crash the app. Only attempt configure when the plist exists.
      let hasGoogleServicePlist = Bundle.main.path(
        forResource: "GoogleService-Info",
        ofType: "plist"
      ) != nil

      if hasGoogleServicePlist {
        FirebaseApp.configure()
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
