# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Test Commands

### Package Building
```bash
# Build the library
swift build

# Build the CLI tool
swift build --product demark

# Build for release
swift build -c release --product demark

# Build for specific platform
swift build -Xswiftc -target -Xswiftc x86_64-apple-macos14.0
```

### Testing
```bash
# Run all tests (uses both XCTest and swift-testing)
swift test

# Run specific test suite
swift test --filter DemarkIntegrationTests

# Run with verbose output
swift test --parallel --verbose
```

### Running the Example App
```bash
# Quick way - use the helper script
./run-example.sh

# Manual way
cd Example
swift run DemarkExample

# Generate Xcode project for example (requires XcodeGen)
cd Example
./generate-xcodeproj.sh
```

### Code Quality
```bash
# Run all linting and formatting checks
./scripts/lint.sh

# Run SwiftFormat (check only)
./scripts/swiftformat.sh --check

# Run SwiftFormat (auto-fix)
./scripts/swiftformat.sh

# Run SwiftLint
./scripts/swiftlint.sh

# Run SwiftLint with auto-fix
./scripts/swiftlint.sh --fix
```

## Architecture Overview

### Main Components

1. **Demark Core** (`Sources/Demark/`)
   - `Demark.swift`: Main API entry point, @MainActor isolated
   - `DemarkTypes.swift`: Public types and configuration options
   - `TurndownRuntime.swift`: WKWebView-based Turndown.js implementation
   - `HTMLToMdRuntime.swift`: JavaScriptCore-based html-to-md implementation
   - `BundleResourceHelper.swift`: Resource loading utilities

2. **Dual Engine Architecture**
   - **Turndown.js**: Full DOM parsing via WKWebView, most accurate but slower (~100ms first, ~10-50ms subsequent)
   - **html-to-md**: Lightweight JavaScriptCore engine, faster (~5-10ms) but less accurate

3. **CLI Tool** (`Sources/DemarkCLI/`)
   - Uses Swift Argument Parser
   - Supports both conversion engines
   - Handles file input/output and stdin/stdout

### Key Design Decisions

1. **Main Actor Requirement**: All public APIs are @MainActor due to WKWebView constraints
2. **Swift 6 Concurrency**: Full strict concurrency checking enabled
3. **Resource Bundling**: JavaScript libraries bundled as resources, loaded dynamically
4. **Protocol-Based Design**: Clean separation between different runtime implementations
5. **Error Handling**: Comprehensive error types with localized descriptions

### Testing Strategy

- **Migration in Progress**: Moving from XCTest to swift-testing
- **Integration Tests**: Test actual HTML to Markdown conversions
- **Service Tests**: Test individual components and edge cases
- **Platform Coverage**: Tests run on all supported platforms

### Important Notes

- WKWebView requires main thread execution - all conversions must happen on @MainActor
- The package has zero external dependencies (only uses WebKit framework)
- JavaScript libraries are minified and bundled in Resources/
- Swift 6 language mode is enforced throughout the project