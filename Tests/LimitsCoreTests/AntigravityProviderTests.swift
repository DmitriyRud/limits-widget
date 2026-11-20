import Foundation
import Testing

@testable import LimitsCore

private struct FakeDaemonDiscovery: AntigravityDaemonDiscovery {
    let hubs: [AntigravityHubInfo]
    func discoverHubs() -> [AntigravityHubInfo] { hubs }
}

private actor RecordingLocalClient: AntigravityLocalClient {
    enum Outcome: Sendable {
        case response(Int, Data)
        case failure
    }

    private var outcomes: [Outcome]
    private(set) var recordedRequests: [(AntigravityHubInfo, URLRequest)] = []

    init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    func send(_ request: URLRequest, hub: AntigravityHubInfo) async throws -> (Data, HTTPURLResponse) {
        recordedRequests.append((hub, request))
        guard !outcomes.isEmpty else { throw URLError(.cannotConnectToHost) }
        switch outcomes.removeFirst() {
        case .failure:
            throw URLError(.cannotConnectToHost)
        case .response(let code, let data):
            let url = request.url ?? URL(string: "https://127.0.0.1:1")!
            let http = HTTPURLResponse(
                url: url, statusCode: code, httpVersion: nil, headerFields: nil)!
            return (data, http)
        }
    }
}

@Suite("AntigravityProvider")
struct AntigravityProviderTests {
    let now = Date(timeIntervalSince1970: 1_795_165_200)

    private static let validSummaryJSON = Data(
        """
        {
          "response": {
            "groups": [
              {
                "displayName": "Gemini Models",
                "buckets": [
                  {"window": "weekly", "remainingFraction": 0.97, "resetTime": "2026-11-26T21:12:51Z"},
                  {"window": "5h", "remainingFraction": 0.98, "resetTime": "2026-11-20T14:09:16Z"}
                ]
              },
              {
                "displayName": "Gemini 4 Argon",
                "buckets": [
                  {"window": "weekly", "remainingFraction": 1, "resetTime": "2026-11-27T09:10:13Z"}
                ]
              }
            ]
          }
        }
        """.utf8)

    private static let validStatusJSON = Data(
        """
        {
          "userStatus": {
            "cascadeModelConfigData": {
              "clientModelConfigs": [
                {
                  "label": "Gemini 4 Neon (High)",
                  "quotaInfo": {
                    "remainingFraction": 0.85,
                    "resetTime": "2026-11-20T14:12:51Z"
                  }
                }
              ]
            }
          }
        }
        """.utf8)

    @Test func returnsNoDataWhenNoHubsFound() async {
        let client = RecordingLocalClient(outcomes: [])
        let provider = AntigravityProvider(
            discovery: FakeDaemonDiscovery(hubs: []),
            client: client,
            now: { now }
        )
        let snapshot = await provider.fetchSnapshot()
        #expect(snapshot.status == .noData)
        #expect(snapshot.windows.isEmpty)
    }

