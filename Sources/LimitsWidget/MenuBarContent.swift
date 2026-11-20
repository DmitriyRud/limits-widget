import AppKit
import LimitsCore
import SwiftUI

/// Menu bar items (FR-010, localized via `L10n`).
struct MenuBarContent: View {
    let model: AppModel

    var body: some View {
        let lang = model.language
        Button(L10n.refresh(lang)) { model.refreshNow() }
        Button(L10n.settingsMenu(lang)) { SettingsWindow.show(model: model) }
        Toggle(
            L10n.launchAtLogin(available: model.loginItem.isAvailable, lang),
            isOn: Binding(
                get: { model.loginItem.isEnabled },
                set: { model.loginItem.setEnabled($0) })
        )
        .disabled(!model.loginItem.isAvailable)
        Divider()
        Button(L10n.quit(lang)) { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
