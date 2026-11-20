import Foundation
import Testing

@testable import LimitsCore

@Suite("Localization (FR-001, FR-002)")
struct LocalizationTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func defaultLanguageIsEnglishAndAllElevenSupported() {
        #expect(AppLanguage.default == .en)
        #expect(AppLanguage.allCases.count == 11)
        let codes = Set(AppLanguage.allCases.map(\.rawValue))
        #expect(codes == ["en", "de", "es", "fr", "it", "nb", "is", "fi", "zh-Hans", "ja", "ru"])
    }

    @Test(arguments: AppLanguage.allCases)
    func everyLanguageProvidesNonEmptyStrings(language: AppLanguage) {
        #expect(!language.nativeName.isEmpty)
        #expect(!L10n.session5h(language).isEmpty)
        #expect(!L10n.short5h(language).isEmpty)
        #expect(!L10n.weekly(language).isEmpty)
        #expect(!L10n.overallLimit(language).isEmpty)
        #expect(!L10n.customHours(2, language).isEmpty)
        #expect(!L10n.customMinutes(30, language).isEmpty)
        #expect(!L10n.remainingPercent(42, language).isEmpty)
        #expect(!L10n.reset(language).isEmpty)
        #expect(!L10n.inDaysHours(days: 2, hours: 3, language).isEmpty)
        #expect(!L10n.inHoursMinutes(hours: 1, minutes: 15, language).isEmpty)
        #expect(!L10n.inMinutes(10, language).isEmpty)
        #expect(!L10n.dataAsOf("10:00", language).isEmpty)
        #expect(!L10n.resetTimeUnknown(language).isEmpty)
        #expect(!L10n.resetsAt("Nov 20", language).isEmpty)
        #expect(!L10n.loading(language).isEmpty)
        #expect(!L10n.noProvidersHint(language).isEmpty)
        #expect(!L10n.notAuthenticated(language).isEmpty)
        #expect(!L10n.tokenExpired(displayName: "Codex", language).isEmpty)
        #expect(!L10n.noData(language).isEmpty)
        #expect(!L10n.staleMark(language).isEmpty)
        #expect(!L10n.networkError(language).isEmpty)
        #expect(!L10n.formatChanged(language).isEmpty)
        #expect(!L10n.credentialsUnreadable(language).isEmpty)
        #expect(!L10n.serverError(statusCode: 500, language).isEmpty)
        #expect(!L10n.refresh(language).isEmpty)
        #expect(!L10n.settingsMenu(language).isEmpty)
        #expect(!L10n.launchAtLogin(available: true, language).isEmpty)
        #expect(!L10n.launchAtLogin(available: false, language).isEmpty)
        #expect(!L10n.quit(language).isEmpty)
        #expect(!L10n.settingsWindowTitle(language).isEmpty)
        #expect(!L10n.agentsSection(language).isEmpty)
        #expect(!L10n.languageSection(language).isEmpty)
        #expect(!L10n.refreshSection(language).isEmpty)
        #expect(!L10n.intervalSeconds(300, language).isEmpty)
        #expect(!L10n.intervalHint(language).isEmpty)
    }

    @Test func groupWindowTitlesSwitchDynamicallyByLanguage() {
        let g5h = WindowKind.group("Gemini", .fiveHour)
        let gWeekly = WindowKind.group("Gemini", .weekly)

        #expect(ResetFormatter.title(for: g5h, language: .en) == "Gemini · 5h")
        #expect(ResetFormatter.title(for: gWeekly, language: .en) == "Gemini · Weekly")
        #expect(ResetFormatter.title(for: g5h, language: .de) == "Gemini · 5 Std.")
        #expect(ResetFormatter.title(for: gWeekly, language: .de) == "Gemini · Wöchentlich")
        #expect(ResetFormatter.title(for: g5h, language: .ja) == "Gemini · 5時間")
        #expect(ResetFormatter.title(for: gWeekly, language: .zhHans) == "Gemini · 每周")
        #expect(ResetFormatter.title(for: g5h, language: .ru) == "Gemini · 5 ч")
        #expect(ResetFormatter.title(for: gWeekly, language: .ru) == "Gemini · Неделя")
    }

    @Test func providerErrorStringsTranslateToSelectedLanguage() {
        #expect(L10n.localizedProviderError(ProviderStatus.networkErrorMessage, .en) == "Network error")
        #expect(L10n.localizedProviderError(ProviderStatus.formatChangedMessage, .de) == "Antwortformat geändert")
        #expect(
            L10n.localizedProviderError(ProviderStatus.httpErrorMessage(statusCode: 503), .en)
                == "Server error (503)")
        #expect(
            L10n.localizedProviderError(ProviderStatus.httpErrorMessage(statusCode: 503), .ja)
                == "サーバーエラー (503)")
    }
}
