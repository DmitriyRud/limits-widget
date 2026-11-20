import Foundation
import Testing

@testable import LimitsCore

@Suite("ResetFormatter")
struct ResetFormatterTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func nilDateShowsDash() {
        #expect(ResetFormatter.relative(until: nil, now: now) == "—")
    }

    @Test func pastDateIsReset() {
        #expect(ResetFormatter.relative(until: now.addingTimeInterval(-1), now: now) == "reset")
        #expect(
            ResetFormatter.relative(until: now.addingTimeInterval(-1), now: now, language: .ru)
                == "сброшено")
    }

    static let englishCases: [(TimeInterval, String)] = [
        (59, "in 1m"),
        (2_700, "in 45m"),
        (8_040, "in 2h 14m"),
        (10_800, "in 3h"),
        (273_600, "in 3d 4h"),
    ]

    @Test(arguments: englishCases)
    func relativeEnglishDefault(offset: TimeInterval, expected: String) {
        #expect(ResetFormatter.relative(until: now.addingTimeInterval(offset), now: now) == expected)
    }

    static let russianCases: [(TimeInterval, String)] = [
        (59, "через 1 мин"),
        (2_700, "через 45 мин"),
        (8_040, "через 2 ч 14 мин"),
        (10_800, "через 3 ч"),
        (273_600, "через 3 дн 4 ч"),
    ]

    @Test(arguments: russianCases)
    func relativeRussian(offset: TimeInterval, expected: String) {
        #expect(
            ResetFormatter.relative(until: now.addingTimeInterval(offset), now: now, language: .ru)
                == expected)
    }

    @Test func windowKindFromMinutes() {
        #expect(WindowKind(windowMinutes: 300) == .session5h)
        #expect(WindowKind(windowMinutes: 10_080) == .weekly)
        #expect(WindowKind(windowMinutes: 60) == .custom(minutes: 60))
    }

    @Test func expiredWindowHasZeroEffectivePercent() {
        let window = UsageWindow(kind: .session5h, usedPercent: 80, resetsAt: now.addingTimeInterval(-5))
        #expect(window.effectivePercent(now: now) == 0)
    }

    @Test func percentIsClamped() {
        #expect(UsageWindow(kind: .weekly, usedPercent: 140, resetsAt: nil).usedPercent == 100)
    }

    @Test func overallAndNamedWindowTitles() {
        #expect(ResetFormatter.title(for: .overall) == "Overall limit")
        #expect(ResetFormatter.title(for: .overall, language: .ru) == "Общий лимит")
        #expect(ResetFormatter.title(for: .named("Custom")) == "Custom")
    }
}
