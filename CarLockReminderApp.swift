import SwiftUI

@main
struct CarLockReminderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var assistant = DrivingAssistant()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(assistant)
                .preferredColorScheme(.dark)
        }
    }
}
