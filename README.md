# Car Lock Reminder – iOS App 🚗🔔

This SwiftUI-based iOS app automatically detects when you're driving and sends a reminder notification once you've parked to ask: **“Did you lock your car?”**

## 📱 Features
- Detects driving status using Core Motion and Core Location
- Sends a local notification immediately after you stop driving
- SwiftUI interface that updates based on your activity
- Lightweight, privacy-conscious – no tracking or background location logging

## 🧠 How It Works
- The app uses `CMMotionActivityManager` to detect automotive motion.
- When driving stops, it triggers a local notification using `UNUserNotificationCenter`.
- Driving state updates the UI in real time using `NotificationCenter`.

## 🛠️ Technologies Used
- Swift
- SwiftUI
- Core Motion
- Core Location
- UserNotifications

## 📸 Screenshots
Coming soon – or build and run the app in Xcode to see the live UI!

## 🧪 Setup Instructions
1. Open the project in **Xcode**.
2. Add the following keys to `Info.plist`:
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>App needs location access to detect driving status.</string>
   <key>NSMotionUsageDescription</key>
   <string>App needs motion data to detect driving.</string>
   <key>NSUserTrackingUsageDescription</key>
   <string>We use this to detect when you're in a car and remind you after parking.</string>
