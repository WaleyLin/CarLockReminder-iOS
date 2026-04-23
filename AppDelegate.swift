import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        // Set delegate so we can handle notification actions in-app
        UNUserNotificationCenter.current().delegate = self

        // Register the "I locked it" action on the notification itself
        let lockedAction = UNNotificationAction(
            identifier: "CONFIRM_LOCKED",
            title: "✅ Yes, I locked it",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: "CAR_LOCK_REMINDER",
            actions: [lockedAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])

        return true
    }

    // Show notification even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // Handle tapping the "I locked it" action button on the notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse,
                                 withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == "CONFIRM_LOCKED" {
            // Remove the notification and cancel any duplicates
            center.removeDeliveredNotifications(withIdentifiers: [response.notification.request.identifier])
        }
        completionHandler()
    }
}
