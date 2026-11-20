import LimitsCore

/// Localized user-facing status strings for the widget.
enum StatusText {
    static func noProvidersHint(language: AppLanguage) -> String {
        L10n.noProvidersHint(language)
    }

    /// Message for non-ok provider status.
    static func message(for snapshot: ProviderSnapshot, language: AppLanguage) -> String {
        switch snapshot.status {
        case .ok: ""
        case .notAuthenticated: L10n.notAuthenticated(language)
        case .tokenExpired: L10n.tokenExpired(displayName: snapshot.displayName, language)
        case .noData: L10n.noData(language)
        case .error(let message): L10n.localizedProviderError(message, language)
        }
    }

    static func staleMark(language: AppLanguage) -> String {
        L10n.staleMark(language)
    }
}
