import Foundation

/// Formats countdowns, data age, and window titles in the selected `AppLanguage` (default: English).
public enum ResetFormatter {
    public static func relative(
        until resetsAt: Date?, now: Date = .now, language: AppLanguage = .default
    ) -> String {
        guard let resetsAt else { return "—" }
        let seconds = resetsAt.timeIntervalSince(now)
        guard seconds > 0 else { return L10n.reset(language) }

        let totalMinutes = Int((seconds / 60).rounded(.up))
        let days = totalMinutes / 1_440
        let hours = (totalMinutes % 1_440) / 60
        let minutes = totalMinutes % 60

        if days > 0 {
            return L10n.inDaysHours(days: days, hours: hours, language)
        }
        if hours > 0 {
            return L10n.inHoursMinutes(hours: hours, minutes: minutes, language)
        }
        return L10n.inMinutes(minutes, language)
    }

    /// Formats data freshness timestamp (date + time if not today).
    public static func dataAge(
        _ fetchedAt: Date,
        now: Date = .now,
        timeZone: TimeZone = .current,
        language: AppLanguage = .default
    ) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.timeZone = timeZone
        formatter.dateFormat =
            calendar.isDate(fetchedAt, inSameDayAs: now) ? "HH:mm" : "d MMM, HH:mm"
        return L10n.dataAsOf(formatter.string(from: fetchedAt), language)
    }

    /// Short localized window title for UI.
    public static func title(for kind: WindowKind, language: AppLanguage = .default) -> String {
        switch kind {
        case .session5h:
            L10n.session5h(language)
        case .weekly:
            L10n.weekly(language)
        case .weeklyModel(let model):
            "\(L10n.weekly(language)) · \(model)"
        case .overall:
            L10n.overallLimit(language)
        case .group(let group, let period):
            switch period {
            case .fiveHour: "\(group) · \(L10n.short5h(language))"
            case .weekly: "\(group) · \(L10n.weekly(language))"
            case .other(let raw): "\(group) · \(raw)"
            }
        case .named(let label):
            label
        case .custom(let minutes):
            minutes % 60 == 0
                ? L10n.customHours(minutes / 60, language)
                : L10n.customMinutes(minutes, language)
        }
    }
}
