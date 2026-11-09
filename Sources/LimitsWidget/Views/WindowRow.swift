import LimitsCore
import SwiftUI

/// Строка одного окна лимита: подпись, остаток лимита (бар и %), время до сброса (FR-005, FR-007, FR-012).
struct WindowRow: View {
    let window: UsageWindow
    let now: Date

    var body: some View {
        let remaining = window.remainingPercent(now: now)
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(ResetFormatter.title(for: window.kind)).font(.subheadline)
                Spacer()
                Text("осталось \(Int(remaining.rounded()))%").font(.subheadline.monospacedDigit())
            }
            UsageBar(fraction: remaining / 100, level: window.level(now: now))
            Text(ResetFormatter.relative(until: window.resetsAt, now: now))
                .font(.caption).foregroundStyle(.secondary)
        }
        .help(tooltip)
    }

    private var tooltip: String {
        guard let resetsAt = window.resetsAt else { return "Время сброса неизвестно" }
        let text = resetsAt.formatted(
            Date.FormatStyle(date: .long, time: .shortened).locale(Locale(identifier: "ru_RU")))
        return "Сброс: \(text)"
    }
}

/// Тонкий прогресс-бар остатка лимита с цветом по `UsageLevel` (FR-007).
struct UsageBar: View {
    let fraction: Double
    let level: UsageLevel

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.primary.opacity(0.12))
                Capsule().fill(color)
                    .frame(width: proxy.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: 10)
    }

    private var color: Color {
        switch level {
        case .normal: .green
        case .warning: .orange
        case .critical: .red
        }
    }
}
