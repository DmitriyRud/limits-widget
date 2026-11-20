import Foundation

/// Ответ `POST /exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary` (research R-2).
/// Возвращает структурированные пулы моделей с отдельными окнами `5h` и `weekly`.
public struct AntigravityQuotaSummaryResponse: Sendable, Hashable, Decodable {
    public struct Bucket: Sendable, Hashable, Decodable {
        public let bucketId: String?
        public let displayName: String?
        public let window: String?
        public let remainingFraction: Double?
        public let resetTime: Date?

        enum CodingKeys: String, CodingKey {
            case bucketId
            case displayName
            case window
            case remainingFraction
            case resetTime
        }

        public init(
            bucketId: String? = nil,
            displayName: String? = nil,
            window: String? = nil,
            remainingFraction: Double? = nil,
            resetTime: Date? = nil
        ) {
            self.bucketId = bucketId
            self.displayName = displayName
            self.window = window
            self.remainingFraction = remainingFraction
            self.resetTime = resetTime
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            bucketId = try c.decodeIfPresent(String.self, forKey: .bucketId)
            displayName = try c.decodeIfPresent(String.self, forKey: .displayName)
            window = try c.decodeIfPresent(String.self, forKey: .window)
            remainingFraction = try c.decodeIfPresent(Double.self, forKey: .remainingFraction)
            if let raw = try c.decodeIfPresent(String.self, forKey: .resetTime) {
                resetTime = AntigravityUsageResponse.parseDate(raw)
            } else {
                resetTime = nil
            }
        }
    }

    public struct Group: Sendable, Hashable, Decodable {
        public let displayName: String?
        public let buckets: [Bucket]?
    }

    public struct Payload: Sendable, Hashable, Decodable {
        public let groups: [Group]?
    }

    public let response: Payload?

    public static func decode(from data: Data) throws -> AntigravityQuotaSummaryResponse {
        try JSONDecoder().decode(AntigravityQuotaSummaryResponse.self, from: data)
    }

    /// Преобразует все группы и бакеты в `[UsageWindow]` (внутри каждой группы сначала `5h`, затем `weekly`).
    public func windows(now: Date = .now) -> [UsageWindow] {
        guard let groups = response?.groups else { return [] }

        var result: [UsageWindow] = []
        for group in groups {
            let groupTitle = Self.shortGroupTitle(group.displayName)
            let buckets = (group.buckets ?? []).sorted { lhs, rhs in
                Self.windowSortOrder(lhs.window) < Self.windowSortOrder(rhs.window)
            }

            for bucket in buckets {
                if bucket.remainingFraction == nil && bucket.resetTime == nil {
                    continue
                }
                let effectiveRemaining: Double
                if let resetTime = bucket.resetTime, resetTime <= now {
                    effectiveRemaining = 1.0
                } else if let fraction = bucket.remainingFraction {
                    effectiveRemaining = min(max(fraction, 0.0), 1.0)
                } else {
                    // protobuf v3 zero-omission: remainingFraction опущен при 0% остатка.
                    effectiveRemaining = 0.0
                }

                let label = Self.windowLabel(
                    groupTitle: groupTitle, window: bucket.window, fallback: bucket.displayName)
                let usedPercent = (1.0 - effectiveRemaining) * 100.0
                result.append(
                    UsageWindow(
                        kind: .named(label), usedPercent: usedPercent, resetsAt: bucket.resetTime))
            }
        }
        return result
    }

    private static func windowSortOrder(_ window: String?) -> Int {
        switch window?.lowercased() {
        case "5h": 0
        case "weekly": 1
        default: 2
        }
    }

    private static func shortGroupTitle(_ raw: String?) -> String {
        guard let raw, !raw.trimmingCharacters(in: .whitespaces).isEmpty else { return "Лимит" }
        var title = raw.trimmingCharacters(in: .whitespaces)
        for suffix in [" Models", " models"] where title.hasSuffix(suffix) {
            title.removeLast(suffix.count)
            break
        }
        return title.replacingOccurrences(of: " and ", with: " & ")
    }

    private static func windowLabel(groupTitle: String, window: String?, fallback: String?)
        -> String
    {
        switch window?.lowercased() {
        case "5h":
            return "\(groupTitle) · 5 ч"
        case "weekly":
            return "\(groupTitle) · Неделя"
        case let other? where !other.isEmpty:
            return "\(groupTitle) · \(other)"
        default:
            return fallback ?? groupTitle
        }
    }
}
