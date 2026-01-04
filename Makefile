.PHONY: build release clean run install

APP_NAME = ClaudeUsageMonitor
BUILD_DIR = build

# Development build
build:
	swift build
	@echo "Built debug binary at .build/debug/$(APP_NAME)"

# Create app bundle for development
bundle: build
	./scripts/bundle.sh

# Create versioned release (pass VERSION=x.y.z or will prompt)
release:
	./scripts/release.sh $(VERSION)

# Run the app
run: bundle
	open $(BUILD_DIR)/$(APP_NAME).app

# Install to /Applications
install: release
	@echo "Installing to /Applications..."
	rm -rf /Applications/$(APP_NAME).app
	cp -R $(BUILD_DIR)/$(APP_NAME).app /Applications/
	@echo "Installed! Launch from Applications or Spotlight."

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -rf .build
	@echo "Cleaned build artifacts"

# Show help
help:
	@echo "Usage:"
	@echo "  make build    - Build debug binary"
	@echo "  make bundle   - Create .app bundle (debug)"
	@echo "  make release  - Create versioned release (VERSION=x.y.z)"
	@echo "  make run      - Build and run the app"
	@echo "  make install  - Install to /Applications"
	@echo "  make clean    - Remove build artifacts"
