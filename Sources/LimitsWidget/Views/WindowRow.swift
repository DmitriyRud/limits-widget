import LimitsCore
import SwiftUI

/// Single usage window row: title, remaining bar & percent, relative countdown, and hover tooltip.
struct WindowRow: View {
    let window: UsageWindow
    let now: Date
    let language: AppLanguage

    var body: some View {
        let remaining = window.remainingPercent(now: now)
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(ResetFormatter.title(for: window.kind, language: language)).font(.subheadline)
                Spacer()
                Text(L10n.remainingPercent(Int(remaining.rounded()), language))
                    .font(.subheadline.monospacedDigit())
            }
            UsageBar(fraction: remaining / 100, level: window.level(now: now))
            Text(ResetFormatter.relative(until: window.resetsAt, now: now, language: language))
                .font(.caption).foregroundStyle(.secondary)
        }
        .help(tooltip)
    }

    private var tooltip: String {
        guard let resetsAt = window.resetsAt else { return L10n.resetTimeUnknown(language) }
        let text = resetsAt.formatted(
            Date.FormatStyle(date: .long, time: .shortened).locale(language.locale))
        return L10n.resetsAt(text, language)
    }
}

/// Remaining limit progress bar colored by `UsageLevel`.
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
