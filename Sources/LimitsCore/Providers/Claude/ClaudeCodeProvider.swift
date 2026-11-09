import Foundation

/// Провайдер лимитов Claude Code через `oauth/usage` (FR-001, FR-002, FR-008).
/// Токен живёт только в локальной переменной на время запроса и не попадает в ошибки.
public struct ClaudeCodeProvider: LimitsProvider {
    public let id = "claude-code"
    public let displayName = "Claude Code"

    static let usageURL = URL(string: "https://api.anthropic.com/api/oauth/usage")

    private let credentials: any CredentialSource
    private let http: any HTTPClient
    private let now: @Sendable () -> Date

    public init(
        credentials: any CredentialSource,
        http: any HTTPClient,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.credentials = credentials
        self.http = http
        self.now = now
    }

    public func fetchSnapshot() async -> ProviderSnapshot {
        switch await credentials.loadClaudeCredentials() {
        case .notFound:
            return snapshot(.notAuthenticated)
        case .unreadable:
            return snapshot(.error(ProviderStatus.credentialsUnreadableMessage))
        case .found(let creds):
            if creds.isExpired(now: now()) { return snapshot(.tokenExpired) }
            return await fetchUsage(creds)
        }
    }

    private func fetchUsage(_ creds: ClaudeCredentials) async -> ProviderSnapshot {
        guard let url = Self.usageURL else {
            return snapshot(.error(ProviderStatus.networkErrorMessage))
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(creds.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await http.send(request)
        } catch {
            return snapshot(.error(ProviderStatus.networkErrorMessage))
        }
        switch response.statusCode {
        case 200..<300:
            break
        case 401, 403:
            return snapshot(.tokenExpired)
        default:
            return snapshot(.error(ProviderStatus.httpErrorMessage(statusCode: response.statusCode)))
        }
        guard let usage = try? ClaudeUsageResponse.decode(from: data) else {
            return snapshot(.error(ProviderStatus.formatChangedMessage))
        }
        return snapshot(.ok, windows: usage.windows())
    }

    private func snapshot(_ status: ProviderStatus, windows: [UsageWindow] = []) -> ProviderSnapshot {
        ProviderSnapshot(
            providerID: id, displayName: displayName, status: status,
            windows: windows, fetchedAt: now())
    }
}
