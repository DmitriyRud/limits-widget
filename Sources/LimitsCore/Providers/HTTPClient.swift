import Foundation

/// Ошибки HTTP-клиента. Не содержат URL, заголовков и тел.
public enum HTTPClientError: Error, Hashable, Sendable {
    case hostNotAllowed
    case insecureScheme
    case invalidResponse
}

/// Абстракция сети (NFR-001, конституция II.3).
public protocol HTTPClient: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

/// `URLSession`-реализация с allowlist хостов: только https и разрешённые хосты.
/// Проверка выполняется до обращения к сети. Ephemeral-сессия: без кеша и cookies.
/// Редиректы запрещены (`NoRedirectDelegate`): иначе запрос с `Authorization` мог бы уйти
/// на хост вне allowlist; ответ 3xx возвращается вызывающему как есть.
public struct URLSessionHTTPClient: HTTPClient {
    public static let defaultAllowedHosts: Set<String> = ["api.anthropic.com"]

    private let allowedHosts: Set<String>
    private let session: URLSession

    public init(
        allowedHosts: Set<String> = URLSessionHTTPClient.defaultAllowedHosts,
        timeout: TimeInterval = 15
    ) {
        self.allowedHosts = Set(allowedHosts.map { $0.lowercased() })
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpCookieStorage = nil
        config.httpShouldSetCookies = false
        self.session = URLSession(
            configuration: config, delegate: NoRedirectDelegate(), delegateQueue: nil)
    }

    /// Клиент для Claude Code: токен Anthropic уходит только на `api.anthropic.com` (конституция II.3).
    public static func forClaude() -> URLSessionHTTPClient {
        URLSessionHTTPClient(allowedHosts: ["api.anthropic.com"])
    }

    /// Клиент для Codex: токен OpenAI уходит только на `chatgpt.com` (конституция II.3).
    public static func forCodex() -> URLSessionHTTPClient {
        URLSessionHTTPClient(allowedHosts: ["chatgpt.com"])
    }

    /// Бросает ошибку, если схема не https или хост вне allowlist.
    func validate(_ request: URLRequest) throws {
        guard let url = request.url, url.scheme?.lowercased() == "https" else {
            throw HTTPClientError.insecureScheme
        }
        guard let host = url.host?.lowercased(), allowedHosts.contains(host) else {
            throw HTTPClientError.hostNotAllowed
        }
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try validate(request)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw HTTPClientError.invalidResponse
        }
        return (data, http)
    }
}

/// Отклоняет любые HTTP-редиректы, чтобы allowlist хостов нельзя было обойти (NFR-001, II.3).
final class NoRedirectDelegate: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest
    ) async -> URLRequest? {
        nil
    }
}
