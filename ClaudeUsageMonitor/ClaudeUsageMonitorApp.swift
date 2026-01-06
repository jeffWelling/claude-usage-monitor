import SwiftUI

@main
struct ClaudeUsageMonitorApp: App {
    @StateObject private var viewModel = UsageViewModel()
    @StateObject private var settingsManager = SettingsManager.shared

    var body: some Scene {
        MenuBarExtra {
            UsageDetailView(viewModel: viewModel, settingsManager: settingsManager)
        } label: {
            MenuBarLabel(viewModel: viewModel, settingsManager: settingsManager)
        }
        .menuBarExtraStyle(.window)
    }
}
