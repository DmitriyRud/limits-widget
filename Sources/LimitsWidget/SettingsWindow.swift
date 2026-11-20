import AppKit
import SwiftUI

/// Окно настроек (FR-006, FR-013). Своё окно: в accessory-приложении Settings-сцена ненадёжна.
@MainActor
enum SettingsWindow {
    private static var window: NSWindow?

    static func show(model: AppModel) {
        if window == nil {
            let w = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(model: model)))
            w.title = "Настройки Limits Widget"
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.center()
            window = w
        }
        model.loginItem.reload()
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }
}

struct SettingsView: View {
    @Bindable var model: AppModel

    var body: some View {
        Form {
            Section("Агенты") {
                Toggle("Claude Code", isOn: $model.claudeEnabled)
                Toggle("Codex", isOn: $model.codexEnabled)
                Toggle("Antigravity", isOn: $model.antigravityEnabled)
            }
            Section("Обновление") {
                Stepper(
                    "Интервал: \(model.refreshSeconds) с",
                    value: $model.refreshSeconds,
                    in: AppModel.minimumRefreshSeconds...3600,
                    step: 60)
                Text("Минимум 60 с. Обратный отсчёт обновляется раз в минуту без сети.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
    }
}
