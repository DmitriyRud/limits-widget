import Foundation
import Testing

@testable import LimitsCore

private func providerFixture(_ name: String, ext: String = "json") throws -> Data {
    let url = try #require(
        Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
}

private let fixedNow = Date(timeIntervalSince1970: 1_793_900_000)
private let testToken = "FAKE-ACCESS-TOKEN-0000"

private func credentials(expiresAt: Date? = fixedNow.addingTimeInterval(3_600)) -> ClaudeCredentials {
    ClaudeCredentials(accessToken: testToken, expiresAt: expiresAt, subscriptionType: "max")
}

private func makeProvider(
    _ creds: ClaudeCredentialsResult, _ http: FakeHTTPClient
) -> ClaudeCodeProvider {
    ClaudeCodeProvider(
        credentials: FakeCredentialSource(result: creds), http: http, now: { fixedNow })
}

@Suite("ClaudeCodeProvider")
struct ClaudeCodeProviderTests {
    @Test func identifiers() {
        let p = makeProvider(.notFound, FakeHTTPClient(.response(status: 200, body: Data())))
        #expect(p.id == "claude-code")
        #expect(p.displayName == "Claude Code")
    }

    @Test func missingCredentialsMeansNotAuthenticated() async {
        let http = FakeHTTPClient(.response(status: 200, body: Data()))
        let s = await makeProvider(.notFound, http).fetchSnapshot()
        #expect(s.status == .notAuthenticated)
        #expect(s.windows.isEmpty)
        #expect(http.requests.isEmpty)
    }

    @Test func unreadableCredentialsMeansError() async {
        let http = FakeHTTPClient(.response(status: 200, body: Data()))
        let s = await makeProvider(.unreadable, http).fetchSnapshot()
        #expect(s.status == .error(ProviderStatus.credentialsUnreadableMessage))
        #expect(http.requests.isEmpty)
    }

    @Test func expiredTokenSkipsNetwork() async {
        let http = FakeHTTPClient(.response(status: 200, body: Data()))
        let creds = credentials(expiresAt: fixedNow.addingTimeInterval(-1))
        let s = await makeProvider(.found(creds), http).fetchSnapshot()
        #expect(s.status == .tokenExpired)
        #expect(http.requests.isEmpty)
    }

    @Test(arguments: [401, 403])
    func unauthorizedMeansTokenExpired(code: Int) async {
        let http = FakeHTTPClient(.response(status: code, body: Data()))
        let s = await makeProvider(.found(credentials()), http).fetchSnapshot()
        #expect(s.status == .tokenExpired)
    }

    @Test func serverErrorMeansError() async {
        let http = FakeHTTPClient(.response(status: 500, body: Data()))
        let s = await makeProvider(.found(credentials()), http).fetchSnapshot()
        #expect(s.status == .error(ProviderStatus.httpErrorMessage(statusCode: 500)))
        #expect(s.windows.isEmpty)
    }

    @Test func networkFailureMeansError() async {
        let http = FakeHTTPClient(.failure(FakeHTTPClient.Failure()))
        let s = await makeProvider(.found(credentials()), http).fetchSnapshot()
        #expect(s.status == .error(ProviderStatus.networkErrorMessage))
    }

    @Test func brokenBodyMeansFormatChanged() async throws {
        let body = try providerFixture("claude_usage_broken")
        let http = FakeHTTPClient(.response(status: 200, body: body))
        let s = await makeProvider(.found(credentials()), http).fetchSnapshot()
        #expect(s.status == .error(ProviderStatus.formatChangedMessage))
    }

    @Test func successReturnsWindowsAndFetchedAt() async throws {
        let body = try providerFixture("claude_usage")
        let http = FakeHTTPClient(.response(status: 200, body: body))
        let s = await makeProvider(.found(credentials()), http).fetchSnapshot()
        #expect(s.status == .ok)
        #expect(s.providerID == "claude-code")
        #expect(s.fetchedAt == fixedNow)
        #expect(
            s.windows.map(\.kind) == [
                .session5h, .weekly, .weeklyModel("Opus"), .weeklyModel("Sonnet"),
            ])
        #expect(s.windows.map(\.usedPercent) == [42.0, 18.0, 77.5, 9.0])
    }

    @Test func requestHasExpectedHostPathAndHeaders() async throws {
        let body = try providerFixture("claude_usage")
        let http = FakeHTTPClient(.response(status: 200, body: body))
        _ = await makeProvider(.found(credentials()), http).fetchSnapshot()
        let request = try #require(http.requests.first)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.scheme == "https")
        #expect(request.url?.host == "api.anthropic.com")
        #expect(request.url?.path == "/api/oauth/usage")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(testToken)")
        #expect(request.value(forHTTPHeaderField: "anthropic-beta") == "oauth-2025-04-20")
    }

    @Test func tokenDoesNotLeakIntoSnapshot() async {
        let http = FakeHTTPClient(.failure(FakeHTTPClient.Failure()))
        let s = await makeProvider(.found(credentials()), http).fetchSnapshot()
        #expect(!String(describing: s).contains(testToken))
    }
}

