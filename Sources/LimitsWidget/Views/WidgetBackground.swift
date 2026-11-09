import SwiftUI

/// Подложка в стиле системных виджетов macOS (FR-009): большое непрерывное скругление,
/// тёмная плотная заливка и тонкая светлая обводка по внутреннему краю.
struct WidgetBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    static let cornerRadius: CGFloat = 23

    // Значения подобраны по пикселям системного виджета macOS (тёмная тема, Retina):
    // подложка полупрозрачная — через неё проступает оттенок обоев (#222c33 на тёмно-синих обоях);
    // обводка 1 pt с переходом: внешний край светлее (#878f94), внутренний темнее (#61696f).
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
        shape
            .fill(fill)
            .overlay(shape.strokeBorder(innerStroke, lineWidth: 1))
            .overlay(shape.strokeBorder(outerStroke, lineWidth: 0.5))
    }

    private var isDark: Bool { colorScheme == .dark }

    private var fill: Color {
        isDark ? Color(white: 0.21).opacity(0.6) : Color(white: 0.97).opacity(0.8)
    }

    private var innerStroke: Color {
        isDark ? Color.white.opacity(0.285) : Color.black.opacity(0.10)
    }

    private var outerStroke: Color {
        isDark ? Color.white.opacity(0.24) : Color.black.opacity(0.06)
    }
}
