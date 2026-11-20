import Foundation
import Testing

@testable import LimitsCore

@Suite("AntigravityQuotaSummaryResponse")
struct AntigravityQuotaSummaryResponseTests {
    // 2026-11-20T09:00:00Z — до всех resetTime в фикстуре
    let now = Date(timeIntervalSince1970: 1_795_165_200)

    @Test func decodesFixtureIntoAllFiveOrderedWindows() throws {
        let url = try #require(
            Bundle.module.url(
                forResource: "antigravity_quota_summary", withExtension: "json",
                subdirectory: "Fixtures"))
        let data = try Data(contentsOf: url)
        let response = try AntigravityQuotaSummaryResponse.decode(from: data)
        let windows = response.windows(now: now)

        #expect(windows.count == 5)
        let titles = windows.map { ResetFormatter.title(for: $0.kind) }
        #expect(
            titles == [
                "Gemini · 5 ч",
                "Gemini · Неделя",
                "Claude & GPT · 5 ч",
                "Claude & GPT · Неделя",
                "Gemini 4 Argon · Неделя",
            ])

        #expect(abs(windows[0].usedPercent - (1 - 0.9839749) * 100) < 0.0001)
        #expect(abs(windows[1].usedPercent - (1 - 0.9720263) * 100) < 0.0001)
        #expect(windows[2].usedPercent == 0)
        #expect(windows[3].usedPercent == 0)
        #expect(windows[4].usedPercent == 0)
    }

    @Test func handlesOmittedFractionAndExpiredResetAndEmptyBucket() throws {
        let json = """
            {
              "response": {
                "groups": [
                  {
                    "displayName": "Gemini Models",
                    "buckets": [
                      {"window": "5h", "resetTime": "2026-11-20T14:00:00Z"},
                      {"window": "weekly", "remainingFraction": 0.2, "resetTime": "2026-11-20T08:00:00Z"},
                      {"window": "empty"}
                    ]
                  }
                ]
              }
            }
            """
        let response = try AntigravityQuotaSummaryResponse.decode(from: Data(json.utf8))
        let windows = response.windows(now: now)

        #expect(windows.count == 2)
        // 5h: remainingFraction опущен при наличии resetTime → 100% использовано
        #expect(windows[0].usedPercent == 100)
        // weekly: resetTime в прошлом → 0% использовано
        #expect(windows[1].usedPercent == 0)
    }
}
