import Foundation

/// Лимиты Codex, извлечённые из события журнала сессии (FR-004).
public struct CodexRateLimitsSample: Hashable, Sendable {
    /// Время события журнала — момент, на который актуальны данные (FR-008).
    public let fetchedAt: Date
    public let windows: [UsageWindow]

    public init(fetchedAt: Date, windows: [UsageWindow]) {
        self.fetchedAt = fetchedAt
        self.windows = windows
    }
}

/// Разбор журналов `~/.codex/sessions/**/rollout-*.jsonl` (FR-004, FR-008).
///
/// Толерантен к битым строкам, невалидному UTF-8 и неизвестным полям.
public enum CodexSessionLogParser {
    /// Возвращает последнее событие журнала с непустым `payload.rate_limits`.
    public static func latestSample(in data: Data) -> CodexRateLimitsSample? {
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for lineData in data.split(separator: UInt8(ascii: "\n"), omittingEmptySubsequences: true)
            .reversed()
        {
            guard
                let object = try? JSONSerialization.jsonObject(with: Data(lineData)),
                let event = object as? [String: Any],
                let payload = event["payload"] as? [String: Any],
                let limits = payload["rate_limits"] as? [String: Any],
                let timestamp = event["timestamp"] as? String,
                let date = fractional.date(from: timestamp) ?? plain.date(from: timestamp)
            else { continue }

            let windows = ["primary", "secondary"].compactMap { key in
                window(from: limits[key] as? [String: Any])
            }
            if windows.isEmpty { continue }
            return CodexRateLimitsSample(fetchedAt: date, windows: windows)
        }
        return nil
    }

    private static func window(from raw: [String: Any]?) -> UsageWindow? {
        guard
            let raw,
            let used = (raw["used_percent"] as? NSNumber)?.doubleValue,
            let minutes = (raw["window_minutes"] as? NSNumber)?.intValue
        else { return nil }
        let resetsAt = (raw["resets_at"] as? NSNumber).map {
            Date(timeIntervalSince1970: $0.doubleValue)
        }
        return UsageWindow(
            kind: WindowKind(windowMinutes: minutes), usedPercent: used, resetsAt: resetsAt)
    }
}
