import Foundation
import SwiftUI

// MARK: - Codable Color Wrapper

struct CodableColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(color: Color) {
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor.gray
        self.red = Double(nsColor.redComponent)
        self.green = Double(nsColor.greenComponent)
        self.blue = Double(nsColor.blueComponent)
        self.alpha = Double(nsColor.alphaComponent)
    }

    init(nsColor: NSColor) {
        let converted = nsColor.usingColorSpace(.sRGB) ?? NSColor.gray
        self.red = Double(converted.redComponent)
        self.green = Double(converted.greenComponent)
        self.blue = Double(converted.blueComponent)
        self.alpha = Double(converted.alphaComponent)
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    var nsColor: NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    // System color presets
    static let systemGreen = CodableColor(nsColor: .systemGreen)
    static let systemYellow = CodableColor(nsColor: .systemYellow)
    static let systemRed = CodableColor(nsColor: .systemRed)
    static let systemBlue = CodableColor(nsColor: .systemBlue)
    static let grayOutline = CodableColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.3)
}

// MARK: - Settings Structs

struct MetricSettings: Codable, Equatable {
    var yellowThreshold: Double
    var redThreshold: Double

    static let fiveHourDefault = MetricSettings(yellowThreshold: 50, redThreshold: 80)
    static let sevenDayDefault = MetricSettings(yellowThreshold: 80, redThreshold: 95)
}

struct ColorSettings: Codable, Equatable {
    var green: CodableColor
    var yellow: CodableColor
    var red: CodableColor
    var outline: CodableColor
    var timeRing: CodableColor

    static let `default` = ColorSettings(
        green: .systemGreen,
        yellow: .systemYellow,
        red: .systemRed,
        outline: .grayOutline,
        timeRing: .systemBlue
    )
}

struct AutomationSettings: Codable, Equatable {
    var enabled: Bool
    var fiveHourThreshold: Double
    var sevenDayThreshold: Double
    var scriptPath: String?

    static let `default` = AutomationSettings(
        enabled: false,
        fiveHourThreshold: 80,
        sevenDayThreshold: 50,
        scriptPath: nil
    )
}

struct GraphSettings: Codable, Equatable {
    var timeWindowHours: Double

    static let `default` = GraphSettings(timeWindowHours: 3)
}

// MARK: - App Settings

struct AppSettings: Codable, Equatable {
    var fiveHour: MetricSettings
    var sevenDay: MetricSettings
    var colors: ColorSettings
    var automation: AutomationSettings
    var graph: GraphSettings

    static let `default` = AppSettings(
        fiveHour: .fiveHourDefault,
        sevenDay: .sevenDayDefault,
        colors: .default,
        automation: .default,
        graph: .default
    )

    /// Get color for a utilization value based on metric thresholds
    func colorForUtilization(_ value: Double, metric: MetricType) -> Color {
        let thresholds = metric == .fiveHour ? fiveHour : sevenDay
        switch value {
        case 0..<thresholds.yellowThreshold:
            return colors.green.color
        case thresholds.yellowThreshold..<thresholds.redThreshold:
            return colors.yellow.color
        default:
            return colors.red.color
        }
    }

    /// Get NSColor for a utilization value (for menu bar rendering)
    func nsColorForUtilization(_ value: Double, metric: MetricType) -> NSColor {
        let thresholds = metric == .fiveHour ? fiveHour : sevenDay
        switch value {
        case 0..<thresholds.yellowThreshold:
            return colors.green.nsColor
        case thresholds.yellowThreshold..<thresholds.redThreshold:
            return colors.yellow.nsColor
        default:
            return colors.red.nsColor
        }
    }
}

enum MetricType {
    case fiveHour
    case sevenDay
}

// MARK: - Settings Manager

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let userDefaultsKey = "com.local.ClaudeUsageMonitor.settings"

    @Published var settings: AppSettings {
        didSet {
            save()
        }
    }

    private init() {
        self.settings = Self.load(key: userDefaultsKey)
    }

    private static func load(key: String) -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }

    func resetToDefaults() {
        settings = .default
    }
}
