import Foundation

/// Форматирует время до сброса окна: «через 2 ч 14 мин», «через 3 дн 4 ч».
public enum ResetFormatter {
    public static func relative(until resetsAt: Date?, now: Date = .now) -> String {
        guard let resetsAt else { return "—" }
        let seconds = resetsAt.timeIntervalSince(now)
        guard seconds > 0 else { return "сброшено" }

        let totalMinutes = Int((seconds / 60).rounded(.up))
        let days = totalMinutes / 1_440
        let hours = (totalMinutes % 1_440) / 60
        let minutes = totalMinutes % 60

        if days > 0 {
            return hours > 0 ? "через \(days) дн \(hours) ч" : "через \(days) дн"
        }
        if hours > 0 {
            return minutes > 0 ? "через \(hours) ч \(minutes) мин" : "через \(hours) ч"
        }
        return "через \(minutes) мин"
    }

    /// FR-008: «данные на 16:41» для сегодняшних данных, «данные на 6 нояб., 16:41» — для более старых,
    /// чтобы давно не обновлявшиеся данные (например, Codex) не выглядели свежими.
    public static func dataAge(_ fetchedAt: Date, now: Date = .now, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.timeZone = timeZone
        formatter.dateFormat =
            calendar.isDate(fetchedAt, inSameDayAs: now) ? "HH:mm" : "d MMM, HH:mm"
        return "данные на \(formatter.string(from: fetchedAt))"
    }

    /// Короткая подпись окна для UI.
    public static func title(for kind: WindowKind) -> String {
        switch kind {
        case .session5h: "5 часов"
        case .weekly: "Неделя"
        case .weeklyModel(let model): "Неделя · \(model)"
        case .overall: "Общий лимит"
        case .named(let label): label
        case .custom(let minutes): minutes % 60 == 0 ? "\(minutes / 60) ч" : "\(minutes) мин"
        }
    }
}
