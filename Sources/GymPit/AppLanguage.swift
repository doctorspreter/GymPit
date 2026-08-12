import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case german
    case english
    case french
    case spanish
    case italian
    case russian
    case chinese
    case japanese

    static let storageKey = "gympit_app_language"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .german: "Deutsch"
        case .english: "English"
        case .french: "Français"
        case .spanish: "Español"
        case .italian: "Italiano"
        case .russian: "Русский"
        case .chinese: "中文"
        case .japanese: "日本語"
        }
    }

    var localeIdentifier: String {
        switch effectiveLanguage {
        case .system: Locale.current.identifier
        case .german: "de_DE"
        case .english: "en_US"
        case .french: "fr_FR"
        case .spanish: "es_ES"
        case .italian: "it_IT"
        case .russian: "ru_RU"
        case .chinese: "zh_Hans"
        case .japanese: "ja_JP"
        }
    }

    var effectiveLanguage: AppLanguage {
        guard self == .system else { return self }

        let preferredCode = Locale.preferredLanguages.first?
            .split(separator: "-")
            .first
            .map(String.init)

        switch preferredCode {
        case "en": return .english
        case "fr": return .french
        case "es": return .spanish
        case "it": return .italian
        case "ru": return .russian
        case "zh": return .chinese
        case "ja": return .japanese
        default: return .german
        }
    }

    static func value(for rawValue: String) -> AppLanguage {
        AppLanguage(rawValue: rawValue) ?? .system
    }

    static var current: AppLanguage {
        let appGroupValue = UserDefaults(suiteName: "group.app.gympit")?.string(forKey: storageKey)
        return value(for: appGroupValue ?? UserDefaults.standard.string(forKey: storageKey) ?? AppLanguage.system.rawValue)
    }

    func ui(_ german: String) -> String {
        guard effectiveLanguage != .german else { return german }
        return Self.statusTexts[german]?[effectiveLanguage]
            ?? Self.uiTextCorrections[german]?[effectiveLanguage]
            ?? Self.uiTexts[german]?[effectiveLanguage]
            ?? Self.additionalUITexts[german]?[effectiveLanguage]
            ?? german
    }

    /// Like `ui`, but for format strings. Every translation keeps the same
    /// placeholders in the same order as the German source text.
    func ui(format german: String, _ arguments: CVarArg...) -> String {
        String(format: ui(german), arguments: arguments)
    }

    // Store status messages are created outside the view. They used to be
    // hard-coded in German. Every language keeps placeholders in the same
    // order as the German source text.
    private static let statusTexts: [String: [AppLanguage: String]] = [
        "Home Assistant hat den Token abgelehnt. Bitte einen neuen Long-Lived Access Token eintragen.": [.english: "Home Assistant rejected the token. Please enter a new long-lived access token.", .french: "Home Assistant a refusé le jeton. Saisis un nouveau jeton d’accès longue durée.", .spanish: "Home Assistant rechazó el token. Introduce un nuevo token de acceso de larga duración.", .italian: "Home Assistant ha rifiutato il token. Inserisci un nuovo token di accesso a lunga durata.", .russian: "Home Assistant отклонил токен. Введите новый долгоживущий токен доступа.", .chinese: "Home Assistant 拒绝了该令牌。请输入新的长期访问令牌。", .japanese: "Home Assistantがトークンを拒否しました。新しい長期アクセストークンを入力してください。"],
        "Home Assistant antwortet, aber die HealthPit-Integration ist dort nicht eingerichtet.": [.english: "Home Assistant responds, but the HealthPit integration is not set up there.", .french: "Home Assistant répond, mais l’intégration HealthPit n’y est pas installée.", .spanish: "Home Assistant responde, pero la integración HealthPit no está configurada allí.", .italian: "Home Assistant risponde, ma l’integrazione HealthPit non è configurata.", .russian: "Home Assistant отвечает, но интеграция HealthPit там не настроена.", .chinese: "Home Assistant 有响应，但那里没有配置 HealthPit 集成。", .japanese: "Home Assistantは応答していますが、HealthPit統合が設定されていません。"],
        "GymPit ist nicht verbunden. Bitte zuerst den Home-Assistant-Token eintragen.": [.english: "GymPit is not connected. Please enter the Home Assistant token first.", .french: "GymPit n’est pas connecté. Saisis d’abord le jeton Home Assistant.", .spanish: "GymPit no está conectado. Introduce primero el token de Home Assistant.", .italian: "GymPit non è connesso. Inserisci prima il token di Home Assistant.", .russian: "GymPit не подключён. Сначала введите токен Home Assistant.", .chinese: "GymPit 未连接。请先输入 Home Assistant 令牌。", .japanese: "GymPitは未接続です。先にHome Assistantのトークンを入力してください。"],
        "Bitte die externe HealthPit-Adresse mit https:// eintragen.": [.english: "Please enter the external address with https://.", .french: "Saisis l’adresse externe avec https://.", .spanish: "Introduce la dirección externa con https://.", .italian: "Inserisci l’indirizzo esterno con https://.", .russian: "Укажите внешний адрес с https://.", .chinese: "请使用 https:// 填写外部地址。", .japanese: "外部アドレスは https:// で入力してください。"],
        "HealthPit hat abgelehnt (%d): %@": [.english: "HealthPit rejected the request (%d): %@", .french: "HealthPit a refusé la requête (%d) : %@", .spanish: "HealthPit rechazó la solicitud (%d): %@", .italian: "HealthPit ha rifiutato la richiesta (%d): %@", .russian: "HealthPit отклонил запрос (%d): %@", .chinese: "HealthPit 拒绝了请求 (%d)：%@", .japanese: "HealthPitがリクエストを拒否しました (%d): %@"],
        "HealthPit-Adresse fehlt.": [.english: "HealthPit address is missing.", .french: "L’adresse HealthPit est manquante.", .spanish: "Falta la dirección de HealthPit.", .italian: "Manca l’indirizzo HealthPit.", .russian: "Не указан адрес HealthPit.", .chinese: "缺少 HealthPit 地址。", .japanese: "HealthPitのアドレスがありません。"],
        "HealthPit-Token fehlt.": [.english: "HealthPit token is missing.", .french: "Le jeton HealthPit est manquant.", .spanish: "Falta el token de HealthPit.", .italian: "Manca il token HealthPit.", .russian: "Не указан токен HealthPit.", .chinese: "缺少 HealthPit 令牌。", .japanese: "HealthPitのトークンがありません。"],
        "HealthPit-Adresse ist ungültig.": [.english: "HealthPit address is invalid.", .french: "L’adresse HealthPit n’est pas valide.", .spanish: "La dirección de HealthPit no es válida.", .italian: "L’indirizzo HealthPit non è valido.", .russian: "Адрес HealthPit недействителен.", .chinese: "HealthPit 地址无效。", .japanese: "HealthPitのアドレスが無効です。"],
        "HealthPit hat die Übertragung abgelehnt (%d).": [.english: "HealthPit rejected the transfer (%d).", .french: "HealthPit a refusé le transfert (%d).", .spanish: "HealthPit rechazó la transferencia (%d).", .italian: "HealthPit ha rifiutato il trasferimento (%d).", .russian: "HealthPit отклонил передачу (%d).", .chinese: "HealthPit 拒绝了传输 (%d)。", .japanese: "HealthPitが転送を拒否しました (%d)。"],
        "Noch nicht übertragen": [.english: "Not transferred yet", .french: "Pas encore transféré", .spanish: "Aún no transferido", .italian: "Non ancora trasferito", .russian: "Ещё не передано", .chinese: "尚未传输", .japanese: "未転送"],
        "Apple Health wird verbunden...": [.english: "Connecting Apple Health...", .french: "Connexion à Apple Santé...", .spanish: "Conectando Apple Salud...", .italian: "Connessione ad Apple Salute...", .russian: "Подключение Apple Health...", .chinese: "正在连接 Apple 健康...", .japanese: "Appleヘルスケアに接続中..."],
        "Apple Health verbunden": [.english: "Apple Health connected", .french: "Apple Santé connecté", .spanish: "Apple Salud conectado", .italian: "Apple Salute connesso", .russian: "Apple Health подключён", .chinese: "Apple 健康已连接", .japanese: "Appleヘルスケアに接続済み"],
        "Apple Health nicht verbunden": [.english: "Apple Health not connected", .french: "Apple Santé non connecté", .spanish: "Apple Salud no conectado", .italian: "Apple Salute non connesso", .russian: "Apple Health не подключён", .chinese: "Apple 健康未连接", .japanese: "Appleヘルスケア未接続"],
        "Apple Health Fehler: %@": [.english: "Apple Health error: %@", .french: "Erreur Apple Santé : %@", .spanish: "Error de Apple Salud: %@", .italian: "Errore Apple Salute: %@", .russian: "Ошибка Apple Health: %@", .chinese: "Apple 健康错误：%@", .japanese: "Appleヘルスケアのエラー: %@"],
        "Kein abgeschlossenes Training vorhanden": [.english: "No completed workout available", .french: "Aucune séance terminée", .spanish: "No hay entrenamientos completados", .italian: "Nessun allenamento completato", .russian: "Нет завершённых тренировок", .chinese: "没有已完成的训练", .japanese: "完了したワークアウトがありません"],
        "Apple-Health-Übertragung läuft bereits": [.english: "Apple Health transfer already running", .french: "Le transfert vers Apple Santé est déjà en cours", .spanish: "La transferencia a Apple Salud ya está en curso", .italian: "Trasferimento ad Apple Salute già in corso", .russian: "Передача в Apple Health уже выполняется", .chinese: "Apple 健康传输已在进行", .japanese: "Appleヘルスケアへの転送は実行中です"],
        "Keine alten Workouts vorhanden": [.english: "No older workouts available", .french: "Aucune ancienne séance", .spanish: "No hay entrenamientos antiguos", .italian: "Nessun allenamento precedente", .russian: "Нет прежних тренировок", .chinese: "没有旧的训练", .japanese: "過去のワークアウトがありません"],
        "Alle Workouts sind bereits in Apple Health (%d)": [.english: "All workouts are already in Apple Health (%d)", .french: "Toutes les séances sont déjà dans Apple Santé (%d)", .spanish: "Todos los entrenamientos ya están en Apple Salud (%d)", .italian: "Tutti gli allenamenti sono già in Apple Salute (%d)", .russian: "Все тренировки уже в Apple Health (%d)", .chinese: "所有训练已存在于 Apple 健康 (%d)", .japanese: "すべてのワークアウトはAppleヘルスケアにあります (%d)"],
        "Apple Health: 0/%d wird übertragen...": [.english: "Apple Health: transferring 0/%d...", .french: "Apple Santé : transfert 0/%d...", .spanish: "Apple Salud: transfiriendo 0/%d...", .italian: "Apple Salute: trasferimento 0/%d...", .russian: "Apple Health: передача 0/%d...", .chinese: "Apple 健康：正在传输 0/%d...", .japanese: "Appleヘルスケア: 0/%d を転送中..."],
        "Apple Health Export läuft...": [.english: "Apple Health export running...", .french: "Export vers Apple Santé en cours...", .spanish: "Exportación a Apple Salud en curso...", .italian: "Esportazione ad Apple Salute in corso...", .russian: "Экспорт в Apple Health выполняется...", .chinese: "正在导出到 Apple 健康...", .japanese: "Appleヘルスケアへ書き出し中..."],
        "Übertragen: %@, %d min, %d kcal": [.english: "Transferred: %@, %d min, %d kcal", .french: "Transféré : %@, %d min, %d kcal", .spanish: "Transferido: %@, %d min, %d kcal", .italian: "Trasferito: %@, %d min, %d kcal", .russian: "Передано: %@, %d мин, %d ккал", .chinese: "已传输：%@，%d 分钟，%d 千卡", .japanese: "転送済み: %@、%d分、%d kcal"],
        "Bereits in Apple Health: %@": [.english: "Already in Apple Health: %@", .french: "Déjà dans Apple Santé : %@", .spanish: "Ya está en Apple Salud: %@", .italian: "Già in Apple Salute: %@", .russian: "Уже в Apple Health: %@", .chinese: "已存在于 Apple 健康：%@", .japanese: "Appleヘルスケアに既存: %@"],
        "Fertig: %d übertragen, %d bereits vorhanden, %d Fehler": [.english: "Done: %d transferred, %d already there, %d errors", .french: "Terminé : %d transférés, %d déjà présents, %d erreurs", .spanish: "Listo: %d transferidos, %d ya existentes, %d errores", .italian: "Fatto: %d trasferiti, %d già presenti, %d errori", .russian: "Готово: передано %d, уже было %d, ошибок %d", .chinese: "完成：已传输 %d，已存在 %d，错误 %d", .japanese: "完了: %d件転送、%d件は既存、%d件エラー"],
        "Keine Duplikate angelegt: %d Workouts bereits vorhanden": [.english: "No duplicates created: %d workouts already there", .french: "Aucun doublon créé : %d séances déjà présentes", .spanish: "No se crearon duplicados: %d entrenamientos ya existentes", .italian: "Nessun duplicato creato: %d allenamenti già presenti", .russian: "Дубликаты не созданы: %d тренировок уже есть", .chinese: "未创建重复项：%d 项训练已存在", .japanese: "重複は作成なし: %d件は既存"],
        "Fertig: %d übertragen, %d bereits vorhanden": [.english: "Done: %d transferred, %d already there", .french: "Terminé : %d transférés, %d déjà présents", .spanish: "Listo: %d transferidos, %d ya existentes", .italian: "Fatto: %d trasferiti, %d già presenti", .russian: "Готово: передано %d, уже было %d", .chinese: "完成：已传输 %d，已存在 %d", .japanese: "完了: %d件転送、%d件は既存"],
        "Apple Health: %d/%d · %d übertragen": [.english: "Apple Health: %d/%d · %d transferred", .french: "Apple Santé : %d/%d · %d transférés", .spanish: "Apple Salud: %d/%d · %d transferidos", .italian: "Apple Salute: %d/%d · %d trasferiti", .russian: "Apple Health: %d/%d · передано %d", .chinese: "Apple 健康：%d/%d · 已传输 %d", .japanese: "Appleヘルスケア: %d/%d · %d件転送"],
        "Apple Health: %d/%d · bereits vorhanden": [.english: "Apple Health: %d/%d · already there", .french: "Apple Santé : %d/%d · déjà présent", .spanish: "Apple Salud: %d/%d · ya existente", .italian: "Apple Salute: %d/%d · già presente", .russian: "Apple Health: %d/%d · уже есть", .chinese: "Apple 健康：%d/%d · 已存在", .japanese: "Appleヘルスケア: %d/%d · 既存"],
        "Apple Health: %d/%d · Fehler": [.english: "Apple Health: %d/%d · error", .french: "Apple Santé : %d/%d · erreur", .spanish: "Apple Salud: %d/%d · error", .italian: "Apple Salute: %d/%d · errore", .russian: "Apple Health: %d/%d · ошибка", .chinese: "Apple 健康：%d/%d · 错误", .japanese: "Appleヘルスケア: %d/%d · エラー"],
        "Apple Health Löschen läuft...": [.english: "Deleting from Apple Health...", .french: "Suppression dans Apple Santé...", .spanish: "Eliminando de Apple Salud...", .italian: "Eliminazione da Apple Salute...", .russian: "Удаление из Apple Health...", .chinese: "正在从 Apple 健康删除...", .japanese: "Appleヘルスケアから削除中..."],
        "Aus Apple Health gelöscht (%d)": [.english: "Deleted from Apple Health (%d)", .french: "Supprimé d’Apple Santé (%d)", .spanish: "Eliminado de Apple Salud (%d)", .italian: "Eliminato da Apple Salute (%d)", .russian: "Удалено из Apple Health (%d)", .chinese: "已从 Apple 健康删除 (%d)", .japanese: "Appleヘルスケアから削除 (%d)"],
        "Aus Apple Health gelöscht: %d, Fehler: %d": [.english: "Deleted from Apple Health: %d, errors: %d", .french: "Supprimé d’Apple Santé : %d, erreurs : %d", .spanish: "Eliminado de Apple Salud: %d, errores: %d", .italian: "Eliminato da Apple Salute: %d, errori: %d", .russian: "Удалено из Apple Health: %d, ошибок: %d", .chinese: "已从 Apple 健康删除：%d，错误：%d", .japanese: "Appleヘルスケアから削除: %d件、エラー: %d件"],
        "HealthPit nicht übertragen": [.english: "Nothing sent to HealthPit yet", .french: "Rien envoyé à HealthPit", .spanish: "Nada enviado a HealthPit", .italian: "Nulla inviato a HealthPit", .russian: "В HealthPit ничего не отправлено", .chinese: "尚未发送到 HealthPit", .japanese: "HealthPitへ未送信"],
        "Keine Trainings vorhanden": [.english: "No workouts available", .french: "Aucune séance", .spanish: "No hay entrenamientos", .italian: "Nessun allenamento", .russian: "Нет тренировок", .chinese: "没有训练", .japanese: "ワークアウトがありません"],
        "HealthPit überträgt Trainings (%d)...": [.english: "HealthPit is sending workouts (%d)...", .french: "HealthPit envoie les séances (%d)...", .spanish: "HealthPit está enviando entrenamientos (%d)...", .italian: "HealthPit sta inviando allenamenti (%d)...", .russian: "HealthPit отправляет тренировки (%d)...", .chinese: "HealthPit 正在发送训练 (%d)...", .japanese: "HealthPitがワークアウトを送信中 (%d)..."],
        "HealthPit: keine neuen Trainings": [.english: "HealthPit: no new workouts", .french: "HealthPit : aucune nouvelle séance", .spanish: "HealthPit: sin entrenamientos nuevos", .italian: "HealthPit: nessun nuovo allenamento", .russian: "HealthPit: новых тренировок нет", .chinese: "HealthPit：没有新的训练", .japanese: "HealthPit: 新しいワークアウトなし"],
        "HealthPit: schon übertragen": [.english: "HealthPit: already sent", .french: "HealthPit : déjà envoyé", .spanish: "HealthPit: ya enviado", .italian: "HealthPit: già inviato", .russian: "HealthPit: уже отправлено", .chinese: "HealthPit：已发送", .japanese: "HealthPit: 送信済み"],
        "HealthPit Export läuft...": [.english: "HealthPit export running...", .french: "Export HealthPit en cours...", .spanish: "Exportación a HealthPit en curso...", .italian: "Esportazione HealthPit in corso...", .russian: "Экспорт в HealthPit выполняется...", .chinese: "正在导出到 HealthPit...", .japanese: "HealthPitへ書き出し中..."],
        "HealthPit Fehler: %@": [.english: "HealthPit error: %@", .french: "Erreur HealthPit : %@", .spanish: "Error de HealthPit: %@", .italian: "Errore HealthPit: %@", .russian: "Ошибка HealthPit: %@", .chinese: "HealthPit 错误：%@", .japanese: "HealthPitのエラー: %@"],
        "HealthPit löscht Trainings (%d)...": [.english: "HealthPit is deleting workouts (%d)...", .french: "HealthPit supprime les séances (%d)...", .spanish: "HealthPit está eliminando entrenamientos (%d)...", .italian: "HealthPit sta eliminando allenamenti (%d)...", .russian: "HealthPit удаляет тренировки (%d)...", .chinese: "HealthPit 正在删除训练 (%d)...", .japanese: "HealthPitがワークアウトを削除中 (%d)..."],
        "HealthPit: Löschung synchronisiert": [.english: "HealthPit: deletion synchronized", .french: "HealthPit : suppression synchronisée", .spanish: "HealthPit: eliminación sincronizada", .italian: "HealthPit: eliminazione sincronizzata", .russian: "HealthPit: удаление синхронизировано", .chinese: "HealthPit：删除已同步", .japanese: "HealthPit: 削除を同期しました"],
        "HealthPit: Löschungen fehlgeschlagen (%d)": [.english: "HealthPit: deletions failed (%d)", .french: "HealthPit : échec des suppressions (%d)", .spanish: "HealthPit: fallaron eliminaciones (%d)", .italian: "HealthPit: eliminazioni non riuscite (%d)", .russian: "HealthPit: не удалось удалить (%d)", .chinese: "HealthPit：删除失败 (%d)", .japanese: "HealthPit: 削除に失敗 (%d)"],
        "Neu: %d": [.english: "New: %d", .french: "Nouveaux : %d", .spanish: "Nuevos: %d", .italian: "Nuovi: %d", .russian: "Новых: %d", .chinese: "新增：%d", .japanese: "新規: %d"],
        "Aktualisiert: %d": [.english: "Updated: %d", .french: "Mis à jour : %d", .spanish: "Actualizados: %d", .italian: "Aggiornati: %d", .russian: "Обновлено: %d", .chinese: "已更新：%d", .japanese: "更新: %d"],
        "Übertragen: %d": [.english: "Transferred: %d", .french: "Transférés : %d", .spanish: "Transferidos: %d", .italian: "Trasferiti: %d", .russian: "Передано: %d", .chinese: "已传输：%d", .japanese: "転送: %d"],
        "Übungen: %d": [.english: "Exercises: %d", .french: "Exercices : %d", .spanish: "Ejercicios: %d", .italian: "Esercizi: %d", .russian: "Упражнений: %d", .chinese: "动作：%d", .japanese: "種目: %d"],
        "Sätze: %d": [.english: "Sets: %d", .french: "Séries : %d", .spanish: "Series: %d", .italian: "Serie: %d", .russian: "Подходов: %d", .chinese: "组数：%d", .japanese: "セット: %d"],
        "Volumen: %@": [.english: "Volume: %@", .french: "Volume : %@", .spanish: "Volumen: %@", .italian: "Volume: %@", .russian: "Объём: %@", .chinese: "容量：%@", .japanese: "ボリューム: %@"],
    ]

    // Additions and corrections for strings that are currently used by the UI.
    // Keeping them separate leaves the legacy tables below unchanged and makes
    // targeted additions for individual languages easier.
    private static let uiTextCorrections: [String: [AppLanguage: String]] = [
        "Anpassen": [.english: "Adjust", .french: "Ajuster", .spanish: "Ajustar", .italian: "Modifica", .russian: "Настроить", .chinese: "调整", .japanese: "調整"],
        "Beende das Training, damit es gespeichert wird.": [.english: "End the workout to save it.", .french: "Termine l’entraînement pour l’enregistrer.", .spanish: "Finaliza el entrenamiento para guardarlo.", .italian: "Termina l’allenamento per salvarlo.", .russian: "Завершите тренировку, чтобы сохранить её.", .chinese: "结束训练后即可保存。", .japanese: "保存するにはワークアウトを終了してください。"],
        "Fortsetzen": [.english: "Resume", .french: "Reprendre", .spanish: "Reanudar", .italian: "Riprendi", .russian: "Продолжить", .chinese: "继续", .japanese: "再開"],
        "Health-Aufzeichnung aus": [.english: "Health recording off", .french: "Enregistrement Santé désactivé", .spanish: "Registro de Salud desactivado", .italian: "Registrazione Salute disattivata", .russian: "Запись в Apple Health выключена", .chinese: "健康记录已关闭", .japanese: "ヘルスケア記録オフ"],
        "Health-Aufzeichnung starten": [.english: "Start Health recording", .french: "Démarrer l’enregistrement Santé", .spanish: "Iniciar registro de Salud", .italian: "Avvia registrazione Salute", .russian: "Начать запись в Apple Health", .chinese: "开始健康记录", .japanese: "ヘルスケア記録を開始"],
        "HealthPit-Adresse fehlt.": [.english: "HealthPit address is missing.", .french: "L’adresse HealthPit est manquante.", .spanish: "Falta la dirección de HealthPit.", .italian: "Manca l’indirizzo HealthPit.", .russian: "Не указан адрес HealthPit.", .chinese: "缺少 HealthPit 地址。", .japanese: "HealthPitのアドレスがありません。"],
        "HealthPit-Adresse ist ungültig.": [.english: "The HealthPit address is invalid.", .french: "L’adresse HealthPit n’est pas valide.", .spanish: "La dirección de HealthPit no es válida.", .italian: "L’indirizzo HealthPit non è valido.", .russian: "Адрес HealthPit недействителен.", .chinese: "HealthPit 地址无效。", .japanese: "HealthPitのアドレスが無効です。"],
        "HealthPit-Token fehlt.": [.english: "HealthPit token is missing.", .french: "Le jeton HealthPit est manquant.", .spanish: "Falta el token de HealthPit.", .italian: "Manca il token HealthPit.", .russian: "Не указан токен HealthPit.", .chinese: "缺少 HealthPit 令牌。", .japanese: "HealthPitトークンがありません。"],
        "Offline · wird später synchronisiert": [.english: "Offline · syncs later", .french: "Hors ligne · synchronisation ultérieure", .spanish: "Sin conexión · se sincronizará después", .italian: "Offline · sincronizzazione successiva", .russian: "Офлайн · синхронизация позже", .chinese: "离线 · 稍后同步", .japanese: "オフライン・後で同期"],
        "Pausieren": [.english: "Pause", .french: "Mettre en pause", .spanish: "Pausar", .italian: "Pausa", .russian: "Приостановить", .chinese: "暂停", .japanese: "一時停止"],
        "Puls, aktive Kalorien und Trainingszeit werden mit Apple Health aufgezeichnet.": [.english: "Heart rate, active calories, and workout time are recorded with Apple Health.", .french: "La fréquence cardiaque, les calories actives et la durée sont enregistrées avec Apple Santé.", .spanish: "La frecuencia cardiaca, las calorías activas y el tiempo se registran con Apple Salud.", .italian: "Frequenza cardiaca, calorie attive e durata vengono registrate con Apple Salute.", .russian: "Пульс, активные калории и время тренировки записываются в Apple Health.", .chinese: "心率、活动能量和训练时间会记录到 Apple 健康。", .japanese: "心拍数、アクティブカロリー、時間をAppleヘルスケアに記録します。"],
        "Schrittweite Gewicht": [.english: "Weight step", .french: "Pas de poids", .spanish: "Incremento de peso", .italian: "Incremento peso", .russian: "Шаг веса", .chinese: "重量步长", .japanese: "重量の刻み"],
        "Legt fest, um wie viel die Plus- und Minus-Tasten auf der Apple Watch das Gewicht ändern.": [.english: "Sets how much the plus and minus buttons on Apple Watch change the weight.", .french: "Définit de combien les boutons plus et moins de l’Apple Watch modifient le poids.", .spanish: "Define cuánto cambian el peso los botones más y menos en el Apple Watch.", .italian: "Definisce di quanto i pulsanti più e meno su Apple Watch cambiano il peso.", .russian: "Определяет, на сколько кнопки плюс и минус на Apple Watch меняют вес.", .chinese: "设定 Apple Watch 上的加号和减号按钮每次改变的重量。", .japanese: "Apple Watchのプラス・マイナスボタンで変わる重量を設定します。"],
        "Schritt": [.english: "Step", .french: "Pas", .spanish: "Paso", .italian: "Passo", .russian: "Шаг", .chinese: "步长", .japanese: "刻み"],
        "Training bearbeiten": [.english: "Edit workout", .french: "Modifier l’entraînement", .spanish: "Editar entrenamiento", .italian: "Modifica allenamento", .russian: "Изменить тренировку", .chinese: "编辑训练", .japanese: "ワークアウトを編集"],
        "Übung bearbeiten": [.english: "Edit exercise", .french: "Modifier l’exercice", .spanish: "Editar ejercicio", .italian: "Modifica esercizio", .russian: "Изменить упражнение", .chinese: "编辑动作", .japanese: "種目を編集"],
        "Apple Health wird aktualisiert...": [.english: "Updating Apple Health...", .french: "Mise à jour d’Apple Santé...", .spanish: "Actualizando Apple Salud...", .italian: "Aggiornamento di Apple Salute...", .russian: "Обновление Apple Health...", .chinese: "正在更新 Apple 健康...", .japanese: "Appleヘルスケアを更新中..."],
        "Satz anpassen": [.english: "Adjust set", .french: "Ajuster la série", .spanish: "Ajustar serie", .italian: "Modifica serie", .russian: "Настроить подход", .chinese: "调整组", .japanese: "セットを調整"],
        "Steuerung": [.english: "Controls", .french: "Commandes", .spanish: "Controles", .italian: "Controlli", .russian: "Управление", .chinese: "控制", .japanese: "コントロール"],
        "Training pausiert": [.english: "Workout paused", .french: "Entraînement en pause", .spanish: "Entrenamiento en pausa", .italian: "Allenamento in pausa", .russian: "Тренировка приостановлена", .chinese: "训练已暂停", .japanese: "ワークアウト一時停止中"],
        "iPhone verbunden": [.english: "iPhone connected", .french: "iPhone connecté", .spanish: "iPhone conectado", .italian: "iPhone connesso", .russian: "iPhone подключён", .chinese: "iPhone 已连接", .japanese: "iPhone接続済み"],
        "Übernehmen": [.english: "Apply", .french: "Appliquer", .spanish: "Aplicar", .italian: "Applica", .russian: "Применить", .chinese: "应用", .japanese: "適用"],
        "Anzeigen": [.english: "Show", .french: "Afficher", .spanish: "Mostrar", .italian: "Mostra", .russian: "Показать", .chinese: "显示", .japanese: "表示"],
        "Bestes Satzvolumen": [.english: "Best set volume", .french: "Meilleur volume de série", .spanish: "Mejor volumen de serie", .italian: "Miglior volume della serie", .russian: "Лучший объём подхода", .chinese: "最佳单组容量", .japanese: "最高セットボリューム"],
        "Die Anteile werden beim Speichern automatisch auf 100 % verteilt.": [.english: "When saved, the shares are automatically normalized to 100%.", .french: "Lors de l’enregistrement, les parts sont automatiquement réparties sur 100 %.", .spanish: "Al guardar, las proporciones se ajustan automáticamente al 100 %.", .italian: "Al salvataggio, le percentuali vengono distribuite automaticamente fino al 100%.", .russian: "При сохранении доли автоматически распределяются до 100 %.", .chinese: "保存时，各比例会自动调整为总计 100%。", .japanese: "保存時に割合の合計が自動的に100%になるよう調整されます。"],
        "GymPit sendet direkt an Home Assistant. Dort muss die Integration HealthPit eingerichtet sein. Der Long-Lived Access Token stammt aus deinem Home-Assistant-Profil und ist die gesamte Anmeldung.": [.english: "GymPit sends directly to Home Assistant. The HealthPit integration has to be set up there. The long-lived access token comes from your Home Assistant profile and is the entire sign-in.", .french: "GymPit envoie directement vers Home Assistant. L’intégration HealthPit doit y être installée. Le jeton d’accès longue durée provient de ton profil Home Assistant et constitue toute la connexion.", .spanish: "GymPit envía directamente a Home Assistant. Allí debe estar configurada la integración HealthPit. El token de acceso de larga duración procede de tu perfil de Home Assistant y es todo el inicio de sesión.", .italian: "GymPit invia direttamente a Home Assistant. Lì deve essere configurata l’integrazione HealthPit. Il token di accesso a lunga durata proviene dal tuo profilo Home Assistant ed è l’intero accesso.", .russian: "GymPit отправляет данные напрямую в Home Assistant. Там должна быть настроена интеграция HealthPit. Долгоживущий токен доступа берётся из вашего профиля Home Assistant и полностью заменяет вход.", .chinese: "GymPit 直接发送到 Home Assistant。需要先在那里配置 HealthPit 集成。长期访问令牌来自你的 Home Assistant 个人资料，它就是全部登录凭据。", .japanese: "GymPitはHome Assistantへ直接送信します。あらかじめHealthPit統合を設定してください。長期アクセストークンはHome Assistantのプロフィールで作成し、これだけがログイン情報になります。"],
        "Dieser Wert fließt in die Kalorienformel unter Mehr ein.": [.english: "This value is used in the calorie formula under More.", .french: "Cette valeur est utilisée dans la formule de calories sous Plus.", .spanish: "Este valor se usa en la fórmula de calorías de Más.", .italian: "Questo valore viene usato nella formula delle calorie in Altro.", .russian: "Это значение используется в формуле калорий в разделе «Ещё».", .chinese: "此数值会用于“更多”中的卡路里计算公式。", .japanese: "この値は「その他」のカロリー計算式に使用されます。"],
        "Eigene Geräte": [.english: "Custom equipment", .french: "Appareils personnalisés", .spanish: "Equipos personalizados", .italian: "Attrezzi personalizzati", .russian: "Свои тренажёры", .chinese: "自定义器械", .japanese: "カスタム器具"],
        "Eigenes Gerät": [.english: "Custom equipment", .french: "Appareil personnalisé", .spanish: "Equipo personalizado", .italian: "Attrezzo personalizzato", .russian: "Свой тренажёр", .chinese: "自定义器械", .japanese: "カスタム器具"],
        "Erfolge": [.english: "Achievements", .french: "Succès", .spanish: "Logros", .italian: "Traguardi", .russian: "Достижения", .chinese: "成就", .japanese: "実績"],
        "Highlights": [.english: "Highlights", .french: "Temps forts", .spanish: "Destacados", .italian: "In evidenza", .russian: "Основные показатели", .chinese: "亮点", .japanese: "ハイライト"],
        "Home Assistant": [.english: "Home Assistant", .french: "Home Assistant", .spanish: "Home Assistant", .italian: "Home Assistant", .russian: "Home Assistant", .chinese: "Home Assistant", .japanese: "Home Assistant"],
        "Lokale Adresse": [.english: "Local address", .french: "Adresse locale", .spanish: "Dirección local", .italian: "Indirizzo locale", .russian: "Локальный адрес", .chinese: "本地地址", .japanese: "ローカルアドレス"],
        "Externe Adresse (optional)": [.english: "External address (optional)", .french: "Adresse externe (facultatif)", .spanish: "Dirección externa (opcional)", .italian: "Indirizzo esterno (facoltativo)", .russian: "Внешний адрес (необязательно)", .chinese: "外部地址（可选）", .japanese: "外部アドレス（任意）"],
        "Long-Lived Access Token": [.english: "Long-lived access token", .french: "Jeton d\u{2019}accès longue durée", .spanish: "Token de acceso de larga duración", .italian: "Token di accesso a lunga durata", .russian: "Долгоживущий токен доступа", .chinese: "长期访问令牌", .japanese: "長期アクセストークン"],
        "Meiste Sätze in einem Training": [.english: "Most sets in one workout", .french: "Plus grand nombre de séries dans une séance", .spanish: "Más series en un entrenamiento", .italian: "Più serie in un allenamento", .russian: "Больше всего подходов за тренировку", .chinese: "单次训练最多组数", .japanese: "1回のワークアウトで最多のセット数"],
        "Meistes Volumen": [.english: "Highest volume", .french: "Volume le plus élevé", .spanish: "Mayor volumen", .italian: "Volume massimo", .russian: "Максимальный объём", .chinese: "最高训练容量", .japanese: "最高ボリューム"],
        "Neues Trainingsvolumen": [.english: "New workout volume", .french: "Nouveau volume d’entraînement", .spanish: "Nuevo volumen de entrenamiento", .italian: "Nuovo volume di allenamento", .russian: "Новый объём тренировки", .chinese: "新的训练容量", .japanese: "新しいワークアウトボリューム"],
        "Notiz vorhanden": [.english: "Note available", .french: "Note disponible", .spanish: "Nota disponible", .italian: "Nota presente", .russian: "Есть заметка", .chinese: "有备注", .japanese: "メモあり"],
        "Nächster Satz": [.english: "Next set", .french: "Prochaine série", .spanish: "Siguiente serie", .italian: "Serie successiva", .russian: "Следующий подход", .chinese: "下一组", .japanese: "次のセット"],
        "Port": [.english: "Port", .french: "Port", .spanish: "Puerto", .italian: "Porta", .russian: "Порт", .chinese: "端口", .japanese: "ポート"],
        "Schließen": [.english: "Close", .french: "Fermer", .spanish: "Cerrar", .italian: "Chiudi", .russian: "Закрыть", .chinese: "关闭", .japanese: "閉じる"],
        "Schwerster Satz": [.english: "Heaviest set", .french: "Série la plus lourde", .spanish: "Serie más pesada", .italian: "Serie più pesante", .russian: "Самый тяжёлый подход", .chinese: "最重一组", .japanese: "最重量セット"],
        "Wähle mindestens eine Muskelgruppe.": [.english: "Select at least one muscle group.", .french: "Sélectionne au moins un groupe musculaire.", .spanish: "Selecciona al menos un grupo muscular.", .italian: "Seleziona almeno un gruppo muscolare.", .russian: "Выберите хотя бы одну группу мышц.", .chinese: "请至少选择一个肌群。", .japanese: "筋肉グループを1つ以上選択してください。"],
        "Ø Gewicht pro Wiederholung": [.english: "Avg. weight per repetition", .french: "Poids moyen par répétition", .spanish: "Peso medio por repetición", .italian: "Peso medio per ripetizione", .russian: "Средний вес на повторение", .chinese: "每次平均重量", .japanese: "1回あたりの平均重量"],
        "Übersicht": [.english: "Overview", .french: "Aperçu", .spanish: "Resumen", .italian: "Panoramica", .russian: "Обзор", .chinese: "概览", .japanese: "概要"],
        "Übungsvolumen": [.english: "Exercise volume", .french: "Volume de l’exercice", .spanish: "Volumen del ejercicio", .italian: "Volume dell’esercizio", .russian: "Объём упражнения", .chinese: "动作容量", .japanese: "種目ボリューム"],
        "Beende das Training, damit es auf dem iPhone gespeichert wird.": [.english: "End the workout so it is saved on your iPhone.", .french: "Termine l’entraînement pour qu’il soit enregistré sur ton iPhone.", .spanish: "Finaliza el entrenamiento para guardarlo en el iPhone.", .italian: "Termina l’allenamento per salvarlo sull’iPhone.", .russian: "Завершите тренировку, чтобы сохранить её на iPhone.", .chinese: "结束训练后，记录会保存到 iPhone。", .japanese: "ワークアウトを終了するとiPhoneに保存されます。"],
        "Satz erledigt": [.english: "Set complete", .french: "Série terminée", .spanish: "Serie completada", .italian: "Serie completata", .russian: "Подход завершён", .chinese: "本组已完成", .japanese: "セット完了"],
        "alle Sätze erledigt": [.english: "all sets complete", .french: "toutes les séries terminées", .spanish: "todas las series completadas", .italian: "tutte le serie completate", .russian: "все подходы завершены", .chinese: "所有组均已完成", .japanese: "すべてのセット完了"],
        "Öffne die iPhone-App und stelle dein Training zusammen.": [.english: "Open the iPhone app and build your workout.", .french: "Ouvre l’app iPhone et compose ton entraînement.", .spanish: "Abre la app del iPhone y prepara tu entrenamiento.", .italian: "Apri l’app per iPhone e prepara il tuo allenamento.", .russian: "Откройте приложение на iPhone и составьте тренировку.", .chinese: "打开 iPhone App 并编排你的训练。", .japanese: "iPhoneアプリを開いてワークアウトを作成してください。"],
        "Öffne die iPhone-App, damit dein Training auf der Watch erscheint.": [.english: "Open the iPhone app so your workout appears on the Watch.", .french: "Ouvre l’app iPhone pour afficher ton entraînement sur la Watch.", .spanish: "Abre la app del iPhone para que tu entrenamiento aparezca en el Watch.", .italian: "Apri l’app per iPhone per visualizzare l’allenamento sul Watch.", .russian: "Откройте приложение на iPhone, чтобы тренировка появилась на часах.", .chinese: "打开 iPhone App，让训练显示在手表上。", .japanese: "iPhoneアプリを開くとワークアウトがWatchに表示されます。"],
        "Aktualisieren": [.english: "Refresh", .french: "Actualiser", .spanish: "Actualizar", .italian: "Aggiorna", .russian: "Обновить", .chinese: "刷新", .japanese: "更新"],
        "Überspringen": [.english: "Skip", .french: "Passer", .spanish: "Omitir", .italian: "Salta", .russian: "Пропустить", .chinese: "跳过", .japanese: "スキップ"],
        "Bereit": [.english: "Ready", .french: "Prêt", .spanish: "Listo", .italian: "Pronto", .russian: "Готово", .chinese: "准备就绪", .japanese: "準備完了"],
        "Nächster": [.english: "Next", .french: "Prochaine", .spanish: "Siguiente", .italian: "Prossima", .russian: "Следующий", .chinese: "下一", .japanese: "次の"],
        "Ziel erreicht": [.english: "Goal achieved", .french: "Objectif atteint", .spanish: "Objetivo alcanzado", .italian: "Obiettivo raggiunto", .russian: "Цель достигнута", .chinese: "目标已达成", .japanese: "目標達成"],
        "Pause fertig": [.english: "Rest complete", .french: "Pause terminée", .spanish: "Descanso terminado", .italian: "Pausa terminata", .russian: "Отдых завершён", .chinese: "休息结束", .japanese: "休憩終了"],
        "bereit": [.english: "ready", .french: "prêt", .spanish: "listo", .italian: "pronto", .russian: "готов", .chinese: "准备就绪", .japanese: "準備完了"],

        "Übertragung läuft...": [.english: "Transfer in progress...", .french: "Transfert en cours…", .spanish: "Transferencia en curso…", .italian: "Trasferimento in corso…", .russian: "Идёт передача…", .chinese: "正在传输…", .japanese: "転送中…"],
        "Superset": [.english: "Superset", .french: "Supersérie", .spanish: "Superserie", .italian: "Superset", .russian: "Суперсет", .chinese: "超级组", .japanese: "スーパーセット"],
        "Trainer": [.english: "Coach", .french: "Coach", .spanish: "Entrenador", .italian: "Coach", .russian: "Тренер", .chinese: "教练", .japanese: "トレーナー"],
        "Analysiert RPE, Gewicht und Wiederholungen für den nächsten Satz.": [.english: "Analyzes RPE, weight and repetitions for the next set.", .french: "Analyse la RPE, le poids et les répétitions pour la prochaine série.", .spanish: "Analiza el RPE, el peso y las repeticiones para la siguiente serie.", .italian: "Analizza RPE, peso e ripetizioni per la serie successiva.", .russian: "Анализирует RPE, вес и повторения для следующего подхода.", .chinese: "分析 RPE、重量和次数，为下一组提供建议。", .japanese: "RPE、重量、回数を分析し、次のセットを提案します。"],
        "Trainer ausschalten": [.english: "Disable coach", .french: "Désactiver le coach", .spanish: "Desactivar entrenador", .italian: "Disattiva coach", .russian: "Выключить тренера", .chinese: "关闭教练", .japanese: "トレーナーをオフ"],
        "Trainer einschalten": [.english: "Enable coach", .french: "Activer le coach", .spanish: "Activar entrenador", .italian: "Attiva coach", .russian: "Включить тренера", .chinese: "开启教练", .japanese: "トレーナーをオン"],
        "Aktueller Verlauf": [.english: "Current workout", .french: "Séance actuelle", .spanish: "Entrenamiento actual", .italian: "Allenamento attuale", .russian: "Текущая тренировка", .chinese: "当前训练", .japanese: "現在のワークアウト"],
        "Letztes Training": [.english: "Last workout", .french: "Dernier entraînement", .spanish: "Último entrenamiento", .italian: "Ultimo allenamento", .russian: "Последняя тренировка", .chinese: "上次训练", .japanese: "前回のワークアウト"],
        "Trainingsplan": [.english: "Workout plan", .french: "Plan d’entraînement", .spanish: "Plan de entrenamiento", .italian: "Piano di allenamento", .russian: "План тренировки", .chinese: "训练计划", .japanese: "トレーニングプラン"],
        "Empfehlung übernommen": [.english: "Recommendation applied", .french: "Recommandation appliquée", .spanish: "Recomendación aplicada", .italian: "Suggerimento applicato", .russian: "Рекомендация применена", .chinese: "已应用建议", .japanese: "提案を適用しました"],
        "Auf nächsten Satz anwenden": [.english: "Apply to next set", .french: "Appliquer à la prochaine série", .spanish: "Aplicar a la siguiente serie", .italian: "Applica alla serie successiva", .russian: "Применить к следующему подходу", .chinese: "应用于下一组", .japanese: "次のセットに適用"],

        "Warm-up wie geplant": [.english: "Warm-up as planned", .french: "Échauffement comme prévu", .spanish: "Calentamiento según lo previsto", .italian: "Riscaldamento come previsto", .russian: "Разминка по плану", .chinese: "按计划热身", .japanese: "予定どおりウォームアップ"],
        "Drop-Satz wie geplant": [.english: "Drop set as planned", .french: "Série dégressive comme prévu", .spanish: "Serie descendente según lo previsto", .italian: "Drop set come previsto", .russian: "Дроп-сет по плану", .chinese: "按计划进行递减组", .japanese: "予定どおりドロップセット"],
        "Mit dem Plan starten": [.english: "Start with the plan", .french: "Commencer selon le plan", .spanish: "Empezar según el plan", .italian: "Inizia secondo il piano", .russian: "Начать по плану", .chinese: "按计划开始", .japanese: "プランどおり開始"],
        "RPE ergänzen": [.english: "Add RPE", .french: "Ajouter la RPE", .spanish: "Añadir RPE", .italian: "Aggiungi RPE", .russian: "Указать RPE", .chinese: "添加 RPE", .japanese: "RPEを入力"],
        "Etwas steigern": [.english: "Increase slightly", .french: "Augmenter légèrement", .spanish: "Aumentar un poco", .italian: "Aumenta leggermente", .russian: "Немного увеличить", .chinese: "略微增加", .japanese: "少し上げる"],
        "Kleine Steigerung": [.english: "Small increase", .french: "Petite augmentation", .spanish: "Pequeño aumento", .italian: "Piccolo aumento", .russian: "Небольшое увеличение", .chinese: "小幅增加", .japanese: "小幅アップ"],
        "Gewicht halten": [.english: "Keep the weight", .french: "Maintenir le poids", .spanish: "Mantener el peso", .italian: "Mantieni il peso", .russian: "Сохранить вес", .chinese: "保持重量", .japanese: "重量を維持"],
        "Leicht entlasten": [.english: "Reduce slightly", .french: "Alléger légèrement", .spanish: "Reducir un poco", .italian: "Riduci leggermente", .russian: "Немного снизить", .chinese: "略微减轻", .japanese: "少し軽くする"],
        "Erholung priorisieren": [.english: "Prioritize recovery", .french: "Prioriser la récupération", .spanish: "Priorizar la recuperación", .italian: "Dai priorità al recupero", .russian: "Уделить внимание восстановлению", .chinese: "优先恢复", .japanese: "回復を優先"],
        "Ermüdung abfangen": [.english: "Manage fatigue", .french: "Gérer la fatigue", .spanish: "Controlar la fatiga", .italian: "Gestisci la fatica", .russian: "Снизить накопившуюся усталость", .chinese: "控制疲劳", .japanese: "疲労を抑える"],
        "Letzte Leistung übernehmen": [.english: "Use previous performance", .french: "Reprendre la dernière performance", .spanish: "Usar el rendimiento anterior", .italian: "Riprendi l’ultima prestazione", .russian: "Взять результат прошлой тренировки", .chinese: "采用上次表现", .japanese: "前回の実績を採用"],
        "Stärker einsteigen": [.english: "Start stronger", .french: "Commencer plus fort", .spanish: "Empezar más fuerte", .italian: "Inizia più forte", .russian: "Начать тяжелее", .chinese: "以更高强度开始", .japanese: "少し強めに開始"],
        "Kontrolliert einsteigen": [.english: "Start conservatively", .french: "Commencer prudemment", .spanish: "Empezar de forma controlada", .italian: "Inizia con controllo", .russian: "Начать осторожно", .chinese: "稳妥开始", .japanese: "控えめに開始"],
        "Leistung bestätigen": [.english: "Confirm performance", .french: "Confirmer la performance", .spanish: "Confirmar el rendimiento", .italian: "Conferma la prestazione", .russian: "Подтвердить результат", .chinese: "确认当前表现", .japanese: "パフォーマンスを確認"],

        "Spezialsätze werden nicht anhand der RPE des Arbeitssatzes verändert.": [.english: "Special sets are not adjusted based on the working set’s RPE.", .french: "Les séries spéciales ne sont pas ajustées selon la RPE de la série de travail.", .spanish: "Las series especiales no se ajustan según el RPE de la serie de trabajo.", .italian: "Le serie speciali non vengono modificate in base all’RPE della serie di lavoro.", .russian: "Специальные подходы не корректируются по RPE рабочего подхода.", .chinese: "特殊组不会根据正式组的 RPE 进行调整。", .japanese: "特殊セットはワーキングセットのRPEを基準に調整しません。"],
        "Noch fehlen vergleichbare RPE-Daten. Erfasse nach dem Satz deine RPE, dann passt der Trainer den nächsten Satz an.": [.english: "There is not enough comparable RPE data yet. Record your RPE after the set so the coach can adjust the next one.", .french: "Il manque encore des données RPE comparables. Saisis ta RPE après la série afin que le coach adapte la suivante.", .spanish: "Aún no hay suficientes datos de RPE comparables. Registra tu RPE después de la serie para que el entrenador ajuste la siguiente.", .italian: "Non ci sono ancora dati RPE confrontabili sufficienti. Registra l’RPE dopo la serie, così il coach potrà adattare la successiva.", .russian: "Пока недостаточно сопоставимых данных RPE. Укажите RPE после подхода, чтобы тренер скорректировал следующий.", .chinese: "目前还没有足够的可比 RPE 数据。请在完成一组后记录 RPE，教练便能调整下一组。", .japanese: "比較できるRPEデータがまだ不足しています。セット後にRPEを記録すると、トレーナーが次のセットを調整します。"],
        "Gewicht und Wiederholungen bleiben vorerst gleich. Mit einer RPE von 6 bis 10 kann der Trainer genauer steuern.": [.english: "Keep weight and repetitions unchanged for now. An RPE from 6 to 10 lets the coach adjust more precisely.", .french: "Garde pour l’instant le même poids et le même nombre de répétitions. Une RPE de 6 à 10 permet au coach d’affiner la recommandation.", .spanish: "Mantén por ahora el peso y las repeticiones. Con un RPE de 6 a 10, el entrenador puede ajustar con más precisión.", .italian: "Per ora mantieni invariati peso e ripetizioni. Con un RPE da 6 a 10, il coach può regolare con maggiore precisione.", .russian: "Пока оставьте вес и повторения без изменений. При RPE от 6 до 10 тренер сможет точнее подобрать нагрузку.", .chinese: "暂时保持重量和次数不变。记录 6 到 10 的 RPE 后，教练可以更精确地调整。", .japanese: "当面は重量と回数を維持します。RPEを6〜10で記録すると、より正確に調整できます。"],
        "Die RPE lässt deutliche Reserven. Der nächste Satz darf etwas schwerer werden.": [.english: "The RPE shows plenty left in reserve. The next set can be slightly heavier.", .french: "La RPE montre une nette réserve. La prochaine série peut être un peu plus lourde.", .spanish: "El RPE muestra bastante margen. La siguiente serie puede ser un poco más pesada.", .italian: "L’RPE indica un buon margine. La serie successiva può essere leggermente più pesante.", .russian: "RPE показывает заметный запас. Следующий подход можно сделать немного тяжелее.", .chinese: "RPE 表明仍有明显余力。下一组可以稍微加重。", .japanese: "RPEから十分な余力があります。次のセットは少し重くできます。"],
        "RPE 7 liegt unter dem produktiven Zielbereich. Eine kleine Laststeigerung ist sinnvoll.": [.english: "RPE 7 is below the productive target range. A small load increase makes sense.", .french: "Une RPE de 7 est sous la zone cible productive. Une légère hausse de charge est appropriée.", .spanish: "Un RPE de 7 está por debajo del rango objetivo productivo. Conviene aumentar un poco la carga.", .italian: "Un RPE di 7 è sotto l’intervallo produttivo. È indicato un piccolo aumento del carico.", .russian: "RPE 7 ниже продуктивного целевого диапазона. Стоит немного увеличить нагрузку.", .chinese: "RPE 7 低于有效目标区间，适合小幅增加负荷。", .japanese: "RPE 7は効果的な目標範囲を下回っています。負荷を少し上げるのが適切です。"],
        "RPE 8 passt gut: Belastung und Technik können im nächsten Satz stabil bleiben.": [.english: "RPE 8 is on target: load and technique can stay consistent in the next set.", .french: "Une RPE de 8 est idéale : la charge et la technique peuvent rester stables à la prochaine série.", .spanish: "Un RPE de 8 es adecuado: la carga y la técnica pueden mantenerse en la siguiente serie.", .italian: "Un RPE di 8 è ideale: carico e tecnica possono restare stabili nella serie successiva.", .russian: "RPE 8 соответствует цели: в следующем подходе можно сохранить нагрузку и технику.", .chinese: "RPE 8 很合适：下一组可保持负荷和动作质量稳定。", .japanese: "RPE 8は適切です。次のセットも負荷とフォームを維持できます。"],
        "RPE 9 war sehr fordernd. Eine kleine Reduktion hält den nächsten Satz sauber.": [.english: "RPE 9 was very demanding. A small reduction helps keep the next set clean.", .french: "Une RPE de 9 était très exigeante. Une légère réduction aidera à garder une exécution propre.", .spanish: "Un RPE de 9 fue muy exigente. Una pequeña reducción ayudará a mantener limpia la siguiente serie.", .italian: "Un RPE di 9 è stato molto impegnativo. Una piccola riduzione aiuta a mantenere pulita la serie successiva.", .russian: "RPE 9 был очень тяжёлым. Небольшое снижение поможет чисто выполнить следующий подход.", .chinese: "RPE 9 强度很高。小幅减轻负荷有助于下一组保持动作质量。", .japanese: "RPE 9はかなり高負荷でした。少し軽くすると次のセットもフォームを保てます。"],
        "RPE 10 bedeutet keine Reserve. Last reduzieren und länger pausieren.": [.english: "RPE 10 means no repetitions were left in reserve. Reduce the load and rest longer.", .french: "Une RPE de 10 signifie qu’il ne restait aucune réserve. Réduis la charge et prolonge la pause.", .spanish: "Un RPE de 10 significa que no quedaba margen. Reduce la carga y descansa más tiempo.", .italian: "Un RPE di 10 indica che non c’era più margine. Riduci il carico e prolunga la pausa.", .russian: "RPE 10 означает отсутствие запаса. Снизьте нагрузку и увеличьте отдых.", .chinese: "RPE 10 表示已无余力。请减轻负荷并延长休息。", .japanese: "RPE 10は余力がない状態です。負荷を下げ、休憩を長くしてください。"],
        "Zwei sehr harte Sätze in Folge sprechen für zusätzliche Entlastung.": [.english: "Two very hard sets in a row call for an additional reduction.", .french: "Deux séries très difficiles de suite justifient une réduction supplémentaire.", .spanish: "Dos series muy duras seguidas aconsejan reducir un poco más la carga.", .italian: "Due serie molto dure consecutive suggeriscono un’ulteriore riduzione.", .russian: "Два очень тяжёлых подхода подряд требуют дополнительного снижения нагрузки.", .chinese: "连续两组强度很高，建议进一步减轻负荷。", .japanese: "非常にきついセットが2回続いたため、さらに負荷を下げるのが適切です。"],
        "Da kein Zusatzgewicht hinterlegt ist, wird über Wiederholungen gesteuert.": [.english: "Because no additional weight is recorded, the adjustment is made through repetitions.", .french: "Comme aucun poids supplémentaire n’est indiqué, l’ajustement se fait par les répétitions.", .spanish: "Como no se ha registrado peso adicional, el ajuste se realiza mediante las repeticiones.", .italian: "Poiché non è indicato alcun peso aggiuntivo, la regolazione avviene tramite le ripetizioni.", .russian: "Поскольку дополнительный вес не указан, нагрузка регулируется числом повторений.", .chinese: "由于未记录额外重量，将通过调整次数来控制强度。", .japanese: "追加重量が記録されていないため、回数で調整します。"],
        "Die letzte Einheit liefert Gewicht und Wiederholungen, aber noch keine RPE für eine belastbare Anpassung.": [.english: "The last workout provides weight and repetitions, but no RPE yet for a reliable adjustment.", .french: "La dernière séance fournit le poids et les répétitions, mais pas encore de RPE pour un ajustement fiable.", .spanish: "El último entrenamiento aporta peso y repeticiones, pero aún no un RPE para un ajuste fiable.", .italian: "L’ultimo allenamento fornisce peso e ripetizioni, ma non ancora un RPE per una regolazione affidabile.", .russian: "В прошлой тренировке есть вес и повторения, но нет RPE для надёжной корректировки.", .chinese: "上次训练提供了重量和次数，但还没有足够的 RPE 数据用于可靠调整。", .japanese: "前回の重量と回数はありますが、信頼できる調整に必要なRPEがまだありません。"],
        "Die letzte Einheit lag im niedrigen RPE-Bereich. Eine kleine Steigerung ist realistisch.": [.english: "The last workout was in a low RPE range. A small increase is realistic.", .french: "La dernière séance se situait dans une zone RPE basse. Une légère augmentation est réaliste.", .spanish: "El último entrenamiento estuvo en un rango de RPE bajo. Un pequeño aumento es realista.", .italian: "L’ultimo allenamento era in un intervallo RPE basso. Un piccolo aumento è realistico.", .russian: "Прошлая тренировка была в низком диапазоне RPE. Небольшое увеличение нагрузки реалистично.", .chinese: "上次训练的 RPE 较低，可以尝试小幅提升。", .japanese: "前回は低いRPE範囲でした。少し上げてもよさそうです。"],
        "Die letzte Einheit lag im sehr hohen RPE-Bereich. Heute etwas leichter beginnen.": [.english: "The last workout was in a very high RPE range. Start a little lighter today.", .french: "La dernière séance se situait dans une zone RPE très élevée. Commence un peu plus léger aujourd’hui.", .spanish: "El último entrenamiento estuvo en un rango de RPE muy alto. Empieza hoy un poco más ligero.", .italian: "L’ultimo allenamento era in un intervallo RPE molto alto. Oggi inizia un po’ più leggero.", .russian: "Прошлая тренировка была в очень высоком диапазоне RPE. Сегодня начните немного легче.", .chinese: "上次训练的 RPE 很高，今天请稍微减轻起始负荷。", .japanese: "前回は非常に高いRPE範囲でした。今日は少し軽めに始めてください。"],
        "Die letzte Einheit lag im Zielbereich. Gewicht und Wiederholungen zunächst bestätigen.": [.english: "The last workout was in the target range. Confirm the weight and repetitions first.", .french: "La dernière séance était dans la zone cible. Confirme d’abord le poids et les répétitions.", .spanish: "El último entrenamiento estuvo en el rango objetivo. Confirma primero el peso y las repeticiones.", .italian: "L’ultimo allenamento era nell’intervallo obiettivo. Conferma prima peso e ripetizioni.", .russian: "Прошлая тренировка была в целевом диапазоне. Сначала подтвердите вес и повторения.", .chinese: "上次训练处于目标区间，先确认当前重量和次数。", .japanese: "前回は目標範囲内でした。まず同じ重量と回数で確認してください。"],

        "100 % bei": [.russian: "100 % при", .chinese: "达到 100%：", .japanese: "100%になる条件："],
        "100 % wird erreicht, wenn alle Übungen erledigt sind.": [.russian: "100 % достигается, когда выполнены все упражнения.", .chinese: "完成所有动作后即达到 100%。", .japanese: "すべての種目を完了すると100%になります。"],
        "Die Einheit ist gespeichert. Dein nächstes Training startet wieder offen.": [.russian: "Тренировка сохранена. Следующая тренировка снова начнётся как открытая.", .chinese: "本次训练已保存。下次训练会重新以未完成状态开始。", .japanese: "ワークアウトを保存しました。次回は再び未完了の状態で開始します。"],
        "Erstes Mal in der Historie": [.russian: "Впервые в истории", .chinese: "历史记录中的首次", .japanese: "履歴で初めて"],
        "Kein Superset": [.russian: "Без суперсета", .chinese: "非超级组", .japanese: "スーパーセットなし"],
        "Keine weiteren Übungen": [.russian: "Других упражнений нет", .chinese: "没有其他动作", .japanese: "ほかの種目はありません"],
        "Keine Übungen in dieser Routine.": [.russian: "В этой программе нет упражнений.", .chinese: "此训练方案中没有动作。", .japanese: "このルーティンには種目がありません。"],
        "Letzte Notiz": [.russian: "Последняя заметка", .chinese: "上次备注", .japanese: "前回のメモ"],
        "Nach dem Abschluss siehst du hier deine letzte Leistung und Rekorde.": [.russian: "После завершения здесь появятся последний результат и рекорды.", .chinese: "完成后，你会在这里看到上次表现和纪录。", .japanese: "完了後、ここに前回の実績と記録が表示されます。"],
        "Noch kein Training zusammengestellt": [.russian: "Тренировка ещё не составлена", .chinese: "尚未编排训练", .japanese: "ワークアウトはまだ作成されていません"],
        "Noch kein Verlauf für diese Übung.": [.russian: "Для этого упражнения ещё нет истории.", .chinese: "此动作尚无历史记录。", .japanese: "この種目の履歴はまだありません。"],
        "Noch keine Übungen geplant.": [.russian: "Упражнения ещё не запланированы.", .chinese: "尚未计划动作。", .japanese: "種目はまだ計画されていません。"],
        "Noch keine Übungen hinzugefügt.": [.russian: "Упражнения ещё не добавлены.", .chinese: "尚未添加动作。", .japanese: "種目はまだ追加されていません。"],
        "Noch keine Übungen in dieser Routine.": [.russian: "В этой программе пока нет упражнений.", .chinese: "此训练方案中尚无动作。", .japanese: "このルーティンにはまだ種目がありません。"],
        "Schließe die aktuelle Übung ab.": [.russian: "Завершите текущее упражнение.", .chinese: "请完成当前动作。", .japanese: "現在の種目を完了してください。"],
        "Starte dein Training. Danach erscheint die erste Übung oben und du kannst offene Übungen durch Antippen wechseln.": [.russian: "Начните тренировку. Первое упражнение появится сверху, а между незавершёнными упражнениями можно переключаться касанием.", .chinese: "开始训练后，第一个动作会显示在顶部；点按即可在未完成的动作之间切换。", .japanese: "ワークアウトを開始すると最初の種目が上部に表示され、タップして未完了の種目を切り替えられます。"],
        "Timer stoppen": [.russian: "Остановить таймер", .chinese: "停止计时器", .japanese: "タイマーを停止"],
        "auswählen": [.russian: "выбрать", .chinese: "选择", .japanese: "選択"],
        "hinzugefügt": [.russian: "добавлено", .chinese: "已添加", .japanese: "追加済み"],
        "im Plan": [.russian: "в плане", .chinese: "计划中", .japanese: "プラン内"],
        "in Routinen": [.russian: "в программах", .chinese: "训练方案中", .japanese: "ルーティン内"],
        "verwendet": [.russian: "используется", .chinese: "已使用", .japanese: "使用中"],
        "Öffne die Einstellungen und füge Standardgeräte zu deinem Plan hinzu.": [.russian: "Откройте настройки и добавьте стандартные тренажёры в свой план.", .chinese: "打开设置，将标准器械添加到你的计划中。", .japanese: "設定を開き、標準器具をプランに追加してください。"]
    ]

    private static let uiTexts: [String: [AppLanguage: String]] = [
        "Training": [.english: "Training", .french: "Entraînement", .spanish: "Entrenamiento", .italian: "Allenamento"],
        "Routinen": [.english: "Routines", .french: "Routines", .spanish: "Rutinas", .italian: "Routine"],
        "Historie": [.english: "History", .french: "Historique", .spanish: "Historial", .italian: "Storico"],
        "Mehr": [.english: "More", .french: "Plus", .spanish: "Más", .italian: "Altro"],
        "App": [.english: "App", .french: "App", .spanish: "App", .italian: "App"],
        "Training und Geräte": [.english: "Training and Equipment", .french: "Entraînement et appareils", .spanish: "Entrenamiento y equipos", .italian: "Allenamento e attrezzi"],
        "App und Daten": [.english: "App and Data", .french: "App et données", .spanish: "App y datos", .italian: "App e dati"],
        "Infos": [.english: "Info", .french: "Infos", .spanish: "Información", .italian: "Info"],
        "Schnittstellen / API": [.english: "Interfaces / API", .french: "Interfaces / API", .spanish: "Interfaces / API", .italian: "Interfacce / API"],
        "Daten": [.english: "Data", .french: "Données", .spanish: "Datos", .italian: "Dati"],
        "Daten / Schnittstellen": [.english: "Data / Interfaces", .french: "Données / interfaces", .spanish: "Datos / interfaces", .italian: "Dati / interfacce"],
        "Geräte": [.english: "Equipment", .french: "Appareils", .spanish: "Máquinas", .italian: "Macchine"],
        "Geräte und Übungen": [.english: "Equipment and Exercises", .french: "Appareils et exercices", .spanish: "Máquinas y ejercicios", .italian: "Macchine ed esercizi"],
        "Über": [.english: "About", .french: "À propos", .spanish: "Acerca de", .italian: "Info"],
        "Datenschutz und Kosten": [.english: "Privacy and Cost", .french: "Confidentialité et coûts", .spanish: "Privacidad y coste", .italian: "Privacy e costi"],
        "Darstellung": [.english: "Appearance", .french: "Affichage", .spanish: "Apariencia", .italian: "Aspetto"],
        "Sprache": [.english: "Language", .french: "Langue", .spanish: "Idioma", .italian: "Lingua"],
        "Modus": [.english: "Mode", .french: "Mode", .spanish: "Modo", .italian: "Modalità"],
        "Hell": [.english: "Light", .french: "Clair", .spanish: "Claro", .italian: "Chiaro"],
        "Dunkel": [.english: "Dark", .french: "Sombre", .spanish: "Oscuro", .italian: "Scuro"],
        "Design": [.english: "Design", .french: "Design", .spanish: "Diseño", .italian: "Design"],
        "Blau": [.english: "Blue", .french: "Bleu", .spanish: "Azul", .italian: "Blu"],
        "Türkis": [.english: "Turquoise", .french: "Turquoise", .spanish: "Turquesa", .italian: "Turchese"],
        "Graphit": [.english: "Graphite", .french: "Graphite", .spanish: "Grafito", .italian: "Grafite"],
        "Grün": [.english: "Green", .french: "Vert", .spanish: "Verde", .italian: "Verde"],
        "Orange": [.english: "Orange", .french: "Orange", .spanish: "Naranja", .italian: "Arancione"],
        "Violett": [.english: "Violet", .french: "Violet", .spanish: "Violeta", .italian: "Viola"],
        "Rot": [.english: "Red", .french: "Rouge", .spanish: "Rojo", .italian: "Rosso"],
        "Einheiten": [.english: "Units", .french: "Unités", .spanish: "Unidades", .italian: "Unità"],
        "Gewichtseinheit": [.english: "Weight unit", .french: "Unité de poids", .spanish: "Unidad de peso", .italian: "Unità di peso"],
        "Kilogramm": [.english: "Kilograms", .french: "Kilogrammes", .spanish: "Kilogramos", .italian: "Chilogrammi"],
        "Pfund": [.english: "Pounds", .french: "Livres", .spanish: "Libras", .italian: "Libbre"],
        "Apple Health": [.english: "Apple Health", .french: "Apple Health", .spanish: "Apple Health", .italian: "Apple Health"],
        "Apple Health verbinden": [.english: "Connect Apple Health", .french: "Connecter Apple Health", .spanish: "Conectar Apple Health", .italian: "Connetti Apple Health"],
        "Alle alten Workouts übertragen": [.english: "Transfer all old workouts", .french: "Transférer tous les anciens entraînements", .spanish: "Transferir entrenamientos antiguos", .italian: "Trasferisci vecchi allenamenti"],
        "HealthPit": [.english: "HealthPit", .french: "HealthPit", .spanish: "HealthPit", .italian: "HealthPit"],
        "Lokale Verbindung verwenden": [.english: "Use local connection", .french: "Utiliser la connexion locale", .spanish: "Usar conexión local", .italian: "Usa connessione locale"],
        "Lokaler Host oder IP": [.english: "Local host or IP", .french: "Hôte local ou IP", .spanish: "Host local o IP", .italian: "Host locale o IP"],
        "Lokaler Port": [.english: "Local port", .french: "Port local", .spanish: "Puerto local", .italian: "Porta locale"],
        "Benutzername": [.english: "Username", .french: "Nom d’utilisateur", .spanish: "Usuario", .italian: "Nome utente"],
        "Gerätename": [.english: "Device name", .french: "Nom de l’appareil", .spanish: "Nombre del dispositivo", .italian: "Nome dispositivo"],
        "API Token": [.english: "API token", .french: "Jeton API", .spanish: "Token API", .italian: "Token API"],
        "HealthPit verbinden": [.english: "Connect HealthPit", .french: "Connecter HealthPit", .spanish: "Conectar HealthPit", .italian: "Connetti HealthPit"],
        "Verbindung trennen": [.english: "Disconnect", .french: "Déconnecter", .spanish: "Desconectar", .italian: "Disconnetti"],
        "HealthPit verbindet...": [.english: "Connecting HealthPit...", .french: "Connexion à HealthPit...", .spanish: "Conectando HealthPit...", .italian: "Connessione HealthPit..."],
        "HealthPit ist verbunden": [.english: "HealthPit is connected", .french: "HealthPit est connecté", .spanish: "HealthPit conectado", .italian: "HealthPit connesso"],
        "HealthPit ist nicht verbunden": [.english: "HealthPit is not connected", .french: "HealthPit n’est pas connecté", .spanish: "HealthPit no conectado", .italian: "HealthPit non connesso"],
        "HealthPit Verbindung Fehler": [.english: "HealthPit connection error", .french: "Erreur de connexion HealthPit", .spanish: "Error de conexión HealthPit", .italian: "Errore connessione HealthPit"],
        "Alle Trainings zu HealthPit übertragen": [.english: "Transfer all workouts to HealthPit", .french: "Transférer tous les entraînements vers HealthPit", .spanish: "Transferir todos los entrenamientos a HealthPit", .italian: "Trasferisci tutti gli allenamenti a HealthPit"],
        "Kalorien": [.english: "Calories", .french: "Calories", .spanish: "Calorías", .italian: "Calorie"],
        "Körpergewicht": [.english: "Body weight", .french: "Poids corporel", .spanish: "Peso corporal", .italian: "Peso corporeo"],
        "Zeit pro Satz inkl. Pause": [.english: "Time per set incl. rest", .french: "Temps par série avec pause", .spanish: "Tiempo por serie incl. descanso", .italian: "Tempo per serie incl. pausa"],
        "Wechselzeit pro Übung": [.english: "Changeover per exercise", .french: "Transition par exercice", .spanish: "Cambio por ejercicio", .italian: "Cambio per esercizio"],
        "Standardpause": [.english: "Default rest", .french: "Pause standard", .spanish: "Descanso estándar", .italian: "Pausa standard"],
        "Kalorienformel": [.english: "Calorie Formula", .french: "Formule calories", .spanish: "Fórmula de calorías", .italian: "Formula calorie"],
        "Sauerstofffaktor": [.english: "Oxygen factor", .french: "Facteur oxygène", .spanish: "Factor de oxígeno", .italian: "Fattore ossigeno"],
        "Divisor": [.english: "Divisor", .french: "Diviseur", .spanish: "Divisor", .italian: "Divisore"],
        "CSV": [.english: "CSV", .french: "CSV", .spanish: "CSV", .italian: "CSV"],
        "Trainings exportieren": [.english: "Export workouts", .french: "Exporter les entraînements", .spanish: "Exportar entrenamientos", .italian: "Esporta allenamenti"],
        "Trainings importieren": [.english: "Import workouts", .french: "Importer les entraînements", .spanish: "Importar entrenamientos", .italian: "Importa allenamenti"],
        "Trainings und Routinen exportieren": [.english: "Export workouts and routines", .french: "Exporter entraînements et routines", .spanish: "Exportar entrenamientos y rutinas", .italian: "Esporta allenamenti e routine"],
        "Trainings und Routinen importieren": [.english: "Import workouts and routines", .french: "Importer entraînements et routines", .spanish: "Importar entrenamientos y rutinas", .italian: "Importa allenamenti e routine"],
        "Import läuft...": [.english: "Import running...", .french: "Import en cours...", .spanish: "Importando...", .italian: "Importazione in corso..."],
        "Unterstützen": [.english: "Support", .french: "Soutenir", .spanish: "Apoyar", .italian: "Supporta"],
        "Kleiner Kaffee": [.english: "Small coffee", .french: "Petit café", .spanish: "Café pequeño", .italian: "Caffè piccolo"],
        "Unterstützer": [.english: "Supporter", .french: "Soutien", .spanish: "Colaborador", .italian: "Sostenitore"],
        "Große Unterstützung": [.english: "Big support", .french: "Grand soutien", .spanish: "Gran apoyo", .italian: "Grande supporto"],
        "Projekt fördern": [.english: "Fund the project", .french: "Soutenir le projet", .spanish: "Apoyar el proyecto", .italian: "Sostieni il progetto"],
        "Unterstützung wird geladen...": [.english: "Loading support options...", .french: "Chargement des options...", .spanish: "Cargando opciones...", .italian: "Caricamento opzioni..."],
        "Unterstützung ist momentan nicht verfügbar.": [.english: "Support is currently unavailable.", .french: "Le soutien est actuellement indisponible.", .spanish: "La ayuda no está disponible ahora.", .italian: "Il supporto non è al momento disponibile."],
        "Unterstützung konnte nicht geladen werden.": [.english: "Support options could not be loaded.", .french: "Impossible de charger les options.", .spanish: "No se pudieron cargar las opciones.", .italian: "Impossibile caricare le opzioni."],
        "Erneut laden": [.english: "Try again", .french: "Réessayer", .spanish: "Reintentar", .italian: "Riprova"],
        "Dieser Kauf ist noch nicht verfügbar.": [.english: "This purchase is not available yet.", .french: "Cet achat n’est pas encore disponible.", .spanish: "Esta compra aún no está disponible.", .italian: "Questo acquisto non è ancora disponibile."],
        "Danke für deine Unterstützung.": [.english: "Thank you for your support.", .french: "Merci pour ton soutien.", .spanish: "Gracias por tu apoyo.", .italian: "Grazie per il supporto."],
        "Kauf abgebrochen.": [.english: "Purchase cancelled.", .french: "Achat annulé.", .spanish: "Compra cancelada.", .italian: "Acquisto annullato."],
        "Kauf wartet auf Bestätigung.": [.english: "Purchase is awaiting approval.", .french: "L’achat attend une confirmation.", .spanish: "La compra espera confirmación.", .italian: "L’acquisto attende conferma."],
        "Kauf konnte nicht abgeschlossen werden.": [.english: "Purchase could not be completed.", .french: "Impossible de finaliser l’achat.", .spanish: "No se pudo completar la compra.", .italian: "Impossibile completare l’acquisto."],
        "OK": [.english: "OK", .french: "OK", .spanish: "OK", .italian: "OK"],
        "Fertig": [.english: "Done", .french: "Terminé", .spanish: "Listo", .italian: "Fine"],
        "Sichern": [.english: "Save", .french: "Enregistrer", .spanish: "Guardar", .italian: "Salva"],
        "Wird sofort auf die App angewendet.": [.english: "Applied to the app immediately.", .french: "Appliqué immédiatement à l’app.", .spanish: "Se aplica inmediatamente a la app.", .italian: "Applicato subito all’app."],
        "Offen": [.english: "Open", .french: "Ouvert", .spanish: "Pendiente", .italian: "Aperto"],
        "Erledigt": [.english: "Done", .french: "Terminé", .spanish: "Hecho", .italian: "Completato"],
        "offen": [.english: "open", .french: "ouverts", .spanish: "pendientes", .italian: "aperti"],
        "erledigt": [.english: "done", .french: "terminés", .spanish: "hechos", .italian: "completati"],
        "Übungen": [.english: "Exercises", .french: "Exercices", .spanish: "Ejercicios", .italian: "Esercizi"],
        "Übung": [.english: "Exercise", .french: "Exercice", .spanish: "Ejercicio", .italian: "Esercizio"],
        "Sätze": [.english: "Sets", .french: "Séries", .spanish: "Series", .italian: "Serie"],
        "Satz": [.english: "Set", .french: "Série", .spanish: "Serie", .italian: "Serie"],
        "Volumen": [.english: "Volume", .french: "Volume", .spanish: "Volumen", .italian: "Volume"],
        "Zeit": [.english: "Time", .french: "Temps", .spanish: "Tiempo", .italian: "Tempo"],
        "Rekorde": [.english: "Records", .french: "Records", .spanish: "Récords", .italian: "Record"],
        "Rekord": [.english: "Record", .french: "Record", .spanish: "Récord", .italian: "Record"],
        "Aktiv": [.english: "Active", .french: "Active", .spanish: "Activa", .italian: "Attiva"],
        "Aktuell": [.english: "Current", .french: "Actuel", .spanish: "Actual", .italian: "Attuale"],
        "Keine weiteren Übungen": [.english: "No more exercises", .french: "Aucun autre exercice", .spanish: "No hay más ejercicios", .italian: "Nessun altro esercizio"],
        "Schließe die aktuelle Übung ab.": [.english: "Complete the current exercise.", .french: "Termine l’exercice actuel.", .spanish: "Completa el ejercicio actual.", .italian: "Completa l’esercizio attuale."],
        "Aktive Routine": [.english: "Active Routine", .french: "Routine active", .spanish: "Rutina activa", .italian: "Routine attiva"],
        "Neue Routine erstellen": [.english: "Create new routine", .french: "Créer une routine", .spanish: "Crear nueva rutina", .italian: "Crea nuova routine"],
        "Als aktive Routine verwenden": [.english: "Use as active routine", .french: "Utiliser comme routine active", .spanish: "Usar como rutina activa", .italian: "Usa come routine attiva"],
        "Standardroutine": [.english: "Default routine", .french: "Routine par défaut", .spanish: "Rutina predeterminada", .italian: "Routine predefinita"],
        "Als Standard favorisieren": [.english: "Set as default", .french: "Définir par défaut", .spanish: "Marcar como predeterminada", .italian: "Imposta come predefinita"],
        "Keine Übungen in dieser Routine.": [.english: "No exercises in this routine.", .french: "Aucun exercice dans cette routine.", .spanish: "No hay ejercicios en esta rutina.", .italian: "Nessun esercizio in questa routine."],
        "Routine": [.english: "Routine", .french: "Routine", .spanish: "Rutina", .italian: "Routine"],
        "Ziel": [.english: "Goal", .french: "Objectif", .spanish: "Objetivo", .italian: "Obiettivo"],
        "Alle Übungen": [.english: "All exercises", .french: "Tous les exercices", .spanish: "Todos los ejercicios", .italian: "Tutti gli esercizi"],
        "Übungsanzahl": [.english: "Exercise count", .french: "Nombre d’exercices", .spanish: "Número de ejercicios", .italian: "Numero esercizi"],
        "Gesamtvolumen": [.english: "Total volume", .french: "Volume total", .spanish: "Volumen total", .italian: "Volume totale"],
        "Trainingszeit": [.english: "Workout time", .french: "Durée d’entraînement", .spanish: "Tiempo de entrenamiento", .italian: "Tempo allenamento"],
        "Satzanzahl": [.english: "Set count", .french: "Nombre de séries", .spanish: "Número de series", .italian: "Numero serie"],
        "100 % bei": [.english: "100% at", .french: "100 % à", .spanish: "100 % en", .italian: "100% a"],
        "100 % wird erreicht, wenn alle Übungen erledigt sind.": [.english: "100% is reached when all exercises are completed.", .french: "100 % est atteint lorsque tous les exercices sont terminés.", .spanish: "El 100 % se alcanza cuando todos los ejercicios están completados.", .italian: "Il 100% si raggiunge quando tutti gli esercizi sono completati."],
        "Übung hinzufügen": [.english: "Add exercise", .french: "Ajouter un exercice", .spanish: "Añadir ejercicio", .italian: "Aggiungi esercizio"],
        "Zur Routine hinzufügen?": [.english: "Add to routine?", .french: "Ajouter à la routine ?", .spanish: "¿Añadir a la rutina?", .italian: "Aggiungere alla routine?", .russian: "Добавить в программу?", .chinese: "添加到例程？", .japanese: "ルーティンに追加しますか？"],
        "Zur Routine hinzufügen": [.english: "Add to routine", .french: "Ajouter à la routine", .spanish: "Añadir a la rutina", .italian: "Aggiungi alla routine", .russian: "Добавить в программу", .chinese: "添加到例程", .japanese: "ルーティンに追加"],
        "Nur dieses Training": [.english: "Only this workout", .french: "Seulement cet entraînement", .spanish: "Solo este entrenamiento", .italian: "Solo questo allenamento", .russian: "Только эта тренировка", .chinese: "仅本次训练", .japanese: "このトレーニングのみ"],
        "neue Übungen": [.english: "new exercises", .french: "nouveaux exercices", .spanish: "ejercicios nuevos", .italian: "nuovi esercizi", .russian: "новых упражнений", .chinese: "个新动作", .japanese: "件の新しい種目"],
        "Übungen mit neuen Sätzen": [.english: "exercises with new sets", .french: "exercices avec de nouvelles séries", .spanish: "ejercicios con series nuevas", .italian: "esercizi con nuove serie", .russian: "упражнений с новыми подходами", .chinese: "个动作含新组", .japanese: "件の種目に新しいセット"],
        "Möchtest du diese Übung dauerhaft in die Routine übernehmen?": [.english: "Do you want to keep this exercise in the routine?", .french: "Veux-tu garder cet exercice dans la routine ?", .spanish: "¿Quieres mantener este ejercicio en la rutina?", .italian: "Vuoi mantenere questo esercizio nella routine?", .russian: "Оставить это упражнение в программе?", .chinese: "要将这个练习保留在例程中吗？", .japanese: "この種目をルーティンに残しますか？"],
        "Möchtest du diese Übungen dauerhaft in die Routine übernehmen?": [.english: "Do you want to keep these exercises in the routine?", .french: "Veux-tu garder ces exercices dans la routine ?", .spanish: "¿Quieres mantener estos ejercicios en la rutina?", .italian: "Vuoi mantenere questi esercizi nella routine?", .russian: "Оставить эти упражнения в программе?", .chinese: "要将这些练习保留在例程中吗？", .japanese: "これらの種目をルーティンに残しますか？"],
        "Noch keine Übungen in dieser Routine.": [.english: "No exercises in this routine yet.", .french: "Aucun exercice dans cette routine.", .spanish: "Todavía no hay ejercicios en esta rutina.", .italian: "Ancora nessun esercizio in questa routine."],
        "Bearbeiten": [.english: "Edit", .french: "Modifier", .spanish: "Editar", .italian: "Modifica"],
        "Noch keine abgeschlossenen Trainings": [.english: "No completed workouts yet", .french: "Aucun entraînement terminé", .spanish: "Aún no hay entrenamientos completados", .italian: "Ancora nessun allenamento completato", .russian: "Завершённых тренировок пока нет", .chinese: "还没有完成的训练", .japanese: "完了したワークアウトはまだありません"],
        "Sobald du alle Übungen abgeschlossen hast, landet das Training hier mit Volumen, Kalorien und Sätzen.": [.english: "Once you complete all exercises, the workout appears here with volume, calories and sets.", .french: "Lorsque tous les exercices sont terminés, l’entraînement apparaît ici avec volume, calories et séries.", .spanish: "Cuando completes todos los ejercicios, el entrenamiento aparecerá aquí con volumen, calorías y series.", .italian: "Quando completi tutti gli esercizi, l’allenamento appare qui con volume, calorie e serie.", .russian: "Когда ты завершишь все упражнения, тренировка появится здесь с объёмом, калориями и подходами.", .chinese: "完成所有动作后，训练会显示在这里，并包含训练量、卡路里和组数。", .japanese: "すべての種目を完了すると、ボリューム、カロリー、セット数と一緒にここに表示されます。"],
        "Graphs": [.english: "Graphs", .french: "Graphiques", .spanish: "Gráficos", .italian: "Grafici", .russian: "Графики", .chinese: "图表", .japanese: "グラフ"],
        "Höchstwert": [.english: "Highest", .french: "Max", .spanish: "Máximo", .italian: "Massimo", .russian: "Максимум", .chinese: "最高", .japanese: "最高"],
        "Höchster": [.english: "Highest", .french: "Max", .spanish: "Máximo", .italian: "Massimo", .russian: "Максимум", .chinese: "最高", .japanese: "最高"],
        "Letzter": [.english: "Latest", .french: "Dernier", .spanish: "Último", .italian: "Ultimo", .russian: "Последний", .chinese: "最新", .japanese: "最新"],
        "Erster": [.english: "First", .french: "Premier", .spanish: "Primero", .italian: "Primo", .russian: "Первый", .chinese: "首次", .japanese: "最初"],
        "Noch kein Verlauf": [.english: "No history yet", .french: "Aucun historique", .spanish: "Sin historial", .italian: "Nessuno storico", .russian: "Истории пока нет", .chinese: "暂无历史", .japanese: "履歴はまだありません"],
        "Trainings": [.english: "Workouts", .french: "Entraînements", .spanish: "Entrenamientos", .italian: "Allenamenti", .russian: "Тренировки", .chinese: "训练", .japanese: "トレーニング"],
        "Training manuell hinzufügen": [.english: "Add workout manually", .french: "Ajouter un entraînement manuellement", .spanish: "Añadir entrenamiento manualmente", .italian: "Aggiungi allenamento manualmente", .russian: "Добавить тренировку вручную", .chinese: "手动添加训练", .japanese: "ワークアウトを手動で追加"],
        "Training nachtragen": [.english: "Log workout", .french: "Saisir un entraînement", .spanish: "Registrar entrenamiento", .italian: "Registra allenamento", .russian: "Записать тренировку", .chinese: "补记训练", .japanese: "ワークアウトを記録"],
        "Trage ein älteres Training mit Datum, Übungen und allen Sätzen ein.": [.english: "Log an older workout with its date, exercises and every set.", .french: "Saisis un ancien entraînement avec sa date, ses exercices et toutes ses séries.", .spanish: "Registra un entrenamiento anterior con fecha, ejercicios y todas las series.", .italian: "Registra un allenamento precedente con data, esercizi e tutte le serie.", .russian: "Запишите прошедшую тренировку с датой, упражнениями и всеми подходами.", .chinese: "补记以前的训练，包括日期、动作和所有组数。", .japanese: "過去のワークアウトを日付、種目、すべてのセットとともに記録します。"],
        "Datum": [.english: "Date", .french: "Date", .spanish: "Fecha", .italian: "Data", .russian: "Дата", .chinese: "日期", .japanese: "日付"],
        "Uhrzeit": [.english: "Time", .french: "Heure", .spanish: "Hora", .italian: "Ora", .russian: "Время", .chinese: "时间", .japanese: "時刻"],
        "Dauer": [.english: "Duration", .french: "Durée", .spanish: "Duración", .italian: "Durata", .russian: "Длительность", .chinese: "时长", .japanese: "時間"],
        "Kalorien optional": [.english: "Calories optional", .french: "Calories facultatives", .spanish: "Calorías opcionales", .italian: "Calorie opzionali", .russian: "Калории необязательно", .chinese: "卡路里可选", .japanese: "カロリー任意"],
        "Satz hinzufügen": [.english: "Add set", .french: "Ajouter une série", .spanish: "Añadir serie", .italian: "Aggiungi serie", .russian: "Добавить подход", .chinese: "添加组", .japanese: "セットを追加"],
        "Abbrechen": [.english: "Cancel", .french: "Annuler", .spanish: "Cancelar", .italian: "Annulla", .russian: "Отмена", .chinese: "取消", .japanese: "キャンセル"],
        "Bestes Set": [.english: "Best set", .french: "Meilleure série", .spanish: "Mejor serie", .italian: "Miglior serie"],
        "Geräteeinstellungen öffnen": [.english: "Open equipment settings", .french: "Ouvrir les réglages de l’appareil", .spanish: "Abrir ajustes del equipo", .italian: "Apri impostazioni attrezzo"],
        "Übersicht öffnen": [.english: "Open overview", .french: "Ouvrir l’aperçu", .spanish: "Abrir vista general", .italian: "Apri panoramica"],
        "Muskelverteilung": [.english: "Muscle Distribution", .french: "Répartition musculaire", .spanish: "Distribución muscular", .italian: "Distribuzione muscolare"],
        "Gesamtzeit": [.english: "Total time", .french: "Temps total", .spanish: "Tiempo total", .italian: "Tempo totale"],
        "Training abgeschlossen": [.english: "Workout completed", .french: "Entraînement terminé", .spanish: "Entrenamiento completado", .italian: "Allenamento completato"],
        "Die Einheit ist gespeichert. Dein nächstes Training startet wieder offen.": [.english: "The workout has been saved. Your next workout starts open again.", .french: "La séance est enregistrée. Le prochain entraînement recommence à zéro.", .spanish: "La sesión se guardó. Tu próximo entrenamiento empezará abierto de nuevo.", .italian: "La sessione è stata salvata. Il prossimo allenamento riparte aperto."],
        "Training bereit": [.english: "Workout ready", .french: "Entraînement prêt", .spanish: "Entrenamiento listo", .italian: "Allenamento pronto"],
        "Starte dein Training. Danach erscheint die erste Übung oben und du kannst offene Übungen durch Antippen wechseln.": [.english: "Start your workout. The first exercise will appear at the top, and you can switch open exercises by tapping them.", .french: "Démarre l’entraînement. Le premier exercice apparaît en haut et tu peux changer d’exercice ouvert en appuyant dessus.", .spanish: "Inicia el entrenamiento. El primer ejercicio aparecerá arriba y puedes cambiar ejercicios pendientes tocándolos.", .italian: "Avvia l’allenamento. Il primo esercizio appare in alto e puoi cambiare esercizio aperto toccandolo."],
        "Training starten": [.english: "Start workout", .french: "Démarrer", .spanish: "Iniciar entrenamiento", .italian: "Avvia allenamento"],
        "Training beenden": [.english: "Finish workout", .french: "Terminer", .spanish: "Finalizar entrenamiento", .italian: "Termina allenamento"],
        "Pause": [.english: "Rest", .french: "Pause", .spanish: "Descanso", .italian: "Pausa"],
        "Timer stoppen": [.english: "Stop timer", .french: "Arrêter le minuteur", .spanish: "Detener temporizador", .italian: "Ferma timer"],
        "Pause überspringen": [.english: "Skip rest", .french: "Passer la pause", .spanish: "Saltar descanso", .italian: "Salta pausa"],
        "Vorherige Leistung": [.english: "Previous Performance", .french: "Performance précédente", .spanish: "Rendimiento anterior", .italian: "Prestazione precedente"],
        "Letztes Mal": [.english: "Last time", .french: "Dernière fois", .spanish: "Última vez", .italian: "Ultima volta"],
        "Zuletzt erhöht": [.english: "Last increased", .french: "Dernière hausse", .spanish: "Último aumento", .italian: "Ultimo aumento"],
        "Letztes Gewicht": [.english: "Latest weight", .french: "Dernier poids", .spanish: "Último peso", .italian: "Ultimo peso"],
        "im letzten Training": [.english: "in the latest workout", .french: "au dernier entraînement", .spanish: "en el último entrenamiento", .italian: "nell’ultimo allenamento"],
        "seit %d Trainings": [.english: "for %d workouts", .french: "depuis %d entraînements", .spanish: "desde hace %d entrenamientos", .italian: "da %d allenamenti"],
        "Noch nicht": [.english: "Not yet", .french: "Pas encore", .spanish: "Aún no", .italian: "Non ancora"],
        "Erstes Mal in der Historie": [.english: "First time in history", .french: "Première fois dans l’historique", .spanish: "Primera vez en el historial", .italian: "Prima volta nello storico"],
        "Nach dem Abschluss siehst du hier deine letzte Leistung und Rekorde.": [.english: "After completing it, your last performance and records will appear here.", .french: "Après l’avoir terminé, ta dernière performance et tes records apparaîtront ici.", .spanish: "Después de completarlo, verás aquí tu último rendimiento y tus récords.", .italian: "Dopo averlo completato, qui vedrai ultima prestazione e record."],
        "Zeitraum": [.english: "Period", .french: "Période", .spanish: "Periodo", .italian: "Periodo"],
        "Wert": [.english: "Value", .french: "Valeur", .spanish: "Valor", .italian: "Valore"],
        "Noch kein Verlauf für diese Übung.": [.english: "No history for this exercise yet.", .french: "Aucun historique pour cet exercice.", .spanish: "Aún no hay historial para este ejercicio.", .italian: "Ancora nessuno storico per questo esercizio."],
        "Diagramm": [.english: "Chart", .french: "Graphique", .spanish: "Gráfico", .italian: "Grafico"],
        "Tippe oder streiche über das Diagramm, um einzelne Werte anzuzeigen.": [.english: "Tap or drag across the chart to inspect individual values.", .french: "Touchez ou faites glisser sur le graphique pour afficher les valeurs.", .spanish: "Toca o desliza por el gráfico para ver valores individuales.", .italian: "Tocca o trascina sul grafico per vedere i singoli valori."],
        "Übungsnotiz": [.english: "Exercise note", .french: "Note d’exercice", .spanish: "Nota del ejercicio", .italian: "Nota esercizio", .russian: "Заметка к упражнению", .chinese: "动作备注", .japanese: "種目メモ"],
        "Letzte Notiz": [.english: "Last note", .french: "Dernière note", .spanish: "Última nota", .italian: "Ultima nota"],
        "Notiz": [.english: "Note", .french: "Note", .spanish: "Nota", .italian: "Nota", .russian: "Заметка", .chinese: "备注", .japanese: "メモ"],
        "Geräteeinstellungen": [.english: "Equipment settings", .french: "Réglages de l’appareil", .spanish: "Ajustes del equipo", .italian: "Impostazioni attrezzo", .russian: "Настройки тренажёра", .chinese: "器械设置", .japanese: "器具設定"],
        "Wieder offen": [.english: "Reopen", .french: "Rouvrir", .spanish: "Reabrir", .italian: "Riapri", .russian: "Открыть снова", .chinese: "重新打开", .japanese: "再開"],
        "hinzugefügt": [.english: "added", .french: "ajouté", .spanish: "añadido", .italian: "aggiunto"],
        "Eigene Übung erstellen": [.english: "Create custom exercise", .french: "Créer un exercice", .spanish: "Crear ejercicio propio", .italian: "Crea esercizio personalizzato"],
        "Schon im Plan": [.english: "Already in plan", .french: "Déjà dans le plan", .spanish: "Ya en el plan", .italian: "Già nel piano"],
        "Noch keine Übungen hinzugefügt.": [.english: "No exercises added yet.", .french: "Aucun exercice ajouté.", .spanish: "Aún no hay ejercicios añadidos.", .italian: "Ancora nessun esercizio aggiunto."],
        "Standardgeräte": [.english: "Standard equipment", .french: "Appareils standard", .spanish: "Máquinas estándar", .italian: "Macchine standard"],
        "Übung suchen": [.english: "Search exercise", .french: "Rechercher un exercice", .spanish: "Buscar ejercicio", .italian: "Cerca esercizio"],
        "Gerät hinzufügen": [.english: "Add equipment", .french: "Ajouter un appareil", .spanish: "Añadir máquina", .italian: "Aggiungi macchina"],
        "Gerät oder Übung suchen": [.english: "Search equipment or exercise", .french: "Rechercher appareil ou exercice", .spanish: "Buscar máquina o ejercicio", .italian: "Cerca macchina o esercizio"],
        "Ansicht": [.english: "View", .french: "Vue", .spanish: "Vista", .italian: "Vista"],
        "verwendet": [.english: "used", .french: "utilisé", .spanish: "usado", .italian: "usato"],
        "in Routinen": [.english: "in routines", .french: "dans les routines", .spanish: "en rutinas", .italian: "nelle routine"],
        "im Plan": [.english: "in plan", .french: "dans le plan", .spanish: "en el plan", .italian: "nel piano"],
        "Startwerte": [.english: "Defaults", .french: "Valeurs initiales", .spanish: "Valores iniciales", .italian: "Valori iniziali"],
        "Neue Übung": [.english: "New exercise", .french: "Nouvel exercice", .spanish: "Nuevo ejercicio", .italian: "Nuovo esercizio"],
        "Hinzufügen": [.english: "Add", .french: "Ajouter", .spanish: "Añadir", .italian: "Aggiungi"],
        "Gerät": [.english: "Equipment", .french: "Appareil", .spanish: "Máquina", .italian: "Macchina"],
        "Kategorie": [.english: "Category", .french: "Catégorie", .spanish: "Categoría", .italian: "Categoria"],
        "Plan": [.english: "Plan", .french: "Plan", .spanish: "Plan", .italian: "Piano"],
        "Name der Übung": [.english: "Exercise name", .french: "Nom de l’exercice", .spanish: "Nombre del ejercicio", .italian: "Nome esercizio"],
        "Name": [.english: "Name", .french: "Nom", .spanish: "Nombre", .italian: "Nome"],
        "Ziel, z. B. 3 x 12": [.english: "Goal, e.g. 3 x 12", .french: "Objectif, p. ex. 3 x 12", .spanish: "Objetivo, p. ej. 3 x 12", .italian: "Obiettivo, es. 3 x 12"],
        "Wiederholungen": [.english: "Reps", .french: "Répétitions", .spanish: "Repeticiones", .italian: "Ripetizioni"],
        "Startgewicht": [.english: "Starting weight", .french: "Poids de départ", .spanish: "Peso inicial", .italian: "Peso iniziale"],
        "Gewicht": [.english: "Weight", .french: "Poids", .spanish: "Peso", .italian: "Peso"],
        "MET / Intensität": [.english: "MET / intensity", .french: "MET / intensité", .spanish: "MET / intensidad", .italian: "MET / intensità"],
        "Dieser Wert fließt in die Kalorienformel unter Einstellungen ein.": [.english: "This value is used in the calorie formula under Settings.", .french: "Cette valeur est utilisée dans la formule calories sous Réglages.", .spanish: "Este valor se usa en la fórmula de calorías en Ajustes.", .italian: "Questo valore viene usato nella formula calorie in Impostazioni."],
        "Optionen": [.english: "Options", .french: "Options", .spanish: "Opciones", .italian: "Opzioni"],
        "Pause nach Satz": [.english: "Rest after set", .french: "Pause après série", .spanish: "Descanso tras serie", .italian: "Pausa dopo serie"],
        "Kein Superset": [.english: "No superset", .french: "Aucun superset", .spanish: "Sin superserie", .italian: "Nessun superset"],
        "Notizen": [.english: "Notes", .french: "Notes", .spanish: "Notas", .italian: "Note"],
        "Aus Plan entfernen": [.english: "Remove from plan", .french: "Retirer du plan", .spanish: "Eliminar del plan", .italian: "Rimuovi dal piano"],
        "entfernen": [.english: "remove", .french: "retirer", .spanish: "eliminar", .italian: "rimuovi", .russian: "удалить", .chinese: "移除", .japanese: "削除"],
        "auswählen": [.english: "select", .french: "sélectionner", .spanish: "seleccionar", .italian: "seleziona"],
        "wieder öffnen": [.english: "reopen", .french: "rouvrir", .spanish: "reabrir", .italian: "riapri"],
        "Nächstes Mal Gewicht erhöhen": [.english: "Increase weight next time", .french: "Augmenter le poids la prochaine fois", .spanish: "Subir peso la próxima vez", .italian: "Aumenta il peso la prossima volta"],
        "Erfasst": [.english: "Logged", .french: "Enregistré", .spanish: "Registrado", .italian: "Registrato"],
        "Typ": [.english: "Type", .french: "Type", .spanish: "Tipo", .italian: "Tipo"],
        "Wdh": [.english: "Reps", .french: "Rép.", .spanish: "Rep.", .italian: "Rip."],
        "Keine RPE": [.english: "No RPE", .french: "Pas de RPE", .spanish: "Sin RPE", .italian: "Nessun RPE", .russian: "Без RPE", .chinese: "无 RPE", .japanese: "RPE なし"],
        "Einstellungen": [.english: "Settings", .french: "Réglages", .spanish: "Ajustes", .italian: "Impostazioni"],
        "Gerätename, z. B. Chest Press": [.english: "Equipment name, e.g. Chest Press", .french: "Nom de l’appareil, p. ex. Chest Press", .spanish: "Nombre de máquina, p. ej. Chest Press", .italian: "Nome macchina, es. Chest Press"],
        "Gerätename, z. B. Brustpresse": [.english: "Equipment name, e.g. Chest Press", .french: "Nom de l’appareil, p. ex. presse pectorale", .spanish: "Nombre de máquina, p. ej. prensa de pecho", .italian: "Nome macchina, es. pressa pettorali"],
        "Übungsname, z. B. Brustpresse": [.english: "Exercise name, e.g. Chest Press", .french: "Nom de l’exercice, p. ex. presse pectorale", .spanish: "Nombre del ejercicio, p. ej. prensa de pecho", .italian: "Nome esercizio, es. pressa pettorali"],
        "Sitzposition": [.english: "Seat position", .french: "Position du siège", .spanish: "Posición del asiento", .italian: "Posizione sedile"],
        "Rückenlehne oder Polster": [.english: "Backrest or pad", .french: "Dossier ou coussin", .spanish: "Respaldo o acolchado", .italian: "Schienale o cuscino"],
        "Griff oder Handle": [.english: "Grip or handle", .french: "Poignée", .spanish: "Agarre o asa", .italian: "Impugnatura"],
        "Bewegungsumfang": [.english: "Range of motion", .french: "Amplitude", .spanish: "Rango de movimiento", .italian: "Ampiezza movimento"],
        "Sitz": [.english: "Seat", .french: "Siège", .spanish: "Asiento", .italian: "Sedile"],
        "Lehne": [.english: "Backrest", .french: "Dossier", .spanish: "Respaldo", .italian: "Schienale"],
        "Griff": [.english: "Grip", .french: "Poignée", .spanish: "Agarre", .italian: "Impugnatura"],
        "Weg": [.english: "Range", .french: "Amplitude", .spanish: "Recorrido", .italian: "Movimento"],
        "Kein Gerät hinterlegt": [.english: "No equipment saved", .french: "Aucun appareil enregistré", .spanish: "No hay máquina guardada", .italian: "Nessuna macchina salvata"],
        "Keine Einstellungen hinterlegt": [.english: "No settings saved", .french: "Aucun réglage enregistré", .spanish: "No hay ajustes guardados", .italian: "Nessuna impostazione salvata"],
        "Technik, Ziel oder Erinnerung": [.english: "Technique, goal or reminder", .french: "Technique, objectif ou rappel", .spanish: "Técnica, objetivo o recordatorio", .italian: "Tecnica, obiettivo o promemoria"],
        "Technik, Gefühl, Schmerzen, Ziel": [.english: "Technique, feeling, pain, goal", .french: "Technique, ressenti, douleur, objectif", .spanish: "Técnica, sensación, dolor, objetivo", .italian: "Tecnica, sensazione, dolore, obiettivo"],
        "Favorit": [.english: "Favorite", .french: "Favori", .spanish: "Favorito", .italian: "Preferito"],
        "Eigene Übung": [.english: "Custom exercise", .french: "Exercice personnel", .spanish: "Ejercicio propio", .italian: "Esercizio personalizzato"],
        "Eigene Übungen": [.english: "Custom exercises", .french: "Exercices personnels", .spanish: "Ejercicios propios", .italian: "Esercizi personalizzati"],
        "Icon": [.english: "Icon", .french: "Icône", .spanish: "Icono", .italian: "Icona"],
        "Löschen": [.english: "Delete", .french: "Supprimer", .spanish: "Eliminar", .italian: "Elimina"],
        "Kabelzug Brust": [.english: "Cable chest", .french: "Presse câble", .spanish: "Pecho en polea", .italian: "Petto ai cavi"],
        "Rudern sitzend": [.english: "Seated row", .french: "Rowing assis", .spanish: "Remo sentado", .italian: "Rematore seduto"],
        "Schulterpresse": [.english: "Shoulder press", .french: "Presse épaules", .spanish: "Press hombro", .italian: "Shoulder press"],
        "Seitheben": [.english: "Lateral raise", .french: "Élévations latérales", .spanish: "Elevación lateral", .italian: "Alzate laterali"],
        "Beinpresse": [.english: "Leg press", .french: "Presse à jambes", .spanish: "Prensa de piernas", .italian: "Leg press"],
        "Beinstrecker": [.english: "Leg extension", .french: "Extension jambes", .spanish: "Extensión piernas", .italian: "Leg extension"],
        "Abduktor": [.english: "Abductor", .french: "Abducteur", .spanish: "Abductor", .italian: "Abduttore"],
        "Adduktor": [.english: "Adductor", .french: "Adducteur", .spanish: "Aductor", .italian: "Adduttore"],
        "Bizepscurl": [.english: "Biceps curl", .french: "Curl biceps", .spanish: "Curl bíceps", .italian: "Curl bicipiti"],
        "Trizepsdrücken": [.english: "Triceps press", .french: "Presse triceps", .spanish: "Press tríceps", .italian: "Pushdown tricipiti"],
        "Bauchpresse": [.english: "Ab crunch", .french: "Crunch abdominal", .spanish: "Crunch abdominal", .italian: "Crunch addominale"],
        "Laufband": [.english: "Treadmill", .french: "Tapis roulant", .spanish: "Cinta", .italian: "Tapis roulant"],
        "Fahrrad": [.english: "Bike", .french: "Vélo", .spanish: "Bicicleta", .italian: "Bici"],
        "Kurzhantelrudern": [.english: "Dumbbell row", .french: "Rowing haltère", .spanish: "Remo mancuerna", .italian: "Rematore manubrio"],
        "Kniebeuge": [.english: "Squat", .french: "Squat", .spanish: "Sentadilla", .italian: "Squat"],
        "Noch keine Übungen geplant.": [.english: "No exercises planned yet.", .french: "Aucun exercice planifié.", .spanish: "Aún no hay ejercicios planificados.", .italian: "Ancora nessun esercizio pianificato."],
        "Noch kein Training zusammengestellt": [.english: "No workout assembled yet", .french: "Aucun entraînement préparé", .spanish: "Aún no hay entrenamiento", .italian: "Nessun allenamento configurato"],
        "Öffne die Einstellungen und füge Standardgeräte zu deinem Plan hinzu.": [.english: "Open settings and add standard equipment to your plan.", .french: "Ouvre les réglages et ajoute des appareils standard à ton plan.", .spanish: "Abre los ajustes y añade máquinas estándar a tu plan.", .italian: "Apri le impostazioni e aggiungi macchine standard al piano."],
        "Satzvolumen": [.english: "Set volume", .french: "Volume de série", .spanish: "Volumen de serie", .italian: "Volume serie"],
        "Sitzungsvolumen": [.english: "Session volume", .french: "Volume de séance", .spanish: "Volumen de sesión", .italian: "Volume sessione"],
        "Höchstes Gewicht": [.english: "Highest weight", .french: "Poids maximal", .spanish: "Peso máximo", .italian: "Peso massimo"],
        "Beste Einzelwiederholung": [.english: "Best single rep", .french: "Meilleure répétition", .spanish: "Mejor repetición", .italian: "Miglior ripetizione"],
        "Bestes Sitzungsvolumen": [.english: "Best session volume", .french: "Meilleur volume de séance", .spanish: "Mejor volumen de sesión", .italian: "Miglior volume sessione"],
        "30 Tage": [.english: "30 days", .french: "30 jours", .spanish: "30 días", .italian: "30 giorni"],
        "90 Tage": [.english: "90 days", .french: "90 jours", .spanish: "90 días", .italian: "90 giorni"],
        "Alle": [.english: "All", .french: "Tous", .spanish: "Todo", .italian: "Tutto"],
        "Das Diagramm zeigt das höchste Gewicht pro Training.": [.english: "The chart shows the highest weight per workout.", .french: "Le graphique montre le poids maximal par entraînement.", .spanish: "El gráfico muestra el peso máximo por entrenamiento.", .italian: "Il grafico mostra il peso massimo per allenamento."],
        "Das Diagramm zeigt das beste Satzvolumen pro Training.": [.english: "The chart shows the best set volume per workout.", .french: "Le graphique montre le meilleur volume de série par entraînement.", .spanish: "El gráfico muestra el mejor volumen de serie por entrenamiento.", .italian: "Il grafico mostra il miglior volume serie per allenamento."],
        "Das Diagramm zeigt das Sitzungsvolumen pro Training.": [.english: "The chart shows the session volume per workout.", .french: "Le graphique montre le volume de séance par entraînement.", .spanish: "El gráfico muestra el volumen de sesión por entrenamiento.", .italian: "Il grafico mostra il volume sessione per allenamento."],
        "zuklappen": [.english: "collapse", .french: "replier", .spanish: "contraer", .italian: "chiudi"],
        "bearbeiten": [.english: "edit", .french: "modifier", .spanish: "editar", .italian: "modifica"],
        "Abgeschlossene Trainings werden als Krafttraining mit Dauer, Kalorien, Volumen und Übungszusammenfassung gespeichert.": [
            .english: "Completed workouts are saved as strength training with duration, calories, volume and an exercise summary.",
            .french: "Les entraînements terminés sont enregistrés comme musculation avec durée, calories, volume et résumé des exercices.",
            .spanish: "Los entrenamientos completados se guardan como fuerza con duración, calorías, volumen y resumen de ejercicios.",
            .italian: "Gli allenamenti completati vengono salvati come forza con durata, calorie, volume e riepilogo esercizi."
        ],
        "Kalorien = MET x Sauerstofffaktor x Körpergewicht / Divisor x Minuten": [
            .english: "Calories = MET x oxygen factor x body weight / divisor x minutes",
            .french: "Calories = MET x facteur oxygène x poids / diviseur x minutes",
            .spanish: "Calorías = MET x factor de oxígeno x peso / divisor x minutos",
            .italian: "Calorie = MET x fattore ossigeno x peso / divisore x minuti"
        ],
        "MET kommt aus der jeweiligen Übung. Minuten entstehen aus erfassten Sätzen, Zeit pro Satz und Wechselzeit.": [
            .english: "MET comes from each exercise. Minutes are based on logged sets, time per set and changeover time.",
            .french: "Le MET vient de chaque exercice. Les minutes viennent des séries enregistrées, du temps par série et des transitions.",
            .spanish: "El MET viene de cada ejercicio. Los minutos se calculan con series registradas, tiempo por serie y cambios.",
            .italian: "Il MET viene da ogni esercizio. I minuti derivano da serie registrate, tempo per serie e cambio."
        ],
        "Die App ist kostenlos und soll es bleiben. Ein freiwilliger Beitrag unterstützt die Weiterentwicklung und hilft, laufende Kosten wie Testgeräte und den Apple Developer Account zu decken. Vielen Dank für deine Unterstützung.": [
            .english: "The app is free and intended to stay that way. A voluntary contribution supports further development and helps cover ongoing costs such as test devices and the Apple Developer account. Thank you for your support.",
            .french: "L’app est gratuite et doit le rester. Une contribution volontaire soutient le développement et aide à couvrir les coûts récurrents comme les appareils de test et le compte Apple Developer. Merci pour votre soutien.",
            .spanish: "La app es gratuita y está pensada para seguir siéndolo. Una contribución voluntaria apoya el desarrollo y ayuda a cubrir costes recurrentes como dispositivos de prueba y la cuenta Apple Developer. Gracias por tu apoyo.",
            .italian: "L’app è gratuita e dovrebbe restarlo. Un contributo volontario sostiene lo sviluppo e aiuta a coprire costi continui come dispositivi di test e account Apple Developer. Grazie per il supporto."
        ],
        "Deine Trainingsdaten bleiben in der App auf deinem Gerät. Export, Import und verbundene Schnittstellen laufen nur, wenn du sie aktiv nutzt.": [
            .english: "Your workout data stays in the app on your device. Export, import and connected interfaces run only when you actively use them.",
            .french: "Tes données d’entraînement restent dans l’app sur ton appareil. L’export, l’import et les interfaces connectées ne fonctionnent que si tu les utilises activement.",
            .spanish: "Tus datos de entrenamiento permanecen en la app en tu dispositivo. La exportación, la importación y las interfaces conectadas solo funcionan cuando las usas activamente.",
            .italian: "I tuoi dati di allenamento restano nell’app sul tuo dispositivo. Esportazione, importazione e interfacce collegate funzionano solo quando le usi attivamente."
        ],
        "GymPit hilft dir, Trainings, Übungen, Sätze, Pausen und Fortschritt festzuhalten.": [
            .english: "GymPit helps you track workouts, exercises, sets, rests and progress.",
            .french: "GymPit t’aide à suivre entraînements, exercices, séries, pauses et progression.",
            .spanish: "GymPit te ayuda a registrar entrenamientos, ejercicios, series, descansos y progreso.",
            .italian: "GymPit ti aiuta a tenere traccia di allenamenti, esercizi, serie, pause e progressi."
        ],
        "Die App ist kostenlos. Sie speichert keine Daten auf einem fremden Server und braucht kein Konto. Deine Trainingsdaten bleiben lokal auf deinem Gerät, außer du exportierst sie oder verbindest freiwillig Apple Health beziehungsweise HealthPit.": [
            .english: "The app is free. It does not store data on an external server and does not require an account. Your workout data stays local on your device unless you export it or voluntarily connect Apple Health or HealthPit.",
            .french: "L’app est gratuite. Elle ne stocke aucune donnée sur un serveur externe et ne nécessite pas de compte. Tes données d’entraînement restent localement sur ton appareil, sauf si tu les exportes ou connectes volontairement Apple Health ou HealthPit.",
            .spanish: "La app es gratuita. No almacena datos en un servidor externo y no requiere cuenta. Tus datos de entrenamiento permanecen localmente en tu dispositivo, salvo que los exportes o conectes voluntariamente Apple Health o HealthPit.",
            .italian: "L’app è gratuita. Non salva dati su un server esterno e non richiede un account. I tuoi dati di allenamento restano localmente sul dispositivo, salvo esportazione o collegamento volontario ad Apple Health o HealthPit."
        ],
        "Hier findest du Maschinen, Kabelzüge und Cardiogeräte aus deinen Routinen sowie den Gerätekatalog.": [
            .english: "Find machines, cable stations and cardio equipment from your routines, along with the equipment catalog.",
            .french: "Retrouve les machines, poulies et appareils cardio de tes routines ainsi que le catalogue d’appareils.",
            .spanish: "Encuentra máquinas, poleas y equipos de cardio de tus rutinas, además del catálogo de máquinas.",
            .italian: "Trova macchine, cavi e attrezzi cardio delle tue routine insieme al catalogo delle macchine."
        ],
        "Hier findest du freie Übungen mit Körpergewicht, Kurz-, Langhantel oder Kettlebell und kannst eigene Übungen anlegen.": [
            .english: "Find free exercises using bodyweight, dumbbells, barbells or kettlebells, and create your own exercises.",
            .french: "Retrouve les exercices libres au poids du corps, avec haltères, barre ou kettlebell, et crée tes propres exercices.",
            .spanish: "Encuentra ejercicios libres con peso corporal, mancuernas, barra o kettlebell y crea tus propios ejercicios.",
            .italian: "Trova esercizi liberi a corpo libero, con manubri, bilanciere o kettlebell e crea i tuoi esercizi."
        ]
    ]

    private static let additionalUITexts: [String: [AppLanguage: String]] = [
        "Ergibt sich aus der Muskelgruppe.": [.english: "Taken from the muscle group.", .french: "Repris du groupe musculaire.", .spanish: "Se toma del grupo muscular.", .italian: "Deriva dal gruppo muscolare.", .russian: "Определяется группой мышц.", .chinese: "由肌肉群决定。", .japanese: "筋肉グループから決まります。"],
        "Jetzt beenden": [.english: "Finish now", .french: "Terminer", .spanish: "Finalizar ahora", .italian: "Termina ora", .russian: "Завершить", .chinese: "立即结束", .japanese: "終了する"],
        "Die Einheit wird gespeichert und der Plan wieder auf offen gesetzt.": [.english: "The session is saved and the plan is reset to open.", .french: "La séance est enregistrée et le plan repasse en ouvert.", .spanish: "La sesión se guarda y el plan vuelve a estar abierto.", .italian: "La sessione viene salvata e il piano torna aperto.", .russian: "Тренировка сохраняется, а план снова открывается.", .chinese: "本次训练将被保存，计划重置为未完成。", .japanese: "セッションを保存し、プランを未完了に戻します。"],
        "Noch keine Daten": [.english: "No data yet", .french: "Pas encore de données", .spanish: "Aún no hay datos", .italian: "Ancora nessun dato", .russian: "Пока нет данных", .chinese: "暂无数据", .japanese: "データがありません"],
        "Pause, Kalorien, Körpergewicht": [.english: "Rest, calories, body weight", .french: "Repos, calories, poids", .spanish: "Descanso, calorías, peso", .italian: "Recupero, calorie, peso", .russian: "Отдых, калории, вес", .chinese: "休息、卡路里、体重", .japanese: "休憩・カロリー・体重"],
        "Design, Sprache, Einheit": [.english: "Design, language, unit", .french: "Design, langue, unité", .spanish: "Diseño, idioma, unidad", .italian: "Design, lingua, unità", .russian: "Оформление, язык, единицы", .chinese: "外观、语言、单位", .japanese: "デザイン・言語・単位"],
        "Health, Home Assistant, CSV": [.english: "Health, Home Assistant, CSV", .french: "Health, Home Assistant, CSV", .spanish: "Health, Home Assistant, CSV", .italian: "Health, Home Assistant, CSV", .russian: "Health, Home Assistant, CSV", .chinese: "Health、Home Assistant、CSV", .japanese: "Health・Home Assistant・CSV"],
        "Training": [.russian: "Тренировка", .chinese: "训练", .japanese: "トレーニング"],
        "Routinen": [.russian: "Программы", .chinese: "训练计划", .japanese: "ルーティン"],
        "Historie": [.russian: "История", .chinese: "历史", .japanese: "履歴"],
        "Mehr": [.russian: "Ещё", .chinese: "更多", .japanese: "その他"],
        "App": [.russian: "Приложение", .chinese: "App", .japanese: "アプリ"],
        "Training und Geräte": [.russian: "Тренировка и оборудование", .chinese: "训练与器械", .japanese: "トレーニングと器具"],
        "App und Daten": [.russian: "Приложение и данные", .chinese: "App 与数据", .japanese: "アプリとデータ"],
        "Infos": [.russian: "Инфо", .chinese: "信息", .japanese: "情報"],
        "Schnittstellen / API": [.russian: "Интерфейсы / API", .chinese: "接口 / API", .japanese: "連携 / API"],
        "Daten": [.russian: "Данные", .chinese: "数据", .japanese: "データ"],
        "Daten / Schnittstellen": [.russian: "Данные / интерфейсы", .chinese: "数据 / 接口", .japanese: "データ / 連携"],
        "Geräte": [.russian: "Тренажёры", .chinese: "器械", .japanese: "器具"],
        "Geräte und Übungen": [.russian: "Тренажёры и упражнения", .chinese: "器械和动作", .japanese: "器具と種目"],
        "Über": [.russian: "О приложении", .chinese: "关于", .japanese: "このアプリについて"],
        "Datenschutz und Kosten": [.russian: "Конфиденциальность и стоимость", .chinese: "隐私与费用", .japanese: "プライバシーと費用"],
        "Darstellung": [.russian: "Внешний вид", .chinese: "外观", .japanese: "表示"],
        "Sprache": [.russian: "Язык", .chinese: "语言", .japanese: "言語"],
        "Modus": [.russian: "Режим", .chinese: "模式", .japanese: "モード"],
        "Hell": [.russian: "Светлый", .chinese: "浅色", .japanese: "ライト"],
        "Dunkel": [.russian: "Тёмный", .chinese: "深色", .japanese: "ダーク"],
        "Design": [.russian: "Дизайн", .chinese: "设计", .japanese: "デザイン"],
        "Blau": [.russian: "Синий", .chinese: "蓝色", .japanese: "青"],
        "Türkis": [.russian: "Бирюзовый", .chinese: "青绿色", .japanese: "ターコイズ"],
        "Graphit": [.russian: "Графит", .chinese: "石墨色", .japanese: "グラファイト"],
        "Grün": [.russian: "Зелёный", .chinese: "绿色", .japanese: "緑"],
        "Orange": [.russian: "Оранжевый", .chinese: "橙色", .japanese: "オレンジ"],
        "Violett": [.russian: "Фиолетовый", .chinese: "紫色", .japanese: "バイオレット"],
        "Rot": [.russian: "Красный", .chinese: "红色", .japanese: "赤"],
        "Einheiten": [.russian: "Единицы", .chinese: "单位", .japanese: "単位"],
        "Gewichtseinheit": [.russian: "Единица веса", .chinese: "重量单位", .japanese: "重量単位"],
        "Kilogramm": [.russian: "Килограммы", .chinese: "公斤", .japanese: "キログラム"],
        "Pfund": [.russian: "Фунты", .chinese: "磅", .japanese: "ポンド"],
        "Wird sofort auf die App angewendet.": [.russian: "Сразу применяется в приложении.", .chinese: "会立即应用到 App。", .japanese: "すぐにアプリへ適用されます。"],
        "Apple Health": [.russian: "Apple Health", .chinese: "Apple 健康", .japanese: "Appleヘルスケア"],
        "Apple Health verbinden": [.russian: "Подключить Apple Health", .chinese: "连接 Apple 健康", .japanese: "Appleヘルスケアに接続"],
        "Alle alten Workouts übertragen": [.russian: "Передать все старые тренировки", .chinese: "传输所有旧训练", .japanese: "過去のワークアウトをすべて転送"],
        "HealthPit": [.russian: "HealthPit", .chinese: "HealthPit", .japanese: "HealthPit"],
        "Lokale Verbindung verwenden": [.russian: "Использовать локальное подключение", .chinese: "使用本地连接", .japanese: "ローカル接続を使用"],
        "Lokaler Host oder IP": [.russian: "Локальный хост или IP", .chinese: "本地主机或 IP", .japanese: "ローカルホストまたはIP"],
        "Lokaler Port": [.russian: "Локальный порт", .chinese: "本地端口", .japanese: "ローカルポート"],
        "Benutzername": [.russian: "Имя пользователя", .chinese: "用户名", .japanese: "ユーザー名"],
        "Gerätename": [.russian: "Имя устройства", .chinese: "设备名称", .japanese: "デバイス名"],
        "API Token": [.russian: "API-токен", .chinese: "API 令牌", .japanese: "APIトークン"],
        "HealthPit verbinden": [.russian: "Подключить HealthPit", .chinese: "连接 HealthPit", .japanese: "HealthPitに接続"],
        "Verbindung trennen": [.russian: "Отключить", .chinese: "断开连接", .japanese: "接続を解除"],
        "HealthPit verbindet...": [.russian: "Подключение к HealthPit...", .chinese: "正在连接 HealthPit...", .japanese: "HealthPitに接続中..."],
        "HealthPit ist verbunden": [.russian: "HealthPit подключён", .chinese: "HealthPit 已连接", .japanese: "HealthPitに接続済み"],
        "HealthPit ist nicht verbunden": [.russian: "HealthPit не подключён", .chinese: "HealthPit 未连接", .japanese: "HealthPit未接続"],
        "HealthPit Verbindung Fehler": [.russian: "Ошибка подключения HealthPit", .chinese: "HealthPit 连接错误", .japanese: "HealthPit接続エラー"],
        "Alle Trainings zu HealthPit übertragen": [.russian: "Передать все тренировки в HealthPit", .chinese: "将所有训练传输到 HealthPit", .japanese: "すべてのワークアウトをHealthPitへ転送"],
        "Kalorien": [.russian: "Калории", .chinese: "卡路里", .japanese: "カロリー"],
        "Körpergewicht": [.russian: "Вес тела", .chinese: "体重", .japanese: "体重"],
        "Zeit pro Satz inkl. Pause": [.russian: "Время на подход с отдыхом", .chinese: "每组时间含休息", .japanese: "休憩込みのセット時間"],
        "Wechselzeit pro Übung": [.russian: "Переход между упражнениями", .chinese: "每个动作的切换时间", .japanese: "種目ごとの切替時間"],
        "Standardpause": [.russian: "Стандартный отдых", .chinese: "默认休息", .japanese: "標準休憩"],
        "Kalorienformel": [.russian: "Формула калорий", .chinese: "卡路里公式", .japanese: "カロリー計算式"],
        "Sauerstofffaktor": [.russian: "Кислородный коэффициент", .chinese: "氧气系数", .japanese: "酸素係数"],
        "Divisor": [.russian: "Делитель", .chinese: "除数", .japanese: "除数"],
        "CSV": [.russian: "CSV", .chinese: "CSV", .japanese: "CSV"],
        "Trainings exportieren": [.russian: "Экспортировать тренировки", .chinese: "导出训练", .japanese: "ワークアウトを書き出す"],
        "Trainings importieren": [.russian: "Импортировать тренировки", .chinese: "导入训练", .japanese: "ワークアウトを読み込む"],
        "Trainings und Routinen exportieren": [.russian: "Экспорт тренировок и программ", .chinese: "导出训练和训练计划", .japanese: "ワークアウトとルーティンを書き出す"],
        "Trainings und Routinen importieren": [.russian: "Импорт тренировок и программ", .chinese: "导入训练和训练计划", .japanese: "ワークアウトとルーティンを読み込む"],
        "Import läuft...": [.russian: "Идёт импорт...", .chinese: "正在导入...", .japanese: "読み込み中..."],
        "Unterstützen": [.russian: "Поддержать", .chinese: "支持", .japanese: "応援"],
        "Kleiner Kaffee": [.russian: "Маленький кофе", .chinese: "小杯咖啡", .japanese: "小さなコーヒー"],
        "Unterstützer": [.russian: "Поддержка", .chinese: "支持者", .japanese: "サポーター"],
        "Große Unterstützung": [.russian: "Большая поддержка", .chinese: "大力支持", .japanese: "大きな応援"],
        "Projekt fördern": [.russian: "Поддержать проект", .chinese: "资助项目", .japanese: "プロジェクト支援"],
        "Fertig": [.russian: "Готово", .chinese: "完成", .japanese: "完了"],
        "Sichern": [.russian: "Сохранить", .chinese: "保存", .japanese: "保存"],
        "OK": [.russian: "OK", .chinese: "OK", .japanese: "OK"],
        "Offen": [.russian: "Открыто", .chinese: "未完成", .japanese: "未完了"],
        "Erledigt": [.russian: "Выполнено", .chinese: "已完成", .japanese: "完了済み"],
        "offen": [.russian: "открыто", .chinese: "未完成", .japanese: "未完了"],
        "erledigt": [.russian: "выполнено", .chinese: "已完成", .japanese: "完了済み"],
        "Übungen": [.russian: "Упражнения", .chinese: "动作", .japanese: "種目"],
        "Übung": [.russian: "Упражнение", .chinese: "动作", .japanese: "種目"],
        "Sätze": [.russian: "Подходы", .chinese: "组", .japanese: "セット"],
        "Satz": [.russian: "Подход", .chinese: "组", .japanese: "セット"],
        "Volumen": [.russian: "Объём", .chinese: "训练量", .japanese: "ボリューム"],
        "Zeit": [.russian: "Время", .chinese: "时间", .japanese: "時間"],
        "Rekorde": [.russian: "Рекорды", .chinese: "纪录", .japanese: "記録"],
        "Rekord": [.russian: "Рекорд", .chinese: "纪录", .japanese: "記録"],
        "Aktiv": [.russian: "Активно", .chinese: "当前", .japanese: "有効"],
        "Aktuell": [.russian: "Текущее", .chinese: "当前", .japanese: "現在"],
        "Aktive Routine": [.russian: "Активная программа", .chinese: "当前计划", .japanese: "現在のルーティン"],
        "Neue Routine erstellen": [.russian: "Создать программу", .chinese: "创建新计划", .japanese: "新しいルーティンを作成"],
        "Als aktive Routine verwenden": [.russian: "Сделать активной", .chinese: "设为当前计划", .japanese: "現在のルーティンにする"],
        "Standardroutine": [.russian: "Программа по умолчанию", .chinese: "默认计划", .japanese: "標準ルーティン"],
        "Als Standard favorisieren": [.russian: "Сделать стандартной", .chinese: "设为默认", .japanese: "標準に設定"],
        "Routine": [.russian: "Программа", .chinese: "计划", .japanese: "ルーティン"],
        "Ziel": [.russian: "Цель", .chinese: "目标", .japanese: "目標"],
        "Alle Übungen": [.russian: "Все упражнения", .chinese: "所有动作", .japanese: "すべての種目"],
        "Übungsanzahl": [.russian: "Количество упражнений", .chinese: "动作数量", .japanese: "種目数"],
        "Gesamtvolumen": [.russian: "Общий объём", .chinese: "总训练量", .japanese: "総ボリューム"],
        "Trainingszeit": [.russian: "Время тренировки", .chinese: "训练时间", .japanese: "トレーニング時間"],
        "Satzanzahl": [.russian: "Количество подходов", .chinese: "组数", .japanese: "セット数"],
        "Übung hinzufügen": [.russian: "Добавить упражнение", .chinese: "添加动作", .japanese: "種目を追加"],
        "Bearbeiten": [.russian: "Изменить", .chinese: "编辑", .japanese: "編集"],
        "Trainings": [.russian: "Тренировки", .chinese: "训练", .japanese: "ワークアウト"],
        "Bestes Set": [.russian: "Лучший подход", .chinese: "最佳组", .japanese: "ベストセット"],
        "Geräteeinstellungen öffnen": [.russian: "Открыть настройки тренажёра", .chinese: "打开器械设置", .japanese: "器具設定を開く"],
        "Übersicht öffnen": [.russian: "Открыть обзор", .chinese: "打开概览", .japanese: "概要を開く"],
        "Muskelverteilung": [.russian: "Распределение мышц", .chinese: "肌群分布", .japanese: "筋肉分布"],
        "Gesamtzeit": [.russian: "Общее время", .chinese: "总时间", .japanese: "合計時間"],
        "Training abgeschlossen": [.russian: "Тренировка завершена", .chinese: "训练完成", .japanese: "トレーニング完了"],
        "Training bereit": [.russian: "Тренировка готова", .chinese: "训练已准备", .japanese: "トレーニング準備完了"],
        "Training starten": [.russian: "Начать тренировку", .chinese: "开始训练", .japanese: "開始"],
        "Training beenden": [.russian: "Завершить тренировку", .chinese: "结束训练", .japanese: "終了"],
        "Pause": [.russian: "Отдых", .chinese: "休息", .japanese: "休憩"],
        "Pause überspringen": [.russian: "Пропустить отдых", .chinese: "跳过休息", .japanese: "休憩をスキップ"],
        "Vorherige Leistung": [.russian: "Предыдущий результат", .chinese: "上次表现", .japanese: "前回の記録"],
        "Letztes Mal": [.russian: "В прошлый раз", .chinese: "上次", .japanese: "前回"],
        "Zeitraum": [.russian: "Период", .chinese: "时间范围", .japanese: "期間"],
        "Wert": [.russian: "Значение", .chinese: "数值", .japanese: "値"],
        "Diagramm": [.russian: "График", .chinese: "图表", .japanese: "グラフ"],
        "Tippe oder streiche über das Diagramm, um einzelne Werte anzuzeigen.": [.russian: "Нажмите или проведите по графику, чтобы посмотреть отдельные значения.", .chinese: "点击或在图表上拖动以查看各个数值。", .japanese: "グラフをタップまたはドラッグして各値を確認できます。"],
        "Eigene Übung erstellen": [.russian: "Создать своё упражнение", .chinese: "创建自定义动作", .japanese: "カスタム種目を作成"],
        "Schon im Plan": [.russian: "Уже в плане", .chinese: "已在计划中", .japanese: "すでにプラン内"],
        "Standardgeräte": [.russian: "Стандартные тренажёры", .chinese: "标准器械", .japanese: "標準器具"],
        "Übung suchen": [.russian: "Искать упражнение", .chinese: "搜索动作", .japanese: "種目を検索"],
        "Gerät hinzufügen": [.russian: "Добавить тренажёр", .chinese: "添加器械", .japanese: "器具を追加"],
        "Gerät oder Übung suchen": [.russian: "Искать тренажёр или упражнение", .chinese: "搜索器械或动作", .japanese: "器具または種目を検索"],
        "Ansicht": [.russian: "Вид", .chinese: "视图", .japanese: "表示"],
        "Startwerte": [.russian: "Начальные значения", .chinese: "初始值", .japanese: "初期値"],
        "Neue Übung": [.russian: "Новое упражнение", .chinese: "新动作", .japanese: "新しい種目"],
        "Hinzufügen": [.russian: "Добавить", .chinese: "添加", .japanese: "追加"],
        "Gerät": [.russian: "Тренажёр", .chinese: "器械", .japanese: "器具"],
        "Kategorie": [.russian: "Категория", .chinese: "类别", .japanese: "カテゴリ"],
        "Plan": [.russian: "План", .chinese: "计划", .japanese: "プラン"],
        "Name der Übung": [.russian: "Название упражнения", .chinese: "动作名称", .japanese: "種目名"],
        "Name": [.russian: "Название", .chinese: "名称", .japanese: "名前"],
        "Ziel, z. B. 3 x 12": [.russian: "Цель, напр. 3 x 12", .chinese: "目标，例如 3 x 12", .japanese: "目標、例: 3 x 12"],
        "Wiederholungen": [.russian: "Повторения", .chinese: "次数", .japanese: "回数"],
        "Startgewicht": [.russian: "Начальный вес", .chinese: "起始重量", .japanese: "開始重量"],
        "Gewicht": [.russian: "Вес", .chinese: "重量", .japanese: "重量"],
        "MET / Intensität": [.russian: "MET / интенсивность", .chinese: "MET / 强度", .japanese: "MET / 強度"],
        "Optionen": [.russian: "Параметры", .chinese: "选项", .japanese: "オプション"],
        "Pause nach Satz": [.russian: "Отдых после подхода", .chinese: "组后休息", .japanese: "セット後の休憩"],
        "Notizen": [.russian: "Заметки", .chinese: "备注", .japanese: "メモ"],
        "Aus Plan entfernen": [.russian: "Удалить из плана", .chinese: "从计划移除", .japanese: "プランから削除"],
        "Nächstes Mal Gewicht erhöhen": [.russian: "В следующий раз увеличить вес", .chinese: "下次增加重量", .japanese: "次回重量を増やす"],
        "Erfasst": [.russian: "Записано", .chinese: "已记录", .japanese: "記録済み"],
        "Typ": [.russian: "Тип", .chinese: "类型", .japanese: "タイプ"],
        "Wdh": [.russian: "Повт.", .chinese: "次数", .japanese: "回数"],
        "Einstellungen": [.russian: "Настройки", .chinese: "设置", .japanese: "設定"],
        "Gerätename, z. B. Chest Press": [.russian: "Название тренажёра, напр. Chest Press", .chinese: "器械名称，例如 Chest Press", .japanese: "器具名、例: Chest Press"],
        "Gerätename, z. B. Brustpresse": [.russian: "Название тренажёра, напр. жим от груди", .chinese: "器械名称，例如推胸机", .japanese: "器具名、例: チェストプレス"],
        "Übungsname, z. B. Brustpresse": [.russian: "Название упражнения, напр. жим от груди", .chinese: "动作名称，例如推胸", .japanese: "種目名、例: チェストプレス"],
        "Sitzposition": [.russian: "Положение сиденья", .chinese: "座椅位置", .japanese: "シート位置"],
        "Rückenlehne oder Polster": [.russian: "Спинка или подушка", .chinese: "靠背或垫子", .japanese: "背もたれまたはパッド"],
        "Griff oder Handle": [.russian: "Хват или ручка", .chinese: "握把", .japanese: "グリップまたはハンドル"],
        "Bewegungsumfang": [.russian: "Амплитуда движения", .chinese: "动作幅度", .japanese: "可動域"],
        "Sitz": [.russian: "Сиденье", .chinese: "座椅", .japanese: "シート"],
        "Lehne": [.russian: "Спинка", .chinese: "靠背", .japanese: "背もたれ"],
        "Griff": [.russian: "Хват", .chinese: "握把", .japanese: "グリップ"],
        "Weg": [.russian: "Амплитуда", .chinese: "幅度", .japanese: "可動域"],
        "Kein Gerät hinterlegt": [.russian: "Тренажёр не сохранён", .chinese: "未保存器械", .japanese: "器具が保存されていません"],
        "Keine Einstellungen hinterlegt": [.russian: "Настройки не сохранены", .chinese: "未保存设置", .japanese: "設定が保存されていません"],
        "Technik, Ziel oder Erinnerung": [.russian: "Техника, цель или напоминание", .chinese: "技巧、目标或提醒", .japanese: "フォーム、目標、メモ"],
        "Technik, Gefühl, Schmerzen, Ziel": [.russian: "Техника, ощущения, боль, цель", .chinese: "技巧、感觉、疼痛、目标", .japanese: "フォーム、感覚、痛み、目標"],
        "Favorit": [.russian: "Избранное", .chinese: "收藏", .japanese: "お気に入り"],
        "Eigene Übung": [.russian: "Своё упражнение", .chinese: "自定义动作", .japanese: "カスタム種目"],
        "Eigene Übungen": [.russian: "Свои упражнения", .chinese: "自定义动作", .japanese: "カスタム種目"],
        "Icon": [.russian: "Иконка", .chinese: "图标", .japanese: "アイコン"],
        "Löschen": [.russian: "Удалить", .chinese: "删除", .japanese: "削除"],
        "Kabelzug Brust": [.russian: "Жим в кроссовере", .chinese: "绳索推胸", .japanese: "ケーブルチェスト"],
        "Rudern sitzend": [.russian: "Тяга сидя", .chinese: "坐姿划船", .japanese: "シーテッドロー"],
        "Schulterpresse": [.russian: "Жим плечами", .chinese: "肩推", .japanese: "ショルダープレス"],
        "Seitheben": [.russian: "Махи в стороны", .chinese: "侧平举", .japanese: "サイドレイズ"],
        "Beinpresse": [.russian: "Жим ногами", .chinese: "腿举", .japanese: "レッグプレス"],
        "Beinstrecker": [.russian: "Разгибание ног", .chinese: "腿屈伸", .japanese: "レッグエクステンション"],
        "Abduktor": [.russian: "Отведение бедра", .chinese: "髋外展", .japanese: "アブダクター"],
        "Adduktor": [.russian: "Приведение бедра", .chinese: "髋内收", .japanese: "アダクター"],
        "Bizepscurl": [.russian: "Сгибание на бицепс", .chinese: "二头弯举", .japanese: "バイセップスカール"],
        "Trizepsdrücken": [.russian: "Жим на трицепс", .chinese: "三头下压", .japanese: "トライセップスプレス"],
        "Bauchpresse": [.russian: "Скручивание", .chinese: "卷腹机", .japanese: "アブクランチ"],
        "Laufband": [.russian: "Беговая дорожка", .chinese: "跑步机", .japanese: "トレッドミル"],
        "Fahrrad": [.russian: "Велотренажёр", .chinese: "单车", .japanese: "バイク"],
        "Kurzhantelrudern": [.russian: "Тяга гантели", .chinese: "哑铃划船", .japanese: "ダンベルロー"],
        "Kniebeuge": [.russian: "Присед", .chinese: "深蹲", .japanese: "スクワット"],
        "Satzvolumen": [.russian: "Объём подхода", .chinese: "单组训练量", .japanese: "セットボリューム"],
        "Höchstes Gewicht": [.russian: "Максимальный вес", .chinese: "最高重量", .japanese: "最高重量"],
        "Beste Einzelwiederholung": [.russian: "Лучшее одноповторное", .chinese: "最佳单次", .japanese: "最高推定1回"],
        "Bestes Sitzungsvolumen": [.russian: "Лучший объём сессии", .chinese: "最佳训练总量", .japanese: "最高セッションボリューム"],
        "Sitzungsvolumen": [.russian: "Объём сессии", .chinese: "训练总量", .japanese: "セッションボリューム"],
        "30 Tage": [.russian: "30 дней", .chinese: "30天", .japanese: "30日"],
        "90 Tage": [.russian: "90 дней", .chinese: "90天", .japanese: "90日"],
        "Alle": [.russian: "Все", .chinese: "全部", .japanese: "すべて"],
        "Zuletzt erhöht": [.russian: "Последнее увеличение", .chinese: "最近增加", .japanese: "最後の増量"],
        "Letztes Gewicht": [.russian: "Последний вес", .chinese: "最近重量", .japanese: "最新の重量"],
        "im letzten Training": [.russian: "на последней тренировке", .chinese: "在最近一次训练中", .japanese: "前回のトレーニングで"],
        "seit %d Trainings": [.russian: "%d тренировок подряд", .chinese: "连续%d次训练", .japanese: "%d回のトレーニング連続"],
        "Noch nicht": [.russian: "Пока нет", .chinese: "还没有", .japanese: "まだなし"],
        "Das Diagramm zeigt das Sitzungsvolumen pro Training.": [.russian: "График показывает объём сессии за тренировку.", .chinese: "图表显示每次训练的训练总量。", .japanese: "グラフは各ワークアウトのセッションボリュームを表示します。"],
        "zuklappen": [.russian: "свернуть", .chinese: "收起", .japanese: "折りたたむ"],
        "bearbeiten": [.russian: "редактировать", .chinese: "编辑", .japanese: "編集"],
        "Deine Trainingsdaten bleiben in der App auf deinem Gerät. Export, Import und verbundene Schnittstellen laufen nur, wenn du sie aktiv nutzt.": [
            .russian: "Ваши тренировочные данные остаются в приложении на вашем устройстве. Экспорт, импорт и подключённые интерфейсы работают только тогда, когда вы используете их сами.",
            .chinese: "你的训练数据会保留在设备上的 App 内。导出、导入和已连接接口只会在你主动使用时运行。",
            .japanese: "トレーニングデータは端末上のアプリ内に残ります。書き出し、読み込み、連携機能は自分で使ったときだけ動作します。"
        ],
        "GymPit hilft dir, Trainings, Übungen, Sätze, Pausen und Fortschritt festzuhalten.": [
            .russian: "GymPit помогает отслеживать тренировки, упражнения, подходы, отдых и прогресс.",
            .chinese: "GymPit 帮你记录训练、动作、组数、休息和进步。",
            .japanese: "GymPitはワークアウト、種目、セット、休憩、進捗の記録を助けます。"
        ],
        "Die App ist kostenlos. Sie speichert keine Daten auf einem fremden Server und braucht kein Konto. Deine Trainingsdaten bleiben lokal auf deinem Gerät, außer du exportierst sie oder verbindest freiwillig Apple Health beziehungsweise HealthPit.": [
            .russian: "Приложение бесплатное. Оно не хранит данные на внешнем сервере и не требует аккаунта. Ваши тренировочные данные остаются локально на устройстве, если вы сами не экспортируете их или добровольно не подключите Apple Health либо HealthPit.",
            .chinese: "这款 App 免费。它不会把数据存到外部服务器，也不需要账号。你的训练数据会保留在本机，除非你主动导出，或自愿连接 Apple 健康或 HealthPit。",
            .japanese: "このアプリは無料です。外部サーバーにデータを保存せず、アカウントも不要です。書き出しを行うか、AppleヘルスケアまたはHealthPitを自分で接続しない限り、トレーニングデータは端末内に残ります。"
        ],
        "Hier findest du Maschinen, Kabelzüge und Cardiogeräte aus deinen Routinen sowie den Gerätekatalog.": [
            .russian: "Здесь находятся тренажёры, блочные станции и кардиооборудование из ваших программ, а также каталог оборудования.",
            .chinese: "在这里可以查看训练计划中的固定器械、绳索器械和有氧设备，以及器械目录。",
            .japanese: "ルーティン内のマシン、ケーブル、有酸素運動器具と器具カタログを確認できます。"
        ],
        "Hier findest du freie Übungen mit Körpergewicht, Kurz-, Langhantel oder Kettlebell und kannst eigene Übungen anlegen.": [
            .russian: "Здесь находятся свободные упражнения с весом тела, гантелями, штангой или гирей, а также можно создавать свои упражнения.",
            .chinese: "在这里可以查看自重、哑铃、杠铃或壶铃自由训练动作，并创建自定义动作。",
            .japanese: "自重、ダンベル、バーベル、ケトルベルを使うフリー種目を確認し、カスタム種目を作成できます。"
        ],
        "Die App ist kostenlos und soll es bleiben. Ein freiwilliger Beitrag unterstützt die Weiterentwicklung und hilft, laufende Kosten wie Testgeräte und den Apple Developer Account zu decken. Vielen Dank für deine Unterstützung.": [
            .russian: "Приложение бесплатное и должно таким оставаться. Добровольный вклад поддерживает дальнейшую разработку и помогает покрывать текущие расходы, например тестовые устройства и аккаунт Apple Developer. Спасибо за поддержку.",
            .chinese: "这款 App 免费，并且希望一直如此。自愿支持可以帮助继续开发，并承担测试设备和 Apple Developer 账号等持续费用。感谢你的支持。",
            .japanese: "このアプリは無料で、今後もそうありたいと考えています。任意の支援は今後の開発や、テスト端末、Apple Developerアカウントなどの継続費用に役立ちます。応援ありがとうございます。"
        ],
        "Unterstützung wird geladen...": [.russian: "Загрузка вариантов поддержки…", .chinese: "正在加载支持选项…", .japanese: "応援オプションを読み込み中…"],
        "Unterstützung ist momentan nicht verfügbar.": [.russian: "Поддержка сейчас недоступна.", .chinese: "支持功能目前不可用。", .japanese: "応援機能は現在利用できません。"],
        "Unterstützung konnte nicht geladen werden.": [.russian: "Не удалось загрузить варианты поддержки.", .chinese: "无法加载支持选项。", .japanese: "応援オプションを読み込めませんでした。"],
        "Erneut laden": [.russian: "Повторить", .chinese: "重试", .japanese: "再読み込み"],
        "Dieser Kauf ist noch nicht verfügbar.": [.russian: "Эта покупка пока недоступна.", .chinese: "此购买项目尚不可用。", .japanese: "この購入はまだ利用できません。"],
        "Danke für deine Unterstützung.": [.russian: "Спасибо за поддержку.", .chinese: "感谢你的支持。", .japanese: "応援ありがとうございます。"],
        "Kauf abgebrochen.": [.russian: "Покупка отменена.", .chinese: "购买已取消。", .japanese: "購入をキャンセルしました。"],
        "Kauf wartet auf Bestätigung.": [.russian: "Покупка ожидает подтверждения.", .chinese: "购买正在等待确认。", .japanese: "購入は承認待ちです。"],
        "Kauf konnte nicht abgeschlossen werden.": [.russian: "Не удалось завершить покупку.", .chinese: "无法完成购买。", .japanese: "購入を完了できませんでした。"],
        "Kalorien = MET x Sauerstofffaktor x Körpergewicht / Divisor x Minuten": [
            .russian: "Калории = MET x кислородный коэффициент x вес тела / делитель x минуты",
            .chinese: "卡路里 = MET x 氧气系数 x 体重 / 除数 x 分钟",
            .japanese: "カロリー = MET x 酸素係数 x 体重 / 除数 x 分"
        ],
        "MET kommt aus der jeweiligen Übung. Minuten entstehen aus erfassten Sätzen, Zeit pro Satz und Wechselzeit.": [
            .russian: "MET берётся из соответствующего упражнения. Минуты рассчитываются из записанных подходов, времени на подход и времени перехода.",
            .chinese: "MET 来自对应动作。分钟数由已记录组数、每组时间和切换时间计算。",
            .japanese: "METは各種目の値です。分数は記録済みセット、セット時間、切替時間から計算されます。"
        ],
        "Aus deinen Routinen": [
            .english: "From your routines",
            .french: "Depuis tes routines",
            .spanish: "De tus rutinas",
            .italian: "Dalle tue routine",
            .russian: "Из твоих программ",
            .chinese: "来自你的计划",
            .japanese: "あなたのルーティンから"
        ],
        "Nicht durchgeführte Sätze einfach abwählen.": [
            .english: "Just deselect the sets you did not perform.",
            .french: "Décoche simplement les séries non réalisées.",
            .spanish: "Simplemente desmarca las series que no hiciste.",
            .italian: "Deseleziona semplicemente le serie non eseguite.",
            .russian: "Просто снимите отметку с невыполненных подходов.",
            .chinese: "只需取消勾选未完成的组。",
            .japanese: "実施しなかったセットのチェックを外すだけです。"
        ],
        "Nicht gemacht": [
            .english: "Not done",
            .french: "Non réalisée",
            .spanish: "No realizada",
            .italian: "Non eseguita",
            .russian: "Не выполнен",
            .chinese: "未完成",
            .japanese: "未実施"
        ],
        "RPE fehlt": [
            .english: "RPE missing",
            .french: "RPE manquante",
            .spanish: "Falta el RPE",
            .italian: "RPE mancante",
            .russian: "Нет RPE",
            .chinese: "缺少 RPE",
            .japanese: "RPEが未入力"
        ],
        "Tippe im Satz auf RPE und wähle einen Wert von 6 bis 10, damit der Trainer rechnen kann.": [
            .english: "Tap RPE in the set and pick a value from 6 to 10 so the trainer can calculate.",
            .french: "Touche RPE dans la série et choisis une valeur de 6 à 10 pour que le coach puisse calculer.",
            .spanish: "Toca RPE en la serie y elige un valor de 6 a 10 para que el entrenador pueda calcular.",
            .italian: "Tocca RPE nella serie e scegli un valore da 6 a 10 così il trainer può calcolare.",
            .russian: "Нажмите RPE в подходе и выберите значение от 6 до 10, чтобы тренер мог рассчитать.",
            .chinese: "在该组中点按 RPE 并选择 6 到 10 的数值，教练才能计算。",
            .japanese: "セットのRPEをタップして6〜10の値を選ぶと、トレーナーが計算できます。"
        ],
        "Für den letzten erfassten Satz fehlt die RPE. Tippe im Satz auf RPE und wähle einen Wert von 6 bis 10.": [
            .english: "The last recorded set has no RPE. Tap RPE in the set and pick a value from 6 to 10.",
            .french: "La dernière série enregistrée n'a pas de RPE. Touche RPE dans la série et choisis une valeur de 6 à 10.",
            .spanish: "La última serie registrada no tiene RPE. Toca RPE en la serie y elige un valor de 6 a 10.",
            .italian: "L'ultima serie registrata non ha RPE. Tocca RPE nella serie e scegli un valore da 6 a 10.",
            .russian: "У последнего записанного подхода нет RPE. Нажмите RPE в подходе и выберите значение от 6 до 10.",
            .chinese: "最近记录的一组没有 RPE。请在该组中点按 RPE 并选择 6 到 10 的数值。",
            .japanese: "直近の記録セットにRPEがありません。セットのRPEをタップして6〜10の値を選んでください。"
        ],
        "Erfasse in dieser Einheit nach jedem Satz die RPE, dann rechnet der Trainer beim nächsten Mal damit.": [
            .english: "Record your RPE after every set in this session, then the trainer will use it next time.",
            .french: "Enregistre ta RPE après chaque série de cette séance, le coach l'utilisera la prochaine fois.",
            .spanish: "Registra tu RPE después de cada serie en esta sesión y el entrenador la usará la próxima vez.",
            .italian: "Registra l'RPE dopo ogni serie in questa sessione, così il trainer la userà la prossima volta.",
            .russian: "Записывайте RPE после каждого подхода в этой тренировке — тренер учтёт это в следующий раз.",
            .chinese: "在本次训练中每组结束后记录 RPE，教练下次就会据此计算。",
            .japanese: "この練習では各セット後にRPEを記録すると、次回トレーナーがそれを使います。"
        ],
        "Wähle nach jedem Satz eine RPE von 6 bis 10 aus. Ohne RPE kann der Trainer Gewicht und Pause nicht anpassen.": [
            .english: "Pick an RPE from 6 to 10 after every set. Without RPE the trainer cannot adjust weight and rest.",
            .french: "Choisis une RPE de 6 à 10 après chaque série. Sans RPE, le coach ne peut pas ajuster la charge et la pause.",
            .spanish: "Elige un RPE de 6 a 10 después de cada serie. Sin RPE el entrenador no puede ajustar peso y descanso.",
            .italian: "Scegli un RPE da 6 a 10 dopo ogni serie. Senza RPE il trainer non può regolare carico e pausa.",
            .russian: "Выбирайте RPE от 6 до 10 после каждого подхода. Без RPE тренер не может корректировать вес и отдых.",
            .chinese: "每组结束后选择 6 到 10 的 RPE。没有 RPE，教练无法调整重量和休息。",
            .japanese: "各セット後に6〜10のRPEを選んでください。RPEがないとトレーナーは重量と休憩を調整できません。"
        ]
    ]
}

