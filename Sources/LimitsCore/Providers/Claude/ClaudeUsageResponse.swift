import Foundation

/// Ответ `GET /api/oauth/usage` (FR-002, research R-1). Толерантный декодер:
/// неизвестные поля игнорируются, отсутствующие/`null` окна — `nil`.
public struct ClaudeUsageResponse: Sendable, Hashable, Decodable {
    public struct Window: Sendable, Hashable, Decodable {
        public let utilization: Double
        public let resetsAt: Date?

        enum CodingKeys: String, CodingKey {
            case utilization
            case resetsAt = "resets_at"
        }

        public init(utilization: Double, resetsAt: Date?) {
            self.utilization = utilization
            self.resetsAt = resetsAt
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            utilization = try c.decode(Double.self, forKey: .utilization)
            if let raw = try c.decodeIfPresent(String.self, forKey: .resetsAt) {
                resetsAt = ClaudeUsageResponse.parseDate(raw)
            } else {
                resetsAt = nil
            }
        }
    }

    public let fiveHour: Window?
    public let sevenDay: Window?
    public let sevenDayOpus: Window?
    public let sevenDaySonnet: Window?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDayOpus = "seven_day_opus"
        case sevenDaySonnet = "seven_day_sonnet"
    }

    public init(
        fiveHour: Window? = nil, sevenDay: Window? = nil,
        sevenDayOpus: Window? = nil, sevenDaySonnet: Window? = nil
    ) {
        self.fiveHour = fiveHour
        self.sevenDay = sevenDay
        self.sevenDayOpus = sevenDayOpus
        self.sevenDaySonnet = sevenDaySonnet
    }

    public static func decode(from data: Data) throws -> ClaudeUsageResponse {
        try JSONDecoder().decode(ClaudeUsageResponse.self, from: data)
    }

    /// Окна в порядке: 5 ч, неделя, Opus, Sonnet; отсутствующие пропускаются.
    public func windows() -> [UsageWindow] {
        let items: [(WindowKind, Window?)] = [
            (.session5h, fiveHour),
            (.weekly, sevenDay),
            (.weeklyModel("Opus"), sevenDayOpus),
            (.weeklyModel("Sonnet"), sevenDaySonnet),
        ]
        return items.compactMap { kind, window in
            window.map { UsageWindow(kind: kind, usedPercent: $0.utilization, resetsAt: $0.resetsAt) }
        }
    }

    // ISO8601DateFormatter не Sendable — создаём локально на каждый разбор.
    static func parseDate(_ string: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: string) { return date }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: string)
    }
}
