import Foundation

/// Учётные данные Claude Code (FR-001, NFR-001, NFR-006). Только чтение; refresh-токен не хранится.
/// Не реализует `Encodable` и `Hashable`; все текстовые представления скрыты.
public struct ClaudeCredentials: Sendable, CustomStringConvertible,
    CustomDebugStringConvertible, CustomReflectable
{
    /// Не `public`: токен нужен только провайдеру внутри LimitsCore (NFR-001).
    let accessToken: String
    public let expiresAt: Date?
    public let subscriptionType: String?

    public init(accessToken: String, expiresAt: Date?, subscriptionType: String?) {
        self.accessToken = accessToken
        self.expiresAt = expiresAt
        self.subscriptionType = subscriptionType
    }

    private struct Envelope: Decodable {
        struct OAuth: Decodable {
            let accessToken: String
            let expiresAt: Double?
            let subscriptionType: String?
        }
        let claudeAiOauth: OAuth
    }

    /// Декодирует `{"claudeAiOauth": {...}}`; `expiresAt` — Unix-время в миллисекундах.
    public static func decode(from data: Data) throws -> ClaudeCredentials {
        let oauth = try JSONDecoder().decode(Envelope.self, from: data).claudeAiOauth
        return ClaudeCredentials(
            accessToken: oauth.accessToken,
            expiresAt: oauth.expiresAt.map { Date(timeIntervalSince1970: $0 / 1000) },
            subscriptionType: oauth.subscriptionType)
    }

    /// Токен считается истёкшим, если срок известен и уже наступил.
    public func isExpired(now: Date) -> Bool {
        guard let expiresAt else { return false }
        return expiresAt <= now
    }

    public var description: String { "ClaudeCredentials(<redacted>)" }
    public var debugDescription: String { "ClaudeCredentials(<redacted>)" }
    public var customMirror: Mirror { Mirror(self, children: [], displayStyle: .struct) }
}