extension DeviceCategory {
    func localizedName(language: AppLanguage) -> String {
        switch language.effectiveLanguage {
        case .system, .german: rawValue
        case .english:
            switch self {
            case .chest: "Chest"
            case .back: "Back"
            case .shoulders: "Shoulders"
            case .legs: "Legs"
            case .arms: "Arms"
            case .core: "Core"
            case .cardio: "Cardio"
            case .freeWeights: "Free Weights"
            }
        case .french:
            switch self {
            case .chest: "Pectoraux"
            case .back: "Dos"
            case .shoulders: "Épaules"
            case .legs: "Jambes"
            case .arms: "Bras"
            case .core: "Sangle abdominale"
            case .cardio: "Cardio"
            case .freeWeights: "Poids libres"
            }
        case .spanish:
            switch self {
            case .chest: "Pecho"
            case .back: "Espalda"
            case .shoulders: "Hombros"
            case .legs: "Piernas"
            case .arms: "Brazos"
            case .core: "Core"
            case .cardio: "Cardio"
            case .freeWeights: "Pesos libres"
            }
        case .italian:
            switch self {
            case .chest: "Petto"
            case .back: "Schiena"
            case .shoulders: "Spalle"
            case .legs: "Gambe"
            case .arms: "Braccia"
            case .core: "Core"
            case .cardio: "Cardio"
            case .freeWeights: "Pesi liberi"
            }
        case .russian:
            switch self {
            case .chest: "Грудь"
            case .back: "Спина"
            case .shoulders: "Плечи"
            case .legs: "Ноги"
            case .arms: "Руки"
            case .core: "Кор"
            case .cardio: "Кардио"
            case .freeWeights: "Свободные веса"
            }
        case .chinese:
            switch self {
            case .chest: "胸部"
            case .back: "背部"
            case .shoulders: "肩部"
            case .legs: "腿部"
            case .arms: "手臂"
            case .core: "核心"
            case .cardio: "有氧"
            case .freeWeights: "自由重量"
            }
        case .japanese:
            switch self {
            case .chest: "胸"
            case .back: "背中"
            case .shoulders: "肩"
            case .legs: "脚"
            case .arms: "腕"
            case .core: "体幹"
            case .cardio: "有酸素"
            case .freeWeights: "フリーウェイト"
            }
        }
    }
}

