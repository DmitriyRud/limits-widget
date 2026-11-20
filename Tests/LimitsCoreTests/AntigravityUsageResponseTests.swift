import Foundation
import Testing

@testable import LimitsCore

@Suite("AntigravityUsageResponse")
struct AntigravityUsageResponseTests {
    // 2026-11-19T22:00:00Z — до всех resetTime в фикстуре
    let now = Date(timeIntervalSince1970: 1_795_125_600)

    @Test func decodesFixtureAndPicksMinimumRemaining() throws {
        let url = try #require(
            Bundle.module.url(
                forResource: "antigravity_user_status", withExtension: "json",
                subdirectory: "Fixtures"))
        let data = try Data(contentsOf: url)
        let response = try AntigravityUsageResponse.decode(from: data)
        let windows = response.windows(now: now)

        #expect(windows.count == 1)
        let overall = try #require(windows.first)
        #expect(overall.kind == .overall)
        // remainingFraction = 0.9645665 → usedPercent ≈ 3.54335, remaining ≈ 96.45665
        #expect(abs(overall.usedPercent - (1 - 0.9645665) * 100) < 0.0001)
        #expect(overall.resetsAt != nil)
    }

    @Test func skipsEmptyQuotaInfoObject() throws {
        let json = """
            {
              "userStatus": {
                "cascadeModelConfigData": {
                  "clientModelConfigs": [
                    {"label": "Carbon", "quotaInfo": {}},
                    {"label": "Neon", "quotaInfo": {"remainingFraction": 0.7, "resetTime": "2026-11-20T02:00:00Z"}}
                  ]
                }
              }
            }
            """
        let response = try AntigravityUsageResponse.decode(from: Data(json.utf8))
        let windows = response.windows(now: now)

        #expect(windows.count == 1)
        #expect(abs(windows[0].usedPercent - 30.0) < 0.001)
    }

    @Test func treatsOmittedRemainingFractionWithResetTimeAsExhausted() throws {
        let json = """
            {
              "userStatus": {
                "cascadeModelConfigData": {
                  "clientModelConfigs": [
                    {"label": "Neon", "quotaInfo": {"resetTime": "2026-11-20T02:00:00Z"}},
                    {"label": "Argon", "quotaInfo": {"remainingFraction": 0.8, "resetTime": "2026-11-26T02:00:00Z"}}
                  ]
                }
              }
            }
            """
        let response = try AntigravityUsageResponse.decode(from: Data(json.utf8))
        let windows = response.windows(now: now)

        #expect(windows.count == 1)
        #expect(windows[0].usedPercent == 100.0)
        #expect(windows[0].resetsAt != nil)
    }

    @Test func treatsExpiredResetTimeAsFullyRestored() throws {
        // resetTime в прошлом (2026-11-19T20:00:00Z < now 22:00:00Z)
        let json = """
            {
              "userStatus": {
                "cascadeModelConfigData": {
                  "clientModelConfigs": [
                    {"label": "ExhaustedOld", "quotaInfo": {"remainingFraction": 0.0, "resetTime": "2026-11-19T20:00:00Z"}},
                    {"label": "Active", "quotaInfo": {"remainingFraction": 0.6, "resetTime": "2026-11-20T02:00:00Z"}}
                  ]
                }
              }
            }
            """
        let response = try AntigravityUsageResponse.decode(from: Data(json.utf8))
        let windows = response.windows(now: now)

        #expect(windows.count == 1)
        #expect(abs(windows[0].usedPercent - 40.0) < 0.001)
    }

    @Test func breaksTieByEarliestFutureResetTime() throws {
        let json = """
            {
              "userStatus": {
                "cascadeModelConfigData": {
                  "clientModelConfigs": [
                    {"label": "Later", "quotaInfo": {"remainingFraction": 0.5, "resetTime": "2026-11-26T02:00:00Z"}},
                    {"label": "Sooner", "quotaInfo": {"remainingFraction": 0.5, "resetTime": "2026-11-20T02:00:00Z"}}
                  ]
                }
              }
            }
            """
        let response = try AntigravityUsageResponse.decode(from: Data(json.utf8))
        let windows = response.windows(now: now)

        let expected = ISO8601DateFormatter().date(from: "2026-11-20T02:00:00Z")
        #expect(windows.first?.resetsAt == expected)
    }

    @Test func emptyOrUnquotedModelsProduceNoWindows() throws {
        let json = """
            {
              "userStatus": {
                "cascadeModelConfigData": {
                  "clientModelConfigs": [
                    {"label": "Carbon", "quotaInfo": {}}
                  ]
                }
              }
            }
            """
        let response = try AntigravityUsageResponse.decode(from: Data(json.utf8))
        #expect(response.windows(now: now).isEmpty)
    }

    @Test func rejectsMalformedJSON() {
        #expect(throws: (any Error).self) {
            _ = try AntigravityUsageResponse.decode(from: Data("{broken".utf8))
        }
    }
}
