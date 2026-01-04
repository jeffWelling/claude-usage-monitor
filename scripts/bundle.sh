#!/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "Building ClaudeUsageMonitor..."
swift build -c release

echo "Creating app bundle..."
mkdir -p build/ClaudeUsageMonitor.app/Contents/MacOS
cp .build/release/ClaudeUsageMonitor build/ClaudeUsageMonitor.app/Contents/MacOS/
cp ClaudeUsageMonitor/Info.plist build/ClaudeUsageMonitor.app/Contents/

echo "Done! App bundle created at: build/ClaudeUsageMonitor.app"
echo ""
echo "To run: open build/ClaudeUsageMonitor.app"
