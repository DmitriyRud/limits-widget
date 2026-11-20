import AppKit
import LimitsCore
import SwiftUI

/// Settings window (FR-003, FR-004). Custom `NSWindow` because SwiftUI `Settings` scene is unreliable in accessory apps.
@MainActor
enum SettingsWindow {
    private static var window: NSWindow?

    static func show(model: AppModel) {
        if window == nil {
            let w = NSWindow(
                contentViewController: NSHostingController(rootView: SettingsView(model: model)))
            w.title = L10n.settingsWindowTitle(model.language)
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.center()
            window = w
        } else {
            window?.title = L10n.settingsWindowTitle(model.language)
        }
        model.loginItem.reload()
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }

    static func updateTitle(for language: AppLanguage) {
        window?.title = L10n.settingsWindowTitle(language)
    }
}

struct SettingsView: View {
    @Bindable var model: AppModel

    var body: some View {
        let lang = model.language
        Form {
            Section(L10n.agentsSection(lang)) {
                Toggle("Claude Code", isOn: $model.claudeEnabled)
                Toggle("Codex", isOn: $model.codexEnabled)
                Toggle("Antigravity", isOn: $model.antigravityEnabled)
            }
            Section(L10n.languageSection(lang)) {
                Picker(L10n.languageSection(lang), selection: $model.language) {
                    ForEach(AppLanguage.allCases) { option in
                        Text(option.nativeName).tag(option)
                    }
                }
            }
            Section(L10n.refreshSection(lang)) {
                Stepper(
                    L10n.intervalSeconds(model.refreshSeconds, lang),
                    value: $model.refreshSeconds,
                    in: AppModel.minimumRefreshSeconds...3600,
                    step: 60)
                Text(L10n.intervalHint(lang))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: model.language) { _, newValue in
            SettingsWindow.updateTitle(for: newValue)
        }
    }
}
