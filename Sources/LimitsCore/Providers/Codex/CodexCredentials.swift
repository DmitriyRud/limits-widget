import Foundation

/// Учётные данные Codex CLI (FR-003, NFR-001). Только access-токен и id аккаунта;
/// refresh- и id-токены не декодируются. Не `Hashable`/`Encodable`; текстовые представления скрыты.
public struct CodexCredentials: Sendable, CustomStringConvertible,
    CustomDebugStringConvertible, CustomReflectable
{
    /// Не `public`: токен нужен только провайдеру внутри LimitsCore (NFR-001).
    let accessToken: String
    let accountID: String?

    public init(accessToken: String, accountID: String?) {
        self.accessToken = accessToken
        self.accountID = accountID
    }

    private struct Envelope: Decodable {
        struct Tokens: Decodable {
            let accessToken: String
            let accountId: String?

            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case accountId = "account_id"
            }
        }
        let tokens: Tokens
    }

    /// Декодирует `{"tokens": {"access_token", "account_id"}}`.
    public static func decode(from data: Data) throws -> CodexCredentials {
        let tokens = try JSONDecoder().decode(Envelope.self, from: data).tokens
        return CodexCredentials(accessToken: tokens.accessToken, accountID: tokens.accountId)
    }

    public var description: String { "CodexCredentials(<redacted>)" }
    public var debugDescription: String { "CodexCredentials(<redacted>)" }
    public var customMirror: Mirror { Mirror(self, children: [], displayStyle: .struct) }
}

/// Результат чтения учётных данных Codex (FR-003).
public enum CodexCredentialsResult: Sendable {
    case found(CodexCredentials)
    /// Файла учётки нет: пользователь не авторизован.
    case noAuthFile
    /// Файл есть, но access-токена нет (например, вход по API-ключу).
    case noTokens
    /// Файл не удалось прочитать или он не JSON.
    case unreadable
}

/// Источник учётных данных Codex. Только чтение, не бросает ошибок наружу.
public protocol CodexCredentialSource: Sendable {
    func loadCodexCredentials() async -> CodexCredentialsResult
}

/// Чтение файла учётки Codex. Только чтение (путь инъецируется).
public struct FileCodexCredentialSource: CodexCredentialSource {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func loadCodexCredentials() async -> CodexCredentialsResult {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return .noAuthFile }
        guard let data = try? Data(contentsOf: fileURL),
            (try? JSONSerialization.jsonObject(with: data)) != nil
        else { return .unreadable }
        guard let credentials = try? CodexCredentials.decode(from: data) else { return .noTokens }
        return .found(credentials)
    }
}
