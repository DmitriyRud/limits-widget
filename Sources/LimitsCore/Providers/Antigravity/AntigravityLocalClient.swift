import Foundation

/// Абстракция локального RPC-клиента к `agy --hub` (V.3).
public protocol AntigravityLocalClient: Sendable {
    func send(_ request: URLRequest, hub: AntigravityHubInfo) async throws -> (Data, HTTPURLResponse)
}

/// Изолированный `URLSession`-клиент строго для loopback `127.0.0.1` без редиректов (NFR-001).
/// Принимает самоподписанный TLS-сертификат локального `agy --hub` исключительно для `127.0.0.1`.
public struct LoopbackAntigravityLocalClient: AntigravityLocalClient {
    private let session: URLSession

    public init(timeout: TimeInterval = 5) {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpCookieStorage = nil
        config.httpShouldSetCookies = false
        self.session = URLSession(
            configuration: config, delegate: LoopbackOnlyDelegate(), delegateQueue: nil)
    }

    /// Проверяет, что запрос идёт строго на loopback `127.0.0.1` по `https` или `http`.
    func validate(_ request: URLRequest) throws {
        guard let url = request.url,
            let scheme = url.scheme?.lowercased(),
            scheme == "https" || scheme == "http"
        else {
            throw HTTPClientError.insecureScheme
        }
        guard url.host?.lowercased() == "127.0.0.1" else {
            throw HTTPClientError.hostNotAllowed
        }
    }

    public func send(_ request: URLRequest, hub: AntigravityHubInfo) async throws -> (
        Data, HTTPURLResponse
    ) {
        try validate(request)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw HTTPClientError.invalidResponse
        }
        return (data, http)
    }
}

/// Запрещает редиректы и принимает самоподписанный TLS только для `127.0.0.1`.
final class LoopbackOnlyDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate, Sendable {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest
    ) async -> URLRequest? {
        nil
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        let space = challenge.protectionSpace
        if space.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            space.host == "127.0.0.1",
            let trust = space.serverTrust
        {
            return (.useCredential, URLCredential(trust: trust))
        }
        return (.performDefaultHandling, nil)
    }
}
