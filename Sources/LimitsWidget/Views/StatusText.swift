import LimitsCore

/// Все пользовательские тексты статусов виджета — в одном месте (FR-005, FR-008).
enum StatusText {
    static let noProvidersHint = "Включите агентов в настройках"

    /// Текст для не-ok статуса.
    static func message(for snapshot: ProviderSnapshot) -> String {
        switch snapshot.status {
        case .ok: ""
        case .notAuthenticated: "Не авторизован"
        case .tokenExpired: "Требуется вход — откройте \(snapshot.displayName)"
        case .noData: "Нет данных"
        case .error(let message): message
        }
    }

    static let staleMark = "данные устарели"
}
