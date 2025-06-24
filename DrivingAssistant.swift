
import Foundation
import CoreMotion
import CoreLocation
import UserNotifications

class DrivingAssistant: NSObject, CLLocationManagerDelegate {
    private let motionManager = CMMotionActivityManager()
    private let locationManager = CLLocationManager()
    private var isDriving = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        startMonitoringMotion()
        requestNotificationPermission()
    }

    private func startMonitoringMotion() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        motionManager.startActivityUpdates(to: OperationQueue.main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }

            if activity.automotive && !self.isDriving {
                self.isDriving = true
                NotificationCenter.default.post(name: .drivingStatusChanged, object: true)
            } else if !activity.automotive && self.isDriving {
                self.isDriving = false
                NotificationCenter.default.post(name: .drivingStatusChanged, object: false)
                self.triggerLockReminder()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Optional: use to refine location-based stopping detection
    }

    private func triggerLockReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Did you lock your car?"
        content.body = "You just stopped driving. Make sure your car is locked."
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
