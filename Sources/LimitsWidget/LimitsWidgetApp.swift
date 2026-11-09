import AppKit
import SwiftUI

/// Точка входа: приложение без окон-сцен, кроме иконки в меню-баре (FR-010, ADR-0001).
@main
struct LimitsWidgetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("Limits Widget", systemImage: "gauge.with.dots.needle.33percent") {
            MenuBarContent(model: AppModel.shared)
        }
    }
}

/// Создаёт панель на рабочем столе и запускает опрос при старте.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: DesktopPanel?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let model = AppModel.shared
        panel = DesktopPanel(model: model)
        panel?.orderFrontRegardless()
        model.start()
    }
}
