import Foundation
import CoreMotion
import CoreLocation
import UserNotifications

class DrivingAssistant: NSObject, CLLocationManagerDelegate, ObservableObject {

    // MARK: - Published state (drives the UI)
    @Published var isDriving: Bool = false
    @Published var lastTripEndedAt: Date? = nil
    @Published var reminderDelay: Int = 30  // seconds after stopping before notifying
    @Published var isEnabled: Bool = true   // master on/off toggle

    // MARK: - Private
    private let motionManager = CMMotionActivityManager()
    private let locationManager = CLLocationManager()

    /// How long a non-automotive activity must persist before we consider driving stopped.
    /// Prevents false triggers at red lights, traffic, etc.
    private let stopDebounceInterval: TimeInterval = 45

    /// Minimum time between reminders (prevents spam on stop-and-go trips)
    private let cooldownInterval: TimeInterval = 300  // 5 minutes

    /// Pending work item — cancelled if driving resumes before debounce fires
    private var stopDebounceWork: DispatchWorkItem?

    /// Timestamp of the last reminder sent
    private var lastReminderSentAt: Date? = nil

    /// Identifier of the pending notification so we can cancel it if user drives again
    private let notificationIdentifier = "car-lock-reminder"

    // MARK: - Init
    override init() {
        super.init()
        setupLocationManager()
        requestNotificationPermission()
        startMonitoringMotion()
    }

    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.activityType = .automotiveNavigation
        locationManager.requestAlwaysAuthorization()
        locationManager.startMonitoringSignificantLocationChanges()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if !granted {
                print("CarLockReminder: Notification permission denied.")
            }
        }
    }

    // MARK: - Motion Monitoring
    private func startMonitoringMotion() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            print("CarLockReminder: Motion activity not available on this device.")
            return
        }

        motionManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self = self, let activity = activity, self.isEnabled else { return }

            // Only act on high or medium confidence readings to reduce noise
            guard activity.confidence != .low else { return }

            let isAutomotive = activity.automotive

            if isAutomotive && !self.isDriving {
                self.handleDrivingStarted()
            } else if !isAutomotive && self.isDriving {
                // Might have stopped — start debounce (catches red lights, brief stops)
                self.startStopDebounce()
            }
        }
    }

    // MARK: - Driving Started
    private func handleDrivingStarted() {
        stopDebounceWork?.cancel()
        stopDebounceWork = nil

        // Cancel any already-scheduled reminder from a recent stop
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])

        DispatchQueue.main.async {
            self.isDriving = true
            NotificationCenter.default.post(name: .drivingStatusChanged, object: true)
        }
    }

    // MARK: - Stop Debounce
    private func startStopDebounce() {
        stopDebounceWork?.cancel()

        let work = DispatchWorkItem { [weak self] in
            self?.handleDrivingConfirmedStopped()
        }
        stopDebounceWork = work

        DispatchQueue.main.asyncAfter(deadline: .now() + stopDebounceInterval, execute: work)
    }

    // MARK: - Driving Confirmed Stopped
    private func handleDrivingConfirmedStopped() {
        DispatchQueue.main.async {
            self.isDriving = false
            self.lastTripEndedAt = Date()
            NotificationCenter.default.post(name: .drivingStatusChanged, object: false)
        }

        // Cooldown check — don't spam if multiple stops happen quickly
        if let lastSent = lastReminderSentAt,
           Date().timeIntervalSince(lastSent) < cooldownInterval {
            return
        }

        scheduleReminder()
    }

    // MARK: - Schedule Notification
    private func scheduleReminder() {
        let content = UNMutableNotificationContent()
        content.title = "🔒 Did you lock your car?"
        content.body = "You just ended a drive. Tap to confirm you locked up."
        content.sound = .default
        content.categoryIdentifier = "CAR_LOCK_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(max(reminderDelay, 1)),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if error == nil {
                DispatchQueue.main.async {
                    self?.lastReminderSentAt = Date()
                }
            }
        }
    }

    // MARK: - User Actions
    func confirmLocked() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notificationIdentifier])
        lastReminderSentAt = Date()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            stopDebounceWork?.cancel()
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        }
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {}

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("CarLockReminder: Location error — \(error.localizedDescription)")
    }
}
