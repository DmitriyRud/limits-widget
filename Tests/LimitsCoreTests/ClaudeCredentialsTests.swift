import Foundation
import Testing

@testable import LimitsCore

private func claudeCredentialsFixture() throws -> Data {
    let url = try #require(
        Bundle.module.url(
            forResource: "claude_credentials", withExtension: "json", subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
}

@Suite("ClaudeCredentials")
struct ClaudeCredentialsTests {
    static let access = "FAKE-ACCESS-TOKEN-0000"
    static let refresh = "FAKE-REFRESH-TOKEN-0000"
    let expiry = Date(timeIntervalSince1970: 1_793_990_035)

    @Test func decodesFields() throws {
        let c = try ClaudeCredentials.decode(from: claudeCredentialsFixture())
        #expect(c.accessToken == Self.access)
        #expect(c.expiresAt == expiry)
        #expect(c.subscriptionType == "max")
    }

    @Test func missingOptionalFieldsDecodeAsNil() throws {
        let json = #"{"claudeAiOauth": {"accessToken": "FAKE-ACCESS-TOKEN-0000"}}"#
        let c = try ClaudeCredentials.decode(from: Data(json.utf8))
        #expect(c.expiresAt == nil)
        #expect(c.subscriptionType == nil)
    }

    @Test func missingClaudeAiOauthThrows() {
        #expect(throws: (any Error).self) {
            try ClaudeCredentials.decode(from: Data("{}".utf8))
        }
    }

    @Test func brokenJsonThrows() {
        #expect(throws: (any Error).self) {
            try ClaudeCredentials.decode(from: Data("{\"claudeAiOauth\": ".utf8))
        }
    }

    // NFR-001: токен не попадает ни в один текстовый вывод
    @Test func textualRepresentationsDoNotLeakTokens() throws {
        let c = try ClaudeCredentials.decode(from: claudeCredentialsFixture())
        var dumped = ""
        dump(c, to: &dumped)
        let outputs = [
            c.description,
            c.debugDescription,
            String(describing: c),
            String(reflecting: c),
            "\(c)",
            dumped,
        ]
        for out in outputs {
            #expect(!out.contains(Self.access))
            #expect(!out.contains(Self.refresh))
            #expect(!out.contains("FAKE-"))
        }
        #expect(c.description.lowercased().contains("redacted"))
        #expect(c.debugDescription.lowercased().contains("redacted"))
    }

    @Test func refreshTokenIsNotStored() throws {
        let c = try ClaudeCredentials.decode(from: claudeCredentialsFixture())
        let mirror = Mirror(reflecting: c)
        #expect(mirror.children.allSatisfy { $0.label != "refreshToken" })
    }

    @Test func isExpiredBeforeAndAfterExpiry() throws {
        let c = try ClaudeCredentials.decode(from: claudeCredentialsFixture())
        #expect(!c.isExpired(now: expiry.addingTimeInterval(-3_600)))
        #expect(c.isExpired(now: expiry.addingTimeInterval(3_600)))
    }
}
