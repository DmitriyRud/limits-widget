import Foundation
import Testing

@testable import LimitsCore

private func networkFixture(_ name: String, ext: String = "json") throws -> Data {
    let url = try #require(
        Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
}

private let fixedNow = Date(timeIntervalSince1970: 1_794_300_000)
private let journalFetchedAt = Date(timeIntervalSince1970: 1_794_219_645.5)
private let accessToken = "FAKE-CODEX-ACCESS-0000"
private let accountID = "FAKE-ACCOUNT-0000"

@Suite("CodexProvider network")
struct CodexNetworkProviderTests {
    private func makeHome(withJournal: Bool) throws -> URL {
        let home = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: home.appendingPathComponent("auth.json"))
        if withJournal {
            let dir = home.appendingPathComponent("sessions/2026/11/06", isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try networkFixture("codex_session", ext: "jsonl")
                .write(to: dir.appendingPathComponent("rollout-test.jsonl"))
        }
        return home
    }

    private func found(account: String? = accountID) -> FakeCodexCredentialSource {
        FakeCodexCredentialSource(
            result: .found(CodexCredentials(accessToken: accessToken, accountID: account)))
    }

    private func provider(
        home: URL, source: FakeCodexCredentialSource, http: FakeHTTPClient?
    ) -> CodexProvider {
        CodexProvider(codexHome: home, credentials: source, http: http, now: { fixedNow })
    }

    private func ok200() throws -> FakeHTTPClient {
        FakeHTTPClient(.response(status: 200, body: try networkFixture("codex_usage")))
    }

