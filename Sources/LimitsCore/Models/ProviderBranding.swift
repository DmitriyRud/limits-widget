import Foundation

/// Логотип агента для UI (FR-005). UI получает его через `LimitsProvider`, не зная конкретных агентов (конституция IV.2).
public struct ProviderBranding: Sendable, Hashable {
    /// Монохромный SVG (viewBox 0 0 24 24); UI рисует его как шаблон и красит в `tintRGB`.
    public let logoSVG: String
    /// Цвет логотипа `0xRRGGBB`; `nil` — цвет основного текста (адаптируется к светлой/тёмной теме).
    public let tintRGB: UInt32?

    public init(logoSVG: String, tintRGB: UInt32?) {
        self.logoSVG = logoSVG
        self.tintRGB = tintRGB
    }
}