@Suite("URLSessionHTTPClient allowlist")
struct URLSessionHTTPClientTests {
    @Test func foreignHostIsRejectedBeforeNetwork() async {
        let client = URLSessionHTTPClient()
        let foreign = URLRequest(url: URL(string: "https://example.com/api/oauth/usage")!)
        await #expect(throws: HTTPClientError.hostNotAllowed) {
            _ = try await client.send(foreign)
        }
    }

    @Test func lookalikeHostIsRejected() async {
        let client = URLSessionHTTPClient()
        let r = URLRequest(url: URL(string: "https://api.anthropic.com.evil.test/x")!)
        await #expect(throws: HTTPClientError.hostNotAllowed) { _ = try await client.send(r) }
    }

    @Test func plainHttpIsRejectedBeforeNetwork() async {
        let client = URLSessionHTTPClient()
        let r = URLRequest(url: URL(string: "http://api.anthropic.com/api/oauth/usage")!)
        await #expect(throws: HTTPClientError.insecureScheme) { _ = try await client.send(r) }
    }
}

@Suite("FileCredentialSource")
struct FileCredentialSourceTests {
    private func tempFile(_ name: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("limits-test-\(UUID().uuidString)-\(name)")
    }

    @Test func readsCredentialsFromFile() async throws {
        let url = tempFile("ok.json")
        defer { try? FileManager.default.removeItem(at: url) }
        try providerFixture("claude_credentials").write(to: url)
        let result = await FileCredentialSource(fileURL: url).loadClaudeCredentials()
        guard case .found(let c) = result else {
            Issue.record("expected .found")
            return
        }
        #expect(c.accessToken == testToken)
    }

    @Test func missingFileIsNotFound() async {
        let result = await FileCredentialSource(fileURL: tempFile("none.json"))
            .loadClaudeCredentials()
        guard case .notFound = result else {
            Issue.record("ожидался .notFound")
            return
        }
    }

    @Test func garbageFileIsUnreadable() async throws {
        let url = tempFile("bad.json")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("not json".utf8).write(to: url)
        let result = await FileCredentialSource(fileURL: url).loadClaudeCredentials()
        guard case .unreadable = result else {
            Issue.record("ожидался .unreadable")
            return
        }
    }

    @Test func chainFallsBackToNextSource() async {
        let creds = credentials()
        let chain = ChainedCredentialSource([
            FakeCredentialSource(result: .notFound),
            FakeCredentialSource(result: .found(creds)),
        ])
        guard case .found(let loaded) = await chain.loadClaudeCredentials() else {
            Issue.record("ожидался .found")
            return
        }
        #expect(loaded.accessToken == creds.accessToken)
    }
}

@Suite("NoRedirectDelegate")
struct NoRedirectDelegateTests {
    @Test func redirectToForeignHostIsRejected() async throws {
        let session = URLSession(configuration: .ephemeral)
        let original = try #require(URL(string: "https://api.anthropic.com/api/oauth/usage"))
        let target = try #require(URL(string: "https://evil.example/steal"))
        let task = session.dataTask(with: original)  // не запускается: resume() не вызывается
        let response = try #require(
            HTTPURLResponse(
                url: original, statusCode: 302, httpVersion: nil,
                headerFields: ["Location": target.absoluteString]))
        var redirect = URLRequest(url: target)
        redirect.setValue("Bearer FAKE-ACCESS-TOKEN-0000", forHTTPHeaderField: "Authorization")
        let next = await NoRedirectDelegate().urlSession(
            session, task: task, willPerformHTTPRedirection: response, newRequest: redirect)
        #expect(next == nil)
        task.cancel()
    }
}

@Suite("Per-provider host allowlist (II.3)")
struct ProviderHostAllowlistTests {
    static func request(_ string: String) throws -> URLRequest {
        URLRequest(url: try #require(URL(string: string)))
    }

    @Test func claudeClientAcceptsOnlyAnthropic() throws {
        let client = URLSessionHTTPClient.forClaude()
        try client.validate(Self.request("https://api.anthropic.com/api/oauth/usage"))
        #expect(throws: HTTPClientError.hostNotAllowed) {
            try client.validate(Self.request("https://chatgpt.com/backend-api/wham/usage"))
        }
    }

    @Test func codexClientAcceptsOnlyChatGPT() throws {
        let client = URLSessionHTTPClient.forCodex()
        try client.validate(Self.request("https://chatgpt.com/backend-api/wham/usage"))
        #expect(throws: HTTPClientError.hostNotAllowed) {
            try client.validate(Self.request("https://api.anthropic.com/api/oauth/usage"))
        }
    }
}