    @Test func fetchesAllQuotaSummaryWindowsFromFirstHub() async {
        let hub = AntigravityHubInfo(httpsPort: 52583, httpPort: 52584, pid: 100, csrfToken: "csrf-abc")
        let client = RecordingLocalClient(outcomes: [.response(200, Self.validSummaryJSON)])
        let provider = AntigravityProvider(
            discovery: FakeDaemonDiscovery(hubs: [hub]),
            client: client,
            now: { now }
        )

        let snapshot = await provider.fetchSnapshot()
        #expect(snapshot.providerID == "antigravity")
        #expect(snapshot.displayName == "Antigravity")
        #expect(snapshot.status == .ok)
        #expect(snapshot.windows.count == 3)
        #expect(ResetFormatter.title(for: snapshot.windows[0].kind) == "Gemini · 5 ч")
        #expect(ResetFormatter.title(for: snapshot.windows[1].kind) == "Gemini · Неделя")
        #expect(ResetFormatter.title(for: snapshot.windows[2].kind) == "Gemini 4 Argon · Неделя")

        let recorded = await client.recordedRequests
        #expect(recorded.count == 1)
        let req = recorded[0].1
        #expect(req.url?.host == "127.0.0.1")
        #expect(req.url?.port == 52583)
        #expect(req.url?.scheme == "https")
        #expect(
            req.url?.path == "/exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary")
        #expect(req.value(forHTTPHeaderField: "X-Codeium-Csrf-Token") == "csrf-abc")
        #expect(req.value(forHTTPHeaderField: "Connect-Protocol-Version") == "1")
    }

    @Test func fallsBackToGetUserStatusWhenSummaryReturns404() async {
        let hub = AntigravityHubInfo(httpsPort: 52583, httpPort: nil, pid: 1, csrfToken: "tok")
        let client = RecordingLocalClient(outcomes: [
            .response(404, Data()),
            .response(200, Self.validStatusJSON),
        ])
        let provider = AntigravityProvider(
            discovery: FakeDaemonDiscovery(hubs: [hub]),
            client: client,
            now: { now }
        )

        let snapshot = await provider.fetchSnapshot()
        #expect(snapshot.status == .ok)
        #expect(snapshot.windows.count == 1)
        #expect(snapshot.windows[0].kind == .overall)
        #expect(abs(snapshot.windows[0].usedPercent - 15.0) < 0.001)

        let recorded = await client.recordedRequests
        #expect(recorded.count == 2)
        #expect(recorded[1].1.url?.path == "/exa.language_server_pb.LanguageServerService/GetUserStatus")
    }

    @Test func fallsBackToSecondHubWhenFirstIsUnreachable() async {
        let stale = AntigravityHubInfo(httpsPort: 50001, httpPort: nil, pid: 1, csrfToken: "old")
        let live = AntigravityHubInfo(httpsPort: 50002, httpPort: nil, pid: 2, csrfToken: "live")
        let client = RecordingLocalClient(outcomes: [.failure, .response(200, Self.validSummaryJSON)])
        let provider = AntigravityProvider(
            discovery: FakeDaemonDiscovery(hubs: [stale, live]),
            client: client,
            now: { now }
        )

        let snapshot = await provider.fetchSnapshot()
        #expect(snapshot.status == .ok)
        let recorded = await client.recordedRequests
        #expect(recorded.count == 2)
        #expect(recorded[1].1.url?.port == 50002)
    }

    @Test func returnsNoDataWhenAllHubsUnreachable() async {
        let stale = AntigravityHubInfo(httpsPort: 50001, httpPort: nil, pid: 1, csrfToken: "old")
        let client = RecordingLocalClient(outcomes: [.failure])
        let provider = AntigravityProvider(
            discovery: FakeDaemonDiscovery(hubs: [stale]),
            client: client,
            now: { now }
        )

        let snapshot = await provider.fetchSnapshot()
        #expect(snapshot.status == .noData)
    }

    @Test func maps401ToNotAuthenticated() async {
        let hub = AntigravityHubInfo(httpsPort: 52583, httpPort: nil, pid: 1, csrfToken: "tok")
        let client = RecordingLocalClient(outcomes: [.response(401, Data())])
        let provider = AntigravityProvider(
            discovery: FakeDaemonDiscovery(hubs: [hub]),
            client: client,
            now: { now }
        )

        let snapshot = await provider.fetchSnapshot()
        #expect(snapshot.status == .notAuthenticated)
    }

    @Test func mapsMalformedFallbackJSONToFormatChangedError() async {
        let hub = AntigravityHubInfo(httpsPort: 52583, httpPort: nil, pid: 1, csrfToken: "tok")
        let client = RecordingLocalClient(outcomes: [
            .response(200, Data("{broken".utf8)),
            .response(200, Data("{broken".utf8)),
        ])
        let provider = AntigravityProvider(
            discovery: FakeDaemonDiscovery(hubs: [hub]),
            client: client,
            now: { now }
        )

        let snapshot = await provider.fetchSnapshot()
        #expect(snapshot.status == .error(ProviderStatus.formatChangedMessage))
    }

    @Test func loopbackClientRejectsExternalHosts() throws {
        let client = LoopbackAntigravityLocalClient()
        let external = URLRequest(url: URL(string: "https://example.com/status")!)
        #expect(throws: HTTPClientError.hostNotAllowed) {
            try client.validate(external)
        }
        let loopback = URLRequest(url: URL(string: "https://127.0.0.1:52583/status")!)
        try client.validate(loopback)
    }
}
