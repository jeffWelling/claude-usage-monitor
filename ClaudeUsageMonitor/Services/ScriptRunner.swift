import Foundation

actor ScriptRunner {
    static let shared = ScriptRunner()

    private var lastExecutionTime: Date?
    private let minimumInterval: TimeInterval = 60  // Don't run more than once per minute

    private init() {}

    /// Execute the automation script if conditions are met
    /// Returns true if script was executed, false otherwise
    @discardableResult
    func executeIfNeeded(
        fiveHourUsage: Double,
        sevenDayUsage: Double,
        settings: AutomationSettings
    ) async -> Bool {
        // Check if automation is enabled
        guard settings.enabled else { return false }

        // Check if script path is set
        guard let scriptPath = settings.scriptPath, !scriptPath.isEmpty else { return false }

        // Check if conditions are met: 5h > threshold AND 7d < threshold
        guard fiveHourUsage > settings.fiveHourThreshold,
              sevenDayUsage < settings.sevenDayThreshold else {
            return false
        }

        // Throttle execution
        if let lastTime = lastExecutionTime,
           Date().timeIntervalSince(lastTime) < minimumInterval {
            return false
        }

        // Execute the script
        lastExecutionTime = Date()
        return await execute(scriptPath: scriptPath)
    }

    /// Execute a script at the given path
    private func execute(scriptPath: String) async -> Bool {
        let process = Process()
        let pipe = Pipe()

        // Determine how to execute based on file extension
        let url = URL(fileURLWithPath: scriptPath)
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "sh", "bash":
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [scriptPath]
        case "zsh":
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = [scriptPath]
        case "py":
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["python3", scriptPath]
        default:
            // Assume it's executable directly
            process.executableURL = url
            process.arguments = []
        }

        process.standardOutput = pipe
        process.standardError = pipe

        // Set environment variables that the script might find useful
        var environment = ProcessInfo.processInfo.environment
        environment["CLAUDE_USAGE_MONITOR_TRIGGER"] = "1"
        process.environment = environment

        do {
            try process.run()
            process.waitUntilExit()

            let exitCode = process.terminationStatus
            if exitCode != 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                print("[ScriptRunner] Script exited with code \(exitCode): \(output)")
            }

            return exitCode == 0
        } catch {
            print("[ScriptRunner] Failed to execute script: \(error)")
            return false
        }
    }

    /// Reset the execution throttle (for testing)
    func resetThrottle() {
        lastExecutionTime = nil
    }
}
