import Foundation

/// Type-safe localization catalog for all 11 supported languages (FR-001, FR-002).
/// Exhaustive switches guarantee compile-time coverage for every language.
public enum L10n {
    // MARK: - Window titles

    public static func session5h(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "5 hours"
        case .de: "5 Stunden"
        case .es: "5 horas"
        case .fr: "5 heures"
        case .it: "5 ore"
        case .nb: "5 timer"
        case .is: "5 klst."
        case .fi: "5 tuntia"
        case .zhHans: "5小时"
        case .ja: "5時間"
        case .ru: "5 часов"
        }
    }

    public static func short5h(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "5h"
        case .de: "5 Std."
        case .es: "5 h"
        case .fr: "5 h"
        case .it: "5 h"
        case .nb: "5 t"
        case .is: "5 klst."
        case .fi: "5 t"
        case .zhHans: "5小时"
        case .ja: "5時間"
        case .ru: "5 ч"
        }
    }

    public static func weekly(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Weekly"
        case .de: "Wöchentlich"
        case .es: "Semanal"
        case .fr: "Hebdo"
        case .it: "Settimanale"
        case .nb: "Ukentlig"
        case .is: "Vikulega"
        case .fi: "Viikko"
        case .zhHans: "每周"
        case .ja: "週間"
        case .ru: "Неделя"
        }
    }

    public static func overallLimit(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Overall limit"
        case .de: "Gesamtlimit"
        case .es: "Límite general"
        case .fr: "Limite globale"
        case .it: "Limite generale"
        case .nb: "Samlet grense"
        case .is: "Heildarmörk"
        case .fi: "Kokonaisraja"
        case .zhHans: "总限额"
        case .ja: "全体制限"
        case .ru: "Общий лимит"
        }
    }

    public static func customHours(_ hours: Int, _ lang: AppLanguage) -> String {
        switch lang {
        case .en: "\(hours)h"
        case .de: "\(hours) Std."
        case .es: "\(hours) h"
        case .fr: "\(hours) h"
        case .it: "\(hours) h"
        case .nb: "\(hours) t"
        case .is: "\(hours) klst."
        case .fi: "\(hours) t"
        case .zhHans: "\(hours)小时"
        case .ja: "\(hours)時間"
        case .ru: "\(hours) ч"
        }
    }

    public static func customMinutes(_ minutes: Int, _ lang: AppLanguage) -> String {
        switch lang {
        case .en: "\(minutes)m"
        case .de: "\(minutes) Min."
        case .es: "\(minutes) min"
        case .fr: "\(minutes) min"
        case .it: "\(minutes) min"
        case .nb: "\(minutes) min"
        case .is: "\(minutes) mín."
        case .fi: "\(minutes) min"
        case .zhHans: "\(minutes)分钟"
        case .ja: "\(minutes)分"
        case .ru: "\(minutes) мин"
        }
    }

    // MARK: - Countdown & Remaining

    public static func remainingPercent(_ percent: Int, _ lang: AppLanguage) -> String {
        switch lang {
        case .en: "\(percent)% left"
        case .de: "\(percent)% übrig"
        case .es: "queda \(percent)%"
        case .fr: "\(percent)% restant"
        case .it: "\(percent)% rimasto"
        case .nb: "\(percent)% igjen"
        case .is: "\(percent)% eftir"
        case .fi: "\(percent)% jäljellä"
        case .zhHans: "剩余 \(percent)%"
        case .ja: "残り \(percent)%"
        case .ru: "осталось \(percent)%"
        }
    }

    public static func reset(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "reset"
        case .de: "zurückgesetzt"
        case .es: "restablecido"
        case .fr: "réinitialisé"
        case .it: "ripristinato"
        case .nb: "tilbakestilt"
        case .is: "endurstillt"
        case .fi: "nollattu"
        case .zhHans: "已重置"
        case .ja: "リセット済み"
        case .ru: "сброшено"
        }
    }

    public static func inDaysHours(days: Int, hours: Int, _ lang: AppLanguage) -> String {
        switch lang {
        case .en: hours > 0 ? "in \(days)d \(hours)h" : "in \(days)d"
        case .de: hours > 0 ? "in \(days) T \(hours) Std." : "in \(days) T"
        case .es: hours > 0 ? "en \(days) d \(hours) h" : "en \(days) d"
        case .fr: hours > 0 ? "dans \(days) j \(hours) h" : "dans \(days) j"
        case .it: hours > 0 ? "tra \(days) g \(hours) h" : "tra \(days) g"
        case .nb: hours > 0 ? "om \(days) d \(hours) t" : "om \(days) d"
        case .is: hours > 0 ? "eftir \(days) d \(hours) klst." : "eftir \(days) d"
        case .fi: hours > 0 ? "\(days) pv \(hours) t kuluttua" : "\(days) pv kuluttua"
        case .zhHans: hours > 0 ? "\(days)天\(hours)小时后" : "\(days)天后"
        case .ja: hours > 0 ? "あと\(days)日\(hours)時間" : "あと\(days)日"
        case .ru: hours > 0 ? "через \(days) дн \(hours) ч" : "через \(days) дн"
        }
    }

    public static func inHoursMinutes(hours: Int, minutes: Int, _ lang: AppLanguage) -> String {
        switch lang {
        case .en: minutes > 0 ? "in \(hours)h \(minutes)m" : "in \(hours)h"
        case .de: minutes > 0 ? "in \(hours) Std. \(minutes) Min." : "in \(hours) Std."
        case .es: minutes > 0 ? "en \(hours) h \(minutes) min" : "en \(hours) h"
        case .fr: minutes > 0 ? "dans \(hours) h \(minutes) min" : "dans \(hours) h"
        case .it: minutes > 0 ? "tra \(hours) h \(minutes) min" : "tra \(hours) h"
        case .nb: minutes > 0 ? "om \(hours) t \(minutes) min" : "om \(hours) t"
        case .is: minutes > 0 ? "eftir \(hours) klst. \(minutes) mín." : "eftir \(hours) klst."
        case .fi: minutes > 0 ? "\(hours) t \(minutes) min kuluttua" : "\(hours) t kuluttua"
        case .zhHans: minutes > 0 ? "\(hours)小时\(minutes)分钟后" : "\(hours)小时后"
        case .ja: minutes > 0 ? "あと\(hours)時間\(minutes)分" : "あと\(hours)時間"
        case .ru: minutes > 0 ? "через \(hours) ч \(minutes) мин" : "через \(hours) ч"
        }
    }

    public static func inMinutes(_ minutes: Int, _ lang: AppLanguage) -> String {
        switch lang {
        case .en: "in \(minutes)m"
        case .de: "in \(minutes) Min."
        case .es: "en \(minutes) min"
        case .fr: "dans \(minutes) min"
        case .it: "tra \(minutes) min"
        case .nb: "om \(minutes) min"
        case .is: "eftir \(minutes) mín."
        case .fi: "\(minutes) min kuluttua"
        case .zhHans: "\(minutes)分钟后"
        case .ja: "あと\(minutes)分"
        case .ru: "через \(minutes) мин"
        }
    }

    public static func dataAsOf(_ formatted: String, _ lang: AppLanguage) -> String {
        switch lang {
        case .en: "as of \(formatted)"
        case .de: "Stand \(formatted)"
        case .es: "datos de \(formatted)"
        case .fr: "données à \(formatted)"
        case .it: "dati delle \(formatted)"
        case .nb: "per \(formatted)"
        case .is: "gögn kl. \(formatted)"
        case .fi: "tilanne \(formatted)"
        case .zhHans: "数据截至 \(formatted)"
        case .ja: "\(formatted) 時点"
        case .ru: "данные на \(formatted)"
        }
    }

    // MARK: - Tooltips

    public static func resetTimeUnknown(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Reset time unknown"
        case .de: "Zurücksetzungszeit unbekannt"
        case .es: "Hora de restablecimiento desconocida"
        case .fr: "Heure de réinitialisation inconnue"
        case .it: "Ora di ripristino sconosciuta"
        case .nb: "Tilbakestillingstid ukjent"
        case .is: "Endurstillingartími óþekktur"
        case .fi: "Nollausaika tuntematon"
        case .zhHans: "重置时间未知"
        case .ja: "リセット時刻不明"
        case .ru: "Время сброса неизвестно"
        }
    }

    public static func resetsAt(_ formatted: String, _ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Resets: \(formatted)"
        case .de: "Zurücksetzung: \(formatted)"
        case .es: "Restablecimiento: \(formatted)"
        case .fr: "Réinitialisation : \(formatted)"
        case .it: "Ripristino: \(formatted)"
        case .nb: "Tilbakestilles: \(formatted)"
        case .is: "Endurstillist: \(formatted)"
        case .fi: "Nollaantuu: \(formatted)"
        case .zhHans: "重置时间：\(formatted)"
        case .ja: "リセット：\(formatted)"
        case .ru: "Сброс: \(formatted)"
        }
    }

    // MARK: - Statuses & Errors

    public static func loading(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Loading…"
        case .de: "Wird geladen…"
        case .es: "Cargando…"
        case .fr: "Chargement…"
        case .it: "Caricamento…"
        case .nb: "Laster…"
        case .is: "Hleður…"
        case .fi: "Ladataan…"
        case .zhHans: "加载中…"
        case .ja: "読み込み中…"
        case .ru: "Загрузка…"
        }
    }

    public static func noProvidersHint(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Enable agents in settings"
        case .de: "Agenten in den Einstellungen aktivieren"
        case .es: "Activa los agentes en ajustes"
        case .fr: "Activez des agents dans les réglages"
        case .it: "Attiva gli agenti nelle impostazioni"
        case .nb: "Aktiver agenter i innstillinger"
        case .is: "Virkjaðu þjónustur í stillingum"
        case .fi: "Ota agentit käyttöön asetuksissa"
        case .zhHans: "请在设置中启用代理"
        case .ja: "設定でエージェントを有効にしてください"
        case .ru: "Включите агентов в настройках"
        }
    }

    public static func notAuthenticated(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Not signed in"
        case .de: "Nicht angemeldet"
        case .es: "No autenticado"
        case .fr: "Non connecté"
        case .it: "Non autenticato"
        case .nb: "Ikke pålogget"
        case .is: "Ekki skráð(ur) inn"
        case .fi: "Ei kirjautunut"
        case .zhHans: "未登录"
        case .ja: "未ログイン"
        case .ru: "Не авторизован"
        }
    }

    public static func tokenExpired(displayName: String, _ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Sign in required — open \(displayName)"
        case .de: "Anmeldung erforderlich — \(displayName) öffnen"
        case .es: "Inicia sesión — abre \(displayName)"
        case .fr: "Connexion requise — ouvrez \(displayName)"
        case .it: "Accesso richiesto — apri \(displayName)"
        case .nb: "Pålogging kreves — åpne \(displayName)"
        case .is: "Innskráning krafist — opnaðu \(displayName)"
        case .fi: "Kirjautuminen vaaditaan — avaa \(displayName)"
        case .zhHans: "需要重新登录 — 请打开 \(displayName)"
        case .ja: "再ログインが必要です — \(displayName) を開いてください"
        case .ru: "Требуется вход — откройте \(displayName)"
        }
    }

    public static func noData(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "No data"
        case .de: "Keine Daten"
        case .es: "Sin datos"
        case .fr: "Aucune donnée"
        case .it: "Nessun dato"
        case .nb: "Ingen data"
        case .is: "Engin gögn"
        case .fi: "Ei tietoja"
        case .zhHans: "暂无数据"
        case .ja: "データなし"
        case .ru: "Нет данных"
        }
    }

    public static func staleMark(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "stale"
        case .de: "veraltet"
        case .es: "desactualizado"
        case .fr: "obsolète"
        case .it: "obsoleto"
        case .nb: "utdatert"
        case .is: "úrelt"
        case .fi: "vanhentunut"
        case .zhHans: "数据已过期"
        case .ja: "古いデータ"
        case .ru: "данные устарели"
        }
    }

    public static func networkError(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Network error"
        case .de: "Netzwerkfehler"
        case .es: "Error de red"
        case .fr: "Erreur réseau"
        case .it: "Errore di rete"
        case .nb: "Nettverksfeil"
        case .is: "Netvilla"
        case .fi: "Verkkovirhe"
        case .zhHans: "网络错误"
        case .ja: "ネットワークエラー"
        case .ru: "Ошибка сети"
        }
    }

    public static func formatChanged(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Response format changed"
        case .de: "Antwortformat geändert"
        case .es: "El formato de respuesta cambió"
        case .fr: "Format de réponse modifié"
        case .it: "Formato risposta modificato"
        case .nb: "Svarformatet er endret"
        case .is: "Svarsnið breyttist"
        case .fi: "Vastausmuoto muuttui"
        case .zhHans: "响应格式已变更"
        case .ja: "レスポンス形式が変更されました"
        case .ru: "Формат ответа изменился"
        }
    }

    public static func credentialsUnreadable(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Could not read credentials"
        case .de: "Anmeldedaten nicht lesbar"
        case .es: "No se pudieron leer las credenciales"
        case .fr: "Impossible de lire les identifiants"
        case .it: "Impossibile leggere le credenziali"
        case .nb: "Kunne ikke lese påloggingsdata"
        case .is: "Gat ekki lesið innskráningargögn"
        case .fi: "Tunnistetietoja ei voitu lukea"
        case .zhHans: "无法读取凭据"
        case .ja: "認証情報を読み取れません"
        case .ru: "Не удалось прочитать учётные данные"
        }
    }

    public static func serverError(statusCode: Int, _ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Server error (\(statusCode))"
        case .de: "Serverfehler (\(statusCode))"
        case .es: "Error del servidor (\(statusCode))"
        case .fr: "Erreur serveur (\(statusCode))"
        case .it: "Errore del server (\(statusCode))"
        case .nb: "Serverfeil (\(statusCode))"
        case .is: "Þjónsvilla (\(statusCode))"
        case .fi: "Palvelinvirhe (\(statusCode))"
        case .zhHans: "服务器错误 (\(statusCode))"
        case .ja: "サーバーエラー (\(statusCode))"
        case .ru: "Ошибка сервера (\(statusCode))"
        }
    }

    /// Maps canonical `ProviderStatus` error strings into the active language.
    public static func localizedProviderError(_ raw: String, _ lang: AppLanguage) -> String {
        if raw == ProviderStatus.networkErrorMessage { return networkError(lang) }
        if raw == ProviderStatus.formatChangedMessage { return formatChanged(lang) }
        if raw == ProviderStatus.credentialsUnreadableMessage { return credentialsUnreadable(lang) }
        if raw.hasPrefix("Ошибка сервера ("), raw.hasSuffix(")") {
            let inner = raw.dropFirst("Ошибка сервера (".count).dropLast()
            if let code = Int(inner) { return serverError(statusCode: code, lang) }
        }
        if raw.hasPrefix("Server error ("), raw.hasSuffix(")") {
            let inner = raw.dropFirst("Server error (".count).dropLast()
            if let code = Int(inner) { return serverError(statusCode: code, lang) }
        }
        return raw
    }

    // MARK: - Menu Bar

    public static func refresh(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Refresh"
        case .de: "Aktualisieren"
        case .es: "Actualizar"
        case .fr: "Actualiser"
        case .it: "Aggiorna"
        case .nb: "Oppdater"
        case .is: "Endurhlaða"
        case .fi: "Päivitä"
        case .zhHans: "刷新"
        case .ja: "更新"
        case .ru: "Обновить"
        }
    }

    public static func settingsMenu(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Settings…"
        case .de: "Einstellungen…"
        case .es: "Ajustes…"
        case .fr: "Réglages…"
        case .it: "Impostazioni…"
        case .nb: "Innstillinger…"
        case .is: "Stillingar…"
        case .fi: "Asetukset…"
        case .zhHans: "设置…"
        case .ja: "設定…"
        case .ru: "Настройки…"
        }
    }

    public static func launchAtLogin(available: Bool, _ lang: AppLanguage) -> String {
        if available {
            switch lang {
            case .en: "Launch at login"
            case .de: "Bei Anmeldung starten"
            case .es: "Abrir al iniciar sesión"
            case .fr: "Ouvrir à la connexion"
            case .it: "Avvia al login"
            case .nb: "Start ved innlogging"
            case .is: "Ræsa við innskráningu"
            case .fi: "Käynnistä kirjautuessa"
            case .zhHans: "登录时启动"
            case .ja: "ログイン時に起動"
            case .ru: "Запускать при входе"
            }
        } else {
            switch lang {
            case .en: "Launch at login (.app only)"
            case .de: "Bei Anmeldung starten (nur .app)"
            case .es: "Abrir al iniciar sesión (solo .app)"
            case .fr: "Ouvrir à la connexion (.app uniquement)"
            case .it: "Avvia al login (solo .app)"
            case .nb: "Start ved innlogging (kun .app)"
            case .is: "Ræsa við innskráningu (aðeins .app)"
            case .fi: "Käynnistä kirjautuessa (vain .app)"
            case .zhHans: "登录时启动（仅限 .app）"
            case .ja: "ログイン時に起動（.app のみ）"
            case .ru: "Запускать при входе (только из .app)"
            }
        }
    }

    public static func quit(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Quit"
        case .de: "Beenden"
        case .es: "Salir"
        case .fr: "Quitter"
        case .it: "Esci"
        case .nb: "Avslutt"
        case .is: "Hætta"
        case .fi: "Lopeta"
        case .zhHans: "退出"
        case .ja: "終了"
        case .ru: "Выход"
        }
    }

    // MARK: - Settings Window

    public static func settingsWindowTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Limits Widget Settings"
        case .de: "Limits Widget — Einstellungen"
        case .es: "Ajustes de Limits Widget"
        case .fr: "Réglages de Limits Widget"
        case .it: "Impostazioni Limits Widget"
        case .nb: "Innstillinger for Limits Widget"
        case .is: "Stillingar Limits Widget"
        case .fi: "Limits Widget -asetukset"
        case .zhHans: "Limits Widget 设置"
        case .ja: "Limits Widget 設定"
        case .ru: "Настройки Limits Widget"
        }
    }

    public static func agentsSection(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Agents"
        case .de: "Agenten"
        case .es: "Agentes"
        case .fr: "Agents"
        case .it: "Agenti"
        case .nb: "Agenter"
        case .is: "Þjónustur"
        case .fi: "Agentit"
        case .zhHans: "代理"
        case .ja: "エージェント"
        case .ru: "Агенты"
        }
    }

    public static func languageSection(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Language"
        case .de: "Sprache"
        case .es: "Idioma"
        case .fr: "Langue"
        case .it: "Lingua"
        case .nb: "Språk"
        case .is: "Tungumál"
        case .fi: "Kieli"
        case .zhHans: "语言"
        case .ja: "言語"
        case .ru: "Язык"
        }
    }

    public static func refreshSection(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Refresh"
        case .de: "Aktualisierung"
        case .es: "Actualización"
        case .fr: "Actualisation"
        case .it: "Aggiornamento"
        case .nb: "Oppdatering"
        case .is: "Uppfærsla"
        case .fi: "Päivitys"
        case .zhHans: "刷新"
        case .ja: "更新"
        case .ru: "Обновление"
        }
    }

    public static func intervalSeconds(_ seconds: Int, _ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Interval: \(seconds)s"
        case .de: "Intervall: \(seconds) Sek."
        case .es: "Intervalo: \(seconds) s"
        case .fr: "Intervalle : \(seconds) s"
        case .it: "Intervallo: \(seconds) s"
        case .nb: "Intervall: \(seconds) s"
        case .is: "Millibil: \(seconds) s"
        case .fi: "Väli: \(seconds) s"
        case .zhHans: "间隔：\(seconds) 秒"
        case .ja: "間隔：\(seconds) 秒"
        case .ru: "Интервал: \(seconds) с"
        }
    }

    public static func intervalHint(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "Minimum 60s. Countdown updates every minute without network."
        case .de: "Mindestens 60 Sek. Der Countdown aktualisiert sich jede Minute ohne Netzwerk."
        case .es: "Mínimo 60 s. La cuenta regresiva se actualiza cada minuto sin red."
        case .fr: "Minimum 60 s. Le compte à rebours s'actualise chaque minute sans réseau."
        case .it: "Minimo 60 s. Il conto alla rovescia si aggiorna ogni minuto senza rete."
        case .nb: "Minimum 60 s. Nedtellingen oppdateres hvert minutt uten nettverk."
        case .is: "Lágmark 60 s. Niðurtalning uppfærist á mínútu fresti án nets."
        case .fi: "Vähintään 60 s. Lähtölaskenta päivittyy minuutin välein ilman verkkoa."
        case .zhHans: "最少 60 秒。倒计时每分钟离线更新一次。"
        case .ja: "最小 60 秒。カウントダウンはネットワークなしで毎分更新されます。"
        case .ru: "Минимум 60 с. Обратный отсчёт обновляется раз в минуту без сети."
        }
    }
}
