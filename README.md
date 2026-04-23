# 🔒 Car Lock Reminder – iOS

An iOS app that automatically detects when you finish a drive and sends a push notification reminding you to lock your car. No manual input needed — open it once, and it runs in the background.

![Swift](https://img.shields.io/badge/Swift-5.9-FA7343?style=flat&logo=swift&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-16%2B-000000?style=flat&logo=apple&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-darkblue?style=flat&logo=swift&logoColor=white)

---

## How It Works

1. The app uses `CMMotionActivityManager` to detect when your iPhone thinks you're driving
2. When automotive motion stops and stays stopped for **45 seconds** (avoids false triggers at red lights), it confirms your trip ended
3. After your configured delay (default 30s — enough time to walk away from the car), a notification fires: **"Did you lock your car?"**
4. The notification has an action button — **"Yes, I locked it"** — right on the lock screen, no need to open the app
5. If you start driving again before the notification fires, it's automatically cancelled

---

## Features

- **Smart debounce** — waits 45s after stopping before confirming a trip ended, so red lights and traffic don't trigger it
- **Configurable delay** — slider in the app lets you choose 10s–2min between parking and getting notified
- **"I locked it" button** — dismisses the notification directly from the lock screen via a notification action
- **Master toggle** — enable/disable reminders without closing the app
- **Cooldown** — 5-minute cooldown between reminders prevents spam during stop-and-go situations
- **Low battery impact** — uses the M-series motion coprocessor for activity detection; only significant location changes to maintain background execution
- **Always dark UI** — designed to be glanceable in a car at night

---

## What Was Improved (vs original)

| Issue | Before | After |
|---|---|---|
| Notification timing | Fired after 1 second (before leaving car) | Fires after user-configured delay (default 30s) |
| False triggers | Any motion stop triggered it | 45s debounce filters out red lights/traffic |
| Noise filtering | Accepted low-confidence motion readings | Ignores `.low` confidence activity updates |
| Spam | No cooldown between reminders | 5-minute cooldown between notifications |
| Lock screen action | None — had to open app | "Yes, I locked it" button directly on notification |
| If driving resumes | Notification still sent | Pending notification cancelled immediately |
| UI | Static car icon + one line of text | Status card, delay slider, enabled toggle, "I locked it" button |
| ObservableObject | No reactive state | `DrivingAssistant` is `@ObservableObject`, UI updates live |

---

## Setup

1. Clone the repo and open in **Xcode 15+**
2. Set your Team in **Signing & Capabilities**
3. Add these keys to `Info.plist`:

```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Used to keep the app running in the background while you drive.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Used to detect when your trip ends.</string>

<key>NSMotionUsageDescription</key>
<string>Used to detect when you start and stop driving.</string>
```

4. In **Signing & Capabilities**, add:
   - `Background Modes` → check **Location updates**

5. Build and run on a **physical device** (motion activity doesn't work in the simulator)

> **Note:** The first time you run it, iOS will ask for Location (choose "Always Allow") and Motion permissions. Both are required for background detection.

---

## Project Structure

```
CarLockReminder/
├── CarLockReminderApp.swift   # App entry point, injects DrivingAssistant as @EnvironmentObject
├── AppDelegate.swift          # Registers notification category + "I locked it" action handler
├── DrivingAssistant.swift     # Core logic — motion detection, debounce, notification scheduling
├── ContentView.swift          # UI — status card, delay slider, toggle, info sheet
└── Extensions.swift           # Notification.Name extension
```

---

## Tech Stack

| Framework | Usage |
|---|---|
| SwiftUI | UI and reactive state |
| CoreMotion | `CMMotionActivityManager` for automotive activity detection |
| CoreLocation | Significant location changes to maintain background execution |
| UserNotifications | Local notifications with action buttons |

---

## Known Limitations

- **Simulator only shows "Not Driving"** — `CMMotionActivityManager` requires a real device
- **iOS may delay background execution** on battery saver mode — notification might arrive a bit late
- **Requires "Always" location permission** — "While Using" won't keep the app alive when you lock your phone and drive away

---

## What I Learned

- Using `CMMotionActivityManager` and understanding activity confidence levels (`.low`, `.medium`, `.high`)
- Building a debounce pattern with `DispatchWorkItem` that can be cancelled mid-flight
- Registering `UNNotificationCategory` and `UNNotificationAction` to add interactive buttons to lock screen notifications
- Managing background execution on iOS using significant location change monitoring
- Passing shared state through a SwiftUI app with `@EnvironmentObject` and `@ObservableObject`
- Handling the `UNUserNotificationCenterDelegate` to present banners while the app is in the foreground
