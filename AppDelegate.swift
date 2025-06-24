
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    var drivingAssistant: DrivingAssistant?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        drivingAssistant = DrivingAssistant()
        return true
    }
}
