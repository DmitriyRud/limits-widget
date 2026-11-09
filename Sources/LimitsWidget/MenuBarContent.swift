import AppKit
import SwiftUI

/// Меню в строке меню (FR-010).
struct MenuBarContent: View {
    let model: AppModel

    var body: some View {
        Button("Обновить") { model.refreshNow() }
        Button("Настройки…") { SettingsWindow.show(model: model) }
        Toggle(
            model.loginItem.isAvailable
                ? "Запускать при входе" : "Запускать при входе (только из .app)",
            isOn: Binding(
                get: { model.loginItem.isEnabled },
                set: { model.loginItem.setEnabled($0) })
        )
        .disabled(!model.loginItem.isAvailable)
        Divider()
        Button("Выход") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
