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
        let fetched = now.addingTimeInterval(-3_600)  // 07:00 того же дня
        #expect(ResetFormatter.dataAge(fetched, now: now, timeZone: utc) == "данные на 07:00")
    }

    @Test func earlierDayShowsDateAndTime() {
        let fetched = now.addingTimeInterval(-3 * 86_400 - 1_800)  // 12 янв, 07:30
        let text = ResetFormatter.dataAge(fetched, now: now, timeZone: utc)
        #expect(text.hasPrefix("данные на 12 "))
        #expect(text.contains("янв"))
        #expect(text.hasSuffix("07:30"))
    }
}
