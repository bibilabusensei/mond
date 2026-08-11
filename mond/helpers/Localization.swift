import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case zhHans = "zh-Hans"
    case en
    case zhHant = "zh-Hant"
    case ja

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .system:
            return .autoupdatingCurrent
        case .zhHans:
            return Locale(identifier: "zh-Hans")
        case .en:
            return Locale(identifier: "en")
        case .zhHant:
            return Locale(identifier: "zh-Hant")
        case .ja:
            return Locale(identifier: "ja")
        }
    }

    var displayName: String {
        switch self {
        case .system: return "跟随系统 / System"
        case .zhHans: return "简体中文"
        case .en: return "English"
        case .zhHant: return "繁體中文"
        case .ja: return "日本語"
        }
    }
}

func currentAppLanguage() -> AppLanguage {
    let raw = UserDefaults.standard.string(forKey: "app_language") ?? AppLanguage.system.rawValue
    return AppLanguage(rawValue: raw) ?? .system
}

/// Localizes strings that are passed through APIs taking `String` instead of
/// `LocalizedStringKey` (for example PartyUI labels and Alertinator messages).
func L(_ key: String) -> String {
    let language = currentAppLanguage()

    if language == .system {
        return NSLocalizedString(key, comment: "")
    }

    guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
          let bundle = Bundle(path: path) else {
        return key
    }

    return bundle.localizedString(forKey: key, value: key, table: nil)
}
