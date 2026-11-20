import Foundation

/// Supported UI languages (FR-001, FR-003). English is the default.
public enum AppLanguage: String, CaseIterable, Sendable, Hashable, Identifiable {
    case en
    case de
    case es
    case fr
    case it
    case nb
    case `is`
    case fi
    case zhHans = "zh-Hans"
    case ja
    case ru

    public static let `default`: AppLanguage = .en

    public var id: String { rawValue }

    /// Native display name shown in the Settings language picker.
    public var nativeName: String {
        switch self {
        case .en: "English"
        case .de: "Deutsch"
        case .es: "Español"
        case .fr: "Français"
        case .it: "Italiano"
        case .nb: "Norsk"
        case .is: "Íslenska"
        case .fi: "Suomi"
        case .zhHans: "中文"
        case .ja: "日本語"
        case .ru: "Русский"
        }
    }

    public var locale: Locale {
        switch self {
        case .en: Locale(identifier: "en_US")
        case .de: Locale(identifier: "de_DE")
        case .es: Locale(identifier: "es_ES")
        case .fr: Locale(identifier: "fr_FR")
        case .it: Locale(identifier: "it_IT")
        case .nb: Locale(identifier: "nb_NO")
        case .is: Locale(identifier: "is_IS")
        case .fi: Locale(identifier: "fi_FI")
        case .zhHans: Locale(identifier: "zh_Hans")
        case .ja: Locale(identifier: "ja_JP")
        case .ru: Locale(identifier: "ru_RU")
        }
    }
}
