# Repository Guidelines

## Project Structure & Module Organization

`App/Sources/` contains the SwiftUI configuration and playground screens; `Keyboard/Sources/` contains the UIKit keyboard extension. `Shared/` holds code used by both targets, including models, prompts, networking, and the analysis pipeline. Keep shared behavior there so the app and keyboard stay consistent. UI automation is in `UITests/`; `tools/PromptCheck/` contains shared-logic regression checks. App icons and other assets are under `App/Assets.xcassets/`. Product and setup documentation lives in `README.md`, `README.en.md`, and `docs/`.

## Build, Test, and Development Commands

- `xcodegen generate` regenerates `JevJarvis.xcodeproj` from `project.yml` after project-definition changes.
- `xcodebuild -project JevJarvis.xcodeproj -target JevJarvis -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` checks an unsigned device build.
- `swiftc -o /tmp/jevcheck tools/PromptCheck/main.swift Shared/*.swift && /tmp/jevcheck` runs shared prompt and behavior regression checks on macOS.
- Run the `JevJarvis` scheme's XCTest UI tests from Xcode with an iPhone simulator selected. They cover launch, tab navigation, and keyboard setup; screenshot captures are in `ScreenshotTests.swift`.

For device installation, set the same Apple Developer Team on `JevJarvis` and `JevKeyboard`; both targets need matching App Group entitlements.

## Coding Style & Naming Conventions

Use four spaces for Swift indentation. Name types and protocols in `UpperCamelCase`; name properties, functions, and enum cases in `lowerCamelCase`. Keep app-specific UI in `App/`, keyboard UI in `Keyboard/`, and platform-neutral shared logic in `Shared/`. Follow nearby file organization and avoid adding dependencies for small utilities. No formatter or linter is configured.

## Testing Guidelines

Add UI coverage in `UITests/` for user-visible flows and name XCTest methods `test` followed by the behavior, such as `testColdLaunchSmoke`. Run the shared regression command when changing prompts, request construction, or shared pipeline behavior. Build the app after project or Swift changes; use a simulator for UI-test changes.

## Commit & Pull Request Guidelines

Recent commits use short `feat:`, `fix:`, `docs:`, and `chore:` prefixes, with English or Chinese descriptions. Keep each commit focused. Pull requests should explain the user-visible change, list validation performed, and include simulator screenshots for UI changes. Link related issues when applicable.

## Security & Review

Never commit API keys, signing credentials, or private chat content; provider keys belong in the app's local configuration. After implementation and relevant tests, run `codex-claude-review` as a read-only independent review, address valid findings, and repeat the review after material fixes.
