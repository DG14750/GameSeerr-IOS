import UIKit
import FirebaseCore

@main

class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    FirebaseApp.configure()
    print("Firebase configured")
      FirebaseManager.shared.authenticatedPing()
    return true
  }
}
