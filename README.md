# Claude Usage Monitor

A macOS menu bar app that displays your Claude Code usage statistics (5-hour and 7-day utilization).

## Features

- **Color-coded pie charts** in the menu bar showing usage percentage
  - Green: < 50% usage
  - Yellow: 50-80% usage
  - Red: > 80% usage
- **Blue time progress ring** around each pie showing elapsed time in the current window
- Displays reset countdown timers for each usage window
- Auto-refreshes every 3 minutes
- Manual refresh option

## Screenshot

Menu bar shows two pie charts with labels and time progress rings:
```
┌───┐      ┌───┐
│ ● │ 5h   │ ● │ 7d
└───┘      └───┘
  │          │
  │          └── 7-day usage pie (colored) with time ring (blue)
  └── 5-hour usage pie (colored) with time ring (blue)
```

- **Inner pie**: Usage percentage (green/yellow/red based on utilization)
- **Outer ring**: Blue arc showing time elapsed toward reset

Clicking shows:
- Detailed pie charts with percentages for 5-hour and 7-day usage
- Reset countdown timers
- Sonnet/Opus usage (if applicable)
- Refresh and Quit options

## Requirements

- macOS 15.0 (Tahoe) or later
- Claude Code installed and logged in
- Swift toolchain (included with Xcode or Command Line Tools)

## Building

```bash
# Clone the repository
git clone git@github.com:jeffWelling/claude-usage-monitor.git
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

## Creating a Release

To create a versioned release with DMG and ZIP:

```bash
# Using the release script
./scripts/release.sh 1.0.0

# Or using make
make release VERSION=1.0.0
```

This creates:
- `build/ClaudeUsageMonitor-X.Y.Z.dmg` - Disk image with drag-to-Applications
- `build/ClaudeUsageMonitor-X.Y.Z.zip` - Portable ZIP archive

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
- **Sonnet/Opus Usage**: Model-specific 7-day utilization (if applicable)

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

Your OAuth token has expired. Start a new Claude Code session to refresh it.

### App shows "⚠️" in menu bar

There was an error fetching usage data. Click on the icon to see the error message.

## Project Structure

```
claude-usage-monitor/
├── Package.swift                 # Swift Package Manager config
├── LICENSE                       # MIT License
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
│       ├── MenuBarLabel.swift        # Menu bar icon rendering
│       ├── PieChartView.swift        # Pie chart components
│       └── UsageDetailView.swift     # Dropdown content
├── scripts/
│   ├── bundle.sh                     # Development build script
│   └── release.sh                    # Versioned release script
└── resources/                        # App icon (optional)
```

## License

MIT - See [LICENSE](LICENSE) file.
