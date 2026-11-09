import Foundation
import Testing

@testable import LimitsCore

private func claudeUsageFixture(_ name: String) throws -> Data {
    let url = try #require(
        Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
}

@Suite("ClaudeUsageResponse")
struct ClaudeUsageResponseTests {
    let fiveHourReset = Date(timeIntervalSince1970: 1_794_258_000)  // 2026-11-09T21:00:00Z
    let weeklyReset = Date(timeIntervalSince1970: 1_794_643_200)  // 2026-11-14T08:00:00Z

    // FR-002: happy path
    @Test func decodesAllFourWindows() throws {
        let r = try ClaudeUsageResponse.decode(from: claudeUsageFixture("claude_usage"))
        #expect(r.fiveHour?.utilization == 42.0)
        #expect(r.sevenDay?.utilization == 18.0)
        #expect(r.sevenDayOpus?.utilization == 77.5)
        #expect(r.sevenDaySonnet?.utilization == 9.0)
    }

    @Test func parsesFractionalSecondsIso8601Reset() throws {
        let r = try ClaudeUsageResponse.decode(from: claudeUsageFixture("claude_usage"))
        let reset = try #require(r.fiveHour?.resetsAt)
        #expect(abs(reset.timeIntervalSince(fiveHourReset)) < 1)
        let weekly = try #require(r.sevenDay?.resetsAt)
        #expect(abs(weekly.timeIntervalSince(weeklyReset)) < 1)
    }

    @Test func windowsAreOrderedAndMappedToKinds() throws {
        let r = try ClaudeUsageResponse.decode(from: claudeUsageFixture("claude_usage"))
        let w = r.windows()
        #expect(
            w.map(\.kind) == [.session5h, .weekly, .weeklyModel("Opus"), .weeklyModel("Sonnet")])
        #expect(w.map(\.usedPercent) == [42.0, 18.0, 77.5, 9.0])
        #expect(abs(try #require(w[0].resetsAt).timeIntervalSince(fiveHourReset)) < 1)
    }

    // FR-002: null / отсутствующие окна
    @Test func nullAndMissingWindowsAreNilAndSkipped() throws {
        let r = try ClaudeUsageResponse.decode(from: claudeUsageFixture("claude_usage_null_windows"))
        #expect(r.fiveHour?.utilization == 42.0)
        #expect(r.sevenDay == nil)
        #expect(r.sevenDayOpus == nil)
        #expect(r.sevenDaySonnet == nil)
        #expect(r.windows().map(\.kind) == [.session5h])
    }

    @Test func emptyObjectYieldsNoWindows() throws {
        let r = try ClaudeUsageResponse.decode(from: Data("{}".utf8))
        #expect(r.windows().isEmpty)
    }

    @Test func windowWithNullResetHasNilResetsAt() throws {
        let json = #"{"five_hour": {"utilization": 5.0, "resets_at": null}}"#
        let r = try ClaudeUsageResponse.decode(from: Data(json.utf8))
        #expect(r.fiveHour?.utilization == 5.0)
        #expect(r.fiveHour?.resetsAt == nil)
        #expect(r.windows().first?.resetsAt == nil)
    }

    // FR-002: неизвестные поля
    @Test func unknownFieldsAreIgnored() throws {
        let r = try ClaudeUsageResponse.decode(
            from: claudeUsageFixture("claude_usage_unknown_fields"))
        #expect(r.fiveHour?.utilization == 42.0)
        #expect(r.sevenDay?.utilization == 18.0)
        #expect(r.windows().map(\.kind) == [.session5h, .weekly])
    }

    // FR-002: битый ввод
    @Test func brokenJsonThrows() throws {
        let data = try claudeUsageFixture("claude_usage_broken")
        #expect(throws: (any Error).self) { try ClaudeUsageResponse.decode(from: data) }
    }

    @Test func emptyDataThrows() {
        #expect(throws: (any Error).self) { try ClaudeUsageResponse.decode(from: Data()) }
    }

    @Test func wrongTypeOfUtilizationThrows() {
        let json = #"{"five_hour": {"utilization": "lots", "resets_at": null}}"#
        #expect(throws: (any Error).self) {
            try ClaudeUsageResponse.decode(from: Data(json.utf8))
        }
    }

    // FR-002 / модель: проценты клампятся в 0...100
    @Test func utilizationAbove100IsClampedInWindows() throws {
        let json = #"{"five_hour": {"utilization": 130.5, "resets_at": null}}"#
        let r = try ClaudeUsageResponse.decode(from: Data(json.utf8))
        #expect(r.windows().first?.usedPercent == 100)
    }

    @Test func negativeUtilizationIsClampedToZero() throws {
        let json = #"{"seven_day": {"utilization": -3.0, "resets_at": null}}"#
        let r = try ClaudeUsageResponse.decode(from: Data(json.utf8))
        #expect(r.windows().first?.usedPercent == 0)
    }
}
