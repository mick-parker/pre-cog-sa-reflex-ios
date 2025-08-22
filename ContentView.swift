import SwiftUI

struct ContentView: View {
    @StateObject private var manager = PreCogManager()

    var body: some View {
        VStack {
            Text("Pre-Cognitive SA Reflex")
                .font(.largeTitle)
                .padding()

            if manager.alertTriggered {
                Text("⚠️ Alert Triggered!")
                    .foregroundColor(.red)
                    .font(.headline)
            } else {
                Text("Monitoring environment...")
                    .foregroundColor(.gray)
            }
        }
    }
}
