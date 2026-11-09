import AppKit
import SwiftUI

/// Безрамочная панель на уровне рабочего стола (FR-009, ADR-0001).
///
/// Уровень: `desktopIconWindow + 1` — окно выше значков рабочего стола, но под обычными окнами.
/// На ровно `desktopIconWindow` порядок относительно окна значков Finder не гарантирован,
/// и клики (перетаскивание) могут не доходить; +1 это исключает. Проверить вручную.
@MainActor
final class DesktopPanel: NSPanel {
    private static let autosaveName = "LimitsWidgetPanel"

    init(model: AppModel) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false

        let controller = NSHostingController(rootView: WidgetView(model: model))
        controller.sizingOptions = [.preferredContentSize]
        contentViewController = controller
        contentView?.layoutSubtreeIfNeeded()
        setContentSize(controller.view.fittingSize)

        if !setFrameUsingName(Self.autosaveName) {
            placeTopRight()
        }
        setFrameAutosaveName(Self.autosaveName)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    private func placeTopRight() {
        guard let area = NSScreen.main?.visibleFrame else { return }
        let margin: CGFloat = 16
        setFrameTopLeftPoint(
            NSPoint(x: area.maxX - frame.width - margin, y: area.maxY - margin))
    }
}
