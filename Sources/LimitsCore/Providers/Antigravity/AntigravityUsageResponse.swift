import Foundation

/// Ответ `POST /exa.language_server_pb.LanguageServerService/GetUserStatus` (FR-002, research R-2).
/// Персональные поля (`email`, `name`, `profilePictureUrl`) намеренно не декодируются (II.1).
public struct AntigravityUsageResponse: Sendable, Hashable, Decodable {
    public struct QuotaInfo: Sendable, Hashable, Decodable {
        public let remainingFraction: Double?
        public let resetTime: Date?

        enum CodingKeys: String, CodingKey {
            case remainingFraction
            case resetTime
        }

        public init(remainingFraction: Double?, resetTime: Date?) {
            self.remainingFraction = remainingFraction
            self.resetTime = resetTime
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            remainingFraction = try c.decodeIfPresent(Double.self, forKey: .remainingFraction)
            if let raw = try c.decodeIfPresent(String.self, forKey: .resetTime) {
                resetTime = AntigravityUsageResponse.parseDate(raw)
            } else {
                resetTime = nil
            }
        }
    }

    public struct ModelConfig: Sendable, Hashable, Decodable {
        public let label: String?
        public let quotaInfo: QuotaInfo?

        public init(label: String? = nil, quotaInfo: QuotaInfo? = nil) {
            self.label = label
            self.quotaInfo = quotaInfo
        }
    }

    public struct CascadeModelConfigData: Sendable, Hashable, Decodable {
        public let clientModelConfigs: [ModelConfig]?
    }

    public struct UserStatus: Sendable, Hashable, Decodable {
        public let cascadeModelConfigData: CascadeModelConfigData?
    }

    public let userStatus: UserStatus?

    public static func decode(from data: Data) throws -> AntigravityUsageResponse {
        try JSONDecoder().decode(AntigravityUsageResponse.self, from: data)
    }

    /// Агрегирует квоты моделей в один общий индикатор — минимальный эффективный остаток (FR-002, FR-004, FR-006).
    /// - Пустой `quotaInfo: {}` (нет ни `remainingFraction`, ни `resetTime`) пропускается.
    /// - Отсутствующий `remainingFraction` при наличии `resetTime` считается 0% остатка (protobuf v3 zero-omission).
    /// - Если `resetTime <= now`, окно считается сброшенным (остаток 100%).
    public func windows(now: Date = .now) -> [UsageWindow] {
        guard let configs = userStatus?.cascadeModelConfigData?.clientModelConfigs else {
            return []
        }

        struct Candidate {
            let remaining: Double
            let resetsAt: Date?
        }

        let candidates: [Candidate] = configs.compactMap { config in
            guard let quota = config.quotaInfo else { return nil }
            // Пустой объект `quotaInfo: {}` (например, "Gemini 4 Carbon") не несёт данных о квоте.
            if quota.remainingFraction == nil && quota.resetTime == nil {
                return nil
            }

            let effectiveRemaining: Double
            if let resetTime = quota.resetTime, resetTime <= now {
                effectiveRemaining = 1.0
            } else if let fraction = quota.remainingFraction {
                effectiveRemaining = min(max(fraction, 0.0), 1.0)
            } else {
                // remainingFraction опущен в protobuf JSON при наличии resetTime → 0% остатка.
                effectiveRemaining = 0.0
            }

            return Candidate(remaining: effectiveRemaining, resetsAt: quota.resetTime)
        }

        guard
            let worst = candidates.min(by: { lhs, rhs in
                if lhs.remaining != rhs.remaining {
                    return lhs.remaining < rhs.remaining
                }
                switch (lhs.resetsAt, rhs.resetsAt) {
                case (let l?, let r?): return l < r
                case (_?, nil): return true
                case (nil, _): return false
                }
            })
        else {
            return []
        }

        let usedPercent = (1.0 - worst.remaining) * 100.0
        return [UsageWindow(kind: .overall, usedPercent: usedPercent, resetsAt: worst.resetsAt)]
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