extension ExerciseCatalog {
    static func localizedName(for id: String, fallback: String, language: AppLanguage) -> String {
        localizedNames[id]?[language.effectiveLanguage] ?? additionalLocalizedNames[id]?[language.effectiveLanguage] ?? fallback
    }

    private static let localizedNames: [String: [AppLanguage: String]] = [
        "chest-press": [.english: "Chest Press", .french: "Presse pectorale", .spanish: "Prensa de pecho", .italian: "Pressa pettorali"],
        "incline-press": [.english: "Incline Chest Press", .french: "Presse inclinée", .spanish: "Prensa inclinada", .italian: "Pressa inclinata"],
        "pec-deck": [.english: "Butterfly / Pec Deck", .french: "Butterfly / Pec Deck", .spanish: "Aperturas / Pec Deck", .italian: "Butterfly / Pec Deck"],
        "cable-fly": [.english: "Cable Fly", .french: "Écartés à la poulie", .spanish: "Aperturas en polea", .italian: "Croci ai cavi"],
        "machine-fly": [.english: "Machine Fly", .french: "Écartés machine", .spanish: "Aperturas en máquina", .italian: "Croci alla macchina"],
        "cable-chest-press": [.english: "Cable Chest Press", .french: "Développé poitrine à la poulie", .spanish: "Press de pecho en polea", .italian: "Chest press ai cavi"],
        "smith-bench-press": [.english: "Smith Machine Bench Press", .french: "Développé couché Smith", .spanish: "Press banca en Smith", .italian: "Panca Smith machine"],
        "push-up": [.english: "Push-Up", .french: "Pompes", .spanish: "Flexiones", .italian: "Piegamenti"],
        "lat-pulldown": [.english: "Lat Pulldown", .french: "Tirage vertical", .spanish: "Jalón al pecho", .italian: "Lat machine"],
        "seated-row": [.english: "Seated Row Machine", .french: "Rameur assis machine", .spanish: "Remo sentado máquina", .italian: "Rematore seduto macchina"],
        "seated-machine-row": [.english: "Seated Row (Machine)", .french: "Rowing assis (machine)", .spanish: "Remo sentado (máquina)", .italian: "Rematore seduto (macchina)"],
        "back-extension": [.english: "Back Extension", .french: "Extensions lombaires", .spanish: "Hiperextensiones", .italian: "Iperestensioni"],
        "assisted-pullup": [.english: "Assisted Pull-Ups", .french: "Tractions assistées", .spanish: "Dominadas asistidas", .italian: "Trazioni assistite"],
        "low-row": [.english: "Low Row Machine", .french: "Rowing bas machine", .spanish: "Remo bajo máquina", .italian: "Low row macchina"],
        "t-bar-row-machine": [.english: "T-Bar Row Machine", .french: "Rowing T-bar machine", .spanish: "Remo T-bar máquina", .italian: "T-bar row macchina"],
        "pullover-machine": [.english: "Pullover Machine", .french: "Pull-over machine", .spanish: "Pullover máquina", .italian: "Pullover machine"],
        "cable-row": [.english: "Seated Cable Row", .french: "Rowing assis à la poulie", .spanish: "Remo sentado en polea", .italian: "Rematore seduto ai cavi"],
        "face-pull": [.english: "Face Pull", .french: "Face pull", .spanish: "Face pull", .italian: "Face pull"],
        "shoulder-press": [.english: "Shoulder Press", .french: "Presse épaules", .spanish: "Press de hombros", .italian: "Shoulder press"],
        "lateral-raise": [.english: "Lateral Raise Machine", .french: "Élévations latérales machine", .spanish: "Elevación lateral máquina", .italian: "Alzate laterali macchina"],
        "rear-delt": [.english: "Reverse Butterfly", .french: "Oiseau inversé", .spanish: "Pájaros inversos", .italian: "Reverse butterfly"],
        "cable-lateral-raise": [.english: "Cable Lateral Raise", .french: "Élévations latérales à la poulie", .spanish: "Elevación lateral en polea", .italian: "Alzate laterali ai cavi"],
        "front-raise": [.english: "Front Raise", .french: "Élévations frontales", .spanish: "Elevación frontal", .italian: "Alzate frontali"],
        "shrug-machine": [.english: "Shrug Machine", .french: "Shrugs machine", .spanish: "Encogimientos máquina", .italian: "Shrug machine"],
        "arnold-press": [.english: "Arnold Press", .french: "Développé Arnold", .spanish: "Press Arnold", .italian: "Arnold press"],
        "leg-press": [.english: "Leg Press", .french: "Presse à cuisses", .spanish: "Prensa de piernas", .italian: "Leg press"],
        "leg-extension": [.english: "Leg Extension", .french: "Extension des jambes", .spanish: "Extensión de piernas", .italian: "Leg extension"],
        "leg-curl": [.english: "Leg Curl", .french: "Curl ischios", .spanish: "Curl femoral", .italian: "Leg curl"],
        "hip-thrust": [.english: "Hip Thrust Machine", .french: "Hip thrust machine", .spanish: "Hip thrust máquina", .italian: "Hip thrust machine"],
        "abductor": [.english: "Abductor", .french: "Abducteurs", .spanish: "Abductor", .italian: "Abduttori"],
        "adductor": [.english: "Adductor", .french: "Adducteurs", .spanish: "Aductor", .italian: "Adduttori"],
        "calf-raise": [.english: "Calf Raise", .french: "Mollets", .spanish: "Elevación de gemelos", .italian: "Calf raise"],
        "hack-squat": [.english: "Hack Squat", .french: "Hack squat", .spanish: "Hack squat", .italian: "Hack squat"],
        "smith-squat": [.english: "Smith Machine Squat", .french: "Squat Smith", .spanish: "Sentadilla Smith", .italian: "Squat Smith machine"],
        "glute-kickback": [.english: "Glute Kickback Machine", .french: "Kickback fessiers machine", .spanish: "Patada de glúteo máquina", .italian: "Glute kickback machine"],
        "seated-calf-raise": [.english: "Seated Calf Raise", .french: "Mollets assis", .spanish: "Gemelos sentado", .italian: "Calf raise seduto"],
        "standing-calf-raise": [.english: "Standing Calf Raise", .french: "Mollets debout", .spanish: "Gemelos de pie", .italian: "Calf raise in piedi"],
        "biceps-curl": [.english: "Biceps Curl Machine", .french: "Curl biceps machine", .spanish: "Curl bíceps máquina", .italian: "Curl bicipiti macchina"],
        "triceps-press": [.english: "Triceps Pushdown", .french: "Extension triceps à la poulie", .spanish: "Extensión de tríceps en polea", .italian: "Pushdown tricipiti"],
        "dip-machine": [.english: "Dip Machine", .french: "Dips machine", .spanish: "Fondos máquina", .italian: "Dip machine"],
        "preacher-curl": [.english: "Preacher Curl Machine", .french: "Curl pupitre machine", .spanish: "Curl predicador máquina", .italian: "Curl panca Scott macchina"],
        "hammer-curl": [.english: "Hammer Curl", .french: "Curl marteau", .spanish: "Curl martillo", .italian: "Curl martello"],
        "cable-curl": [.english: "Cable Curl", .french: "Curl à la poulie", .spanish: "Curl en polea", .italian: "Curl ai cavi"],
        "overhead-triceps": [.english: "Overhead Triceps Extension", .french: "Extension triceps au-dessus de la tête", .spanish: "Tríceps por encima de la cabeza", .italian: "Estensione tricipiti sopra la testa"],
        "skull-crusher": [.english: "Skull Crusher", .french: "Skull crusher", .spanish: "Rompecráneos", .italian: "Skull crusher"],
        "ab-crunch": [.english: "Abdominal Machine", .french: "Crunch machine", .spanish: "Máquina abdominal", .italian: "Macchina addominali"],
        "crunch-press": [.english: "Crunch / Abdominal Press", .french: "Crunch / presse abdominale", .spanish: "Crunch / prensa abdominal", .italian: "Crunch / pressa addominale"],
        "rotary-torso": [.english: "Torso Rotation", .french: "Rotation du buste", .spanish: "Rotación de torso", .italian: "Rotazione busto"],
        "plank": [.english: "Plank", .french: "Planche", .spanish: "Plancha", .italian: "Plank"],
        "cable-crunch": [.english: "Cable Crunch", .french: "Crunch à la poulie", .spanish: "Crunch en polea", .italian: "Crunch ai cavi"],
        "hanging-leg-raise": [.english: "Hanging Leg Raise", .french: "Relevé de jambes suspendu", .spanish: "Elevación de piernas colgado", .italian: "Sollevamento gambe sospeso"],
        "roman-chair": [.english: "Roman Chair Sit-Up", .french: "Sit-up chaise romaine", .spanish: "Sit-up en silla romana", .italian: "Sit-up Roman chair"],
        "pallof-press": [.english: "Pallof Press", .french: "Pallof press", .spanish: "Pallof press", .italian: "Pallof press"],
        "treadmill": [.english: "Treadmill", .french: "Tapis de course", .spanish: "Cinta de correr", .italian: "Tapis roulant"],
        "bike": [.english: "Exercise Bike", .french: "Vélo ergomètre", .spanish: "Bicicleta estática", .italian: "Cyclette"],
        "cross-trainer": [.english: "Elliptical Trainer", .french: "Vélo elliptique", .spanish: "Elíptica", .italian: "Ellittica"],
        "rowing": [.english: "Rowing Ergometer", .french: "Rameur", .spanish: "Remo ergómetro", .italian: "Vogatore"],
        "stairmaster": [.english: "Stair Climber", .french: "Escalier", .spanish: "Escaladora", .italian: "Stairmaster"],
        "skierg": [.english: "SkiErg", .french: "SkiErg", .spanish: "SkiErg", .italian: "SkiErg"],
        "air-bike": [.english: "Air Bike", .french: "Air Bike", .spanish: "Air Bike", .italian: "Air Bike"],
        "bench-press": [.english: "Bench Press", .french: "Développé couché", .spanish: "Press banca", .italian: "Panca piana"],
        "squat": [.english: "Squat", .french: "Squat", .spanish: "Sentadilla", .italian: "Squat"],
        "deadlift": [.english: "Deadlift", .french: "Soulevé de terre", .spanish: "Peso muerto", .italian: "Stacco da terra"],
        "dumbbell-row": [.english: "Dumbbell Row", .french: "Rowing haltère", .spanish: "Remo con mancuerna", .italian: "Rematore con manubrio"],
        "romanian-deadlift": [.english: "Romanian Deadlift", .french: "Soulevé de terre roumain", .spanish: "Peso muerto rumano", .italian: "Stacco rumeno"],
        "goblet-squat": [.english: "Goblet Squat", .french: "Goblet squat", .spanish: "Sentadilla goblet", .italian: "Goblet squat"],
        "walking-lunge": [.english: "Walking Lunges", .french: "Fentes marchées", .spanish: "Zancadas caminando", .italian: "Affondi camminati"],
        "dumbbell-bench-press": [.english: "Dumbbell Bench Press", .french: "Développé couché haltères", .spanish: "Press banca con mancuernas", .italian: "Panca con manubri"]
    ]

