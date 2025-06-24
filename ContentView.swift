import SwiftUI

struct ContentView: View {
    @State private var isDriving: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: isDriving ? "car.fill" : "parkingsign.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(isDriving ? .blue : .green)
            Text(isDriving ? "Driving Detected" : "Not Driving")
                .font(.title2)
            Text("You'll be notified when your trip ends to check if you locked your car.")
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: .drivingStatusChanged)) { notif in
            if let status = notif.object as? Bool {
                isDriving = status
            }
        }
    }
}
