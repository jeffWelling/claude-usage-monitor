#!/bin/bash
# Bump the app version. Usage:
#   ./scripts/bump-version.sh patch   # 0.2.0 -> 0.2.1
#   ./scripts/bump-version.sh minor   # 0.2.0 -> 0.3.0
#   ./scripts/bump-version.sh major   # 0.2.0 -> 1.0.0
#   ./scripts/bump-version.sh 1.2.3   # set explicit version
set -e

cd "$(dirname "$0")/.."

VERSION_FILE="ClaudeUsageMonitor/AppVersion.swift"
PLIST_FILE="ClaudeUsageMonitor/Info.plist"

# Extract current version
CURRENT=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$VERSION_FILE")
if [ -z "$CURRENT" ]; then
    echo "Error: Could not read current version from $VERSION_FILE"
    exit 1
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

BUMP="${1:-patch}"

case "$BUMP" in
    patch)
        PATCH=$((PATCH + 1))
        NEW_VERSION="$MAJOR.$MINOR.$PATCH"
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        NEW_VERSION="$MAJOR.$MINOR.$PATCH"
        ;;
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        NEW_VERSION="$MAJOR.$MINOR.$PATCH"
        ;;
    *)
        # Treat as explicit version
        if [[ "$BUMP" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            NEW_VERSION="$BUMP"
        else
            echo "Usage: $0 [patch|minor|major|X.Y.Z]"
            exit 1
        fi
        ;;
esac

echo "$CURRENT -> $NEW_VERSION"

# Update AppVersion.swift
sed -i '' "s/\"$CURRENT\"/\"$NEW_VERSION\"/" "$VERSION_FILE"

# Update Info.plist
sed -i '' "s/<string>$CURRENT<\/string>/<string>$NEW_VERSION<\/string>/" "$PLIST_FILE"

echo "Updated $VERSION_FILE and $PLIST_FILE"
