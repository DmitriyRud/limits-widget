import Foundation
import Testing

@testable import LimitsCore

@Suite("CodexSessionLogParser")
struct CodexSessionLogParserTests {
    private func fixture(_ name: String) throws -> Data {
        let url = try #require(
            Bundle.module.url(forResource: name, withExtension: "jsonl", subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }

    private func line(timestamp: String, rateLimits: String) -> Data {
        Data(
            """
            {"timestamp": "\(timestamp)", "type": "event_msg", "payload": {"type": "token_count", "rate_limits": \(rateLimits)}}
            """.utf8)
    }

    private static let primaryOnly =
        #"{"primary": {"used_percent": 10.0, "window_minutes": 300, "resets_at": 1794000000}, "secondary": null}"#

    // MARK: happy path (FR-004)

    @Test func latestRateLimitsEventWinsOverEarlierOnes() throws {
        let sample = try #require(
            CodexSessionLogParser.latestSample(in: try fixture("codex_session")))
        let primary = try #require(sample.windows.first)
        #expect(primary.usedPercent == 42.5)
        #expect(primary.resetsAt == Date(timeIntervalSince1970: 1_793_990_099))
    }

    @Test func eventWithoutRateLimitsAfterLatestSampleIsIgnored() throws {
        // последнее событие файла (agent_message) не содержит rate_limits
        let sample = try #require(
            CodexSessionLogParser.latestSample(in: try fixture("codex_session")))
        #expect(sample.windows.count == 2)
    }

    @Test func windowsAreOrderedPrimaryThenSecondaryWithKinds() throws {
        let sample = try #require(
            CodexSessionLogParser.latestSample(in: try fixture("codex_session")))
        #expect(sample.windows.map(\.kind) == [.session5h, .weekly])
    }

    @Test func secondaryWindowValuesAreParsed() throws {
        let sample = try #require(
            CodexSessionLogParser.latestSample(in: try fixture("codex_session")))
        let weekly = try #require(sample.windows.last)
        #expect(weekly.usedPercent == 100.0)
        #expect(weekly.resetsAt == Date(timeIntervalSince1970: 1_794_300_000))
    }

    // MARK: fetchedAt (FR-008)

    @Test func fetchedAtIsTimestampOfLatestRateLimitsEvent() throws {
        let sample = try #require(
            CodexSessionLogParser.latestSample(in: try fixture("codex_session")))
        // 2026-11-09T10:20:45.500Z, а не 10:30:00Z последнего события файла
        #expect(sample.fetchedAt == Date(timeIntervalSince1970: 1_794_219_645.5))
    }

    @Test func timestampWithoutFractionalSecondsIsParsed() throws {
        let data = line(timestamp: "2026-11-09T10:15:30Z", rateLimits: Self.primaryOnly)
        let sample = try #require(CodexSessionLogParser.latestSample(in: data))
        #expect(sample.fetchedAt == Date(timeIntervalSince1970: 1_794_219_330))
    }

    @Test func timestampWithFractionalSecondsKeepsFraction() throws {
        let data = line(timestamp: "2026-11-09T10:15:30.123Z", rateLimits: Self.primaryOnly)
        let sample = try #require(CodexSessionLogParser.latestSample(in: data))
        #expect(abs(sample.fetchedAt.timeIntervalSince1970 - 1_794_219_330.123) < 0.001)
    }

    // MARK: null / отсутствующие поля

    @Test func nullSecondaryWindowIsSkipped() throws {
        let sample = try #require(
            CodexSessionLogParser.latestSample(in: try fixture("codex_null_secondary")))
        #expect(sample.windows.count == 1)
        #expect(sample.windows.first?.kind == .session5h)
        #expect(sample.windows.first?.usedPercent == 38.0)
    }

    @Test func missingSecondaryKeyIsSkipped() throws {
        let data = line(
            timestamp: "2026-11-09T10:15:30Z",
            rateLimits:
                #"{"primary": {"used_percent": 10.0, "window_minutes": 300, "resets_at": 1794000000}}"#
        )
        let sample = try #require(CodexSessionLogParser.latestSample(in: data))
        #expect(sample.windows.map(\.kind) == [.session5h])
    }

    @Test func nullPrimaryKeepsSecondary() throws {
        let data = line(
            timestamp: "2026-11-09T10:15:30Z",
            rateLimits:
                #"{"primary": null, "secondary": {"used_percent": 5.0, "window_minutes": 10080, "resets_at": 1794000000}}"#
        )
        let sample = try #require(CodexSessionLogParser.latestSample(in: data))
        #expect(sample.windows.map(\.kind) == [.weekly])
    }

    @Test func noRateLimitsEventsReturnsNil() throws {
        // в фикстуре есть token_count с "rate_limits": null и без поля
        #expect(CodexSessionLogParser.latestSample(in: try fixture("codex_no_rate_limits")) == nil)
    }

    // MARK: неизвестные поля

    @Test func unknownFieldsAreIgnored() throws {
        // codex_session.jsonl содержит лишние поля на всех уровнях
        let sample = try #require(
            CodexSessionLogParser.latestSample(in: try fixture("codex_session")))
        #expect(sample.windows.count == 2)
    }

    // MARK: битый ввод

    @Test func brokenAndEmptyLinesAreSkipped() throws {
        let sample = try #require(
            CodexSessionLogParser.latestSample(in: try fixture("codex_broken_lines")))
        #expect(sample.windows.first?.usedPercent == 38.0)
        #expect(sample.fetchedAt == Date(timeIntervalSince1970: 1_794_219_330.123))
    }

    @Test func truncatedLastLineDoesNotHideEarlierValidSample() throws {
        // в фикстуре после валидного события идёт обрезанная строка с used_percent 77
        let sample = try #require(
            CodexSessionLogParser.latestSample(in: try fixture("codex_broken_lines")))
        #expect(sample.windows.first?.usedPercent != 77.0)
    }

    @Test func emptyDataReturnsNil() {
        #expect(CodexSessionLogParser.latestSample(in: Data()) == nil)
    }

    @Test func garbageDataReturnsNil() {
        #expect(CodexSessionLogParser.latestSample(in: Data([0xFF, 0xFE, 0x00, 0x7B])) == nil)
    }

    @Test func whitespaceOnlyDataReturnsNil() {
        #expect(CodexSessionLogParser.latestSample(in: Data("\n \n\n".utf8)) == nil)
    }
}