    // FR-004: сеть, happy path
    @Test func networkSuccessYieldsOkWithWindowsFromResponse() async throws {
        let home = try makeHome(withJournal: false)
        defer { try? FileManager.default.removeItem(at: home) }
        let snapshot = await provider(home: home, source: found(), http: try ok200())
            .fetchSnapshot()
        #expect(snapshot.status == .ok)
        #expect(snapshot.providerID == "codex")
        #expect(snapshot.windows.map(\.kind) == [.session5h, .weekly])
        #expect(snapshot.windows.map(\.usedPercent) == [0, 14])
        #expect(
            snapshot.windows.map(\.resetsAt) == [
                Date(timeIntervalSince1970: 1_794_267_824),
                Date(timeIntervalSince1970: 1_794_829_044),
            ])
        #expect(snapshot.fetchedAt == fixedNow)
    }

    @Test func networkSuccessIgnoresJournalWhenBothExist() async throws {
        let home = try makeHome(withJournal: true)
        defer { try? FileManager.default.removeItem(at: home) }
        let snapshot = await provider(home: home, source: found(), http: try ok200())
            .fetchSnapshot()
        #expect(snapshot.fetchedAt == fixedNow)
        #expect(snapshot.windows.map(\.usedPercent) == [0, 14])
    }

    // NFR-001/NFR-003: форма запроса
    @Test func requestTargetsUsageEndpointWithAuthHeaders() async throws {
        let home = try makeHome(withJournal: false)
        defer { try? FileManager.default.removeItem(at: home) }
        let http = try ok200()
        _ = await provider(home: home, source: found(), http: http).fetchSnapshot()
        let request = try #require(http.requests.first)
        #expect(http.requests.count == 1)
        #expect(request.httpMethod == "GET" || request.httpMethod == nil)
        #expect(request.url?.scheme == "https")
        #expect(request.url?.host == "chatgpt.com")
        #expect(request.url?.path == "/backend-api/wham/usage")
        #expect(request.url == CodexProvider.usageURL)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(accessToken)")
        #expect(request.value(forHTTPHeaderField: "ChatGPT-Account-Id") == accountID)
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func accountHeaderIsOmittedWhenAccountIDIsNil() async throws {
        let home = try makeHome(withJournal: false)
        defer { try? FileManager.default.removeItem(at: home) }
        let http = try ok200()
        let snapshot = await provider(home: home, source: found(account: nil), http: http)
            .fetchSnapshot()
        let request = try #require(http.requests.first)
        #expect(request.value(forHTTPHeaderField: "ChatGPT-Account-Id") == nil)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(accessToken)")
        #expect(snapshot.status == .ok)
    }

    // FR-008: деградация к журналам
    @Test func unauthorizedWithJournalFallsBackToJournalData() async throws {
        let home = try makeHome(withJournal: true)
        defer { try? FileManager.default.removeItem(at: home) }
        let http = FakeHTTPClient(.response(status: 401, body: Data()))
        let snapshot = await provider(home: home, source: found(), http: http).fetchSnapshot()
        #expect(snapshot.status == .ok)
        #expect(snapshot.windows.count == 2)
        #expect(snapshot.fetchedAt == journalFetchedAt)
        #expect(snapshot.fetchedAt != fixedNow)
    }

    @Test func unauthorizedWithoutJournalMeansTokenExpired() async throws {
        let home = try makeHome(withJournal: false)
        defer { try? FileManager.default.removeItem(at: home) }
        let http = FakeHTTPClient(.response(status: 401, body: Data()))
        let snapshot = await provider(home: home, source: found(), http: http).fetchSnapshot()
        #expect(snapshot.status == .tokenExpired)
    }

    @Test func forbiddenWithoutJournalMeansTokenExpired() async throws {
        let home = try makeHome(withJournal: false)
        defer { try? FileManager.default.removeItem(at: home) }
        let http = FakeHTTPClient(.response(status: 403, body: Data()))
        let snapshot = await provider(home: home, source: found(), http: http).fetchSnapshot()
        #expect(snapshot.status == .tokenExpired)
    }

    @Test func serverErrorWithoutJournalMeansError() async throws {
        let home = try makeHome(withJournal: false)
        defer { try? FileManager.default.removeItem(at: home) }
        let http = FakeHTTPClient(.response(status: 500, body: Data()))
        let snapshot = await provider(home: home, source: found(), http: http).fetchSnapshot()
        guard case .error = snapshot.status else {
            Issue.record("expected .error, got \(snapshot.status)")
            return
        }
    }

    @Test func serverErrorWithJournalFallsBackToJournal() async throws {
        let home = try makeHome(withJournal: true)
        defer { try? FileManager.default.removeItem(at: home) }
        let http = FakeHTTPClient(.response(status: 500, body: Data()))
        let snapshot = await provider(home: home, source: found(), http: http).fetchSnapshot()
        #expect(snapshot.status == .ok)
        #expect(snapshot.fetchedAt == journalFetchedAt)
    }

    @Test func networkFailureWithJournalFallsBackToJournal() async throws {
        let home = try makeHome(withJournal: true)
        defer { try? FileManager.default.removeItem(at: home) }
        let http = FakeHTTPClient(.failure(FakeHTTPClient.Failure()))
        let snapshot = await provider(home: home, source: found(), http: http).fetchSnapshot()
        #expect(snapshot.status == .ok)
        #expect(snapshot.windows.count == 2)
        #expect(snapshot.fetchedAt == journalFetchedAt)
    }

    @Test func networkFailureWithoutJournalMeansError() async throws {
        let home = try makeHome(withJournal: false)
        defer { try? FileManager.default.removeItem(at: home) }
        let http = FakeHTTPClient(.failure(FakeHTTPClient.Failure()))
        let snapshot = await provider(home: home, source: found(), http: http).fetchSnapshot()
        guard case .error = snapshot.status else {
            Issue.record("expected .error, got \(snapshot.status)")
            return
        }
    }

    @Test func brokenJsonWithJournalFallsBackToJournal() async throws {
        let home = try makeHome(withJournal: true)
        defer { try? FileManager.default.removeItem(at: home) }
        let http = FakeHTTPClient(
            .response(status: 200, body: try networkFixture("codex_usage_broken")))
        let snapshot = await provider(home: home, source: found(), http: http).fetchSnapshot()
        #expect(snapshot.status == .ok)
        #expect(snapshot.fetchedAt == journalFetchedAt)
    }

    @Test func brokenJsonWithoutJournalMeansError() async throws {
        let home = try makeHome(withJournal: false)
        defer { try? FileManager.default.removeItem(at: home) }
        let http = FakeHTTPClient(
            .response(status: 200, body: try networkFixture("codex_usage_broken")))
        let snapshot = await provider(home: home, source: found(), http: http).fetchSnapshot()
        guard case .error = snapshot.status else {
            Issue.record("expected .error, got \(snapshot.status)")
            return
        }
    }

    // FR-003: отсутствие/непригодность учётки
    @Test func noAuthFileMeansNotAuthenticatedAndNoHTTPCall() async throws {
        let home = try makeHome(withJournal: true)
        defer { try? FileManager.default.removeItem(at: home) }
        let http = try ok200()
        let snapshot = await provider(
            home: home, source: FakeCodexCredentialSource(result: .noAuthFile), http: http
        ).fetchSnapshot()
        #expect(snapshot.status == .notAuthenticated)
        #expect(http.requests.isEmpty)
    }

    @Test func noTokensUsesJournalWithoutHTTPCall() async throws {
        let home = try makeHome(withJournal: true)
        defer { try? FileManager.default.removeItem(at: home) }
        let http = try ok200()
        let snapshot = await provider(
            home: home, source: FakeCodexCredentialSource(result: .noTokens), http: http
        ).fetchSnapshot()
        #expect(snapshot.status == .ok)
        #expect(snapshot.fetchedAt == journalFetchedAt)
        #expect(http.requests.isEmpty)
    }

    @Test func noTokensWithoutJournalMeansNoData() async throws {
        let home = try makeHome(withJournal: false)
        defer { try? FileManager.default.removeItem(at: home) }
        let http = try ok200()
        let snapshot = await provider(
            home: home, source: FakeCodexCredentialSource(result: .noTokens), http: http
        ).fetchSnapshot()
        #expect(snapshot.status == .noData)
        #expect(http.requests.isEmpty)
    }

    @Test func unreadableCredentialsUseJournalWithoutHTTPCall() async throws {
        let home = try makeHome(withJournal: true)
        defer { try? FileManager.default.removeItem(at: home) }
        let http = try ok200()
        let snapshot = await provider(
            home: home, source: FakeCodexCredentialSource(result: .unreadable), http: http
        ).fetchSnapshot()
        #expect(snapshot.status == .ok)
        #expect(snapshot.fetchedAt == journalFetchedAt)
        #expect(http.requests.isEmpty)
    }

    // сеть выключена (http == nil): поведение только по журналам
    @Test func withoutHTTPClientOnlyJournalIsUsed() async throws {
        let home = try makeHome(withJournal: true)
        defer { try? FileManager.default.removeItem(at: home) }
        let snapshot = await provider(home: home, source: found(), http: nil).fetchSnapshot()
        #expect(snapshot.status == .ok)
        #expect(snapshot.fetchedAt == journalFetchedAt)
    }

    @Test func withoutHTTPClientAndJournalMeansNoData() async throws {
        let home = try makeHome(withJournal: false)
        defer { try? FileManager.default.removeItem(at: home) }
        let snapshot = await provider(home: home, source: found(), http: nil).fetchSnapshot()
        #expect(snapshot.status == .noData)
    }
}
