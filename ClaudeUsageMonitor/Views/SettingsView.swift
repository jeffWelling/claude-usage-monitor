import SwiftUI

/// A simple button that opens the settings window
struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager

    var body: some View {
        Button(action: {
            SettingsWindowController.shared.showWindow(settingsManager: settingsManager)
        }) {
            Label("Settings", systemImage: "gearshape")
        }
    }
}
