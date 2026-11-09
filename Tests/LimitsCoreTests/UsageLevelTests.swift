import Foundation
import Testing

@testable import LimitsCore

@Suite("UsageLevel")
struct UsageLevelTests {
    static let now = Date(timeIntervalSince1970: 1_800_000_000)

    // FR-007: <70 normal; 70..<90 warning; >=90 critical.
    static let cases: [(Double, UsageLevel)] = [
        (0, .normal),
        (69.9, .normal),
        (70, .warning),
        (89.99, .warning),
        (90, .critical),
        (100, .critical),
        (-5, .normal),
        (150, .critical),
    ]

    @Test("пороги 70/90", arguments: UsageLevelTests.cases)
    func levelMatchesThresholds(percent: Double, expected: UsageLevel) {
        #expect(UsageLevel(percent: percent) == expected)
    }

    @Test func windowWithFutureResetUsesRawPercent() {
        let w = UsageWindow(
            kind: .session5h, usedPercent: 95,
            resetsAt: Self.now.addingTimeInterval(3600))
        #expect(w.level(now: Self.now) == .critical)
    }

    // FR-012: сброшенное окно -> normal.
    @Test func windowWithPastResetIsNormal() {
        let w = UsageWindow(
            kind: .session5h, usedPercent: 95,
            resetsAt: Self.now.addingTimeInterval(-60))
        #expect(w.level(now: Self.now) == .normal)
    }

    @Test func windowResettingExactlyNowIsNormal() {
        let w = UsageWindow(kind: .weekly, usedPercent: 95, resetsAt: Self.now)
        #expect(w.level(now: Self.now) == .normal)
    }

    @Test func windowWithoutResetUsesRawPercent() {
        let w = UsageWindow(kind: .weekly, usedPercent: 75, resetsAt: nil)
        #expect(w.level(now: Self.now) == .warning)
    }
}
