import AppKit
import LimitsCore
import SwiftUI

/// Логотип агента перед названием (FR-005). SVG из `ProviderBranding` рисуется как шаблон
/// и красится в фирменный цвет или в цвет текста.
struct ProviderLogo: View {
    let branding: ProviderBranding
    var size: CGFloat = 16

    var body: some View {
        if let image = LogoCache.image(for: branding.logoSVG) {
            Image(nsImage: image)
                .resizable()
                .renderingMode(.template)
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
        }
    }

    private var tint: Color {
        guard let rgb = branding.tintRGB else { return .primary }
        return Color(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255)
    }
}

/// Разобранные SVG кешируются: `NSImage(data:)` не должен выполняться при каждой отрисовке (NFR-002).
@MainActor
private enum LogoCache {
    static var images: [String: NSImage] = [:]

    static func image(for svg: String) -> NSImage? {
        if let cached = images[svg] { return cached }
        guard let image = NSImage(data: Data(svg.utf8)) else { return nil }
        image.isTemplate = true
        images[svg] = image
        return image
    }
}
