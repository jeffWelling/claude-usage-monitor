# Claude Usage Monitor

A macOS menu bar app that displays your Claude Code usage statistics (5-hour and 7-day utilization).

## Features

- Shows current 5-hour and 7-day usage percentages in the menu bar
- Color-coded progress bars (green < 50%, yellow 50-80%, red > 80%)
- Displays reset times for each usage window
- Auto-refreshes every 5 minutes
- Manual refresh option

## Screenshot

```
Menu Bar:  5h: 6% | 7d: 35%
```

Clicking shows:
- Progress bars for 5-hour and 7-day usage
- Reset countdown timers
- Opus usage (if applicable)
- Refresh and Quit options

## Requirements

- macOS 15.0 (Tahoe) or later
- Claude Code installed and logged in
- Swift toolchain (included with Xcode Command Line Tools)

## Building

```bash
# Clone the repository
git clone https://github.com/yourusername/claude-usage-monitor.git
cd claude-usage-monitor

# Build with Swift Package Manager
swift build -c release

# Create the app bundle
./scripts/bundle.sh
```

Or manually:

```bash
# Build
swift build -c release

# Create app bundle structure
mkdir -p build/ClaudeUsageMonitor.app/Contents/MacOS
cp .build/release/ClaudeUsageMonitor build/ClaudeUsageMonitor.app/Contents/MacOS/
cp ClaudeUsageMonitor/Info.plist build/ClaudeUsageMonitor.app/Contents/

# Run
open build/ClaudeUsageMonitor.app
```

## Installation

1. Build the app (see above)
2. Move `build/ClaudeUsageMonitor.app` to `/Applications/` (optional)
3. Launch the app

### Running Unsigned App

Since this app is not code-signed, you may need to bypass Gatekeeper on first launch:

1. Right-click on `ClaudeUsageMonitor.app`
2. Select "Open" from the context menu
3. Click "Open" in the dialog that appears

Alternatively, via Terminal:
```bash
xattr -cr ClaudeUsageMonitor.app
open ClaudeUsageMonitor.app
```

## How It Works

The app retrieves usage data from Anthropic's OAuth usage endpoint using your Claude Code credentials stored in the macOS Keychain. It displays:

- **5-Hour Usage**: Rolling 5-hour utilization percentage
- **7-Day Usage**: Weekly utilization percentage
- **Opus Usage**: Opus-specific 7-day utilization (if applicable)

## Data Source

The app reads your OAuth token from the macOS Keychain (stored by Claude Code) and queries:

```
GET https://api.anthropic.com/api/oauth/usage
```

This is the same endpoint that Claude Code's `/status` command uses.

## Troubleshooting

### "Claude Code credentials not found"

Ensure Claude Code is installed and you're logged in. The app looks for credentials in the Keychain under "Claude Code-credentials".

### "Token expired"

Your OAuth token has expired. Restart Claude Code to refresh it.

### App shows "⚠️" in menu bar

There was an error fetching usage data. Click on the icon to see the error message.

## Project Structure

```
claude-usage-monitor/
├── Package.swift                 # Swift Package Manager config
├── ClaudeUsageMonitor/
│   ├── ClaudeUsageMonitorApp.swift   # App entry point
│   ├── Info.plist                    # App bundle config
│   ├── Models/
│   │   └── UsageResponse.swift       # API response models
│   ├── Services/
│   │   ├── AnthropicAPI.swift        # API client
│   │   └── CredentialManager.swift   # Keychain access
│   ├── ViewModels/
│   │   └── UsageViewModel.swift      # State management
│   └── Views/
│       ├── MenuBarLabel.swift        # Menu bar title
│       └── UsageDetailView.swift     # Dropdown content
└── README.md
```

## License

MIT
