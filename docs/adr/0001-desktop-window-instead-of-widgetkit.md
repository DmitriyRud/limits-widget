# ADR-0001: Desktop-Level Window Instead of WidgetKit

- Status: accepted (approved alongside `specs/001-limits-widget-mvp/plan.md`)
- Date: 2026-11-09

## Context
Starting with macOS 14, WidgetKit widgets can be placed on the desktop. However:
- A WidgetKit extension must run in the App Sandbox, which blocks direct read access to `~/.codex`, `~/.gemini`, and other apps' Keychain items; it would require a companion host process, App Group, and a signed Apple Developer Team ID.
- WidgetKit requires an Xcode project and provisioning profiles, breaking Constitution principle III.2 (build with `swift build`).
- WidgetKit timelines are throttled by the OS budget and cannot guarantee minute-by-minute countdown updates.

## Decision
Build a standalone SwiftPM application (`LSUIElement`, no Dock icon) hosting a borderless `NSPanel` at window level `CGWindowLevelForKey(.desktopIconWindow) + 1` (above desktop icons, below regular windows; see Refinement below) with `collectionBehavior = [.canJoinAllSpaces, .stationary]` and SwiftUI content, plus a `MenuBarExtra` for controls.

## Consequences
+ Full read-only access to agent files/Keychain without sandbox restrictions, single-command SPM build, exact 60-second countdown timer.
− Not a native Notification Center widget (not managed via macOS "Edit Widgets").
→ A WidgetKit target can still be added later while reusing `LimitsCore` unchanged.

## Refinement (2026-11-09, owner decision)
Window level is set to `desktopIconWindow + 1` instead of exactly `desktopIconWindow`: at the exact desktop icon level, z-order relative to Finder icons is not guaranteed and mouse dragging can fail. Verified manually: dragging and position persistence work reliably. Recorded as deviation D-1 in `specs/001-limits-widget-mvp/plan.md`.
