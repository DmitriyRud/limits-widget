import Foundation
import Testing

@testable import LimitsCore

private func codexUsageFixture(_ name: String) throws -> Data {
    let url = try #require(
        Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
}

@Suite("CodexUsageResponse")
struct CodexUsageResponseTests {
    let primaryReset = Date(timeIntervalSince1970: 1_794_267_824)
    let secondaryReset = Date(timeIntervalSince1970: 1_794_829_044)

    // FR-004: happy path
    @Test func decodesPlanAndBothWindows() throws {
        let r = try CodexUsageResponse.decode(from: codexUsageFixture("codex_usage"))
        #expect(r.planType == "plus")
        #expect(r.primaryWindow?.usedPercent == 0)
        #expect(r.primaryWindow?.limitWindowSeconds == 18_000)
        #expect(r.primaryWindow?.resetAt == primaryReset)
        #expect(r.secondaryWindow?.usedPercent == 14)
        #expect(r.secondaryWindow?.limitWindowSeconds == 604_800)
        #expect(r.secondaryWindow?.resetAt == secondaryReset)
    }

    @Test func windowsAreOrderedAndMappedToKinds() throws {
        let r = try CodexUsageResponse.decode(from: codexUsageFixture("codex_usage"))
        let w = r.windows()
        #expect(w.map(\.kind) == [.session5h, .weekly])
        #expect(w.map(\.usedPercent) == [0, 14])
        #expect(w.map(\.resetsAt) == [primaryReset, secondaryReset])
    }

    @Test func unusualWindowLengthBecomesCustomKind() throws {
        let json = #"""
            {"rate_limit": {"primary_window":
              {"used_percent": 3, "limit_window_seconds": 3600, "reset_at": 1794267824}}}
            """#
        let r = try CodexUsageResponse.decode(from: Data(json.utf8))
        #expect(r.windows().map(\.kind) == [.custom(minutes: 60)])
    }

    // FR-004: null / отсутствующие поля
    @Test func nullSecondaryWindowIsSkipped() throws {
        let r = try CodexUsageResponse.decode(from: codexUsageFixture("codex_usage_null_windows"))
        #expect(r.planType == "free")
        #expect(r.primaryWindow?.usedPercent == 7)
        #expect(r.secondaryWindow == nil)
        #expect(r.windows().map(\.kind) == [.session5h])
    }

    @Test func missingRateLimitYieldsNoWindows() throws {
        let r = try CodexUsageResponse.decode(from: Data(#"{"plan_type": "plus"}"#.utf8))
        #expect(r.primaryWindow == nil)
        #expect(r.secondaryWindow == nil)
        #expect(r.windows().isEmpty)
    }

    @Test func nullRateLimitYieldsNoWindows() throws {
        let r = try CodexUsageResponse.decode(from: Data(#"{"rate_limit": null}"#.utf8))
        #expect(r.windows().isEmpty)
    }

    @Test func emptyObjectYieldsNoWindowsAndNilPlan() throws {
        let r = try CodexUsageResponse.decode(from: Data("{}".utf8))
        #expect(r.planType == nil)
        #expect(r.windows().isEmpty)
    }

    @Test func windowWithoutLimitWindowSecondsIsSkipped() throws {
        let json = #"""
            {"rate_limit": {
              "primary_window": {"used_percent": 5, "reset_at": 1794267824},
              "secondary_window": {"used_percent": 14, "limit_window_seconds": 604800,
                                   "reset_at": 1794829044}}}
            """#
        let r = try CodexUsageResponse.decode(from: Data(json.utf8))
        #expect(r.primaryWindow?.limitWindowSeconds == nil)
        #expect(r.windows().map(\.kind) == [.weekly])
    }

    @Test func windowWithNullLimitWindowSecondsIsSkipped() throws {
        let json = #"""
            {"rate_limit": {"primary_window":
              {"used_percent": 5, "limit_window_seconds": null, "reset_at": 1794267824}}}
            """#
        let r = try CodexUsageResponse.decode(from: Data(json.utf8))
        #expect(r.windows().isEmpty)
    }

    @Test func nullOrMissingResetAtGivesNilResetsAt() throws {
        let json = #"""
            {"rate_limit": {
              "primary_window": {"used_percent": 5, "limit_window_seconds": 18000,
                                 "reset_at": null},
              "secondary_window": {"used_percent": 6, "limit_window_seconds": 604800}}}
            """#
        let r = try CodexUsageResponse.decode(from: Data(json.utf8))
        #expect(r.primaryWindow?.resetAt == nil)
        #expect(r.secondaryWindow?.resetAt == nil)
        #expect(r.windows().map(\.resetsAt) == [nil, nil])
    }

    // FR-004: числа
    @Test func integerAndFractionalUsedPercentAreAccepted() throws {
        let json = #"""
            {"rate_limit": {
              "primary_window": {"used_percent": 12, "limit_window_seconds": 18000},
              "secondary_window": {"used_percent": 33.5, "limit_window_seconds": 604800}}}
            """#
        let r = try CodexUsageResponse.decode(from: Data(json.utf8))
        #expect(r.windows().map(\.usedPercent) == [12.0, 33.5])
    }

    @Test func usedPercentAbove100IsClampedInWindows() throws {
        let json = #"""
            {"rate_limit": {"primary_window":
              {"used_percent": 130.5, "limit_window_seconds": 18000}}}
            """#
        let r = try CodexUsageResponse.decode(from: Data(json.utf8))
        #expect(r.windows().first?.usedPercent == 100)
    }

    @Test func negativeUsedPercentIsClampedToZero() throws {
        let json = #"""
            {"rate_limit": {"primary_window":
              {"used_percent": -4, "limit_window_seconds": 18000}}}
            """#
        let r = try CodexUsageResponse.decode(from: Data(json.utf8))
        #expect(r.windows().first?.usedPercent == 0)
    }

    // FR-004: неизвестные поля
    @Test func unknownFieldsAreIgnored() throws {
        let r = try CodexUsageResponse.decode(from: codexUsageFixture("codex_usage_unknown_fields"))
        #expect(r.planType == "pro")
        #expect(r.windows().map(\.kind) == [.session5h, .weekly])
        #expect(r.windows().map(\.usedPercent) == [0, 14])
    }

    // FR-004: битый ввод
    @Test func brokenJsonThrows() throws {
        let data = try codexUsageFixture("codex_usage_broken")
        #expect(throws: (any Error).self) { try CodexUsageResponse.decode(from: data) }
    }

    @Test func emptyDataThrows() {
        #expect(throws: (any Error).self) { try CodexUsageResponse.decode(from: Data()) }
    }

    @Test func wrongTypeOfUsedPercentThrows() {
        let json = #"""
            {"rate_limit": {"primary_window":
              {"used_percent": "lots", "limit_window_seconds": 18000}}}
            """#
        #expect(throws: (any Error).self) {
            try CodexUsageResponse.decode(from: Data(json.utf8))
        }
    }
}