    private static let additionalLocalizedNames: [String: [AppLanguage: String]] = [
        "chest-press": [.russian: "Жим от груди", .chinese: "坐姿推胸", .japanese: "チェストプレス"],
        "incline-press": [.russian: "Наклонный жим от груди", .chinese: "上斜推胸", .japanese: "インクラインチェストプレス"],
        "pec-deck": [.russian: "Баттерфляй / Pec Deck", .chinese: "蝴蝶机夹胸", .japanese: "ペックデック"],
        "cable-fly": [.russian: "Сведение рук в кроссовере", .chinese: "绳索夹胸", .japanese: "ケーブルフライ"],
        "machine-fly": [.russian: "Сведение рук в тренажёре", .chinese: "器械夹胸", .japanese: "マシンフライ"],
        "cable-chest-press": [.russian: "Жим от груди в кроссовере", .chinese: "绳索推胸", .japanese: "ケーブルチェストプレス"],
        "smith-bench-press": [.russian: "Жим лёжа в Смите", .chinese: "史密斯卧推", .japanese: "スミスマシンベンチプレス"],
        "push-up": [.russian: "Отжимания", .chinese: "俯卧撑", .japanese: "腕立て伏せ"],
        "lat-pulldown": [.russian: "Тяга верхнего блока", .chinese: "高位下拉", .japanese: "ラットプルダウン"],
        "seated-row": [.russian: "Тяга сидя в тренажёре", .chinese: "坐姿划船机", .japanese: "シーテッドロー"],
        "seated-machine-row": [.russian: "Тяга сидя (тренажёр)", .chinese: "坐姿划船（器械）", .japanese: "シーテッドロー（マシン）"],
        "back-extension": [.russian: "Гиперэкстензия", .chinese: "背部伸展", .japanese: "バックエクステンション"],
        "assisted-pullup": [.russian: "Подтягивания с ассистом", .chinese: "辅助引体向上", .japanese: "アシスト懸垂"],
        "low-row": [.russian: "Низкая тяга", .chinese: "低位划船机", .japanese: "ローロー"],
        "t-bar-row-machine": [.russian: "Тяга T-грифа в тренажёре", .chinese: "T杠划船机", .japanese: "Tバーローマシン"],
        "pullover-machine": [.russian: "Пуловер в тренажёре", .chinese: "器械直臂下压", .japanese: "プルオーバーマシン"],
        "cable-row": [.russian: "Тяга нижнего блока сидя", .chinese: "坐姿绳索划船", .japanese: "シーテッドケーブルロー"],
        "face-pull": [.russian: "Тяга к лицу", .chinese: "面拉", .japanese: "フェイスプル"],
        "shoulder-press": [.russian: "Жим плечами", .chinese: "肩推", .japanese: "ショルダープレス"],
        "lateral-raise": [.russian: "Разведения в стороны в тренажёре", .chinese: "器械侧平举", .japanese: "ラテラルレイズマシン"],
        "rear-delt": [.russian: "Обратный баттерфляй", .chinese: "反向飞鸟", .japanese: "リアデルト"],
        "cable-lateral-raise": [.russian: "Разведение в сторону в кроссовере", .chinese: "绳索侧平举", .japanese: "ケーブルサイドレイズ"],
        "front-raise": [.russian: "Подъём перед собой", .chinese: "前平举", .japanese: "フロントレイズ"],
        "shrug-machine": [.russian: "Шраги в тренажёре", .chinese: "器械耸肩", .japanese: "シュラッグマシン"],
        "arnold-press": [.russian: "Жим Арнольда", .chinese: "阿诺德推举", .japanese: "アーノルドプレス"],
        "leg-press": [.russian: "Жим ногами", .chinese: "腿举", .japanese: "レッグプレス"],
        "leg-extension": [.russian: "Разгибание ног", .chinese: "腿屈伸", .japanese: "レッグエクステンション"],
        "leg-curl": [.russian: "Сгибание ног", .chinese: "腿弯举", .japanese: "レッグカール"],
        "hip-thrust": [.russian: "Ягодичный мост в тренажёре", .chinese: "臀推机", .japanese: "ヒップスラストマシン"],
        "abductor": [.russian: "Отведение бедра", .chinese: "髋外展", .japanese: "アブダクター"],
        "adductor": [.russian: "Приведение бедра", .chinese: "髋内收", .japanese: "アダクター"],
        "calf-raise": [.russian: "Подъём на икры", .chinese: "提踵", .japanese: "カーフレイズ"],
        "hack-squat": [.russian: "Гакк-присед", .chinese: "哈克深蹲", .japanese: "ハックスクワット"],
        "smith-squat": [.russian: "Присед в Смите", .chinese: "史密斯深蹲", .japanese: "スミスマシンスクワット"],
        "glute-kickback": [.russian: "Отведение ноги назад", .chinese: "臀部后踢机", .japanese: "グルートキックバック"],
        "seated-calf-raise": [.russian: "Подъём на икры сидя", .chinese: "坐姿提踵", .japanese: "シーテッドカーフレイズ"],
        "standing-calf-raise": [.russian: "Подъём на икры стоя", .chinese: "站姿提踵", .japanese: "スタンディングカーフレイズ"],
        "biceps-curl": [.russian: "Сгибание на бицепс в тренажёре", .chinese: "二头弯举机", .japanese: "バイセップスカールマシン"],
        "triceps-press": [.russian: "Разгибание на трицепс", .chinese: "绳索下压", .japanese: "トライセップスプレスダウン"],
        "dip-machine": [.russian: "Брусья в тренажёре", .chinese: "双杠臂屈伸机", .japanese: "ディップマシン"],
        "preacher-curl": [.russian: "Сгибание на скамье Скотта", .chinese: "牧师凳弯举机", .japanese: "プリーチャーカール"],
        "hammer-curl": [.russian: "Молотковые сгибания", .chinese: "锤式弯举", .japanese: "ハンマーカール"],
        "cable-curl": [.russian: "Сгибание на бицепс в кроссовере", .chinese: "绳索弯举", .japanese: "ケーブルカール"],
        "overhead-triceps": [.russian: "Разгибание трицепса над головой", .chinese: "过头三头伸展", .japanese: "オーバーヘッドトライセップス"],
        "skull-crusher": [.russian: "Французский жим лёжа", .chinese: "仰卧臂屈伸", .japanese: "スカルクラッシャー"],
        "ab-crunch": [.russian: "Пресс в тренажёре", .chinese: "腹肌卷腹机", .japanese: "アブクランチ"],
        "crunch-press": [.russian: "Кранч / пресс-машина", .chinese: "卷腹/腹压机", .japanese: "クランチプレス"],
        "rotary-torso": [.russian: "Повороты корпуса", .chinese: "躯干旋转", .japanese: "ロータリートーソ"],
        "plank": [.russian: "Планка", .chinese: "平板支撑", .japanese: "プランク"],
        "cable-crunch": [.russian: "Кранч на блоке", .chinese: "绳索卷腹", .japanese: "ケーブルクランチ"],
        "hanging-leg-raise": [.russian: "Подъём ног в висе", .chinese: "悬垂举腿", .japanese: "ハンギングレッグレイズ"],
        "roman-chair": [.russian: "Ситап на римском стуле", .chinese: "罗马椅仰卧起坐", .japanese: "ローマンチェアシットアップ"],
        "pallof-press": [.russian: "Жим Паллофа", .chinese: "帕洛夫推", .japanese: "パロフプレス"],
        "treadmill": [.russian: "Беговая дорожка", .chinese: "跑步机", .japanese: "トレッドミル"],
        "bike": [.russian: "Велотренажёр", .chinese: "健身车", .japanese: "エアロバイク"],
        "cross-trainer": [.russian: "Эллиптический тренажёр", .chinese: "椭圆机", .japanese: "クロストレーナー"],
        "rowing": [.russian: "Гребной тренажёр", .chinese: "划船机", .japanese: "ローイングエルゴ"],
        "stairmaster": [.russian: "Степпер", .chinese: "登阶机", .japanese: "ステアクライマー"],
        "skierg": [.russian: "SkiErg", .chinese: "滑雪机", .japanese: "SkiErg"],
        "air-bike": [.russian: "Air Bike", .chinese: "风阻单车", .japanese: "エアバイク"],
        "bench-press": [.russian: "Жим лёжа", .chinese: "卧推", .japanese: "ベンチプレス"],
        "squat": [.russian: "Присед", .chinese: "深蹲", .japanese: "スクワット"],
        "deadlift": [.russian: "Становая тяга", .chinese: "硬拉", .japanese: "デッドリフト"],
        "dumbbell-row": [.russian: "Тяга гантели", .chinese: "哑铃划船", .japanese: "ダンベルロー"],
        "romanian-deadlift": [.russian: "Румынская тяга", .chinese: "罗马尼亚硬拉", .japanese: "ルーマニアンデッドリフト"],
        "goblet-squat": [.russian: "Гоблет-присед", .chinese: "高脚杯深蹲", .japanese: "ゴブレットスクワット"],
        "walking-lunge": [.russian: "Выпады в ходьбе", .chinese: "行走弓步", .japanese: "ウォーキングランジ"],
        "dumbbell-bench-press": [.russian: "Жим гантелей лёжа", .chinese: "哑铃卧推", .japanese: "ダンベルベンチプレス"]
    ]
}

extension Exercise {
    func localizedName(language: AppLanguage) -> String {
        ExerciseCatalog.localizedName(for: catalogID, fallback: name, language: language)
    }
}

extension WorkoutSessionExercise {
    func localizedName(language: AppLanguage) -> String {
        ExerciseCatalog.localizedName(for: catalogID, fallback: name, language: language)
    }
}

extension ExerciseCatalogItem {
    func localizedName(language: AppLanguage) -> String {
        ExerciseCatalog.localizedName(for: id, fallback: name, language: language)
    }
}
