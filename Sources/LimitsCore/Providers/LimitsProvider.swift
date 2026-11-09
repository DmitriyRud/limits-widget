import Foundation

/// Источник лимитов одного ИИ-агента (конституция, принцип IV).
///
/// Реализация обязана:
/// - только читать учётные данные агента, никогда их не изменять;
/// - не логировать и не возвращать токены;
/// - не бросать ошибки наружу: любые сбои превращаются в `ProviderStatus`.
public protocol LimitsProvider: Sendable {
    /// Стабильный идентификатор, например `"claude-code"`, `"codex"`.
    var id: String { get }
    /// Имя для UI, например `"Claude Code"`.
    var displayName: String { get }

    /// Логотип для UI (FR-005); `nil` — без логотипа.
    var branding: ProviderBranding? { get }

    func fetchSnapshot() async -> ProviderSnapshot
}

extension LimitsProvider {
    public var branding: ProviderBranding? { nil }
}
