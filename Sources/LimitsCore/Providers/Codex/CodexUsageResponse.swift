import Foundation

/// Ответ `GET chatgpt.com/backend-api/wham/usage` (FR-004, research R-2). Толерантный декодер:
/// неизвестные поля игнорируются; `user_id`/`account_id`/`email` намеренно не декодируются.
public struct CodexUsageResponse: Sendable, Decodable {
    public struct Window: Sendable, Decodable {
        public let usedPercent: Double
        public let limitWindowSeconds: Int?
        public let resetAt: Date?

        enum CodingKeys: String, CodingKey {
            case usedPercent = "used_percent"
            case limitWindowSeconds = "limit_window_seconds"
            case resetAt = "reset_at"
        }

        public init(usedPercent: Double, limitWindowSeconds: Int?, resetAt: Date?) {
            self.usedPercent = usedPercent
            self.limitWindowSeconds = limitWindowSeconds
            self.resetAt = resetAt
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            usedPercent = try c.decode(Double.self, forKey: .usedPercent)
            limitWindowSeconds = try c.decodeIfPresent(Int.self, forKey: .limitWindowSeconds)
            resetAt = try c.decodeIfPresent(Double.self, forKey: .resetAt)
                .map { Date(timeIntervalSince1970: $0) }
        }
    }

    private struct RateLimit: Decodable {
        let primaryWindow: Window?
        let secondaryWindow: Window?

        enum CodingKeys: String, CodingKey {
            case primaryWindow = "primary_window"
            case secondaryWindow = "secondary_window"
        }
    }

    public let planType: String?
    public let primaryWindow: Window?
    public let secondaryWindow: Window?

    enum CodingKeys: String, CodingKey {
        case planType = "plan_type"
        case rateLimit = "rate_limit"
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        planType = try c.decodeIfPresent(String.self, forKey: .planType)
        let limit = try c.decodeIfPresent(RateLimit.self, forKey: .rateLimit)
        primaryWindow = limit?.primaryWindow
        secondaryWindow = limit?.secondaryWindow
    }

    public static func decode(from data: Data) throws -> CodexUsageResponse {
        try JSONDecoder().decode(CodexUsageResponse.self, from: data)
    }

    /// Окна [primary, secondary]; без `limit_window_seconds` окно пропускается.
    public func windows() -> [UsageWindow] {
        [primaryWindow, secondaryWindow].compactMap { window in
            guard let window, let seconds = window.limitWindowSeconds else { return nil }
            return UsageWindow(
                kind: WindowKind(windowMinutes: seconds / 60),
                usedPercent: window.usedPercent, resetsAt: window.resetAt)
        }
    }
}
