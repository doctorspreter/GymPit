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
        return Self.uiTexts[german]?[effectiveLanguage] ?? Self.additionalUITexts[german]?[effectiveLanguage] ?? german
    }

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
        "Healthpit": [.english: "Healthpit", .french: "Healthpit", .spanish: "Healthpit", .italian: "Healthpit"],
        "Externe Healthpit URL": [.english: "External Healthpit URL", .french: "URL externe Healthpit", .spanish: "URL externa de Healthpit", .italian: "URL Healthpit esterno"],
        "Lokale Verbindung verwenden": [.english: "Use local connection", .french: "Utiliser la connexion locale", .spanish: "Usar conexión local", .italian: "Usa connessione locale"],
        "Lokaler Host oder IP": [.english: "Local host or IP", .french: "Hôte local ou IP", .spanish: "Host local o IP", .italian: "Host locale o IP"],
        "Lokaler Port": [.english: "Local port", .french: "Port local", .spanish: "Puerto local", .italian: "Porta locale"],
        "Benutzername": [.english: "Username", .french: "Nom d’utilisateur", .spanish: "Usuario", .italian: "Nome utente"],
        "Gerätename": [.english: "Device name", .french: "Nom de l’appareil", .spanish: "Nombre del dispositivo", .italian: "Nome dispositivo"],
        "API Token": [.english: "API token", .french: "Jeton API", .spanish: "Token API", .italian: "Token API"],
        "OTP Code optional": [.english: "OTP code optional", .french: "Code OTP optionnel", .spanish: "Código OTP opcional", .italian: "Codice OTP opzionale"],
        "OTP Code zum Verbinden": [.english: "OTP code to connect", .french: "Code OTP pour connecter", .spanish: "Código OTP para conectar", .italian: "Codice OTP per connettere"],
        "Healthpit verbinden": [.english: "Connect Healthpit", .french: "Connecter Healthpit", .spanish: "Conectar Healthpit", .italian: "Connetti Healthpit"],
        "Verbindung trennen": [.english: "Disconnect", .french: "Déconnecter", .spanish: "Desconectar", .italian: "Disconnetti"],
        "Healthpit verbindet...": [.english: "Connecting Healthpit...", .french: "Connexion à Healthpit...", .spanish: "Conectando Healthpit...", .italian: "Connessione Healthpit..."],
        "Healthpit ist verbunden": [.english: "Healthpit is connected", .french: "Healthpit est connecté", .spanish: "Healthpit conectado", .italian: "Healthpit connesso"],
        "Healthpit ist nicht verbunden": [.english: "Healthpit is not connected", .french: "Healthpit n’est pas connecté", .spanish: "Healthpit no conectado", .italian: "Healthpit non connesso"],
        "Healthpit verbunden bis": [.english: "Healthpit connected until", .french: "Healthpit connecté jusqu’au", .spanish: "Healthpit conectado hasta", .italian: "Healthpit connesso fino al"],
        "Healthpit Verbindung Fehler": [.english: "Healthpit connection error", .french: "Erreur de connexion Healthpit", .spanish: "Error de conexión Healthpit", .italian: "Errore connessione Healthpit"],
        "Alle Trainings zu Healthpit übertragen": [.english: "Transfer all workouts to Healthpit", .french: "Transférer tous les entraînements vers Healthpit", .spanish: "Transferir todos los entrenamientos a Healthpit", .italian: "Trasferisci tutti gli allenamenti a Healthpit"],
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
        "Noch nicht": [.english: "Not yet", .french: "Pas encore", .spanish: "Aún no", .italian: "Non ancora"],
        "Erstes Mal in der Historie": [.english: "First time in history", .french: "Première fois dans l’historique", .spanish: "Primera vez en el historial", .italian: "Prima volta nello storico"],
        "Nach dem Abschluss siehst du hier deine letzte Leistung und Rekorde.": [.english: "After completing it, your last performance and records will appear here.", .french: "Après l’avoir terminé, ta dernière performance et tes records apparaîtront ici.", .spanish: "Después de completarlo, verás aquí tu último rendimiento y tus récords.", .italian: "Dopo averlo completato, qui vedrai ultima prestazione e record."],
        "Zeitraum": [.english: "Period", .french: "Période", .spanish: "Periodo", .italian: "Periodo"],
        "Wert": [.english: "Value", .french: "Valeur", .spanish: "Valor", .italian: "Valore"],
        "Noch kein Verlauf für diese Übung.": [.english: "No history for this exercise yet.", .french: "Aucun historique pour cet exercice.", .spanish: "Aún no hay historial para este ejercicio.", .italian: "Ancora nessuno storico per questo esercizio."],
        "Diagramm": [.english: "Chart", .french: "Graphique", .spanish: "Gráfico", .italian: "Grafico"],
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
        "Die App ist kostenlos. Sie speichert keine Daten auf einem fremden Server und braucht kein Konto. Deine Trainingsdaten bleiben lokal auf deinem Gerät, außer du exportierst sie oder verbindest freiwillig Apple Health beziehungsweise Healthpit.": [
            .english: "The app is free. It does not store data on an external server and does not require an account. Your workout data stays local on your device unless you export it or voluntarily connect Apple Health or Healthpit.",
            .french: "L’app est gratuite. Elle ne stocke aucune donnée sur un serveur externe et ne nécessite pas de compte. Tes données d’entraînement restent localement sur ton appareil, sauf si tu les exportes ou connectes volontairement Apple Health ou Healthpit.",
            .spanish: "La app es gratuita. No almacena datos en un servidor externo y no requiere cuenta. Tus datos de entrenamiento permanecen localmente en tu dispositivo, salvo que los exportes o conectes voluntariamente Apple Health o Healthpit.",
            .italian: "L’app è gratuita. Non salva dati su un server esterno e non richiede un account. I tuoi dati di allenamento restano localmente sul dispositivo, salvo esportazione o collegamento volontario ad Apple Health o Healthpit."
        ],
        "Hier bearbeitest du genutzte Geräte aus deinen Routinen und siehst den Standard-Gerätekatalog.": [
            .english: "Edit equipment used in your routines and view the standard equipment catalog.",
            .french: "Modifie les appareils utilisés dans tes routines et consulte le catalogue standard.",
            .spanish: "Edita las máquinas usadas en tus rutinas y consulta el catálogo estándar.",
            .italian: "Modifica le macchine usate nelle routine e consulta il catalogo standard."
        ],
        "Hier findest du den Übungskatalog und kannst eigene Übungen anlegen. In Routinen fügst du Übungen direkt beim Bearbeiten hinzu.": [
            .english: "Find the exercise catalog and create custom exercises. Add exercises to routines directly while editing them.",
            .french: "Retrouve le catalogue d’exercices et crée tes propres exercices. Ajoute les exercices aux routines directement pendant la modification.",
            .spanish: "Encuentra el catálogo de ejercicios y crea ejercicios propios. Añade ejercicios a las rutinas directamente al editarlas.",
            .italian: "Trovi il catalogo esercizi e puoi creare esercizi personalizzati. Aggiungi gli esercizi alle routine direttamente durante la modifica."
        ]
    ]

    private static let additionalUITexts: [String: [AppLanguage: String]] = [
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
        "Healthpit": [.russian: "Healthpit", .chinese: "Healthpit", .japanese: "Healthpit"],
        "Externe Healthpit URL": [.russian: "Внешний URL Healthpit", .chinese: "外部 Healthpit URL", .japanese: "外部Healthpit URL"],
        "Lokale Verbindung verwenden": [.russian: "Использовать локальное подключение", .chinese: "使用本地连接", .japanese: "ローカル接続を使用"],
        "Lokaler Host oder IP": [.russian: "Локальный хост или IP", .chinese: "本地主机或 IP", .japanese: "ローカルホストまたはIP"],
        "Lokaler Port": [.russian: "Локальный порт", .chinese: "本地端口", .japanese: "ローカルポート"],
        "Benutzername": [.russian: "Имя пользователя", .chinese: "用户名", .japanese: "ユーザー名"],
        "Gerätename": [.russian: "Имя устройства", .chinese: "设备名称", .japanese: "デバイス名"],
        "API Token": [.russian: "API-токен", .chinese: "API 令牌", .japanese: "APIトークン"],
        "OTP Code zum Verbinden": [.russian: "OTP-код для подключения", .chinese: "用于连接的 OTP 代码", .japanese: "接続用OTPコード"],
        "Healthpit verbinden": [.russian: "Подключить Healthpit", .chinese: "连接 Healthpit", .japanese: "Healthpitに接続"],
        "Verbindung trennen": [.russian: "Отключить", .chinese: "断开连接", .japanese: "接続を解除"],
        "Healthpit verbindet...": [.russian: "Подключение к Healthpit...", .chinese: "正在连接 Healthpit...", .japanese: "Healthpitに接続中..."],
        "Healthpit ist verbunden": [.russian: "Healthpit подключён", .chinese: "Healthpit 已连接", .japanese: "Healthpitに接続済み"],
        "Healthpit ist nicht verbunden": [.russian: "Healthpit не подключён", .chinese: "Healthpit 未连接", .japanese: "Healthpit未接続"],
        "Healthpit verbunden bis": [.russian: "Healthpit подключён до", .chinese: "Healthpit 连接有效至", .japanese: "Healthpit接続期限"],
        "Healthpit Verbindung Fehler": [.russian: "Ошибка подключения Healthpit", .chinese: "Healthpit 连接错误", .japanese: "Healthpit接続エラー"],
        "Alle Trainings zu Healthpit übertragen": [.russian: "Передать все тренировки в Healthpit", .chinese: "将所有训练传输到 Healthpit", .japanese: "すべてのワークアウトをHealthpitへ転送"],
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
        "Die App ist kostenlos. Sie speichert keine Daten auf einem fremden Server und braucht kein Konto. Deine Trainingsdaten bleiben lokal auf deinem Gerät, außer du exportierst sie oder verbindest freiwillig Apple Health beziehungsweise Healthpit.": [
            .russian: "Приложение бесплатное. Оно не хранит данные на внешнем сервере и не требует аккаунта. Ваши тренировочные данные остаются локально на устройстве, если вы сами не экспортируете их или добровольно не подключите Apple Health либо Healthpit.",
            .chinese: "这款 App 免费。它不会把数据存到外部服务器，也不需要账号。你的训练数据会保留在本机，除非你主动导出，或自愿连接 Apple 健康或 Healthpit。",
            .japanese: "このアプリは無料です。外部サーバーにデータを保存せず、アカウントも不要です。書き出しを行うか、AppleヘルスケアまたはHealthpitを自分で接続しない限り、トレーニングデータは端末内に残ります。"
        ],
        "Hier bearbeitest du genutzte Geräte aus deinen Routinen und siehst den Standard-Gerätekatalog.": [
            .russian: "Здесь можно редактировать тренажёры из ваших программ и смотреть стандартный каталог тренажёров.",
            .chinese: "在这里可以编辑训练计划中使用的器械，并查看标准器械目录。",
            .japanese: "ルーティンで使っている器具を編集し、標準器具カタログを確認できます。"
        ],
        "Hier findest du den Übungskatalog und kannst eigene Übungen anlegen. In Routinen fügst du Übungen direkt beim Bearbeiten hinzu.": [
            .russian: "Здесь находится каталог упражнений, и можно создавать свои упражнения. В программы упражнения добавляются прямо при редактировании.",
            .chinese: "在这里可以查看动作目录并创建自定义动作。编辑训练计划时可以直接添加动作。",
            .japanese: "種目カタログを確認し、カスタム種目を作成できます。ルーティンへは編集画面から直接追加します。"
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
