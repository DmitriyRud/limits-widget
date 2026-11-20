import Foundation
import Testing

@testable import LimitsCore

@Suite("Remaining percent (FR-005)")
struct RemainingPercentTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func remainingIsHundredMinusUsed() {
        let window = UsageWindow(kind: .session5h, usedPercent: 38, resetsAt: now.addingTimeInterval(600))
        #expect(window.remainingPercent(now: now) == 62)
    }

    @Test func resetWindowHasFullRemaining() {
        let window = UsageWindow(kind: .weekly, usedPercent: 100, resetsAt: now.addingTimeInterval(-1))
        #expect(window.remainingPercent(now: now) == 100)
    }

    @Test func exhaustedWindowHasZeroRemaining() {
        let window = UsageWindow(kind: .weekly, usedPercent: 140, resetsAt: nil)
        #expect(window.remainingPercent(now: now) == 0)
    }
}

@Suite("Data age (FR-008)")
struct DataAgeTests {
    let utc = TimeZone(identifier: "UTC") ?? .gmt
    // 2027-01-15T08:00:00Z
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func todayShowsOnlyTime() {
        let fetched = now.addingTimeInterval(-3_600)  // 07:00 same day
        #expect(ResetFormatter.dataAge(fetched, now: now, timeZone: utc) == "as of 07:00")
        #expect(
            ResetFormatter.dataAge(fetched, now: now, timeZone: utc, language: .ru)
                == "данные на 07:00")
    }

    @Test func earlierDayShowsDateAndTime() {
        let fetched = now.addingTimeInterval(-3 * 86_400 - 1_800)  // 12 Jan, 07:30
        let enText = ResetFormatter.dataAge(fetched, now: now, timeZone: utc)
        #expect(enText.hasPrefix("as of 12 "))
        #expect(enText.contains("Jan"))
        #expect(enText.hasSuffix("07:30"))

        let ruText = ResetFormatter.dataAge(fetched, now: now, timeZone: utc, language: .ru)
        #expect(ruText.hasPrefix("данные на 12 "))
        #expect(ruText.contains("янв"))
        #expect(ruText.hasSuffix("07:30"))
    }
}
