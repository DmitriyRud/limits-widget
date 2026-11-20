import Foundation

extension AntigravityProvider {
    /// Монохромный векторный логотип (4-лучевая звезда Google/Antigravity, viewBox 0 0 24 24) и фирменный синий (FR-003).
    public static let branding = ProviderBranding(
        logoSVG: #"<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 1C12 7.075 16.925 12 23 12C16.925 12 12 16.925 12 23C12 16.925 7.075 12 1 12C7.075 12 12 7.075 12 1Z"/></svg>"#,
        tintRGB: 0x4285F4)

    public var branding: ProviderBranding? { Self.branding }
}
