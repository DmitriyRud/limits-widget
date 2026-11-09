import Foundation
import Testing

@testable import LimitsCore

private func codexCredentialsFixture() throws -> Data {
    let url = try #require(
        Bundle.module.url(
            forResource: "codex_credentials", withExtension: "json", subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
}

@Suite("CodexCredentials")
struct CodexCredentialsTests {
    static let access = "FAKE-CODEX-ACCESS-0000"
    static let refresh = "FAKE-CODEX-REFRESH-0000"
    static let idToken = "FAKE-CODEX-ID-TOKEN-0000"
    static let account = "FAKE-ACCOUNT-0000"
    static let secrets = [access, refresh, idToken, account]

    private func makeDir() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    // FR-003: декодирование
    @Test func decodesAccessTokenAndAccountID() throws {
        let c = try CodexCredentials.decode(from: codexCredentialsFixture())
        #expect(c.accessToken == Self.access)
        #expect(c.accountID == Self.account)
    }

    @Test func missingAccountIDDecodesAsNil() throws {
        let json = #"{"tokens": {"access_token": "FAKE-CODEX-ACCESS-0000"}}"#
        let c = try CodexCredentials.decode(from: Data(json.utf8))
        #expect(c.accessToken == Self.access)
        #expect(c.accountID == nil)
    }

    @Test func nullAccountIDDecodesAsNil() throws {
        let json = #"{"tokens": {"access_token": "FAKE-CODEX-ACCESS-0000", "account_id": null}}"#
        let c = try CodexCredentials.decode(from: Data(json.utf8))
        #expect(c.accountID == nil)
    }

    @Test func unknownFieldsAreIgnored() throws {
        let json = #"""
            {"unknown": 1, "tokens": {"access_token": "FAKE-CODEX-ACCESS-0000", "x": [1]}}
            """#
        let c = try CodexCredentials.decode(from: Data(json.utf8))
        #expect(c.accessToken == Self.access)
    }

    @Test func missingTokensThrows() {
        #expect(throws: (any Error).self) {
            try CodexCredentials.decode(from: Data(#"{"OPENAI_API_KEY": "x"}"#.utf8))
        }
    }

    @Test func nullTokensThrows() {
        #expect(throws: (any Error).self) {
            try CodexCredentials.decode(from: Data(#"{"tokens": null}"#.utf8))
        }
    }

    @Test func missingAccessTokenThrows() {
        #expect(throws: (any Error).self) {
            try CodexCredentials.decode(from: Data(#"{"tokens": {"account_id": "x"}}"#.utf8))
        }
    }

    @Test func brokenJsonThrows() {
        #expect(throws: (any Error).self) {
            try CodexCredentials.decode(from: Data("{\"tokens\": ".utf8))
        }
    }

    // NFR-001: секреты не попадают ни в один текстовый вывод
    @Test func textualRepresentationsDoNotLeakSecrets() throws {
        let c = try CodexCredentials.decode(from: codexCredentialsFixture())
        var dumped = ""
        dump(c, to: &dumped)
        let mirrorText = Mirror(reflecting: c).children
            .map { "\($0.label ?? "") \($0.value)" }.joined(separator: "\n")
        let outputs = [
            c.description,
            c.debugDescription,
            String(describing: c),
            String(reflecting: c),
            "\(c)",
            dumped,
            mirrorText,
        ]
        for out in outputs {
            for secret in Self.secrets {
                #expect(!out.contains(secret))
            }
            #expect(!out.contains("FAKE-"))
        }
        #expect(c.description.lowercased().contains("redacted"))
        #expect(c.debugDescription.lowercased().contains("redacted"))
    }

    @Test func refreshAndIdTokensAreNotStored() throws {
        let c = try CodexCredentials.decode(from: codexCredentialsFixture())
        let labels = Mirror(reflecting: c).children.compactMap(\.label)
        #expect(!labels.contains("refreshToken"))
        #expect(!labels.contains("idToken"))
    }

    // FR-003: FileCodexCredentialSource
    @Test func missingFileMeansNoAuthFile() async throws {
        let dir = try makeDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let source = FileCodexCredentialSource(fileURL: dir.appendingPathComponent("absent.json"))
        let result = await source.loadCodexCredentials()
        guard case .noAuthFile = result else {
            Issue.record("expected .noAuthFile")
            return
        }
    }

    @Test func fileWithoutTokensMeansNoTokens() async throws {
        let dir = try makeDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("a.json")
        try Data(#"{"OPENAI_API_KEY": "x"}"#.utf8).write(to: file)
        let result = await FileCodexCredentialSource(fileURL: file).loadCodexCredentials()
        guard case .noTokens = result else {
            Issue.record("expected .noTokens")
            return
        }
    }

    @Test func garbageFileMeansUnreadable() async throws {
        let dir = try makeDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("a.json")
        try Data("not json at all {{{".utf8).write(to: file)
        let result = await FileCodexCredentialSource(fileURL: file).loadCodexCredentials()
        guard case .unreadable = result else {
            Issue.record("expected .unreadable")
            return
        }
    }

    @Test func validFileYieldsFoundCredentials() async throws {
        let dir = try makeDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("a.json")
        try codexCredentialsFixture().write(to: file)
        let result = await FileCodexCredentialSource(fileURL: file).loadCodexCredentials()
        guard case .found(let c) = result else {
            Issue.record("expected .found")
            return
        }
        #expect(c.accessToken == Self.access)
        #expect(c.accountID == Self.account)
    }

    @Test func readingDoesNotModifyTheFile() async throws {
        let dir = try makeDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("a.json")
        let original = try codexCredentialsFixture()
        try original.write(to: file)
        _ = await FileCodexCredentialSource(fileURL: file).loadCodexCredentials()
        #expect(try Data(contentsOf: file) == original)
    }
}
