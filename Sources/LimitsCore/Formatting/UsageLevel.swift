import Foundation

/// Уровень заполнения лимита для цвета индикатора (FR-007).
public enum UsageLevel: Hashable, Sendable {
    /// Меньше 70%.
    case normal
    /// От 70% до 90% не включая.
    case warning
    /// 90% и выше.
    case critical

    public init(percent: Double) {
        switch percent {
        case ..<70: self = .normal
        case ..<90: self = .warning
        default: self = .critical
        }
    }
}

extension UsageWindow {
    /// Уровень окна с учётом уже наступившего сброса (FR-007, FR-012).
    public func level(now: Date) -> UsageLevel {
        UsageLevel(percent: effectivePercent(now: now))
    }
}
