import Foundation

/// Тип окна лимита. Подпись в UI строится из него, а не из провайдера.
public enum WindowKind: Hashable, Sendable {
    /// Короткое скользящее окно (5 часов) — «дневной» лимит.
    case session5h
    /// Недельное окно (7 дней).
    case weekly
    /// Недельное окно для конкретной модели (например, "Opus").
    case weeklyModel(String)
    /// Общий агрегированный лимит (например, минимум по моделям).
    case overall
    /// Именованное окно лимита (например, пул моделей + период: «Gemini · 5 ч»).
    case named(String)
    /// Окно нестандартной длины.
    case custom(minutes: Int)

    /// Сопоставляет длину окна в минутах с известным типом.
    public init(windowMinutes: Int) {
        switch windowMinutes {
        case 300: self = .session5h
        case 10_080: self = .weekly
        default: self = .custom(minutes: windowMinutes)
        }
    }
}

/// Одно окно лимита: процент использования и момент сброса.
public struct UsageWindow: Hashable, Sendable {
    public let kind: WindowKind
    /// Использование в процентах, всегда в диапазоне 0...100.
    public let usedPercent: Double
    public let resetsAt: Date?

    public init(kind: WindowKind, usedPercent: Double, resetsAt: Date?) {
        self.kind = kind
        self.usedPercent = min(max(usedPercent, 0), 100)
        self.resetsAt = resetsAt
    }

    /// FR-012: если момент сброса уже прошёл, окно считается обнулённым.
    public func effectivePercent(now: Date = .now) -> Double {
        if let resetsAt, resetsAt <= now { return 0 }
        return usedPercent
    }

    /// FR-005: оставшийся процент лимита (100 − эффективное использование), 0...100.
    public func remainingPercent(now: Date = .now) -> Double {
        100 - effectivePercent(now: now)
    }
}
