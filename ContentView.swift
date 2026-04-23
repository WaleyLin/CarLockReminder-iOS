import SwiftUI

struct ContentView: View {
    @EnvironmentObject var assistant: DrivingAssistant
    @State private var showSettings = false
    @State private var showLockedConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: assistant.isDriving
                        ? [Color.blue.opacity(0.15), Color.black]
                        : [Color.green.opacity(0.1), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {

                    // ── Status Card ──
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(assistant.isDriving ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                                .frame(width: 130, height: 130)

                            Image(systemName: assistant.isDriving ? "car.fill" : "lock.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 56, height: 56)
                                .foregroundColor(assistant.isDriving ? .blue : .green)
                        }
                        .animation(.easeInOut(duration: 0.4), value: assistant.isDriving)

                        Text(assistant.isDriving ? "Driving" : "Parked")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(assistant.isDriving
                            ? "Trip in progress — you'll be reminded when you park."
                            : lastTripText)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // ── Enabled Toggle ──
                    Toggle(isOn: Binding(
                        get: { assistant.isEnabled },
                        set: { assistant.setEnabled($0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reminders Enabled")
                                .foregroundColor(.white)
                                .font(.subheadline.weight(.semibold))
                            Text("Notifies you after every drive")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.caption)
                        }
                    }
                    .tint(.green)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)

                    // ── Reminder Delay Slider ──
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Notify after parking")
                                .foregroundColor(.white)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(assistant.reminderDelay)s")
                                .foregroundColor(.green)
                                .font(.subheadline.weight(.bold))
                                .monospacedDigit()
                        }

                        Slider(value: Binding(
                            get: { Double(assistant.reminderDelay) },
                            set: { assistant.reminderDelay = Int($0) }
                        ), in: 10...120, step: 5)
                        .tint(.green)

                        HStack {
                            Text("10s")
                            Spacer()
                            Text("2 min")
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .disabled(!assistant.isEnabled)
                    .opacity(assistant.isEnabled ? 1 : 0.4)

                    // ── "I Locked It" Button ──
                    if !assistant.isDriving {
                        Button {
                            assistant.confirmLocked()
                            showLockedConfirm = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showLockedConfirm = false
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: showLockedConfirm ? "checkmark.circle.fill" : "lock.shield.fill")
                                Text(showLockedConfirm ? "Got it!" : "Yes, I Locked It")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(showLockedConfirm ? Color.green : Color.white.opacity(0.12))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .animation(.easeInOut(duration: 0.2), value: showLockedConfirm)
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                InfoSheet()
            }
        }
    }

    private var lastTripText: String {
        guard let ended = assistant.lastTripEndedAt else {
            return "Open the app before your drive so it can track your trip."
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Last trip ended \(formatter.localizedString(for: ended, relativeTo: Date()))"
    }
}

// MARK: - Info Sheet
struct InfoSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    infoRow(icon: "car.fill", color: .blue,
                            title: "How It Works",
                            body: "The app uses your iPhone's motion sensor to detect when you're driving. Once you stop and get out, it sends you a notification after your chosen delay.")

                    infoRow(icon: "timer", color: .orange,
                            title: "Why the Delay?",
                            body: "The notification fires after a short delay (default 30s) so you have time to actually walk away from the car before being reminded.")

                    infoRow(icon: "bolt.slash.fill", color: .yellow,
                            title: "False Triggers",
                            body: "The app waits 45 seconds before confirming you've stopped driving — so red lights, traffic jams, and brief pauses won't set it off.")

                    infoRow(icon: "battery.100", color: .green,
                            title: "Battery Usage",
                            body: "Motion detection is handled by a low-power coprocessor. Only significant location changes are used to keep the app alive in the background.")

                    infoRow(icon: "location.slash.fill", color: .gray,
                            title: "Privacy",
                            body: "No location data is stored or sent anywhere. Everything stays on your device. Location is only used to keep the app running in the background.")
                }
                .padding(24)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.green)
                }
            }
        }
    }

    @ViewBuilder
    private func infoRow(icon: String, color: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text(body)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
