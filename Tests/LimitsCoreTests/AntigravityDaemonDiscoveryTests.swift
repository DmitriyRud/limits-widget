import Foundation
import Testing

@testable import LimitsCore

@Suite("AntigravityDaemonDiscovery")
struct AntigravityDaemonDiscoveryTests {
    @Test func redactsCsrfTokenInAllStringRepresentations() {
        let secret = "csrf-secret-value-1234567890"
        let info = AntigravityHubInfo(httpsPort: 52583, httpPort: 52584, pid: 1234, csrfToken: secret)

        #expect(!info.description.contains(secret))
        #expect(!info.debugDescription.contains(secret))
        #expect(!String(describing: info).contains(secret))
        #expect(!String(reflecting: info).contains(secret))
        #expect(Mirror(reflecting: info).children.isEmpty)
    }

    @Test func discoversHubFilesSortedNewestFirstAndSkipsMalformed() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("antigravity-discovery-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let older = dir.appendingPathComponent("hub_50001.json")
        let newer = dir.appendingPathComponent("hub_50002.json")
        let broken = dir.appendingPathComponent("hub_50003.json")
        let ignored = dir.appendingPathComponent("other.json")

        try Data(#"{"httpsPort":50001,"httpPort":50011,"pid":10,"csrfToken":"tok-old"}"#.utf8)
            .write(to: older)
        try Data(#"{"httpsPort":50002,"httpPort":50012,"pid":20,"csrfToken":"tok-new"}"#.utf8)
            .write(to: newer)
        try Data("{not-json".utf8).write(to: broken)
        try Data(#"{"httpsPort":50004,"csrfToken":"tok-other"}"#.utf8).write(to: ignored)

        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSince1970: 1_000)], ofItemAtPath: older.path)
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSince1970: 2_000)], ofItemAtPath: newer.path)

        let discovery = FileAntigravityDaemonDiscovery(daemonDirectory: dir)
        let hubs = discovery.discoverHubs()

        #expect(hubs.count == 2)
        #expect(hubs[0].httpsPort == 50002)
        #expect(hubs[1].httpsPort == 50001)
    }

    @Test func returnsEmptyWhenDirectoryMissing() {
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("antigravity-missing-\(UUID().uuidString)", isDirectory: true)
        let discovery = FileAntigravityDaemonDiscovery(daemonDirectory: missing)
        #expect(discovery.discoverHubs().isEmpty)
    }
}
