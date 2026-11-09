import Foundation
import Observation
import ServiceManagement
import os

/// Автозапуск при входе через `SMAppService.mainApp` (FR-011).
/// Работает только из `.app`-бандла; при `swift run` пункт неактивен.
@MainActor
@Observable
final class LoginItem {
    private(set) var isEnabled = false
    private static let logger = Logger(subsystem: "local.limitswidget", category: "LoginItem")

    /// Запущены ли мы из `.app` (иначе регистрация невозможна).
    var isAvailable: Bool { Bundle.main.bundleURL.pathExtension == "app" }

    init() { reload() }

    func reload() {
        guard isAvailable else {
            isEnabled = false
            return
        }
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        guard isAvailable else { return }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            Self.logger.error("Не удалось изменить автозапуск (enabled=\(enabled, privacy: .public))")
        }
        reload()
    }
}
