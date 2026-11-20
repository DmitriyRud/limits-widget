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
        #expect(ResetFormatter.relative(until: now.addingTimeInterval(-1), now: now) == "сброшено")
    }

    static let cases: [(TimeInterval, String)] = [
        (59, "через 1 мин"),
        (2_700, "через 45 мин"),
        (8_040, "через 2 ч 14 мин"),
        (10_800, "через 3 ч"),
        (273_600, "через 3 дн 4 ч"),
    ]

    @Test(arguments: cases)
    func relative(offset: TimeInterval, expected: String) {
        #expect(ResetFormatter.relative(until: now.addingTimeInterval(offset), now: now) == expected)
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

    @Test func overallWindowTitle() {
        #expect(ResetFormatter.title(for: .overall) == "Общий лимит")
        #expect(ResetFormatter.title(for: .named("Gemini · 5 ч")) == "Gemini · 5 ч")
    }
}
