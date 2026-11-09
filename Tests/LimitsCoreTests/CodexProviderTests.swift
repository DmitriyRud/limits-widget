import Foundation
import Testing

@testable import LimitsCore

@Suite("CodexProvider")
struct CodexProviderTests {
    private func makeHome() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func fixture(_ name: String) throws -> Data {
        let url = try #require(
            Bundle.module.url(forResource: name, withExtension: "jsonl", subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }

    private func writeAuth(_ home: URL) throws {
        try Data("{}".utf8).write(to: home.appendingPathComponent("auth.json"))
    }

    @discardableResult
    private func writeSession(
        _ home: URL, day: String = "2026/11/09", name: String, data: Data, mtime: Date
    ) throws -> URL {
        let dir = home.appendingPathComponent("sessions/\(day)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent(name)
        try data.write(to: file)
        try FileManager.default.setAttributes([.modificationDate: mtime], ofItemAtPath: file.path)
        return file
    }

    @Test func missingAuthFileMeansNotAuthenticated() async throws {
        let home = try makeHome()
        defer { try? FileManager.default.removeItem(at: home) }
        let snapshot = await CodexProvider(codexHome: home).fetchSnapshot()
        #expect(snapshot.status == .notAuthenticated)
        #expect(snapshot.providerID == "codex")
    }

    @Test func authWithoutSessionsMeansNoData() async throws {
        let home = try makeHome()
        defer { try? FileManager.default.removeItem(at: home) }
        try writeAuth(home)
        let snapshot = await CodexProvider(codexHome: home).fetchSnapshot()
        #expect(snapshot.status == .noData)
    }

    @Test func sessionWithRateLimitsYieldsOkSnapshot() async throws {
        let home = try makeHome()
        defer { try? FileManager.default.removeItem(at: home) }
        try writeAuth(home)
        try writeSession(
            home, name: "rollout-a.jsonl", data: try fixture("codex_session"),
            mtime: Date(timeIntervalSince1970: 1_794_000_000))
        let snapshot = await CodexProvider(codexHome: home).fetchSnapshot()
        #expect(snapshot.status == .ok)
        #expect(snapshot.windows.count == 2)
        #expect(snapshot.fetchedAt == Date(timeIntervalSince1970: 1_794_219_645.5))
    }

    @Test func newestFileByMtimeWins() async throws {
        let home = try makeHome()
        defer { try? FileManager.default.removeItem(at: home) }
        try writeAuth(home)
        try writeSession(
            home, name: "rollout-old.jsonl", data: try fixture("codex_session"),
            mtime: Date(timeIntervalSince1970: 1_794_000_000))
        try writeSession(
            home, name: "rollout-new.jsonl", data: try fixture("codex_null_secondary"),
            mtime: Date(timeIntervalSince1970: 1_794_100_000))
        let snapshot = await CodexProvider(codexHome: home).fetchSnapshot()
        #expect(snapshot.status == .ok)
        #expect(snapshot.windows.count == 1)
    }

    @Test func fallsBackToPreviousFileWhenNewestHasNoRateLimits() async throws {
        let home = try makeHome()
        defer { try? FileManager.default.removeItem(at: home) }
        try writeAuth(home)
        try writeSession(
            home, day: "2026/11/08", name: "rollout-old.jsonl",
            data: try fixture("codex_session"),
            mtime: Date(timeIntervalSince1970: 1_794_000_000))
        try writeSession(
            home, name: "rollout-new.jsonl", data: try fixture("codex_no_rate_limits"),
            mtime: Date(timeIntervalSince1970: 1_794_100_000))
        let snapshot = await CodexProvider(codexHome: home).fetchSnapshot()
        #expect(snapshot.status == .ok)
        #expect(snapshot.windows.count == 2)
    }

    @Test func sessionsWithoutRateLimitsMeanNoData() async throws {
        let home = try makeHome()
        defer { try? FileManager.default.removeItem(at: home) }
        try writeAuth(home)
        try writeSession(
            home, name: "rollout-a.jsonl", data: try fixture("codex_no_rate_limits"),
            mtime: Date(timeIntervalSince1970: 1_794_000_000))
        let snapshot = await CodexProvider(codexHome: home).fetchSnapshot()
        #expect(snapshot.status == .noData)
    }
}
