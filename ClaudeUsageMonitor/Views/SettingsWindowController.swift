import SwiftUI
import AppKit

/// Manages a standalone settings window
@MainActor
class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    private init() {}

    func showWindow(settingsManager: SettingsManager) {
        // If window exists and is visible, just bring to front
        if let window = window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create new window with settings content
        let settingsView = SettingsWindowContent(settingsManager: settingsManager) { [weak self] in
            self?.closeWindow()
        }

        let hostingView = NSHostingView(rootView: settingsView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 500)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Claude Usage Monitor Settings"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 350, height: 400)

        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeWindow() {
        window?.close()
    }
}

/// The content view for the settings window
struct SettingsWindowContent: View {
    @ObservedObject var settingsManager: SettingsManager
    var onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 5-Hour Thresholds
                thresholdSection(
                    title: "5-Hour Thresholds",
                    yellowBinding: $settingsManager.settings.fiveHour.yellowThreshold,
                    redBinding: $settingsManager.settings.fiveHour.redThreshold
                )

                Divider()

                // 7-Day Thresholds
                thresholdSection(
                    title: "7-Day Thresholds",
                    yellowBinding: $settingsManager.settings.sevenDay.yellowThreshold,
                    redBinding: $settingsManager.settings.sevenDay.redThreshold
                )

                Divider()

                // Colors
                colorsSection

                Divider()

                // Graph Settings
                graphSection

                Divider()

                // Automation
                automationSection

                Divider()

                // Reset button
                HStack {
                    Button("Reset to Defaults") {
                        settingsManager.resetToDefaults()
                    }

                    Spacer()

                    Button("Done") {
                        onClose()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(20)
        }
        .frame(minWidth: 350, minHeight: 400)
    }

    private func thresholdSection(title: String, yellowBinding: Binding<Double>, redBinding: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            HStack {
                Text("Yellow threshold:")
                    .frame(width: 120, alignment: .leading)
                Slider(value: yellowBinding, in: 0...100, step: 5)
                Text("\(Int(yellowBinding.wrappedValue))%")
                    .monospacedDigit()
                    .frame(width: 40)
            }

            HStack {
                Text("Red threshold:")
                    .frame(width: 120, alignment: .leading)
                Slider(value: redBinding, in: 0...100, step: 5)
                Text("\(Int(redBinding.wrappedValue))%")
                    .monospacedDigit()
                    .frame(width: 40)
            }
        }
    }

    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Colors")
                .font(.headline)

            HStack(spacing: 20) {
                colorPicker("Green", binding: colorBinding(\.green))
                colorPicker("Yellow", binding: colorBinding(\.yellow))
                colorPicker("Red", binding: colorBinding(\.red))
            }

            HStack(spacing: 20) {
                colorPicker("Outline", binding: colorBinding(\.outline))
                colorPicker("Time Ring", binding: colorBinding(\.timeRing))
            }

            HStack(spacing: 8) {
                Toggle(isOn: percentTextEnabled) {
                    Text("Custom % text")
                }
                .toggleStyle(.checkbox)

                if settingsManager.settings.colors.percentText != nil {
                    ColorPicker("", selection: percentTextColorBinding)
                        .labelsHidden()
                }
            }
        }
    }

    private var percentTextEnabled: Binding<Bool> {
        Binding(
            get: { settingsManager.settings.colors.percentText != nil },
            set: { enabled in
                if enabled {
                    settingsManager.settings.colors.percentText = .systemBlue
                } else {
                    settingsManager.settings.colors.percentText = nil
                }
            }
        )
    }

    private var percentTextColorBinding: Binding<Color> {
        Binding(
            get: { settingsManager.settings.colors.percentText?.color ?? .blue },
            set: { newColor in
                settingsManager.settings.colors.percentText = CodableColor(color: newColor)
            }
        )
    }

    private func colorPicker(_ label: String, binding: Binding<Color>) -> some View {
        HStack(spacing: 6) {
            Text(label)
            ColorPicker("", selection: binding)
                .labelsHidden()
        }
    }

    private func colorBinding(_ keyPath: WritableKeyPath<ColorSettings, CodableColor>) -> Binding<Color> {
        Binding(
            get: { settingsManager.settings.colors[keyPath: keyPath].color },
            set: { newColor in
                settingsManager.settings.colors[keyPath: keyPath] = CodableColor(color: newColor)
            }
        )
    }

    private var graphSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Graph")
                .font(.headline)

            HStack {
                Text("Time window:")
                    .frame(width: 120, alignment: .leading)
                Slider(value: $settingsManager.settings.graph.timeWindowHours, in: 1...168, step: 1)
                Text(formatTimeWindow(settingsManager.settings.graph.timeWindowHours))
                    .monospacedDigit()
                    .frame(width: 40)
            }
        }
    }

    private var automationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Automation")
                .font(.headline)

            Toggle(isOn: $settingsManager.settings.automation.enabled) {
                Text("Enable script trigger")
            }
            .toggleStyle(.checkbox)

            if settingsManager.settings.automation.enabled {
                Text("Run script when 5h usage exceeds threshold AND 7d usage is below threshold")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text("5h >")
                    TextField("", value: $settingsManager.settings.automation.fiveHourThreshold, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("% AND 7d <")
                    TextField("", value: $settingsManager.settings.automation.sevenDayThreshold, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("%")
                }

                HStack {
                    Text("Script:")
                    TextField("Path to script", text: Binding(
                        get: { settingsManager.settings.automation.scriptPath ?? "" },
                        set: { settingsManager.settings.automation.scriptPath = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)

                    Button("Browse...") {
                        browseForScript()
                    }
                }
            }
        }
    }

    private func formatTimeWindow(_ hours: Double) -> String {
        if hours < 24 {
            return "\(Int(hours))h"
        } else {
            return "\(Int(hours / 24))d"
        }
    }

    private func browseForScript() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.shellScript, .pythonScript, .executable]

        if panel.runModal() == .OK, let url = panel.url {
            settingsManager.settings.automation.scriptPath = url.path
        }
    }
}
