import Foundation
import LimitsCore
import Observation
import os

/// Состояние приложения: настройки (FR-006, FR-013) и текущий `LimitsStore`.
/// При изменении настроек стор пересоздаётся: отключённые провайдеры не опрашиваются вообще.
@MainActor
@Observable
final class AppModel {
    static let shared = AppModel()

    static let defaultRefreshSeconds = 300
    static let minimumRefreshSeconds = 60

    private enum Key {
        static let refresh = "refreshIntervalSeconds"
        static let claude = "claudeEnabled"
        static let codex = "codexEnabled"
    }

    /// Интервал обновления данных, секунды (минимум 60).
    var refreshSeconds: Int {
        didSet {
            let clamped = max(refreshSeconds, Self.minimumRefreshSeconds)
            if clamped != refreshSeconds {
                refreshSeconds = clamped
                return
            }
            defaults.set(refreshSeconds, forKey: Key.refresh)
            scheduleRebuild()
        }
    }
    var claudeEnabled: Bool {
        didSet {
            defaults.set(claudeEnabled, forKey: Key.claude)
            scheduleRebuild()
        }
    }
    var codexEnabled: Bool {
        didSet {
            defaults.set(codexEnabled, forKey: Key.codex)
            scheduleRebuild()
        }
    }

    private(set) var store: LimitsStore
    let loginItem = LoginItem()

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var started = false
    @ObservationIgnored private var rebuildTask: Task<Void, Never>?

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let seconds = defaults.object(forKey: Key.refresh) as? Int ?? Self.defaultRefreshSeconds
        let refresh = max(seconds, Self.minimumRefreshSeconds)
        let claude = defaults.object(forKey: Key.claude) as? Bool ?? true
        let codex = defaults.object(forKey: Key.codex) as? Bool ?? true
        self.refreshSeconds = refresh
        self.claudeEnabled = claude
        self.codexEnabled = codex
        self.store = Self.makeStore(refresh: refresh, claude: claude, codex: codex)
    }

    var hasEnabledProviders: Bool { claudeEnabled || codexEnabled }

    /// Первый запуск: store.start() делает refresh сразу.
    func start() {
        started = true
        store.start()
    }

    func refreshNow() {
        let store = store
        Task { await store.refresh() }
    }

    /// По одному HTTP-клиенту на провайдера на всё время работы приложения: при пересборке стора
    /// клиенты переиспользуются, поэтому `URLSession` не накапливаются. Свой allowlist у каждого (II.3).
    private static let claudeHTTP = URLSessionHTTPClient.forClaude()
    private static let codexHTTP = URLSessionHTTPClient.forCodex()

    private static func makeStore(refresh: Int, claude: Bool, codex: Bool) -> LimitsStore {
        var providers: [any LimitsProvider] = []
        if claude {
            providers.append(
                ClaudeCodeProvider(
                    credentials: ChainedCredentialSource.standard(), http: claudeHTTP))
        }
        if codex { providers.append(CodexProvider(http: codexHTTP)) }
        return LimitsStore(providers: providers, refreshInterval: .seconds(refresh))
    }

    /// Дебаунс: Stepper может менять значение часто, а пересборка = лишние обращения к Keychain.
    private func scheduleRebuild() {
        guard started else { return }
        rebuildTask?.cancel()
        rebuildTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled, let self else { return }
            self.rebuild()
        }
    }

    private func rebuild() {
        store.stop()
        store = Self.makeStore(refresh: refreshSeconds, claude: claudeEnabled, codex: codexEnabled)
        store.start()
    }
}
