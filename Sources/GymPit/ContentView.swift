import Charts
import StoreKit
import SwiftUI
import UIKit
import UniformTypeIdentifiers

private enum AppLayout {
    static let cornerRadius: CGFloat = 8
    static let compactCornerRadius: CGFloat = cornerRadius
}

private enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Hell"
    case dark = "Dunkel"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var iconName: String {
        switch self {
        case .system: "iphone"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

    static func value(for rawValue: String) -> AppearanceMode {
        AppearanceMode(rawValue: rawValue) ?? .system
    }
}

private enum AppDesign: String, CaseIterable, Identifiable {
    case ocean = "Blau"
    case turquoise = "Türkis"
    case graphite = "Graphit"
    case forest = "Grün"
    case amber = "Orange"
    case violet = "Violett"
    case rose = "Rot"

    var id: String { rawValue }

    var accentColor: Color {
        switch self {
        case .ocean: Color.blue
        case .turquoise: Color(red: 0.0, green: 0.68, blue: 0.64)
        case .graphite: Color.gray
        case .forest: Color.green
        case .amber: Color.orange
        case .violet: Color.purple
        case .rose: Color.red
        }
    }

    static func value(for rawValue: String) -> AppDesign {
        if rawValue == "Gruen" {
            return .forest
        }

        return AppDesign(rawValue: rawValue) ?? .ocean
    }
}

private extension AppDesign {
    var pageBackground: Color {
        switch self {
        case .ocean:
            adaptive(light: (0.93, 0.96, 1.0), dark: (0.02, 0.04, 0.07))
        case .turquoise:
            adaptive(light: (0.90, 0.99, 0.97), dark: (0.01, 0.08, 0.08))
        case .graphite:
            adaptive(light: (0.94, 0.94, 0.95), dark: (0.04, 0.04, 0.05))
        case .forest:
            adaptive(light: (0.92, 0.98, 0.93), dark: (0.02, 0.07, 0.04))
        case .amber:
            adaptive(light: (1.0, 0.96, 0.89), dark: (0.10, 0.06, 0.02))
        case .violet:
            adaptive(light: (0.96, 0.93, 1.0), dark: (0.06, 0.03, 0.09))
        case .rose:
            adaptive(light: (1.0, 0.93, 0.95), dark: (0.09, 0.03, 0.04))
        }
    }

    var cardBackground: Color {
        switch self {
        case .ocean:
            adaptive(light: (0.985, 0.992, 1.0), dark: (0.07, 0.10, 0.15))
        case .turquoise:
            adaptive(light: (0.965, 1.0, 0.99), dark: (0.04, 0.13, 0.13))
        case .graphite:
            adaptive(light: (1.0, 1.0, 1.0), dark: (0.10, 0.10, 0.11))
        case .forest:
            adaptive(light: (0.97, 1.0, 0.97), dark: (0.05, 0.11, 0.06))
        case .amber:
            adaptive(light: (1.0, 0.985, 0.95), dark: (0.14, 0.09, 0.04))
        case .violet:
            adaptive(light: (0.99, 0.97, 1.0), dark: (0.10, 0.06, 0.14))
        case .rose:
            adaptive(light: (1.0, 0.97, 0.98), dark: (0.14, 0.06, 0.08))
        }
    }

    var secondaryCardBackground: Color {
        switch self {
        case .ocean, .turquoise, .forest, .amber, .violet, .rose:
            accentColor.opacity(0.10)
        case .graphite:
            adaptive(light: (0.92, 0.92, 0.94), dark: (0.16, 0.16, 0.18))
        }
    }

    var cardStroke: Color {
        accentColor.opacity(0.18)
    }

    private func adaptive(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> Color {
        Color(UIColor { traits in
            let values = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: values.0, green: values.1, blue: values.2, alpha: 1)
        })
    }
}

private struct ThemedPageBackground: ViewModifier {
    @AppStorage("gympit_app_design") private var appDesignRawValue = AppDesign.ocean.rawValue

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(AppDesign.value(for: appDesignRawValue).pageBackground.ignoresSafeArea())
    }
}

private struct ThemedCardBackground: ViewModifier {
    @AppStorage("gympit_app_design") private var appDesignRawValue = AppDesign.ocean.rawValue
    var cornerRadius: CGFloat = AppLayout.cornerRadius
    var highlighted = false

    func body(content: Content) -> some View {
        let design = AppDesign.value(for: appDesignRawValue)
        content
            .background(
                highlighted ? design.secondaryCardBackground : design.cardBackground,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(highlighted ? design.accentColor.opacity(0.32) : design.cardStroke, lineWidth: 1)
            )
    }
}

private extension View {
    func themedPageBackground() -> some View {
        modifier(ThemedPageBackground())
    }

    func themedCard(cornerRadius: CGFloat = AppLayout.cornerRadius, highlighted: Bool = false) -> some View {
        modifier(ThemedCardBackground(cornerRadius: cornerRadius, highlighted: highlighted))
    }

    func neutralCard(cornerRadius: CGFloat = AppLayout.cornerRadius) -> some View {
        background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color(.separator).opacity(0.22), lineWidth: 0.75)
            )
    }

    func standardFieldFrame(cornerRadius: CGFloat = AppLayout.cornerRadius) -> some View {
        background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color(.separator).opacity(0.22), lineWidth: 0.5)
            )
    }

    func fullWidthStandardFieldFrame(cornerRadius: CGFloat = AppLayout.cornerRadius, alignment: Alignment = .leading) -> some View {
        frame(maxWidth: .infinity, alignment: alignment)
            .standardFieldFrame(cornerRadius: cornerRadius)
    }
}

private enum SupportOption: String, CaseIterable, Identifiable {
    case smallCoffee
    case supporter
    case bigSupport
    case project

    var id: String { productID }

    var productID: String {
        switch self {
        case .smallCoffee: "app.gympit.support.small_coffee"
        case .supporter: "app.gympit.support.supporter"
        case .bigSupport: "app.gympit.support.big_support"
        case .project: "app.gympit.support.project"
        }
    }

    var title: String {
        switch self {
        case .smallCoffee: "Kleiner Kaffee"
        case .supporter: "Unterstützer"
        case .bigSupport: "Große Unterstützung"
        case .project: "Projekt fördern"
        }
    }

    var iconName: String {
        switch self {
        case .smallCoffee: "cup.and.saucer.fill"
        case .supporter: "heart.fill"
        case .bigSupport: "sparkles"
        case .project: "star.circle.fill"
        }
    }
}

@MainActor
private final class SupportPurchaseStore: ObservableObject {
    @Published private(set) var products: [String: Product] = [:]
    @Published private(set) var isPurchasing = false
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: String?

    func loadProducts() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedProducts = try await Product.products(for: SupportOption.allCases.map(\.productID))
            products = Dictionary(uniqueKeysWithValues: loadedProducts.map { ($0.id, $0) })
            loadError = loadedProducts.isEmpty
                ? "Unterstützung ist momentan nicht verfügbar."
                : nil
        } catch {
            products = [:]
            loadError = "Unterstützung konnte nicht geladen werden."
        }
    }

    func displayPrice(for option: SupportOption) -> String {
        products[option.productID]?.displayPrice ?? "–"
    }

    func isAvailable(_ option: SupportOption) -> Bool {
        products[option.productID] != nil
    }

    func purchase(_ option: SupportOption) async -> String {
        if products[option.productID] == nil {
            await loadProducts()
        }
        guard let product = products[option.productID] else {
            return "Dieser Kauf ist noch nicht verfügbar."
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                return "Danke für deine Unterstützung."
            case .userCancelled:
                return "Kauf abgebrochen."
            case .pending:
                return "Kauf wartet auf Bestätigung."
            @unknown default:
                return "Kauf konnte nicht abgeschlossen werden."
            }
        } catch {
            return "Kauf fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.notAvailableInStorefront
        case .verified(let safe):
            return safe
        }
    }
}

struct ContentView: View {
    @AppStorage("gympit_appearance_mode") private var appearanceModeRawValue = AppearanceMode.system.rawValue
    @AppStorage("gympit_app_design") private var appDesignRawValue = AppDesign.ocean.rawValue
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue

    var body: some View {
        TabView {
            TrainingView()
                .tabItem {
                    Label(appLanguage.ui("Training"), systemImage: "figure.strengthtraining.traditional")
                }

            RoutinesView()
                .tabItem {
                    Label(appLanguage.ui("Routinen"), systemImage: "list.bullet.rectangle")
                }

            HistoryView()
                .tabItem {
                    Label(appLanguage.ui("Historie"), systemImage: "clock.arrow.circlepath")
                }

            SettingsView()
                .tabItem {
                    Label(appLanguage.ui("Einstellungen"), systemImage: "gearshape")
                }
        }
        .preferredColorScheme(AppearanceMode.value(for: appearanceModeRawValue).colorScheme)
        .tint(AppDesign.value(for: appDesignRawValue).accentColor)
        .accentColor(AppDesign.value(for: appDesignRawValue).accentColor)
        .background(AppDesign.value(for: appDesignRawValue).pageBackground.ignoresSafeArea())
        .environment(\.locale, Locale(identifier: appLanguage.localeIdentifier))
        .onAppear {
            GymPitSharedStorage.set(appLanguageRawValue, forKey: AppLanguage.storageKey)
        }
        .onChange(of: appLanguageRawValue) { _, newValue in
            GymPitSharedStorage.set(newValue, forKey: AppLanguage.storageKey)
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct TrainingView: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage("gympit_app_design") private var appDesignRawValue = AppDesign.ocean.rawValue
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage("gympit_trainer_enabled") private var isTrainerEnabled = false
    @State private var completedSummarySession: WorkoutSession?
    @State private var lastPresentedSummaryID: UUID?
    @State private var isAddingExerciseDuringWorkout = false
    @State private var isAddingManualWorkout = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                Form {
                    Section {
                        WorkoutOverviewCard()
                            .id("trainingTop")
                    }

                    if store.plan.exercises.isEmpty {
                        Section {
                            EmptyPlanView()
                        }
                    } else if !store.plan.isWorkoutStarted {
                        if let session = store.latestCompletedSession {
                            Section {
                                TrainingSummaryCard(session: session)
                            }
                            if store.hasPendingRoutineChanges {
                                Section {
                                    RoutineUpdatePrompt()
                                }
                            }
                        }

                        Section {
                            StartTrainingPrompt()
                        }
                    } else {
                        if let activeExercise = store.plan.activeExercise {
                            Section {
                                ActiveExerciseCard(exercise: activeExercise)
                                if isTrainerEnabled {
                                    TrainerRecommendationCard(exercise: activeExercise)
                                }
                            }
                        }

                        remainingExercises(scrollProxy: proxy)

                        Section {
                            TrainingEndButton()
                        }

                        completedExercises
                    }

                    manualWorkoutEntrySection
                }
                .contentMargins(.top, 4, for: .scrollContent)
                .listSectionSpacing(.compact)
                .scrollDismissesKeyboard(.interactively)
                .background(currentDesign.pageBackground)
                .safeAreaInset(edge: .top, spacing: 0) {
                    StickyRestTimerInset(timerState: store.restTimerState)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(appLanguage.ui("Fertig")) {
                        UIApplication.shared.endEditing()
                    }
                }
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                store.tickRestTimer()
            }
            .onAppear {
                lastPresentedSummaryID = store.latestCompletedSession?.id
            }
            .onChange(of: store.latestCompletedSession?.id) { _, newID in
                guard let newID,
                      newID != lastPresentedSummaryID,
                      let session = store.latestCompletedSession else { return }
                lastPresentedSummaryID = newID
                completedSummarySession = session
            }
            .fullScreenCover(item: $completedSummarySession) { session in
                WorkoutCompletionSummaryView(session: session)
            }
            .sheet(isPresented: $isAddingExerciseDuringWorkout) {
                NavigationStack {
                    AddExerciseView(addsToCurrentWorkoutOnly: true)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(appLanguage.ui("Fertig")) {
                                    isAddingExerciseDuringWorkout = false
                                }
                            }
                    }
                }
            }
            .sheet(isPresented: $isAddingManualWorkout) {
                NavigationStack {
                    ManualWorkoutEntryView()
                }
            }
            .buttonBorderShape(.roundedRectangle(radius: AppLayout.cornerRadius))
        }
    }

    @ViewBuilder
    private var manualWorkoutEntrySection: some View {
        if !store.plan.isWorkoutStarted {
            Section {
                Button {
                    isAddingManualWorkout = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title3)
                            .foregroundStyle(currentDesign.accentColor)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(appLanguage.ui("Training nachtragen"))
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(appLanguage.ui("Trage ein älteres Training mit Datum, Übungen und allen Sätzen ein."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer(minLength: 8)

                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(appLanguage.ui("Training manuell hinzufügen"))
            }
        }
    }

    private func remainingExercises(scrollProxy: ScrollViewProxy) -> some View {
        Section {
            if remainingAfterActive.isEmpty {
                InfoRow(icon: "checkmark.circle", title: appLanguage.ui("Keine weiteren Übungen"), subtitle: appLanguage.ui("Schließe die aktuelle Übung ab."))
            } else {
                ForEach(remainingAfterActive) { exercise in
                    ExerciseRow(exercise: exercise) {
                        store.start(exercise)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            scrollProxy.scrollTo("trainingTop", anchor: .top)
                        }
                    }
                }
            }

            Button {
                isAddingExerciseDuringWorkout = true
            } label: {
                Label(appLanguage.ui("Übung hinzufügen"), systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        } header: {
            Text("\(appLanguage.ui("Offen")) (\(store.plan.openExercises.count)/\(store.plan.exercises.count))")
        }
    }

    private var remainingAfterActive: [Exercise] {
        guard let activeID = store.plan.activeExercise?.id else { return store.plan.openExercises }
        return store.plan.openExercises.filter { $0.id != activeID }
    }

    private var completedExercises: some View {
        Section {
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                    store.toggleCompletedSection()
                }
            } label: {
                HStack {
                    Label(appLanguage.ui("Erledigt"), systemImage: "checkmark.circle.fill")
                    Text("(\(store.plan.completedExercises.count)/\(store.plan.exercises.count))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: store.plan.isCompletedSectionExpanded ? "chevron.up" : "chevron.down")
                        .font(.footnote.weight(.semibold))
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)

            if store.plan.isCompletedSectionExpanded {
                ForEach(store.plan.completedExercises) { exercise in
                    CompletedExerciseRow(exercise: exercise)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var currentDesign: AppDesign {
        AppDesign.value(for: appDesignRawValue)
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var store: WorkoutStore
    @StateObject private var supportStore = SupportPurchaseStore()
    @AppStorage("gympit_appearance_mode") private var appearanceModeRawValue = AppearanceMode.system.rawValue
    @AppStorage("gympit_app_design") private var appDesignRawValue = AppDesign.ocean.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(GymPitBridgeSettings.baseURLKey) private var bridgeBaseURL = ""
    @AppStorage(GymPitBridgeSettings.localHostKey) private var bridgeLocalHost = ""
    @AppStorage(GymPitBridgeSettings.localPortKey) private var bridgeLocalPort = HealthpitAPI.defaultPort
    @AppStorage(GymPitBridgeSettings.usernameKey) private var bridgeUsername = ""
    @AppStorage(GymPitBridgeSettings.deviceIDKey) private var bridgeDeviceID = "GymPit"
    @State private var bodyWeight = 80.0
    @State private var minutesPerSet = 3.5
    @State private var setupMinutes = 2.0
    @State private var defaultRestSeconds = 90
    @State private var calorieOxygenFactor = 3.5
    @State private var calorieDivisor = 200.0
    @State private var bridgeHomeAssistantToken = ""
    @State private var bridgeConnectionStatus = ""
    @State private var isBridgeConnected = false
    @State private var isConnectingBridge = false
    @State private var csvExportItem: CSVExportItem?
    @State private var isImportingCSV = false
    @State private var isProcessingWorkoutImport = false
    @State private var csvAlertMessage = ""
    @State private var isShowingCSVAlert = false
    @State private var supportAlertMessage = ""
    @State private var isShowingSupportAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section(appLanguage.ui("Training und Geräte")) {
                    NavigationLink {
                        DeviceManagementView()
                    } label: {
                        Label(appLanguage.ui("Geräte und Übungen"), systemImage: "slider.horizontal.3")
                    }

                    NavigationLink {
                        trainingSettingsForm
                    } label: {
                        Label(appLanguage.ui("Training"), systemImage: "figure.strengthtraining.traditional")
                    }
                }

                Section(appLanguage.ui("App und Daten")) {
                    NavigationLink {
                        appSettingsForm
                    } label: {
                        Label(appLanguage.ui("App"), systemImage: "paintpalette")
                    }

                    NavigationLink {
                        dataAndInterfacesSettingsForm
                    } label: {
                        Label(appLanguage.ui("Daten / Schnittstellen"), systemImage: "externaldrive.connected.to.line.below")
                    }
                }

                Section(appLanguage.ui("Infos")) {
                    NavigationLink {
                        supportSettingsForm
                    } label: {
                        Label(appLanguage.ui("Unterstützen"), systemImage: "heart")
                    }

                    NavigationLink {
                        aboutSettingsForm
                    } label: {
                        Label(appLanguage.ui("Über"), systemImage: "info.circle")
                    }
                }

            }
            .navigationTitle(appLanguage.ui("Einstellungen"))
            .environment(\.editMode, .constant(.inactive))
            .onAppear(perform: syncState)
            .onChange(of: bodyWeight) { _, _ in saveProfile() }
            .onChange(of: minutesPerSet) { _, _ in saveProfile() }
            .onChange(of: setupMinutes) { _, _ in saveProfile() }
            .onChange(of: defaultRestSeconds) { _, _ in saveProfile() }
            .onChange(of: calorieOxygenFactor) { _, _ in saveProfile() }
            .onChange(of: calorieDivisor) { _, _ in saveProfile() }
            .onChange(of: bridgeHomeAssistantToken) { _, newValue in
                GymPitBridgeKeychainStore.set(newValue, for: GymPitBridgeSettings.homeAssistantTokenKey)
                resetBridgeConnection()
            }
            .onChange(of: weightUnitRawValue) { _, newValue in
                GymPitSharedStorage.set(newValue, forKey: WeightUnit.storageKey)
            }
            .onChange(of: bridgeConnectionResetSignature) { _, _ in resetBridgeConnection() }
            .task {
                await supportStore.loadProducts()
            }
            .sheet(item: $csvExportItem) { item in
                CSVShareSheet(url: item.url)
            }
            .fileImporter(
                isPresented: $isImportingCSV,
                allowedContentTypes: [.json, .data]
            ) { result in
                importCSV(result)
            }
            .alert(appLanguage.ui("Daten"), isPresented: $isShowingCSVAlert) {
                Button(appLanguage.ui("OK"), role: .cancel) {}
            } message: {
                Text(csvAlertMessage)
            }
            .alert(appLanguage.ui("Unterstützen"), isPresented: $isShowingSupportAlert) {
                Button(appLanguage.ui("OK"), role: .cancel) {}
            } message: {
                Text(supportAlertMessage)
            }
            .themedPageBackground()
            .overlay {
                if isProcessingWorkoutImport {
                    ZStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .ignoresSafeArea()

                        ProgressView(appLanguage.ui("Import läuft..."))
                            .padding(18)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
                    }
                }
            }
        }
    }

    private var appSettingsForm: some View {
        Form {
            Section(appLanguage.ui("Darstellung")) {
                Picker(appLanguage.ui("Sprache"), selection: $appLanguageRawValue) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.title).tag(language.rawValue)
                    }
                }
                .foregroundStyle(.primary)
                .tint(currentDesign.accentColor)

                Picker(appLanguage.ui("Modus"), selection: $appearanceModeRawValue) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Label(appLanguage.ui(mode.rawValue), systemImage: mode.iconName)
                            .tag(mode.rawValue)
                    }
                }
                .foregroundStyle(.primary)
                .tint(currentDesign.accentColor)

                Picker(appLanguage.ui("Design"), selection: $appDesignRawValue) {
                    ForEach(AppDesign.allCases) { design in
                        DesignPickerRow(design: design)
                            .tag(design.rawValue)
                    }
                }

                DesignPreviewRow(
                    mode: AppearanceMode.value(for: appearanceModeRawValue),
                    design: AppDesign.value(for: appDesignRawValue)
                )
            }

            Section(appLanguage.ui("Einheiten")) {
                Picker(appLanguage.ui("Gewichtseinheit"), selection: $weightUnitRawValue) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(appLanguage.ui(unit.title)).tag(unit.rawValue)
                    }
                }
                .foregroundStyle(.primary)
                .tint(currentDesign.accentColor)
            }
        }
        .navigationTitle(appLanguage.ui("App"))
        .themedPageBackground()
    }

    private var bridgeConnectionResetSignature: String {
        [
            bridgeBaseURL,
            bridgeLocalHost,
            bridgeLocalPort,
            bridgeUsername
        ].joined(separator: "|")
    }

    private var dataAndInterfacesSettingsForm: some View {
        Form {
            Section(appLanguage.ui("Daten")) {
                Text(appLanguage.ui("Deine Trainingsdaten bleiben in der App auf deinem Gerät. Export, Import und verbundene Schnittstellen laufen nur, wenn du sie aktiv nutzt."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button {
                    exportCSV()
                } label: {
                    Label(appLanguage.ui("Trainings und Routinen exportieren"), systemImage: "square.and.arrow.up")
                }
                .disabled(store.history.isEmpty && store.routines.isEmpty)

                Button {
                    beginWorkoutImport()
                } label: {
                    Label(appLanguage.ui("Trainings und Routinen importieren"), systemImage: "square.and.arrow.down")
                }
                .disabled(isProcessingWorkoutImport)

            }

            Section(appLanguage.ui("Apple Health")) {
                Button {
                    store.connectAppleHealth()
                } label: {
                    Label(appLanguage.ui("Apple Health verbinden"), systemImage: "heart.text.square")
                }

                Button {
                    store.exportAllHistoricSessionsToHealth()
                } label: {
                    if store.isHealthExportInProgress {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text(appLanguage.ui("Übertragung läuft..."))
                        }
                    } else {
                        Label(appLanguage.ui("Alle alten Workouts übertragen"), systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                .disabled(store.history.isEmpty || store.isHealthExportInProgress)

                if store.healthExportStatus != "Noch nicht übertragen" {
                    Text(store.healthExportStatus)
                        .font(.footnote)
                        .foregroundStyle(store.healthExportStatus.contains("Fehler") ? Color.red : Color.secondary)
                }
            }

            Section(appLanguage.ui("Home Assistant")) {
                TextField(appLanguage.ui("Lokale Adresse"), text: $bridgeLocalHost)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                TextField(appLanguage.ui("Port"), text: $bridgeLocalPort)
                    .keyboardType(.numberPad)

                TextField(appLanguage.ui("Externe Adresse (optional)"), text: $bridgeBaseURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                SecureField(appLanguage.ui("Long-Lived Access Token"), text: $bridgeHomeAssistantToken)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button {
                    connectBridge()
                } label: {
                    Label(appLanguage.ui("Healthpit verbinden"), systemImage: "link")
                }
                .disabled(
                    isConnectingBridge ||
                    bridgeUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    requiredBridgeToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )

                Button(role: .destructive) {
                    disconnectBridge()
                } label: {
                    Label(appLanguage.ui("Verbindung trennen"), systemImage: "link.badge.minus")
                }
                .disabled(!isBridgeConnected)

                Button {
                    store.uploadAllHistoricSessionsToBridge()
                } label: {
                    Label(appLanguage.ui("Alle Trainings zu Healthpit übertragen"), systemImage: "arrow.up.heart")
                }
                .disabled(store.history.isEmpty)

                Text(bridgeConnectionStatus)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text(store.bridgeSyncStatus)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(appLanguage.ui("Daten / Schnittstellen"))
        .themedPageBackground()
    }

    private var trainingSettingsForm: some View {
        Form {
            Section(appLanguage.ui("Kalorien")) {
                Stepper(value: $bodyWeight, in: 35...180, step: 1) {
                    SettingsValueRow(title: appLanguage.ui("Körpergewicht"), value: bodyWeight.formattedWeight(unit: weightUnit))
                }
                Stepper(value: $minutesPerSet, in: 1...8, step: 0.5) {
                    SettingsValueRow(title: appLanguage.ui("Zeit pro Satz inkl. Pause"), value: "\(minutesPerSet.formatted(.number.precision(.fractionLength(1)))) min")
                }
                Stepper(value: $setupMinutes, in: 0...8, step: 0.5) {
                    SettingsValueRow(title: appLanguage.ui("Wechselzeit pro Übung"), value: "\(setupMinutes.formatted(.number.precision(.fractionLength(1)))) min")
                }
                Stepper(value: $defaultRestSeconds, in: 30...300, step: 15) {
                    SettingsValueRow(title: appLanguage.ui("Standardpause"), value: "\(defaultRestSeconds) s")
                }
            }

            Section(appLanguage.ui("Kalorienformel")) {
                Text(appLanguage.ui("Kalorien = MET x Sauerstofffaktor x Körpergewicht / Divisor x Minuten"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Stepper(value: $calorieOxygenFactor, in: 1...8, step: 0.1) {
                    SettingsValueRow(title: appLanguage.ui("Sauerstofffaktor"), value: calorieOxygenFactor.formatted(.number.precision(.fractionLength(1))))
                }
                Stepper(value: $calorieDivisor, in: 100...400, step: 5) {
                    SettingsValueRow(title: appLanguage.ui("Divisor"), value: calorieDivisor.formatted(.number.precision(.fractionLength(0))))
                }

                Text(appLanguage.ui("MET kommt aus der jeweiligen Übung. Minuten entstehen aus erfassten Sätzen, Zeit pro Satz und Wechselzeit."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(appLanguage.ui("Training"))
        .themedPageBackground()
    }

    private var supportSettingsForm: some View {
        Form {
            Section(appLanguage.ui("Unterstützen")) {
                Text(appLanguage.ui("Die App ist kostenlos und soll es bleiben. Ein freiwilliger Beitrag unterstützt die Weiterentwicklung und hilft, laufende Kosten wie Testgeräte und den Apple Developer Account zu decken. Vielen Dank für deine Unterstützung."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ForEach(SupportOption.allCases) { option in
                    Button {
                        Task {
                            supportAlertMessage = appLanguage.ui(await supportStore.purchase(option))
                            isShowingSupportAlert = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Label(appLanguage.ui(option.title), systemImage: option.iconName)
                            Spacer()
                            Text(supportStore.displayPrice(for: option))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(supportStore.isPurchasing || !supportStore.isAvailable(option))
                }

                if supportStore.isLoading {
                    HStack {
                        ProgressView()
                        Text(appLanguage.ui("Unterstützung wird geladen..."))
                            .foregroundStyle(.secondary)
                    }
                } else if let loadError = supportStore.loadError {
                    Text(appLanguage.ui(loadError))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button(appLanguage.ui("Erneut laden")) {
                        Task {
                            await supportStore.loadProducts()
                        }
                    }
                }
            }
        }
        .navigationTitle(appLanguage.ui("Unterstützen"))
        .themedPageBackground()
    }

    private var aboutSettingsForm: some View {
        Form {
            Section(appLanguage.ui("Über")) {
                Text(appLanguage.ui("GymPit hilft dir, Trainings, Übungen, Sätze, Pausen und Fortschritt festzuhalten."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section(appLanguage.ui("Datenschutz und Kosten")) {
                Text(appLanguage.ui("Die App ist kostenlos. Sie speichert keine Daten auf einem fremden Server und braucht kein Konto. Deine Trainingsdaten bleiben lokal auf deinem Gerät, außer du exportierst sie oder verbindest freiwillig Apple Health beziehungsweise Healthpit."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(appLanguage.ui("Über"))
        .themedPageBackground()
    }

    private func syncState() {
        bodyWeight = store.plan.profile.bodyWeightKilograms
        minutesPerSet = store.plan.profile.minutesPerSet
        setupMinutes = store.plan.profile.setupMinutesPerExercise
        defaultRestSeconds = store.plan.profile.defaultRestSeconds
        calorieOxygenFactor = store.plan.profile.calorieOxygenFactor
        calorieDivisor = store.plan.profile.calorieDivisor
        if bridgeDeviceID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || bridgeDeviceID == "GymPitApp" {
                bridgeDeviceID = "GymPit"
        }
        bridgeHomeAssistantToken = GymPitBridgeKeychainStore.string(for: GymPitBridgeSettings.homeAssistantTokenKey)
        refreshBridgeConnectionStatus()
    }

    /// Das Token, das zum Verbinden gebraucht wird.
    private var requiredBridgeToken: String { bridgeHomeAssistantToken }

    private func connectBridge() {
        isConnectingBridge = true
        bridgeConnectionStatus = appLanguage.ui("Healthpit verbindet...")
        Task {
            do {
                _ = try await GymPitBridgeSyncService.shared.connect()
                await MainActor.run {
                    isConnectingBridge = false
                    isBridgeConnected = true
                    bridgeConnectionStatus = appLanguage.ui("Healthpit ist verbunden")
                }
            } catch {
                await MainActor.run {
                    isConnectingBridge = false
                    refreshBridgeConnectionStatus()
                    bridgeConnectionStatus = "\(appLanguage.ui("Healthpit Verbindung Fehler")): \(error.localizedDescription)"
                }
            }
        }
    }

    /// Vom Anwender ausgeloest: der Token ist die Anmeldung, also muss er weg.
    private func disconnectBridge() {
        GymPitBridgeSyncService.shared.disconnect()
        bridgeHomeAssistantToken = ""
        refreshBridgeConnectionStatus()
    }

    /// Nur die Anzeige neu bewerten, wenn sich Adresse oder Token aendern.
    ///
    /// Hier darf nicht getrennt werden: der Token *ist* die Anmeldung, und beim
    /// Tippen kaeme jeder Tastendruck einem Loeschen des gerade eingegebenen
    /// Tokens gleich.
    private func resetBridgeConnection() {
        refreshBridgeConnectionStatus()
    }

    private func refreshBridgeConnectionStatus() {
        let service = GymPitBridgeSyncService.shared
        isBridgeConnected = service.hasSession
        // Ein Long-Lived Token laeuft nicht ab, es gibt also keine Restlaufzeit.
        if service.hasSession {
            bridgeConnectionStatus = appLanguage.ui("Healthpit ist verbunden")
        } else {
            bridgeConnectionStatus = appLanguage.ui("Healthpit ist nicht verbunden")
        }
    }

    private func saveProfile() {
        store.updateProfile(
            UserProfile(
                bodyWeightKilograms: bodyWeight,
                minutesPerSet: minutesPerSet,
                setupMinutesPerExercise: setupMinutes,
                defaultRestSeconds: defaultRestSeconds,
                calorieOxygenFactor: calorieOxygenFactor,
                calorieDivisor: calorieDivisor
            )
        )
    }

    private func importCSV(_ result: Result<URL, Error>) {
        Task {
            await processWorkoutImport(result)
        }
    }

    @MainActor
    private func processWorkoutImport(_ result: Result<URL, Error>) async {
        isProcessingWorkoutImport = true
        defer { isProcessingWorkoutImport = false }

        do {
            let url = try result.get()
            let data = try await Self.importData(from: url)
            let archive = try await Self.gymPitArchive(from: data)
            let summary = store.importDataArchive(archive)
            showCSVAlert(
                "\(summary.sessions.imported) Trainings und \(summary.routinesImported) Routinen importiert; "
                + "\(summary.sessions.skipped) Trainings und \(summary.routinesSkipped) Routinen übersprungen."
            )
        } catch {
            showCSVAlert("Import fehlgeschlagen: \(error.localizedDescription)")
        }
    }

    private func beginWorkoutImport() {
        DispatchQueue.main.async {
            isImportingCSV = true
        }
    }

    private static func importData(from url: URL) async throws -> Data {
        try await Task.detached(priority: .userInitiated) {
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            return try Data(contentsOf: url)
        }.value
    }

    private static func gymPitArchive(from data: Data) async throws -> WorkoutDataArchive {
        try await Task.detached(priority: .userInitiated) {
            try WorkoutDataArchiveCodec.importArchive(from: data)
        }.value
    }

    private func exportCSV() {
        do {
            let fileName = "gympit-daten-\(Self.csvFileDateFormatter.string(from: Date())).json"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try store.exportDataArchive().write(to: url, options: .atomic)
            csvExportItem = CSVExportItem(url: url)
        } catch {
            showCSVAlert("Export fehlgeschlagen: \(error.localizedDescription)")
        }
    }

    private func showCSVAlert(_ message: String) {
        csvAlertMessage = message
        isShowingCSVAlert = true
    }

    private static let csvFileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return formatter
    }()

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }

    private var currentDesign: AppDesign {
        AppDesign.value(for: appDesignRawValue)
    }
}

private struct CSVExportItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct CSVShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}

private struct DesignPickerRow: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let design: AppDesign

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(design.accentColor)
                .frame(width: 14, height: 14)
            Text(appLanguage.ui(design.rawValue))
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct DesignPreviewRow: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let mode: AppearanceMode
    let design: AppDesign

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: mode.iconName)
                .foregroundStyle(design.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(appLanguage.ui(mode.rawValue)) · \(appLanguage.ui(design.rawValue))")
                    .font(.subheadline.weight(.semibold))
                Text(appLanguage.ui("Wird sofort auf die App angewendet."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous)
                    .fill(design.accentColor)
                    .frame(width: 20, height: 20)
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous)
                    .fill(design.pageBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous)
                            .stroke(design.cardStroke, lineWidth: 1)
                    )
                    .frame(width: 20, height: 20)
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous)
                    .fill(design.cardBackground)
                    .frame(width: 20, height: 20)
            }
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private enum RoutineRoute: Hashable, Identifiable {
    case detail(UUID)
    case edit(UUID)

    var id: String {
        switch self {
        case .detail(let id): "detail-\(id.uuidString)"
        case .edit(let id): "edit-\(id.uuidString)"
        }
    }
}

private struct RoutinesView: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage("gympit_app_design") private var appDesignRawValue = AppDesign.ocean.rawValue
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    @State private var route: RoutineRoute?

    var body: some View {
        NavigationStack {
            List {
                Section(appLanguage.ui("Routinen")) {
                    ForEach(store.routines) { routine in
                        HStack(spacing: 8) {
                            Button {
                                store.selectRoutine(routine)
                            } label: {
                                RoutineListRow(routine: routine)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Button {
                                route = .detail(routine.id)
                            } label: {
                                Image(systemName: "list.bullet.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 32, height: 32)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(routine.name) \(appLanguage.ui("Anzeigen"))")

                            Button {
                                route = .edit(routine.id)
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 32, height: 32)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(routine.name) \(appLanguage.ui("Bearbeiten"))")
                        }
                    }
                    .onDelete(perform: store.deleteRoutine)
                }

                Section {
                    Button {
                        store.createEmptyRoutine()
                        route = .edit(store.plan.id)
                    } label: {
                        Label(appLanguage.ui("Neue Routine erstellen"), systemImage: "plus.square")
                    }
                }

                Section(appLanguage.ui("Aktive Routine")) {
                    StatTile(title: appLanguage.ui("Übungen"), value: "\(store.plan.exercises.count)", icon: "list.bullet")
                    StatTile(title: appLanguage.ui("Volumen"), value: store.plan.totalVolume.formattedWeight(unit: weightUnit), icon: "scalemass")
                    StatTile(title: appLanguage.ui("Kalorien"), value: "\(store.plan.estimatedCalories)", icon: "flame")
                }
            }
            .navigationTitle(appLanguage.ui("Routinen"))
            .navigationDestination(item: $route) { route in
                switch route {
                case .detail(let routineID):
                    if let routine = store.routines.first(where: { $0.id == routineID }) {
                        RoutineDetailView(routine: routine)
                    }
                case .edit(let routineID):
                    if let routine = store.routines.first(where: { $0.id == routineID }) {
                        RoutineEditorView(routine: routine)
                    }
                }
            }
            .themedPageBackground()
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var currentDesign: AppDesign {
        AppDesign.value(for: appDesignRawValue)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }
}

private struct RoutineDetailView: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let routine: WorkoutPlan

    private var currentRoutine: WorkoutPlan {
        store.routines.first(where: { $0.id == routine.id }) ?? routine
    }

    var body: some View {
        List {
            Section {
                StatTile(title: appLanguage.ui("Übungen"), value: "\(currentRoutine.exercises.count)", icon: "list.bullet")
                StatTile(title: appLanguage.ui("Sätze"), value: "\(currentRoutine.exercises.reduce(0) { $0 + $1.sets.count })", icon: "checklist")
                StatTile(title: appLanguage.ui("Kalorien"), value: "\(currentRoutine.estimatedCalories)", icon: "flame")

                if currentRoutine.id != store.plan.id {
                    Button {
                        store.selectRoutine(currentRoutine)
                    } label: {
                        Label(appLanguage.ui("Als aktive Routine verwenden"), systemImage: "checkmark.circle")
                    }
                }
            }

            Section(appLanguage.ui("Übungen")) {
                if currentRoutine.exercises.isEmpty {
                    Text(appLanguage.ui("Keine Übungen in dieser Routine."))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(currentRoutine.exercises.enumerated()), id: \.element.id) { index, exercise in
                        NavigationLink {
                            ExerciseRecordsView(exercise: exercise)
                        } label: {
                            HStack(spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.caption.weight(.semibold))
                                    .frame(width: 26, height: 26)
                                    .background(Color(.secondarySystemGroupedBackground), in: Circle())

                                PlanExerciseSettingsRow(exercise: exercise)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(currentRoutine.name)
        .navigationBarTitleDisplayMode(.inline)
        .themedPageBackground()
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct RoutineListRow: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let routine: WorkoutPlan

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isDefault ? "star.fill" : "list.bullet.rectangle")
                .foregroundStyle(isDefault ? .yellow : (isActive ? Color.accentColor : .secondary))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(routine.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if isActive {
                        Text(appLanguage.ui("Aktiv"))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                Text("\(routine.exercises.count) \(appLanguage.ui("Übungen"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var isActive: Bool {
        routine.id == store.plan.id
    }

    private var isDefault: Bool {
        routine.id == store.defaultRoutineID
    }
}

private struct RoutineEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    let routine: WorkoutPlan
    @State private var planName = ""
    @State private var isAddingExercise = false
    @State private var goalMode: WorkoutCompletionGoalMode = .allExercises
    @State private var goalValue: Double = 0

    var body: some View {
        List {
            Section(appLanguage.ui("Routine")) {
                TextField(appLanguage.ui("Name"), text: $planName)
                    .onSubmit(savePlanName)

                Button {
                    store.setDefaultRoutine(store.plan)
                } label: {
                    Label(store.plan.id == store.defaultRoutineID ? appLanguage.ui("Standardroutine") : appLanguage.ui("Als Standard favorisieren"), systemImage: store.plan.id == store.defaultRoutineID ? "star.fill" : "star")
                }
            }

            Section(appLanguage.ui("Ziel")) {
                Picker(appLanguage.ui("100 % bei"), selection: $goalMode) {
                    ForEach(WorkoutCompletionGoalMode.allCases) { mode in
                        Text(appLanguage.ui(mode.rawValue)).tag(mode)
                    }
                }

                if goalMode != .allExercises {
                    Stepper(value: $goalValue, in: goalRange, step: goalStep) {
                        SettingsValueRow(title: goalValueTitle, value: goalValueText)
                    }
                } else {
                    Text(appLanguage.ui("100 % wird erreicht, wenn alle Übungen erledigt sind."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section(appLanguage.ui("Übungen")) {
                Button {
                    isAddingExercise = true
                } label: {
                    Label(appLanguage.ui("Übung hinzufügen"), systemImage: "plus.circle.fill")
                }

                if store.plan.exercises.isEmpty {
                    Text(appLanguage.ui("Noch keine Übungen in dieser Routine."))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.plan.exercises) { exercise in
                        NavigationLink {
                            ExercisePlanEditor(exercise: exercise)
                        } label: {
                            PlanExerciseSettingsRow(exercise: exercise)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.map { store.plan.exercises[$0] }.forEach(store.removeExercise)
                    }
                    .onMove(perform: store.moveExercise)
                }
            }
        }
        .navigationTitle(appLanguage.ui("Bearbeiten"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isAddingExercise) {
            AddExerciseView()
        }
        .onAppear {
            store.selectRoutine(routine)
            planName = store.plan.name
            goalMode = store.plan.completionGoal.mode
            goalValue = defaultGoalValue(for: goalMode, stored: store.plan.completionGoal.value)
        }
        .onChange(of: goalMode) { _, newMode in
            goalValue = defaultGoalValue(for: newMode, stored: goalValue)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(appLanguage.ui("Sichern")) {
                    savePlanName()
                    saveGoal()
                    dismiss()
                }
            }
        }
        .themedPageBackground()
    }

    private func savePlanName() {
        store.renamePlan(planName)
        planName = store.plan.name
    }

    private func saveGoal() {
        store.updateCompletionGoal(WorkoutCompletionGoal(mode: goalMode, value: goalValue))
        goalValue = store.plan.completionGoal.value
    }

    private var goalRange: ClosedRange<Double> {
        switch goalMode {
        case .allExercises:
            0...0
        case .exerciseCount:
            1...Double(max(1, store.plan.exercises.count))
        case .totalVolume:
            100...50000
        case .durationMinutes:
            5...240
        case .setCount:
            1...Double(max(1, store.plan.exercises.reduce(0) { $0 + $1.sets.count }))
        }
    }

    private var goalStep: Double {
        switch goalMode {
        case .allExercises, .exerciseCount, .durationMinutes, .setCount:
            1
        case .totalVolume:
            100
        }
    }

    private var goalValueText: String {
        switch goalMode {
        case .allExercises:
            "Alle"
        case .exerciseCount:
            "\(Int(goalValue.rounded())) Übungen"
        case .totalVolume:
            goalValue.formattedWeight(unit: weightUnit)
        case .durationMinutes:
            "\(Int(goalValue.rounded())) min"
        case .setCount:
            "\(Int(goalValue.rounded())) Sätze"
        }
    }

    private var goalValueTitle: String {
        switch goalMode {
        case .exerciseCount:
            "Verfügbare Übungen für 100 %"
        case .totalVolume:
            "Gesamtvolumen für 100 %"
        case .durationMinutes:
            "Trainingszeit für 100 %"
        case .setCount:
            "Satzanzahl für 100 %"
        case .allExercises:
            "Zielwert"
        }
    }

    private func defaultGoalValue(for mode: WorkoutCompletionGoalMode, stored: Double) -> Double {
        if mode == .allExercises {
            return 0
        }
        let range = goalRange(for: mode)
        if stored > 0 {
            return min(max(stored, range.lowerBound), range.upperBound)
        }
        switch mode {
        case .allExercises:
            return 0
        case .exerciseCount:
            return Double(max(1, store.plan.exercises.count))
        case .totalVolume:
            return 5000
        case .durationMinutes:
            return 60
        case .setCount:
            return Double(max(1, store.plan.exercises.reduce(0) { $0 + $1.sets.count }))
        }
    }

    private func goalRange(for mode: WorkoutCompletionGoalMode) -> ClosedRange<Double> {
        switch mode {
        case .allExercises:
            0...0
        case .exerciseCount:
            1...Double(max(1, store.plan.exercises.count))
        case .totalVolume:
            100...50000
        case .durationMinutes:
            5...240
        case .setCount:
            1...Double(max(1, store.plan.exercises.reduce(0) { $0 + $1.sets.count }))
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }
}

private struct HistoryView: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage("gympit_app_design") private var appDesignRawValue = AppDesign.ocean.rawValue
    @State private var isAddingManualWorkout = false
    @State private var mode: HistoryMode = .graphs
    @State private var selectedRoutineID: UUID?

    var body: some View {
        let design = AppDesign.value(for: appDesignRawValue)

        NavigationStack {
            List {
                Section {
                    Picker(appLanguage.ui("Ansicht"), selection: $mode) {
                        ForEach(HistoryMode.allCases) { mode in
                            Text(appLanguage.ui(mode.rawValue)).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if mode == .graphs {
                    HistoryGraphsSection(selectedRoutineID: $selectedRoutineID)
                } else {
                    if store.history.isEmpty {
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(appLanguage.ui("Noch keine abgeschlossenen Trainings"), systemImage: "clock")
                                    .font(.headline)
                                Text(appLanguage.ui("Sobald du alle Übungen abgeschlossen hast, landet das Training hier mit Volumen, Kalorien und Sätzen."))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    } else {
                        Section(appLanguage.ui("Trainings")) {
                            ForEach(store.history) { session in
                                NavigationLink {
                                    SessionDetailView(session: session)
                                } label: {
                                    SessionRow(session: session)
                                }
                            }
                            .onDelete(perform: store.deleteHistory)
                        }
                    }
                }
            }
            .navigationTitle(appLanguage.ui("Historie"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if mode == .trainings {
                        Button {
                            isAddingManualWorkout = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel(appLanguage.ui("Training manuell hinzufügen"))
                    }
                }
            }
            .sheet(isPresented: $isAddingManualWorkout) {
                NavigationStack {
                    ManualWorkoutEntryView()
                }
            }
            .tint(design.accentColor)
            .themedPageBackground()
            .onAppear(perform: ensureSelectedRoutine)
            .onChange(of: store.routines) { _, _ in
                ensureSelectedRoutine()
            }
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private func ensureSelectedRoutine() {
        guard selectedRoutineID == nil || !store.routines.contains(where: { $0.id == selectedRoutineID }) else { return }
        selectedRoutineID = store.routines.first(where: { $0.id == store.defaultRoutineID })?.id ?? store.routines.first?.id ?? store.plan.id
    }
}

private enum HistoryMode: String, CaseIterable, Identifiable {
    case graphs = "Graphs"
    case trainings = "Trainings"

    var id: String { rawValue }
}

private struct HistoryExerciseRoute: Hashable, Identifiable {
    let id: UUID
}

private struct HistoryGraphsSection: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @Binding var selectedRoutineID: UUID?
    @State private var selectedExerciseRoute: HistoryExerciseRoute?

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]

    var body: some View {
        Group {
            if store.routines.count > 1 {
                Section(appLanguage.ui("Routine")) {
                    Picker(appLanguage.ui("Routine"), selection: $selectedRoutineID) {
                        ForEach(store.routines) { routine in
                            Text(routine.name).tag(Optional(routine.id))
                        }
                    }
                }
            }

            Section(appLanguage.ui("Graphs")) {
                if currentRoutine.exercises.isEmpty {
                    Text(appLanguage.ui("Keine Übungen in dieser Routine."))
                        .foregroundStyle(.secondary)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(currentRoutine.exercises) { exercise in
                            Button {
                                selectedExerciseRoute = HistoryExerciseRoute(id: exercise.id)
                            } label: {
                                HistoryExerciseGraphTile(exercise: exercise)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(exercise.localizedName(language: appLanguage)) \(appLanguage.ui("Übersicht öffnen"))")
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                }
            }
        }
        .navigationDestination(item: $selectedExerciseRoute) { route in
            if let exercise = exercise(for: route.id) {
                ExerciseRecordsView(exercise: exercise)
            } else {
                EmptyView()
            }
        }
    }

    private var currentRoutine: WorkoutPlan {
        if let selectedRoutineID,
           let routine = store.routines.first(where: { $0.id == selectedRoutineID }) {
            return routine
        }

        return store.routines.first(where: { $0.id == store.defaultRoutineID }) ?? store.routines.first ?? store.plan
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private func exercise(for id: UUID) -> Exercise? {
        currentRoutine.exercises.first(where: { $0.id == id }) ??
        store.routines.flatMap(\.exercises).first(where: { $0.id == id })
    }
}

private struct HistoryExerciseGraphTile: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                ExerciseArtwork(category: exercise.category, size: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text(exercise.localizedName(language: appLanguage))
                        .font(.caption.weight(.semibold))
                        .lineLimit(2)
                    if let latestDateText {
                        Text(latestDateText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                Spacer(minLength: 0)
            }

            if trendPoints.isEmpty {
                Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(trendPoints) { point in
                    AreaMark(
                        x: .value("Datum", point.date),
                        y: .value(appLanguage.ui("Gewicht"), point.maxWeight)
                    )
                    .foregroundStyle(Color.accentColor.opacity(0.14))

                    LineMark(
                        x: .value("Datum", point.date),
                        y: .value(appLanguage.ui("Gewicht"), point.maxWeight)
                    )
                    .foregroundStyle(Color.accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            HStack(spacing: 6) {
                GraphTileValue(title: appLanguage.ui("Erster"), value: firstValueText, alignment: .leading)
                GraphTileValue(title: appLanguage.ui("Höchster"), value: highestValueText, alignment: .center, titleColor: .yellow, valueColor: .yellow)
                GraphTileValue(title: appLanguage.ui("Letzter"), value: latestValueText, alignment: .trailing, titleColor: latestValueColor, valueColor: latestValueColor)
            }
        }
        .padding(10)
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous)
                .stroke(Color.accentColor.opacity(0.12), lineWidth: 1)
        )
    }

    private var trendPoints: [ExerciseTrendPoint] {
        store.trendPoints(for: exercise, scale: .all)
    }

    private var measuredTrendPoints: [ExerciseTrendPoint] {
        trendPoints.filter { $0.maxWeight > 0 }
    }

    private var latestDateText: String? {
        guard let latest = trendPoints.last else { return nil }
        return latest.date.formatted(date: .abbreviated, time: .omitted)
    }

    private var highestValueText: String {
        valueText(measuredTrendPoints.map(\.maxWeight).max())
    }

    private var latestValueText: String {
        valueText(measuredTrendPoints.last?.maxWeight)
    }

    private var latestValueColor: Color {
        latestValueIsHighest ? .green : .primary
    }

    private var latestValueIsHighest: Bool {
        guard let latest = measuredTrendPoints.last?.maxWeight,
              let highest = measuredTrendPoints.map(\.maxWeight).max(),
              latest > 0 else { return false }
        return abs(latest - highest) < 0.001
    }

    private var firstValueText: String {
        valueText(measuredTrendPoints.first?.maxWeight)
    }

    private func valueText(_ value: Double?) -> String {
        guard let value, value > 0 else { return "-" }
        return value.formattedWeight(unit: weightUnit)
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }
}

private struct GraphTileValue: View {
    let title: String
    let value: String
    var alignment: HorizontalAlignment = .leading
    var titleColor: Color = .secondary
    var valueColor: Color = .primary

    private var frameAlignment: Alignment {
        switch alignment {
        case .center:
            return .center
        case .trailing:
            return .trailing
        default:
            return .leading
        }
    }

    var body: some View {
        VStack(alignment: alignment, spacing: 1) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(titleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(value)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
    }
}

private struct ManualWorkoutDraftSet: Identifiable, Equatable {
    let id: UUID
    var type: WorkoutSetType
    var reps: Int
    var weightText: String
    var rpe: Int
    var isLogged: Bool

    init(
        id: UUID = UUID(),
        type: WorkoutSetType = .normal,
        reps: Int,
        weightText: String,
        rpe: Int = 0,
        isLogged: Bool = true
    ) {
        self.id = id
        self.type = type
        self.reps = reps
        self.weightText = weightText
        self.rpe = rpe
        self.isLogged = isLogged
    }

    init(set: ExerciseSet, weightUnit: WeightUnit) {
        self.init(
            type: set.type,
            reps: set.reps,
            weightText: formattedWeightInput(set.weight, unit: weightUnit),
            rpe: set.rpe ?? 0
        )
    }

    func sessionSet(weightUnit: WeightUnit) -> WorkoutSessionSet {
        WorkoutSessionSet(
            id: id,
            type: type,
            reps: max(1, min(999, reps)),
            weight: parsedWeightInput(weightText, unit: weightUnit),
            rpe: rpe == 0 ? nil : rpe
        )
    }
}

private struct ManualWorkoutDraftExercise: Identifiable, Equatable {
    let id: UUID
    var catalogID: String
    var name: String
    var target: String
    var category: DeviceCategory
    var deviceSettings: DeviceSettings
    var notes: String
    var sets: [ManualWorkoutDraftSet]

    init(item: ExerciseCatalogItem, weightUnit: WeightUnit) {
        id = UUID()
        catalogID = item.id
        name = item.name
        target = item.target
        category = item.category
        deviceSettings = item.device
        notes = ""
        sets = (0..<max(1, item.defaultSets)).map { _ in
            ManualWorkoutDraftSet(reps: item.defaultReps, weightText: formattedWeightInput(item.defaultWeight, unit: weightUnit))
        }
    }

    init(exercise: Exercise, weightUnit: WeightUnit) {
        id = UUID()
        catalogID = exercise.catalogID
        name = exercise.name
        target = exercise.target
        category = exercise.category
        deviceSettings = exercise.device
        notes = exercise.notes
        let planned = exercise.sets.isEmpty
            ? [ExerciseSet(id: UUID(), type: .normal, reps: 12, weight: 0, rpe: nil, isLogged: false)]
            : exercise.sets
        sets = planned.map { ManualWorkoutDraftSet(set: $0, weightUnit: weightUnit) }
    }

    var loggedSets: [ManualWorkoutDraftSet] {
        sets.filter(\.isLogged)
    }

    func sessionExercise(weightUnit: WeightUnit) -> WorkoutSessionExercise? {
        let recordedSets = loggedSets
        guard !recordedSets.isEmpty else { return nil }

        return WorkoutSessionExercise(
            id: id,
            catalogID: catalogID,
            name: name,
            category: category,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            deviceSettings: deviceSettings,
            sets: recordedSets.map { $0.sessionSet(weightUnit: weightUnit) }
        )
    }
}

private struct ManualWorkoutEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue

    @State private var planName = ""
    @State private var performedAt = Date()
    @State private var durationMinutes = 60
    @State private var caloriesText = ""
    @State private var notes = ""
    @State private var selectedRoutineID: UUID?
    @State private var exercises: [ManualWorkoutDraftExercise] = []
    @State private var isAddingExercise = false
    @State private var hasLoadedRoutine = false

    var body: some View {
        Form {
            Section(appLanguage.ui("Training")) {
                if !store.routines.isEmpty {
                    Picker(appLanguage.ui("Routine"), selection: $selectedRoutineID) {
                        ForEach(store.routines) { routine in
                            Text(routine.name).tag(Optional(routine.id))
                        }
                    }
                }
                TextField(appLanguage.ui("Name"), text: $planName)
                DatePicker(
                    appLanguage.ui("Datum"),
                    selection: $performedAt,
                    in: ...Date(),
                    displayedComponents: .date
                )
                DatePicker(
                    appLanguage.ui("Uhrzeit"),
                    selection: $performedAt,
                    in: ...Date(),
                    displayedComponents: .hourAndMinute
                )
                Stepper(value: $durationMinutes, in: 1...1_440, step: 5) {
                    SettingsValueRow(title: appLanguage.ui("Dauer"), value: "\(durationMinutes) min")
                }
                TextField(appLanguage.ui("Kalorien optional"), text: $caloriesText)
                    .keyboardType(.numberPad)
            }

            if exercises.isEmpty {
                Section {
                    Label(appLanguage.ui("Noch keine Übungen hinzugefügt."), systemImage: "checklist")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach($exercises) { $exercise in
                    ManualWorkoutExerciseEditor(exercise: $exercise) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            exercises.removeAll { $0.id == exercise.id }
                        }
                    }
                }
            }

            Section {
                Button {
                    isAddingExercise = true
                } label: {
                    Label(appLanguage.ui("Übung hinzufügen"), systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } footer: {
                Text(appLanguage.ui("Nicht durchgeführte Sätze einfach abwählen."))
            }

            Section(appLanguage.ui("Notizen")) {
                TextField(appLanguage.ui("Notiz"), text: $notes, axis: .vertical)
                    .lineLimit(2...6)
            }
        }
        .navigationTitle(appLanguage.ui("Training nachtragen"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(appLanguage.ui("Abbrechen")) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(appLanguage.ui("Sichern")) {
                    save()
                }
                .disabled(!canSave)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(appLanguage.ui("Fertig")) {
                    UIApplication.shared.endEditing()
                }
            }
        }
        .sheet(isPresented: $isAddingExercise) {
            NavigationStack {
                ManualWorkoutExercisePicker { exercise in
                    exercises.append(exercise)
                }
            }
        }
        .onAppear(perform: loadInitialRoutineIfNeeded)
        .onChange(of: selectedRoutineID) { _, newValue in
            guard hasLoadedRoutine else { return }
            applyRoutine(id: newValue)
        }
        .themedPageBackground()
    }

    private var canSave: Bool {
        exercises.contains { !$0.loggedSets.isEmpty }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }

    private func loadInitialRoutineIfNeeded() {
        guard !hasLoadedRoutine else { return }
        hasLoadedRoutine = true

        let routine = store.routines.first(where: { $0.id == store.plan.id })
            ?? store.routines.first(where: { $0.id == store.defaultRoutineID })
            ?? store.routines.first
        selectedRoutineID = routine?.id
        apply(routine: routine)
    }

    private func applyRoutine(id: UUID?) {
        apply(routine: store.routines.first(where: { $0.id == id }))
    }

    private func apply(routine: WorkoutPlan?) {
        guard let routine else { return }
        planName = routine.name
        exercises = routine.exercises.map { ManualWorkoutDraftExercise(exercise: $0, weightUnit: weightUnit) }
        durationMinutes = estimatedMinutes(for: routine)
    }

    private func estimatedMinutes(for routine: WorkoutPlan) -> Int {
        let setCount = routine.exercises.reduce(0) { $0 + $1.sets.count }
        guard setCount > 0 else { return durationMinutes }
        let minutes = Double(setCount) * routine.profile.minutesPerSet
            + Double(routine.exercises.count) * routine.profile.setupMinutesPerExercise
        return max(1, min(1_440, Int(minutes.rounded())))
    }

    private func save() {
        let parsedCalories = Int(caloriesText.trimmingCharacters(in: .whitespacesAndNewlines))
        let sessionExercises = exercises.compactMap { $0.sessionExercise(weightUnit: weightUnit) }
        guard store.addManualHistorySession(
            planName: planName,
            performedAt: performedAt,
            durationMinutes: Double(durationMinutes),
            calories: parsedCalories,
            notes: notes,
            exercises: sessionExercises
        ) != nil else { return }
        dismiss()
    }
}

private struct ManualWorkoutExercisePicker: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    let onSelect: (ManualWorkoutDraftExercise) -> Void

    @State private var searchText = ""

    var body: some View {
        List {
            let routineExercises = filteredRoutineExercises
            if !routineExercises.isEmpty {
                Section(appLanguage.ui("Aus deinen Routinen")) {
                    ForEach(routineExercises) { exercise in
                        Button {
                            onSelect(ManualWorkoutDraftExercise(exercise: exercise, weightUnit: weightUnit))
                            dismiss()
                        } label: {
                            HStack(spacing: 10) {
                                ExerciseArtwork(category: exercise.category, size: 34)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.localizedName(language: appLanguage))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(exercise.target)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer(minLength: 8)

                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            ForEach(DeviceCategory.allCases) { category in
                let items = filteredItems(for: category)
                if !items.isEmpty {
                    Section(category.localizedName(language: appLanguage)) {
                        ForEach(items) { item in
                            CatalogItemRow(item: item) {
                                onSelect(ManualWorkoutDraftExercise(item: item, weightUnit: weightUnit))
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(appLanguage.ui("Übung hinzufügen"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: appLanguage.ui("Übung suchen"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(appLanguage.ui("Abbrechen")) {
                    dismiss()
                }
            }
        }
    }

    private var filteredRoutineExercises: [Exercise] {
        var seen: Set<String> = []
        let exercises = store.routines
            .flatMap(\.exercises)
            .filter { seen.insert($0.catalogID).inserted }
        guard !trimmedSearchText.isEmpty else { return exercises }
        return exercises.filter {
            $0.localizedName(language: appLanguage).localizedCaseInsensitiveContains(trimmedSearchText) ||
            $0.name.localizedCaseInsensitiveContains(trimmedSearchText)
        }
    }

    private func filteredItems(for category: DeviceCategory) -> [ExerciseCatalogItem] {
        let items = ExerciseCatalog.all.filter { $0.category == category }
        guard !trimmedSearchText.isEmpty else { return items }
        return items.filter {
            $0.localizedName(language: appLanguage).localizedCaseInsensitiveContains(trimmedSearchText) ||
            $0.name.localizedCaseInsensitiveContains(trimmedSearchText) ||
            $0.device.machineName.localizedCaseInsensitiveContains(trimmedSearchText)
        }
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }
}

private struct ManualWorkoutExerciseEditor: View {
    @Binding var exercise: ManualWorkoutDraftExercise
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    let onDelete: () -> Void

    var body: some View {
        Section {
            HStack(spacing: 10) {
                ExerciseArtwork(category: exercise.category, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.localizedName(language: appLanguage))
                        .font(.subheadline.weight(.semibold))
                    Text(exercise.target.isEmpty ? exercise.category.localizedName(language: appLanguage) : exercise.target)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("\(exercise.localizedName(language: appLanguage)) \(appLanguage.ui("entfernen"))")
            }

            TextField(appLanguage.ui("Übungsnotiz"), text: $exercise.notes, axis: .vertical)
                .lineLimit(1...4)

            ForEach(Array(exercise.sets.indices), id: \.self) { index in
                ManualWorkoutSetEditor(
                    set: $exercise.sets[index],
                    index: index,
                    canDelete: exercise.sets.count > 1
                ) {
                    exercise.sets.remove(at: index)
                }
            }

            Button {
                addSet()
            } label: {
                Label(appLanguage.ui("Satz hinzufügen"), systemImage: "plus.circle")
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        } header: {
            Text(exercise.localizedName(language: appLanguage))
        } footer: {
            Text(summaryText)
        }
    }

    private var summaryText: String {
        let loggedCount = exercise.loggedSets.count
        let volume = exercise.loggedSets.reduce(0.0) {
            $0 + parsedWeightInput($1.weightText, unit: weightUnit) * Double(max(0, $1.reps))
        }
        let volumeText = volume > 0 ? " · \(volume.formattedWeight(unit: weightUnit))" : ""
        return "\(loggedCount)/\(exercise.sets.count) \(appLanguage.ui("Sätze"))\(volumeText)"
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }

    private func addSet() {
        let template = exercise.sets.last ?? ManualWorkoutDraftSet(reps: 12, weightText: formattedWeightInput(0, unit: weightUnit))
        exercise.sets.append(
            ManualWorkoutDraftSet(
                type: template.type,
                reps: template.reps,
                weightText: template.weightText,
                rpe: template.rpe
            )
        )
    }
}

private struct ManualWorkoutSetEditor: View {
    @Binding var set: ManualWorkoutDraftSet
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    let index: Int
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(appLanguage.ui("Satz")) \(index + 1)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(set.isLogged ? appLanguage.ui("Erfasst") : appLanguage.ui("Nicht gemacht"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(set.isLogged ? .green : .secondary)

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.borderless)
                .disabled(!canDelete)
                .accessibilityLabel("\(appLanguage.ui("Satz")) \(index + 1) \(appLanguage.ui("entfernen"))")
            }

            HStack(spacing: 6) {
                typeMenu
                loggedToggle
                repsField
                weightField
                Spacer(minLength: 0)
                rpeMenu
            }
            .padding(.horizontal, 5)
            .frame(height: 42)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous)
                    .stroke(Color(.separator).opacity(0.26), lineWidth: 0.75)
            )
            .opacity(set.isLogged ? 1 : 0.55)
        }
        .padding(.vertical, 2)
    }

    private var typeMenu: some View {
        Menu {
            ForEach(WorkoutSetType.allCases) { type in
                Button(type.rawValue) {
                    set.type = type
                }
            }
        } label: {
            VStack(spacing: 2) {
                Text(set.type.shortTitle)
                    .font(.caption.weight(.bold))
                Text(appLanguage.ui("Typ"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 38, height: 32)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: AppLayout.cornerRadius - 2, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var loggedToggle: some View {
        Button {
            set.isLogged.toggle()
        } label: {
            Image(systemName: set.isLogged ? "checkmark.circle.fill" : "circle")
                .font(.title3.weight(.semibold))
                .foregroundStyle(set.isLogged ? .green : .secondary)
                .frame(width: 26, height: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(appLanguage.ui("Satz")) \(index + 1) \(appLanguage.ui(set.isLogged ? "Nicht gemacht" : "Erfasst"))")
    }

    private var repsField: some View {
        SetInputField(title: appLanguage.ui("Wdh"), text: repsText, width: 34, keyboardType: .numberPad, isCompact: true) {}
    }

    private var weightField: some View {
        SetInputField(title: weightUnit.symbol, text: $set.weightText, width: 48, keyboardType: .decimalPad, isCompact: true) {}
    }

    private var rpeMenu: some View {
        Menu {
            Button(appLanguage.ui("Keine RPE")) {
                set.rpe = 0
            }
            ForEach(1...10, id: \.self) { value in
                Button("RPE \(value)") {
                    set.rpe = value
                }
            }
        } label: {
            Text(set.rpe == 0 ? "RPE" : "RPE \(set.rpe)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(minWidth: 46, minHeight: 32)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: AppLayout.cornerRadius - 2, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var repsText: Binding<String> {
        Binding(
            get: { String(set.reps) },
            set: { newValue in
                set.reps = max(1, min(999, Int(newValue) ?? set.reps))
            }
        )
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private extension ManualWorkoutDraftExercise {
    func localizedName(language: AppLanguage) -> String {
        ExerciseCatalog.localizedName(for: catalogID, fallback: name, language: language)
    }
}

private struct SessionDetailView: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    let session: WorkoutSession

    var body: some View {
        List {
            Section {
                LabeledContent {
                    Text("\(session.calories)")
                        .monospacedDigit()
                } label: {
                    Label(appLanguage.ui("Kalorien"), systemImage: "flame")
                }

                LabeledContent {
                    Text(session.totalVolume.formattedWeight(unit: weightUnit))
                        .monospacedDigit()
                } label: {
                    Label(appLanguage.ui("Volumen"), systemImage: "scalemass")
                }

                LabeledContent {
                    Text("\(session.totalSets)")
                        .monospacedDigit()
                } label: {
                    Label(appLanguage.ui("Sätze"), systemImage: "checklist")
                }

                if !session.notes.isEmpty {
                    Text(session.notes)
                        .foregroundStyle(.secondary)
                }
            }

            Section(appLanguage.ui("Muskelverteilung")) {
                MuscleDistributionView(
                    distribution: HistoryMuscleSummary.distribution(for: [session]),
                    showsCompletedProgress: false
                )
            }

            ForEach(session.exercises) { exercise in
                Section(exercise.localizedName(language: appLanguage)) {
                    if let route = deviceRoute(for: exercise) {
                        NavigationLink {
                            ExerciseRecordsView(exercise: route.exercise)
                        } label: {
                            Label(appLanguage.ui("Übersicht öffnen"), systemImage: "chart.bar.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(route.exercise.category.historyColor)
                        }
                    }

                    HStack {
                        Text("\(appLanguage.ui("Bestes Set")): \(exercise.bestSetDescription)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if exerciseHasRecord(exercise) {
                            Image(systemName: "trophy.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.yellow)
                                .accessibilityLabel(appLanguage.ui("Rekord"))
                        }
                    }

                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("\(index + 1)")
                                .font(.caption.weight(.semibold))
                                .frame(width: 24, height: 24)
                                .background(Color(.secondarySystemGroupedBackground), in: Circle())
                            Text(set.type.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(set.reps) x \(set.weight.formattedWeight(unit: weightUnit))")
                                .monospacedDigit()
                            if setHasRecord(set, in: exercise) {
                                Image(systemName: "trophy.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.yellow)
                                    .accessibilityLabel(appLanguage.ui("Rekord"))
                            }
                            if let rpe = set.rpe {
                                Text("RPE \(rpe)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(session.planName)
        .navigationBarTitleDisplayMode(.inline)
        .themedPageBackground()
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }

    private func deviceRoute(for sessionExercise: WorkoutSessionExercise) -> (routine: WorkoutPlan, exercise: Exercise)? {
        for routine in store.routines {
            if let exactExercise = routine.exercises.first(where: { $0.id == sessionExercise.id }) {
                return (routine, exactExercise)
            }

            if let catalogExercise = routine.exercises.first(where: { $0.catalogID == sessionExercise.catalogID }) {
                return (routine, catalogExercise)
            }

            let sessionExerciseName = normalizedExerciseName(sessionExercise.name)
            if let namedExercise = routine.exercises.first(where: { normalizedExerciseName($0.name) == sessionExerciseName }) {
                return (routine, namedExercise)
            }
        }

        return nil
    }

    private func normalizedExerciseName(_ name: String) -> String {
        name
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .filter { $0.isLetter || $0.isNumber }
            .lowercased()
    }

    private func historicalExercises(before sessionExercise: WorkoutSessionExercise) -> [WorkoutSessionExercise] {
        let sessionExerciseName = normalizedExerciseName(sessionExercise.name)

        return store.history
            .filter { $0.date < session.date }
            .sorted { $0.date < $1.date }
            .compactMap { oldSession in
                oldSession.exercises.first {
                    $0.catalogID == sessionExercise.catalogID ||
                    (!sessionExerciseName.isEmpty && normalizedExerciseName($0.name) == sessionExerciseName)
                }
            }
    }

    private func exerciseHasRecord(_ exercise: WorkoutSessionExercise) -> Bool {
        let previous = historicalExercises(before: exercise)
        let previousMaxWeight = previous.compactMap(\.maximumWeight).max() ?? 0
        let previousVolume = previous.map(\.volume).max() ?? 0
        let currentMaxWeight = exercise.maximumWeight ?? 0

        return (currentMaxWeight > previousMaxWeight && currentMaxWeight > 0) ||
            (exercise.volume > previousVolume && exercise.volume > 0)
    }

    private func setHasRecord(_ set: WorkoutSessionSet, in exercise: WorkoutSessionExercise) -> Bool {
        let historicalSets = historicalExercises(before: exercise).flatMap(\.sets)
        let setVolume = Double(set.reps) * set.weight
        let estimatedOneRepMax = set.weight * (1 + Double(max(0, set.reps)) / 30)

        let previousSetVolume = historicalSets.map { Double($0.reps) * $0.weight }.max() ?? 0
        let previousMaxWeight = historicalSets.map(\.weight).max() ?? 0
        let previousEstimatedOneRepMax = historicalSets
            .filter { $0.reps > 0 && $0.weight > 0 }
            .map { $0.weight * (1 + Double($0.reps) / 30) }
            .max() ?? 0

        return (setVolume > previousSetVolume && setVolume > 0) ||
            (set.weight > previousMaxWeight && set.weight > 0) ||
            (estimatedOneRepMax > previousEstimatedOneRepMax && estimatedOneRepMax > 0)
    }
}

private struct SessionRow: View {
    let session: WorkoutSession

    var body: some View {
        let category = HistoryMuscleSummary.dominantCategory(for: session)

        HStack(spacing: 10) {
            Image(systemName: category.iconName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(category.historyColor)
                .frame(width: 24)

            Text(session.planName)
                .font(.body)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private enum HistoryMuscleSummary {
    static func dominantCategory(for session: WorkoutSession) -> DeviceCategory {
        let totals = totals(for: [session])

        return orderedCategories.max { lhs, rhs in
            let lhsValue = totals[lhs, default: 0]
            let rhsValue = totals[rhs, default: 0]
            if lhsValue == rhsValue {
                return orderIndex(of: lhs) > orderIndex(of: rhs)
            }
            return lhsValue < rhsValue
        } ?? .freeWeights
    }

    static func distribution(for sessions: [WorkoutSession]) -> [(category: DeviceCategory, completedSets: Double, plannedSets: Double)] {
        let totals = totals(for: sessions)

        return orderedCategories.compactMap { category in
            let value = totals[category, default: 0]
            guard value > 0 else { return nil }
            return (category: category, completedSets: 0, plannedSets: value)
        }
    }

    private static func totals(for sessions: [WorkoutSession]) -> [DeviceCategory: Double] {
        var totals: [DeviceCategory: Double] = [:]

        for session in sessions {
            for exercise in session.exercises {
                let setCount = Double(max(1, exercise.sets.count))
                let weights = ExerciseCatalog.muscleWeights(for: exercise.catalogID, fallback: exercise.category)

                for (category, weight) in weights where weight > 0 {
                    totals[category, default: 0] += setCount * weight
                }
            }
        }

        return totals
    }

    private static var orderedCategories: [DeviceCategory] {
        DeviceCategory.muscleCategories + [.freeWeights]
    }

    private static func orderIndex(of category: DeviceCategory) -> Int {
        orderedCategories.firstIndex(of: category) ?? orderedCategories.count
    }
}

private extension DeviceCategory {
    var historyColor: Color {
        switch self {
        case .chest: .red
        case .back: .blue
        case .shoulders: .purple
        case .legs: .green
        case .arms: .orange
        case .core: .pink
        case .cardio: .cyan
        case .freeWeights: .indigo
        }
    }
}

private struct AddExerciseView: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    var addsToCurrentWorkoutOnly = false
    @State private var searchText = ""
    @State private var addedExerciseID: String?
    @State private var addedExerciseName: String?
    @State private var itemToConfigure: ExerciseCatalogItem?

    var body: some View {
        List {
            if let addedExerciseName {
                Section {
                    Label("\(addedExerciseName) \(appLanguage.ui("hinzugefügt"))", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            Section {
                NavigationLink {
                    DeviceExerciseCreatorView()
                } label: {
                    Label(appLanguage.ui("Eigene Übung erstellen"), systemImage: "plus.square.dashed")
                }
            }

            Section(appLanguage.ui("Schon im Plan")) {
                if store.plan.exercises.isEmpty {
                    Text(appLanguage.ui("Noch keine Übungen hinzugefügt."))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.plan.exercises) { exercise in
                        HStack(spacing: 10) {
                            ExerciseArtwork(category: exercise.category, size: 34)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.localizedName(language: appLanguage))
                                    .font(.subheadline.weight(.semibold))
                                Text(exercise.target)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button(role: .destructive) {
                                remove(exercise)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("\(exercise.localizedName(language: appLanguage)) \(appLanguage.ui("entfernen"))")
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.map { store.plan.exercises[$0] }.forEach(remove)
                    }
                }
            }

            ForEach(DeviceCategory.allCases) { category in
                let items = filteredItems(for: category)
                if !items.isEmpty {
                    Section(category.localizedName(language: appLanguage)) {
                        ForEach(items) { item in
                            CatalogItemRow(item: item, isAdded: addedExerciseID == item.id, countInPlan: countInPlan(for: item)) {
                                itemToConfigure = item
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(appLanguage.ui("Übung hinzufügen"))
        .searchable(text: $searchText, prompt: appLanguage.ui("Übung suchen"))
        .sheet(item: $itemToConfigure) { item in
            NavigationStack {
                AddCatalogExerciseConfigurationView(item: item) { setCount, reps, weight, target in
                    add(item, setCount: setCount, reps: reps, weight: weight, target: target)
                    itemToConfigure = nil
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func filteredItems(for category: DeviceCategory) -> [ExerciseCatalogItem] {
        let items = ExerciseCatalog.all.filter { $0.category == category }
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return items }
        return items.filter {
            $0.localizedName(language: appLanguage).localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.device.machineName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func add(_ item: ExerciseCatalogItem, setCount: Int, reps: Int, weight: Double, target: String) {
        if addsToCurrentWorkoutOnly {
            store.addWorkoutOnlyExercise(from: item, target: target, setCount: setCount, reps: reps, defaultWeight: weight)
        } else {
            store.addExercise(from: item, target: target, setCount: setCount, reps: reps, defaultWeight: weight)
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            addedExerciseID = item.id
            addedExerciseName = item.localizedName(language: appLanguage)
        }
    }

    private func remove(_ exercise: Exercise) {
        store.removeExercise(exercise)
        if addedExerciseID == exercise.catalogID {
            addedExerciseID = nil
            addedExerciseName = nil
        }
    }

    private func countInPlan(for item: ExerciseCatalogItem) -> Int {
        store.plan.exercises.filter { $0.catalogID == item.id }.count
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct WeightInputRow: View {
    let title: String
    @Binding var text: String
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue

    var body: some View {
        TextField("\(title) (\(weightUnit.symbol))", text: $text)
            .keyboardType(.decimalPad)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }
}

private struct MuscleDistributionEditor: View {
    @Binding var shares: [MuscleDistributionShare]
    let appLanguage: AppLanguage

    var body: some View {
        Section(appLanguage.ui("Muskelverteilung")) {
            ForEach(DeviceCategory.muscleCategories) { category in
                Stepper(value: percentageBinding(for: category), in: 0...100, step: 5) {
                    SettingsValueRow(
                        title: category.localizedName(language: appLanguage),
                        value: "\(Int(percentage(for: category).rounded())) %"
                    )
                }
            }

            Text(appLanguage.ui("Die Anteile werden beim Speichern automatisch auf 100 % verteilt."))
                .font(.footnote)
                .foregroundStyle(.secondary)

            if MuscleDistributionShare.normalizedShares(shares).isEmpty {
                Text(appLanguage.ui("Wähle mindestens eine Muskelgruppe."))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red)
            }
        }
    }

    private func percentage(for category: DeviceCategory) -> Double {
        (shares.first { $0.category == category }?.weight ?? 0) * 100
    }

    private func percentageBinding(for category: DeviceCategory) -> Binding<Double> {
        Binding(
            get: {
                percentage(for: category)
            },
            set: { newValue in
                let weight = max(0, min(100, newValue)) / 100
                if let index = shares.firstIndex(where: { $0.category == category }) {
                    if weight > 0 {
                        shares[index].weight = weight
                    } else {
                        shares.remove(at: index)
                    }
                } else if weight > 0 {
                    shares.append(MuscleDistributionShare(category: category, weight: weight))
                }
            }
        )
    }
}

private func formattedWeightInput(_ value: Double, unit: WeightUnit = .current) -> String {
    unit.displayValue(fromKilograms: value).formatted(.number.precision(.fractionLength(2)))
}

private func parsedWeightInput(_ text: String, fallback: Double = 0, unit: WeightUnit = .current) -> Double {
    let normalized = text
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: ",", with: ".")
    guard let value = Double(normalized) else { return fallback }
    let kilograms = unit.kilograms(fromDisplayValue: value)
    return min(400, max(0, (kilograms * 100).rounded() / 100))
}

private struct AddCatalogExerciseConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let item: ExerciseCatalogItem
    let onAdd: (Int, Int, Double, String) -> Void

    @State private var target: String
    @State private var setCount: Int
    @State private var reps: Int
    @State private var weightText: String

    init(item: ExerciseCatalogItem, onAdd: @escaping (Int, Int, Double, String) -> Void) {
        self.item = item
        self.onAdd = onAdd
        _target = State(initialValue: item.target)
        _setCount = State(initialValue: item.defaultSets)
        _reps = State(initialValue: item.category == .cardio ? item.defaultReps : 12)
        _weightText = State(initialValue: formattedWeightInput(item.defaultWeight))
    }

    var body: some View {
        Form {
            Section(appLanguage.ui("Übung")) {
                HStack(spacing: 12) {
                    ExerciseArtwork(category: item.category, size: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.localizedName(language: appLanguage))
                            .font(.headline)
                        Text(item.device.machineName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section(appLanguage.ui("Plan")) {
                TextField(appLanguage.ui("Ziel, z. B. 3 x 12"), text: $target)
                Stepper(value: $setCount, in: 1...8) {
                    SettingsValueRow(title: appLanguage.ui("Sätze"), value: "\(setCount)")
                }
                Stepper(value: $reps, in: 1...30) {
                    SettingsValueRow(title: appLanguage.ui("Wiederholungen"), value: "\(reps)")
                }
                WeightInputRow(title: appLanguage.ui("Startgewicht"), text: $weightText)
            }
        }
        .navigationTitle(appLanguage.ui("Hinzufügen"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(appLanguage.ui("Hinzufügen")) {
                    onAdd(setCount, reps, parsedWeightInput(weightText), target)
                    dismiss()
                }
            }
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct ExercisePlanEditor: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let exercise: Exercise

    @State private var exerciseName: String
    @State private var target: String
    @State private var setCount: Int
    @State private var reps: Int
    @State private var weightText: String
    @State private var muscleDistribution: [MuscleDistributionShare]
    @State private var metValue: Double
    @State private var notes: String
    @State private var restSeconds: Int
    @State private var supersetGroup: Int
    @State private var isFavorite: Bool
    @State private var deviceSettings: DeviceSettings

    init(exercise: Exercise) {
        self.exercise = exercise
        _exerciseName = State(initialValue: exercise.name)
        _target = State(initialValue: exercise.target)
        _setCount = State(initialValue: exercise.sets.count)
        _reps = State(initialValue: exercise.sets.first?.reps ?? 12)
        _weightText = State(initialValue: formattedWeightInput(exercise.sets.first?.weight ?? 0))
        _muscleDistribution = State(initialValue: exercise.effectiveMuscleDistribution)
        _metValue = State(initialValue: exercise.metValue)
        _notes = State(initialValue: exercise.notes)
        _restSeconds = State(initialValue: exercise.restSeconds)
        _supersetGroup = State(initialValue: exercise.supersetGroup ?? 0)
        _isFavorite = State(initialValue: exercise.isFavorite)
        _deviceSettings = State(initialValue: exercise.device.withoutDashPlaceholders)
    }

    var body: some View {
        Form {
            Section(appLanguage.ui("Übung")) {
                TextField(appLanguage.ui("Name der Übung"), text: $exerciseName)
            }

            Section(appLanguage.ui("Plan")) {
                TextField(appLanguage.ui("Ziel, z. B. 3 x 12"), text: $target)
                Stepper(value: $setCount, in: 1...8) {
                    SettingsValueRow(title: appLanguage.ui("Sätze"), value: "\(setCount)")
                }
                Stepper(value: $reps, in: 1...30) {
                    SettingsValueRow(title: appLanguage.ui("Wiederholungen"), value: "\(reps)")
                }
                WeightInputRow(title: appLanguage.ui("Startgewicht"), text: $weightText)
            }

            Section(appLanguage.ui("Kalorien")) {
                Stepper(value: $metValue, in: 1...12, step: 0.1) {
                    SettingsValueRow(title: appLanguage.ui("MET / Intensität"), value: metValue.formatted(.number.precision(.fractionLength(1))))
                }
                Text(appLanguage.ui("Dieser Wert fließt in die Kalorienformel unter Mehr ein."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            MuscleDistributionEditor(shares: $muscleDistribution, appLanguage: appLanguage)

            if exercise.isDeviceBased {
                DeviceSettingsFields(settings: $deviceSettings)
            }

            Section(appLanguage.ui("Optionen")) {
                Toggle(appLanguage.ui("Favorit"), isOn: $isFavorite)
                Stepper(value: $restSeconds, in: 0...300, step: 15) {
                    SettingsValueRow(title: appLanguage.ui("Pause nach Satz"), value: "\(restSeconds) s")
                }
                Picker(appLanguage.ui("Superset"), selection: $supersetGroup) {
                    Text(appLanguage.ui("Kein Superset")).tag(0)
                    Text("\(appLanguage.ui("Superset")) A").tag(1)
                    Text("\(appLanguage.ui("Superset")) B").tag(2)
                    Text("\(appLanguage.ui("Superset")) C").tag(3)
                }
            }

            Section(appLanguage.ui("Notizen")) {
                TextField(appLanguage.ui("Technik, Ziel oder Erinnerung"), text: $notes, axis: .vertical)
                    .lineLimit(2...6)
            }

            Section {
                Button(role: .destructive) {
                    store.removeExercise(exercise)
                    dismiss()
                } label: {
                    Label(appLanguage.ui("Aus Plan entfernen"), systemImage: "trash")
                }
            }
        }
        .navigationTitle(exercise.localizedName(language: appLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(appLanguage.ui("Fertig")) {
                    let weight = parsedWeightInput(weightText, fallback: exercise.sets.first?.weight ?? 0)
                    store.renameExercise(exercise, name: exerciseName)
                    store.updateExercise(exercise, target: target, setCount: setCount, reps: reps, defaultWeight: weight, metValue: metValue)
                    store.updateMuscleDistribution(exercise, shares: muscleDistribution)
                    store.updateExerciseNotes(exercise, notes: notes)
                    store.updateDevice(for: exercise, settings: deviceSettings)
                    store.updateExerciseOptions(
                        exercise,
                        restSeconds: restSeconds,
                        supersetGroup: supersetGroup == 0 ? nil : supersetGroup,
                        isFavorite: isFavorite
                    )
                    dismiss()
                }
            }
        }
        .themedPageBackground()
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct WorkoutOverviewCard: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage("gympit_trainer_enabled") private var isTrainerEnabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: store.plan.isWorkoutStarted ? 5 : 7) {
            header

            ProgressView(value: progress)
                .tint(Color.accentColor)
                .frame(height: 3)

            if !store.plan.isWorkoutStarted {
                HStack(spacing: 6) {
                    MiniStatTile(title: appLanguage.ui("Übungen"), value: "\(store.plan.exercises.count)", icon: "list.bullet")
                    MiniStatTile(title: appLanguage.ui("Sätze"), value: "\(store.plan.totalCompletedSets)", icon: "checklist")
                    MiniStatTile(title: appLanguage.ui("Kalorien"), value: "\(store.plan.estimatedCalories)", icon: "flame")
                }
            }

            if !store.plan.exercises.isEmpty {
                DisclosureGroup {
                    MuscleDistributionView(
                        distribution: store.plan.muscleProgressDistribution,
                        showsCompletedProgress: store.plan.isWorkoutStarted
                    )
                        .padding(.top, 4)
                } label: {
                    Label(appLanguage.ui("Muskelverteilung"), systemImage: "chart.bar.fill")
                        .font(.caption.weight(.semibold))
                }
            }
        }
        .padding(store.plan.isWorkoutStarted ? 8 : 10)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .neutralCard()
    }

    private var header: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(store.plan.name)
                    .font(store.plan.isWorkoutStarted ? .subheadline.weight(.semibold) : .headline.weight(.semibold))
                    .lineLimit(1)
                Text("\(store.plan.openExercises.count) \(appLanguage.ui("offen")), \(store.plan.completedExercises.count) \(appLanguage.ui("erledigt")) · \(store.plan.progressSummary(language: appLanguage))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if store.plan.isWorkoutStarted {
                    WorkoutElapsedText(startDate: store.plan.workoutStartedAt)
                }
            }

            Spacer()

            Text("\((progress * 100).formatted(.number.precision(.fractionLength(1))))%")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(Color.accentColor)

            if store.plan.isWorkoutStarted {
                Button {
                    isTrainerEnabled.toggle()
                } label: {
                    Image(systemName: isTrainerEnabled ? "figure.run.circle.fill" : "figure.run.circle")
                        .font(.title3)
                        .foregroundStyle(isTrainerEnabled ? Color.accentColor : .secondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    isTrainerEnabled
                        ? appLanguage.ui("Trainer ausschalten")
                        : appLanguage.ui("Trainer einschalten")
                )
            }

        }
    }

    private var progress: Double {
        store.plan.progressFraction
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct WorkoutElapsedText: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let startDate: Date?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            Text("\(appLanguage.ui("Gesamtzeit")) \(timeText(at: timeline.date))")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func timeText(at date: Date) -> String {
        guard let startDate else { return "0:00" }
        let seconds = max(0, Int(date.timeIntervalSince(startDate)))
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct TrainingSummaryCard: View {
    @EnvironmentObject private var store: WorkoutStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    let session: WorkoutSession?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(appLanguage.ui("Training abgeschlossen"), systemImage: "flag.checkered")
                .font(.headline)

            LazyVGrid(columns: summaryColumns, spacing: 10) {
                TrainingSummaryMetric(title: appLanguage.ui("Volumen"), value: totalVolume.formattedWeight(unit: weightUnit), icon: "scalemass")
                TrainingSummaryMetric(title: appLanguage.ui("Sätze"), value: "\(totalSets)", icon: "checkmark.circle")
                TrainingSummaryMetric(title: appLanguage.ui("Zeit"), value: "\(durationMinutes) min", icon: "timer")
                TrainingSummaryMetric(title: appLanguage.ui("Kalorien"), value: "\(calories)", icon: "flame.fill")
                TrainingSummaryMetric(title: appLanguage.ui("Rekorde"), value: "\(recordCount)", icon: "trophy.fill")
                TrainingSummaryMetric(title: appLanguage.ui("Übungen"), value: "\(exerciseCount)", icon: "figure.strengthtraining.traditional")
            }

            Text(appLanguage.ui("Die Einheit ist gespeichert. Dein nächstes Training startet wieder offen."))
                .font(.footnote)
                .foregroundStyle(.secondary)

        }
        .padding(16)
        .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.green.opacity(0.25), lineWidth: 1)
        )
    }

    private var summaryColumns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(minimum: 0), spacing: 10), count: count)
    }

    private var totalVolume: Double {
        session?.totalVolume ?? store.plan.totalVolume
    }

    private var totalSets: Int {
        session?.totalSets ?? store.plan.totalCompletedSets
    }

    private var durationMinutes: Int {
        Int((session?.durationMinutes ?? 0).rounded())
    }

    private var calories: Int {
        session?.calories ?? store.plan.estimatedCalories
    }

    private var exerciseCount: Int {
        session?.exercises.count ?? store.plan.completedExercises.count
    }

    private var recordCount: Int {
        guard let session else { return 0 }
        return session.exercises.reduce(0) { partial, exercise in
            partial + recordFlags(for: exercise, in: session).filter { $0 }.count
        }
    }

    private func recordFlags(for exercise: WorkoutSessionExercise, in session: WorkoutSession) -> [Bool] {
        let previous = store.history
            .filter { $0.date < session.date }
            .compactMap { oldSession in
                oldSession.exercises.first { $0.catalogID == exercise.catalogID }
            }

        let previousMaxWeight = previous.compactMap(\.maximumWeight).max() ?? 0
        let previousVolume = previous.map(\.volume).max() ?? 0
        let currentMaxWeight = exercise.maximumWeight ?? 0

        return [
            currentMaxWeight > previousMaxWeight && currentMaxWeight > 0,
            exercise.volume > previousVolume && exercise.volume > 0
        ]
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }
}

private struct TrainingSummaryMetric: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(value)
                .font(.headline.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .padding(10)
        .background(Color.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct WorkoutCompletionSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage("gympit_app_design") private var appDesignRawValue = AppDesign.ocean.rawValue
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    let session: WorkoutSession

    var body: some View {
        ZStack {
            currentDesign.pageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appLanguage.ui("Training abgeschlossen"))
                            .font(.title2.bold())
                        Text(session.planName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.semibold))
                            .frame(width: 42, height: 42)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(appLanguage.ui("Schließen"))
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 10)

                if store.hasPendingRoutineChanges {
                    RoutineUpdatePrompt()
                        .padding(.horizontal, 18)
                        .padding(.bottom, 10)
                }

                TabView {
                    CompletionOverviewPage(session: session)
                    CompletionHighlightsPage(session: session)
                    if !achievements.isEmpty {
                        CompletionAchievementsPage(achievements: achievements)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            }
        }
    }

    private var achievements: [CompletionAchievement] {
        CompletionAchievement.build(for: session, history: store.history, language: appLanguage, weightUnit: weightUnit)
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var currentDesign: AppDesign {
        AppDesign.value(for: appDesignRawValue)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }
}

private struct RoutineUpdatePrompt: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(appLanguage.ui("Zur Routine hinzufügen?"), systemImage: "plus.rectangle.on.rectangle")
                .font(.subheadline.weight(.semibold))

            Text(summaryText)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button {
                    store.keepPendingWorkoutExercisesInRoutine()
                } label: {
                    Text(appLanguage.ui("Zur Routine hinzufügen"))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    store.discardPendingWorkoutExercisesFromRoutine()
                } label: {
                    Text(appLanguage.ui("Nur dieses Training"))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous)
                .stroke(Color(.separator).opacity(0.22), lineWidth: 0.75)
        )
    }

    private var summaryText: String {
        let exerciseCount = store.pendingRoutineExercises.count
        let setExerciseCount = store.pendingRoutineSetExercises.count

        if exerciseCount > 0 && setExerciseCount > 0 {
            return "\(exerciseCount) \(appLanguage.ui("neue Übungen")) · \(setExerciseCount) \(appLanguage.ui("Übungen mit neuen Sätzen"))"
        }
        if exerciseCount > 0 {
            return "\(exerciseCount) \(appLanguage.ui("neue Übungen"))"
        }
        return "\(setExerciseCount) \(appLanguage.ui("Übungen mit neuen Sätzen"))"
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct CompletionOverviewPage: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    let session: WorkoutSession

    var body: some View {
        CompletionPage {
            VStack(alignment: .leading, spacing: 16) {
                Label(appLanguage.ui("Übersicht"), systemImage: "chart.bar.fill")
                    .font(.title3.bold())

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        StatTile(title: appLanguage.ui("Volumen"), value: session.totalVolume.formattedWeight(unit: weightUnit), icon: "scalemass")
                        StatTile(title: appLanguage.ui("Sätze"), value: "\(session.totalSets)", icon: "checklist")
                    }
                    HStack(spacing: 8) {
                        StatTile(title: appLanguage.ui("Zeit"), value: "\(Int(session.durationMinutes.rounded())) min", icon: "timer")
                        StatTile(title: appLanguage.ui("Kalorien"), value: "\(session.calories)", icon: "flame.fill")
                    }
                }

                CompletionMetricRow(icon: "figure.strengthtraining.traditional", title: appLanguage.ui("Übungen"), value: "\(session.exercises.count)")
                CompletionMetricRow(icon: "repeat", title: appLanguage.ui("Wiederholungen"), value: "\(totalReps)")
                CompletionMetricRow(icon: "calendar", title: appLanguage.ui("Datum"), value: session.date.formatted(date: .abbreviated, time: .shortened))
            }
        }
    }

    private var totalReps: Int {
        session.exercises.flatMap(\.sets).reduce(0) { $0 + $1.reps }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }
}

private struct CompletionHighlightsPage: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    let session: WorkoutSession

    var body: some View {
        CompletionPage {
            VStack(alignment: .leading, spacing: 16) {
                Label(appLanguage.ui("Highlights"), systemImage: "sparkles")
                    .font(.title3.bold())

                CompletionMetricRow(icon: "dumbbell.fill", title: appLanguage.ui("Schwerster Satz"), value: heaviestSetText)
                CompletionMetricRow(icon: "scalemass.fill", title: appLanguage.ui("Meistes Volumen"), value: topVolumeExerciseText)
                CompletionMetricRow(icon: "number", title: appLanguage.ui("Ø Gewicht pro Wiederholung"), value: averageWeightText)

                if let bestSet = bestSetVolume {
                    CompletionMetricRow(icon: "chart.line.uptrend.xyaxis", title: appLanguage.ui("Bestes Satzvolumen"), value: bestSet.formattedWeight(unit: weightUnit))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(appLanguage.ui("Übungen"))
                        .font(.headline)
                    ForEach(session.exercises.prefix(6)) { exercise in
                        HStack {
                            Text(exercise.localizedName(language: appLanguage))
                                .lineLimit(1)
                            Spacer()
                            Text(exercise.volume.formattedWeight(unit: weightUnit))
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                        }
                        .font(.subheadline)
                    }
                }
                .padding(14)
                .themedCard()
            }
        }
    }

    private var heaviestSetText: String {
        guard let entry = session.exercises.compactMap({ exercise in
            exercise.sets.max(by: { $0.weight < $1.weight }).map { (exercise, $0) }
        }).max(by: { $0.1.weight < $1.1.weight }) else { return "-" }
        return "\(entry.0.localizedName(language: appLanguage)) · \(entry.1.reps) x \(entry.1.weight.formattedWeight(unit: weightUnit))"
    }

    private var topVolumeExerciseText: String {
        guard let exercise = session.exercises.max(by: { $0.volume < $1.volume }) else { return "-" }
        return "\(exercise.localizedName(language: appLanguage)) · \(exercise.volume.formattedWeight(unit: weightUnit))"
    }

    private var averageWeightText: String {
        let totalReps = session.exercises.flatMap(\.sets).reduce(0) { $0 + $1.reps }
        guard totalReps > 0 else { return "-" }
        return (session.totalVolume / Double(totalReps)).formattedWeight(unit: weightUnit)
    }

    private var bestSetVolume: Double? {
        session.exercises.flatMap(\.sets).map { Double($0.reps) * $0.weight }.max()
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }
}

private struct CompletionAchievementsPage: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let achievements: [CompletionAchievement]

    var body: some View {
        CompletionPage {
            VStack(alignment: .leading, spacing: 16) {
                Label(appLanguage.ui("Erfolge"), systemImage: "trophy.fill")
                    .font(.title3.bold())

                ForEach(achievements) { achievement in
                    CompletionMetricRow(icon: achievement.icon, title: achievement.title, value: achievement.value)
                }
            }
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct CompletionPage<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            content
                .padding(18)
                .frame(maxWidth: 620, alignment: .leading)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 46)
        }
    }
}

private struct CompletionMetricRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28, height: 28)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer(minLength: 10)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
        }
        .padding(14)
        .themedCard()
    }
}

private struct CompletionAchievement: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let value: String

    static func build(for session: WorkoutSession, history: [WorkoutSession], language: AppLanguage, weightUnit: WeightUnit) -> [CompletionAchievement] {
        let previousSessions = history.filter { $0.id != session.id && $0.date < session.date }
        var achievements: [CompletionAchievement] = []

        if let previousVolume = previousSessions.map(\.totalVolume).max(),
           session.totalVolume > previousVolume,
           session.totalVolume > 0 {
            achievements.append(
                CompletionAchievement(
                    icon: "scalemass.fill",
                    title: language.ui("Neues Trainingsvolumen"),
                    value: session.totalVolume.formattedWeight(unit: weightUnit)
                )
            )
        }

        if let previousSets = previousSessions.map(\.totalSets).max(),
           session.totalSets > previousSets {
            achievements.append(
                CompletionAchievement(
                    icon: "checklist.checked",
                    title: language.ui("Meiste Sätze in einem Training"),
                    value: "\(session.totalSets)"
                )
            )
        }

        for exercise in session.exercises {
            let previous = previousSessions.compactMap { oldSession in
                oldSession.exercises.first { $0.catalogID == exercise.catalogID }
            }
            let previousMaxWeight = previous.compactMap(\.maximumWeight).max() ?? 0
            let currentMaxWeight = exercise.maximumWeight ?? 0
            if currentMaxWeight > previousMaxWeight && currentMaxWeight > 0 {
                achievements.append(
                    CompletionAchievement(
                        icon: "trophy.fill",
                        title: "\(language.ui("Höchstes Gewicht")) · \(exercise.localizedName(language: language))",
                        value: currentMaxWeight.formattedWeight(unit: weightUnit)
                    )
                )
            }

            let previousVolume = previous.map(\.volume).max() ?? 0
            if exercise.volume > previousVolume && exercise.volume > 0 {
                achievements.append(
                    CompletionAchievement(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "\(language.ui("Übungsvolumen")) · \(exercise.localizedName(language: language))",
                        value: exercise.volume.formattedWeight(unit: weightUnit)
                    )
                )
            }
        }

        return Array(achievements.prefix(8))
    }
}

private struct StartTrainingPrompt: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage("gympit_trainer_enabled") private var isTrainerEnabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(appLanguage.ui("Training bereit"), systemImage: "play.circle.fill")
                .font(.headline)
            Text(appLanguage.ui("Starte dein Training. Danach erscheint die erste Übung oben und du kannst offene Übungen durch Antippen wechseln."))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Toggle(isOn: $isTrainerEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Label(appLanguage.ui("Trainer"), systemImage: "figure.run.circle.fill")
                        .font(.subheadline.weight(.semibold))
                    Text(appLanguage.ui("Analysiert RPE, Gewicht und Wiederholungen für den nächsten Satz."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Color.accentColor)

            Button {
                store.startWorkout()
            } label: {
                ZStack {
                    Text(appLanguage.ui("Training starten"))
                        .font(.body.weight(.semibold))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                    HStack {
                        Image(systemName: "play.fill")
                            .accessibilityHidden(true)
                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .neutralCard()
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct TrainerRecommendationCard: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    let exercise: Exercise
    @State private var appliedRecommendation: TrainerRecommendation?

    var body: some View {
        let recommendation = store.trainerRecommendation(for: exercise)

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label(appLanguage.ui("Trainer"), systemImage: "figure.run.circle.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                Spacer()
                Text(basisText(recommendation.basis))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(appLanguage.ui(recommendation.title))
                .font(.headline)

            HStack(spacing: 8) {
                recommendationMetric(
                    title: appLanguage.ui("Gewicht"),
                    value: weightText(recommendation.weightKilograms),
                    icon: "scalemass"
                )
                recommendationMetric(
                    title: appLanguage.ui("Wdh"),
                    value: "\(recommendation.repetitions)",
                    icon: "repeat"
                )
                recommendationMetric(
                    title: appLanguage.ui("Pause"),
                    value: "\(recommendation.restSeconds) s",
                    icon: "timer"
                )
            }

            Text(appLanguage.ui(recommendation.explanation))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            missingRPEHint(for: recommendation)

            ForEach(recommendation.detailKeys, id: \.self) { detailKey in
                Text(appLanguage.ui(detailKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if store.hasOpenSet(for: exercise) {
                Button {
                    if store.applyTrainerRecommendation(recommendation, to: exercise) {
                        appliedRecommendation = recommendation
                    }
                } label: {
                    Label(
                        appLanguage.ui(appliedRecommendation == recommendation ? "Empfehlung übernommen" : "Auf nächsten Satz anwenden"),
                        systemImage: appliedRecommendation == recommendation ? "checkmark.circle.fill" : "arrow.down.circle"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(10)
        .background(Color.accentColor.opacity(0.09), in: RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous)
                .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
        )
        .onChange(of: recommendation) { oldValue, newValue in
            if oldValue != newValue {
                appliedRecommendation = nil
            }
        }
    }

    @ViewBuilder
    private func missingRPEHint(for recommendation: TrainerRecommendation) -> some View {
        let missingCount = store.loggedSetsMissingRPE(for: exercise)

        if recommendation.requiresRPEInput || missingCount > 0 {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(missingCount > 0
                         ? "\(appLanguage.ui("RPE fehlt")) (\(missingCount) \(appLanguage.ui("Sätze")))"
                         : appLanguage.ui("RPE fehlt"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.orange)
                    Text(appLanguage.ui(recommendation.missingRPEHint ?? "Tippe im Satz auf RPE und wähle einen Wert von 6 bis 10, damit der Trainer rechnen kann."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: AppLayout.cornerRadius - 2, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius - 2, style: .continuous)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
        }
    }

    private func recommendationMetric(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(7)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: AppLayout.cornerRadius - 2, style: .continuous))
    }

    private func basisText(_ basis: TrainerRecommendation.Basis) -> String {
        switch basis {
        case .currentWorkout: appLanguage.ui("Aktueller Verlauf")
        case .previousWorkout: appLanguage.ui("Letztes Training")
        case .plan: appLanguage.ui("Trainingsplan")
        }
    }

    private func weightText(_ kilograms: Double) -> String {
        kilograms > 0 ? kilograms.formattedWeight(unit: weightUnit) : appLanguage.ui("Körpergewicht")
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }
}

private struct TrainingEndButton: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue

    var body: some View {
        if store.plan.isWorkoutStarted && !store.plan.exercises.isEmpty {
            Button(role: .destructive) {
                store.endWorkout()
            } label: {
                Label(appLanguage.ui("Training beenden"), systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.vertical, 4)
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct RestTimerCard: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(appLanguage.ui("Pause"))
                    .font(.headline)
                Text(timeText)
                    .font(.title3.bold())
                    .monospacedDigit()
            }

            Spacer()

            Button("+15") {
                store.addRestTime(15)
            }
            .buttonStyle(.bordered)

            Button {
                store.stopRestTimer()
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(appLanguage.ui("Timer stoppen"))
        }
        .padding(14)
        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
        )
    }

    private var timeText: String {
        let minutes = store.restRemainingSeconds / 60
        let seconds = store.restRemainingSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct StickyRestTimerInset: View {
    @ObservedObject var timerState: WorkoutRestTimerState
    @AppStorage("gympit_app_design") private var appDesignRawValue = AppDesign.ocean.rawValue

    var body: some View {
        if timerState.remainingSeconds > 0 {
            StickyRestTimerBar(remainingSeconds: timerState.remainingSeconds)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                .background(currentDesign.pageBackground)
        }
    }

    private var currentDesign: AppDesign {
        AppDesign.value(for: appDesignRawValue)
    }
}

private struct StickyRestTimerBar: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let remainingSeconds: Int

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "timer")
                .foregroundStyle(.orange)

            Text(appLanguage.ui("Pause"))
                .font(.subheadline.weight(.semibold))

            Text(timeText)
                .font(.subheadline.monospacedDigit().weight(.bold))
                .foregroundStyle(.orange)

            Spacer()

            Button("+15") {
                store.addRestTime(15)
            }
            .font(.caption.weight(.semibold))
            .buttonStyle(.bordered)

            Button {
                store.stopRestTimer()
            } label: {
                Image(systemName: "forward.fill")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel(appLanguage.ui("Pause überspringen"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous)
                .stroke(Color(.separator).opacity(0.22), lineWidth: 0.5)
        )
    }

    private var timeText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct PreviousPerformanceView: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    let exercise: Exercise

    var body: some View {
        if let previous = store.previousSessionExercise(for: exercise) {
            VStack(spacing: 6) {
                StatTile(title: appLanguage.ui("Letztes Mal"), value: previous.bestSetDescription, icon: "clock")
                StatTile(title: appLanguage.ui("Volumen"), value: previous.volume.formattedWeight(unit: weightUnit), icon: "scalemass")
                StatTile(title: appLanguage.ui("Zuletzt erhöht"), value: lastIncreaseText, icon: "arrow.up.circle")
                StatTile(title: appLanguage.ui("Rekord"), value: recordText, icon: "trophy")
            }
        } else {
            InfoRow(
                icon: "sparkles",
                title: appLanguage.ui("Erstes Mal in der Historie"),
                subtitle: appLanguage.ui("Nach dem Abschluss siehst du hier deine letzte Leistung und Rekorde.")
            )
        }
    }

    private var recordText: String {
        guard let best = store.bestWeight(for: exercise) else { return "-" }
        return best.formattedWeight(unit: weightUnit)
    }

    private var lastIncreaseText: String {
        guard let increase = store.lastWeightIncrease(for: exercise) else {
            return appLanguage.ui("Noch nicht")
        }

        let date = increase.date.formatted(
            .dateTime
                .day(.twoDigits)
                .month(.twoDigits)
                .year(.twoDigits)
                .locale(Locale(identifier: appLanguage.localeIdentifier))
        )
        return "\(date) · \(increase.weight.formattedWeight(unit: weightUnit))"
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }
}

private struct ExerciseRecordsView: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    let exercise: Exercise
    @State private var scale: RecordTimeScale = .ninetyDays
    @State private var chartMetric: ExerciseChartMetric = .maxWeight
    @State private var selectedChartDate: Date?

    var body: some View {
        List {
            ExerciseDetailArtwork(exercise: currentExercise)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            Section(appLanguage.ui("Rekorde")) {
                ForEach(store.recordSummaries(for: currentExercise)) { record in
                    HStack(spacing: 12) {
                        Image(systemName: record.metric.iconName)
                            .foregroundStyle(.yellow)
                            .frame(width: 24)
                        Text(appLanguage.ui(record.metric.rawValue))
                        Spacer()
                        Text(valueText(for: record))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                }

            }

            Section {
                HStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(appLanguage.ui("Letztes Gewicht"))
                        Text(latestWeightUsageText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }

            Section {
                Picker(appLanguage.ui("Zeitraum"), selection: $scale) {
                    ForEach(RecordTimeScale.allCases) { scale in
                        Text(appLanguage.ui(scale.rawValue)).tag(scale)
                    }
                }
                .pickerStyle(.segmented)

                Picker(appLanguage.ui("Wert"), selection: $chartMetric) {
                    ForEach(ExerciseChartMetric.allCases) { metric in
                        Text(appLanguage.ui(metric.rawValue)).tag(metric)
                    }
                }
                .pickerStyle(.segmented)

                if trendPoints.isEmpty {
                    Text(appLanguage.ui("Noch kein Verlauf für diese Übung."))
                        .foregroundStyle(.secondary)
                } else {
                    Chart(trendPoints) { point in
                        LineMark(
                            x: .value("Datum", point.date),
                            y: .value(appLanguage.ui(chartMetric.rawValue), chartMetric.value(for: point))
                        )
                        .foregroundStyle(Color.accentColor)

                        PointMark(
                            x: .value("Datum", point.date),
                            y: .value(appLanguage.ui(chartMetric.rawValue), chartMetric.value(for: point))
                        )
                        .foregroundStyle(Color.accentColor)

                        if point.id == selectedTrendPoint?.id {
                            RuleMark(x: .value("Auswahl", point.date))
                                .foregroundStyle(Color.secondary.opacity(0.55))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                            PointMark(
                                x: .value("Datum", point.date),
                                y: .value(appLanguage.ui(chartMetric.rawValue), chartMetric.value(for: point))
                            )
                            .foregroundStyle(Color.accentColor)
                            .symbolSize(90)
                            .annotation(position: .top, spacing: 10) {
                                ChartSelectionLabel(
                                    date: point.date,
                                    value: chartValueText(for: point),
                                    language: appLanguage
                                )
                            }
                        }
                    }
                    .frame(height: 220)
                    .chartYAxisLabel(appLanguage.ui(chartMetric.rawValue))
                    .chartXSelection(value: $selectedChartDate)
                }
            } header: {
                Text(appLanguage.ui("Diagramm"))
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appLanguage.ui(chartMetric.footerText))
                    Text(appLanguage.ui("Tippe oder streiche über das Diagramm, um einzelne Werte anzuzeigen."))
                }
            }
        }
        .navigationTitle(exercise.localizedName(language: appLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scale) { _, _ in selectedChartDate = nil }
        .onChange(of: chartMetric) { _, _ in selectedChartDate = nil }
    }

    private var currentExercise: Exercise {
        store.plan.exercises.first { $0.id == exercise.id } ?? exercise
    }

    private var trendPoints: [ExerciseTrendPoint] {
        store.trendPoints(for: currentExercise, scale: scale)
    }

    private var selectedTrendPoint: ExerciseTrendPoint? {
        guard let selectedChartDate else { return nil }
        return trendPoints.min {
            abs($0.date.timeIntervalSince(selectedChartDate)) < abs($1.date.timeIntervalSince(selectedChartDate))
        }
    }

    private func chartValueText(for point: ExerciseTrendPoint) -> String {
        chartMetric.value(for: point).formattedWeight(unit: weightUnit)
    }

    private func valueText(for record: ExerciseRecordSummary) -> String {
        guard let value = record.value else { return "-" }
        switch record.metric {
        case .setVolume, .sessionVolume:
            return value.formattedWeight(unit: weightUnit)
        case .maxWeight, .estimatedOneRepMax:
            return value.formattedWeight(unit: weightUnit)
        }
    }

    private var latestWeightUsageText: String {
        guard let usage = store.latestWeightUsage(for: currentExercise) else {
            return appLanguage.ui("Noch nicht")
        }

        let usageCount: String
        switch usage.consecutiveWorkouts {
        case 1:
            usageCount = appLanguage.ui("im letzten Training")
        default:
            usageCount = String(format: appLanguage.ui("seit %d Trainings"), usage.consecutiveWorkouts)
        }
        return "\(usage.weight.formattedWeight(unit: weightUnit)) · \(usageCount)"
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }
}

private struct ChartSelectionLabel: View {
    let date: Date
    let value: String
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption.weight(.bold))
                .monospacedDigit()
            Text(date.formatted(
                .dateTime
                    .day(.twoDigits)
                    .month(.twoDigits)
                    .year(.twoDigits)
                    .locale(Locale(identifier: language.localeIdentifier))
            ))
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private enum ExerciseChartMetric: String, CaseIterable, Identifiable {
    case maxWeight = "Gewicht"
    case setVolume = "Satzvolumen"
    case sessionVolume = "Sitzungsvolumen"

    var id: String { rawValue }

    func value(for point: ExerciseTrendPoint) -> Double {
        switch self {
        case .maxWeight: point.maxWeight
        case .setVolume: point.bestSetVolume
        case .sessionVolume: point.volume
        }
    }

    var footerText: String {
        switch self {
        case .maxWeight:
            "Das Diagramm zeigt das höchste Gewicht pro Training."
        case .setVolume:
            "Das Diagramm zeigt das beste Satzvolumen pro Training."
        case .sessionVolume:
            "Das Diagramm zeigt das Sitzungsvolumen pro Training."
        }
    }
}

private struct ExerciseNotesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let exercise: Exercise

    @State private var notes: String

    init(exercise: Exercise) {
        self.exercise = exercise
        _notes = State(initialValue: exercise.notes)
    }

    var body: some View {
        Form {
            Section(appLanguage.ui("Übungsnotiz")) {
                TextField(appLanguage.ui("Technik, Gefühl, Schmerzen, Ziel"), text: $notes, axis: .vertical)
                    .lineLimit(5...10)
            }

            if let previous = store.previousSessionExercise(for: exercise), !previous.notes.isEmpty {
                Section(appLanguage.ui("Letzte Notiz")) {
                    Text(previous.notes)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(exercise.localizedName(language: appLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(appLanguage.ui("Fertig")) {
                    store.updateExerciseNotes(exercise, notes: notes)
                    dismiss()
                }
            }
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private enum ExerciseImageLoader {
    static func image(named name: String) -> UIImage? {
        image(named: name, subdirectory: "ExerciseDetailImages")
    }

    static func detailImage(named name: String) -> UIImage? {
        image(named: name, subdirectory: "ExerciseDetailImages")
    }

    private static func image(named name: String, subdirectory: String) -> UIImage? {
        if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: subdirectory),
           let bundledImage = UIImage(contentsOfFile: url.path) {
            return bundledImage
        }

        return UIImage(named: name)
    }
}

private struct ExerciseDetailArtwork: View {
    let exercise: Exercise

    var body: some View {
        if let imageName, let image = ExerciseImageLoader.detailImage(named: imageName) {
            Image(uiImage: image)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 230)
        }
    }

    private var imageName: String? {
        guard exercise.iconName.hasPrefix("exercise.") else { return nil }
        let id = String(exercise.iconName.dropFirst("exercise.".count))
        return "exercise_\(id.replacingOccurrences(of: "-", with: "_"))"
    }
}

private struct ExerciseArtwork: View {
    let category: DeviceCategory
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous)
                .fill(groupBackground)

            MuscleGroupArtwork(category: category, size: size)
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous)
                .stroke(foreground.opacity(0.18), lineWidth: 1)
        )
    }

    private var groupBackground: LinearGradient {
        LinearGradient(
            colors: [foreground.opacity(0.24), foreground.opacity(0.10)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var foreground: Color {
        switch category {
        case .chest: Color.red
        case .back: Color.blue
        case .shoulders: Color.purple
        case .legs: Color.green
        case .arms: Color.orange
        case .core: Color.teal
        case .cardio: Color.pink
        case .freeWeights: Color.indigo
        }
    }
}

private struct MuscleGroupArtwork: View {
    let category: DeviceCategory
    let size: CGFloat

    var body: some View {
        Image(systemName: iconName)
            .symbolRenderingMode(.hierarchical)
            .font(.system(size: iconSize, weight: .bold))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)
    }

    private var iconSize: CGFloat {
        switch category {
        case .arms, .freeWeights:
            size * 0.50
        default:
            size * 0.54
        }
    }

    private var iconName: String {
        switch category {
        case .chest:
            "figure.strengthtraining.traditional"
        case .back:
            "figure.rower"
        case .shoulders:
            "figure.arms.open"
        case .legs:
            "figure.strengthtraining.functional"
        case .arms:
            "dumbbell.fill"
        case .core:
            "figure.core.training"
        case .cardio:
            "heart.fill"
        case .freeWeights:
            "scalemass.fill"
        }
    }

    private var color: Color {
        switch category {
        case .chest: .red
        case .back: .blue
        case .shoulders: .purple
        case .legs: .green
        case .arms: .orange
        case .core: .teal
        case .cardio: .pink
        case .freeWeights: .indigo
        }
    }
}

private enum ActiveExerciseDestination: Hashable, Identifiable {
    case overview
    case notes
    case deviceSettings

    var id: Self { self }
}

private struct ActiveExerciseCard: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let exercise: Exercise
    @State private var destination: ActiveExerciseDestination?
    @State private var isPreviousPerformanceExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Button {
                destination = .overview
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    ExerciseArtwork(category: exercise.category, size: 38)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appLanguage.ui("Aktuell"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                        Text(exercise.localizedName(language: appLanguage))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        Text(exercise.target)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .trailing, spacing: 3) {
                        WeightBadge(title: "Max", value: exercise.maximumWeight)
                        HStack(spacing: 6) {
                            if !exercise.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Image(systemName: "note.text")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .accessibilityLabel(appLanguage.ui("Notiz vorhanden"))
                            }
                            WeightBadge(title: "1RM", value: exercise.estimatedOneRepMax)
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(exercise.localizedName(language: appLanguage)) \(appLanguage.ui("Übersicht öffnen"))")

            ExerciseBadges(exercise: exercise)

            DeviceSummary(device: exercise.device)

            Button {
                withAnimation(.snappy(duration: 0.18)) {
                    isPreviousPerformanceExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                    Text(appLanguage.ui("Vorherige Leistung"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                    Image(systemName: isPreviousPerformanceExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .font(.caption.weight(.semibold))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isPreviousPerformanceExpanded {
                PreviousPerformanceView(exercise: exercise)
                    .padding(.top, 2)
            }

            VStack(spacing: 5) {
                ForEach(exercise.sets) { set in
                    SetRow(exercise: exercise, set: set)
                }

                Button {
                    store.addSet(to: exercise)
                } label: {
                    Label(appLanguage.ui("Satz hinzufügen"), systemImage: "plus.circle")
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            exerciseActionButtons
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .neutralCard()
        .navigationDestination(item: $destination) { destination in
            switch destination {
            case .overview:
                ExerciseRecordsView(exercise: exercise)
            case .notes:
                ExerciseNotesView(exercise: exercise)
            case .deviceSettings:
                DeviceExerciseEditorView(exercise: exercise)
            }
        }
    }

    private var exerciseActionButtons: some View {
        HStack(spacing: 8) {
            Button {
                destination = .notes
            } label: {
                Label(appLanguage.ui("Notiz"), systemImage: "note.text")
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button {
                destination = .deviceSettings
            } label: {
                Label(appLanguage.ui("Gerät"), systemImage: "slider.horizontal.3")
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel(appLanguage.ui("Geräteeinstellungen"))
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct ExerciseRow: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let exercise: Exercise
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                ExerciseArtwork(category: exercise.category, size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(exercise.localizedName(language: appLanguage))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        if exercise.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                    }
                    Text(exercise.target)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let group = exercise.supersetGroup {
                        Text("\(appLanguage.ui("Superset")) \(groupLabel(group))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                WeightBadge(title: appLanguage.ui("Nächster Satz"), value: nextPlannedWeight)
                    .fixedSize(horizontal: true, vertical: false)
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .buttonStyle(.plain)
        .accessibilityLabel("\(exercise.localizedName(language: appLanguage)) \(appLanguage.ui("auswählen"))")
    }

    private func groupLabel(_ group: Int) -> String {
        ["A", "B", "C"].indices.contains(group - 1) ? ["A", "B", "C"][group - 1] : "\(group)"
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var nextPlannedWeight: Double? {
        (exercise.sets.first { !$0.isLogged } ?? exercise.sets.first)?.weight
    }
}

private struct CompletedExerciseRow: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    let exercise: Exercise
    @State private var destination: ActiveExerciseDestination?
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Button {
                withAnimation(.snappy(duration: 0.18)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    ExerciseArtwork(category: exercise.category, size: 34)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.localizedName(language: appLanguage))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(summaryText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(exercise.localizedName(language: appLanguage)) \(appLanguage.ui(isExpanded ? "zuklappen" : "bearbeiten"))")

            if isExpanded {
                VStack(spacing: 5) {
                    ForEach(exercise.sets) { set in
                        SetRow(exercise: exercise, set: set)
                    }

                    Button {
                        store.addSet(to: exercise, isLogged: true, keepExerciseCompleted: true)
                    } label: {
                        Label(appLanguage.ui("Satz hinzufügen"), systemImage: "plus.circle")
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                completedActionButtons
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .navigationDestination(item: $destination) { destination in
            switch destination {
            case .overview:
                ExerciseRecordsView(exercise: exercise)
            case .notes:
                ExerciseNotesView(exercise: exercise)
            case .deviceSettings:
                DeviceExerciseEditorView(exercise: exercise)
            }
        }
    }

    private var summaryText: String {
        let maxText = exercise.maximumWeight.map { "Max \($0.formattedWeight(unit: weightUnit))" } ?? "Max -"
        return "\(exercise.completedSetsCount) \(appLanguage.ui("Sätze")) · \(maxText)"
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }

    private var completedActionButtons: some View {
        HStack(spacing: 8) {
            Button {
                destination = .notes
            } label: {
                Label(appLanguage.ui("Notiz"), systemImage: "note.text")
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button {
                destination = .deviceSettings
            } label: {
                Label(appLanguage.ui("Gerät"), systemImage: "slider.horizontal.3")
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel(appLanguage.ui("Geräteeinstellungen"))
        }
    }
}

private struct SetRow: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    let exercise: Exercise
    let set: ExerciseSet

    private enum FocusedField: Hashable {
        case reps
        case weight
    }

    @State private var repsText: String = ""
    @State private var weightText: String = ""
    @State private var setType: WorkoutSetType = .normal
    @State private var rpe: Int?
    @FocusState private var focusedField: FocusedField?

    var body: some View {
        let recordFlags = store.personalRecordFlags(for: set, in: exercise)

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(appLanguage.ui("Satz"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(recordFlags.hasAny ? .yellow : .secondary)
                if recordFlags.hasAny {
                    Label("PR", systemImage: "trophy.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.yellow)
                }
                Spacer()
                Text(set.isLogged ? appLanguage.ui("Erfasst") : appLanguage.ui("Offen"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(set.isLogged ? .green : .secondary)
            }

            HStack(spacing: 6) {
                Menu {
                    ForEach(WorkoutSetType.allCases) { type in
                        Button(type.rawValue) {
                            setType = type
                            commit(isLogged: currentLoggedState)
                        }
                    }
                } label: {
                    VStack(spacing: 1) {
                        Text(setType.shortTitle)
                            .font(.caption.weight(.bold))
                        Text(appLanguage.ui("Typ"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 38, height: 32)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: AppLayout.cornerRadius - 2, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    commit(isLogged: !currentLoggedState)
                } label: {
                    Image(systemName: set.isLogged ? "checkmark.circle.fill" : "circle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(set.isLogged ? .green : .secondary)
                        .frame(width: 26, height: 32)
                }
                .buttonStyle(.plain)

                FocusedSetInputField(
                    title: appLanguage.ui("Wdh"),
                    text: $repsText,
                    width: 34,
                    keyboardType: .numberPad,
                    focusedField: $focusedField,
                    focusValue: .reps,
                    isCompact: true
                ) {
                    commit(isLogged: currentLoggedState)
                }

                FocusedSetInputField(
                    title: weightUnit.symbol,
                    text: $weightText,
                    width: 48,
                    keyboardType: .decimalPad,
                    focusedField: $focusedField,
                    focusValue: .weight,
                    showsIncreaseHint: exercise.shouldIncreaseWeightNextTime,
                    isCompact: true
                ) {
                    commit(isLogged: currentLoggedState)
                }

                Spacer(minLength: 0)

                Menu {
                    Button(appLanguage.ui("Keine RPE")) {
                        rpe = nil
                        commit(isLogged: currentLoggedState)
                    }
                    ForEach(6...10, id: \.self) { value in
                        Button("RPE \(value)") {
                            rpe = value
                            commit(isLogged: true)
                        }
                    }
                } label: {
                    Text(rpe.map { "RPE \($0)" } ?? "RPE")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(minWidth: 46, minHeight: 32)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: AppLayout.cornerRadius - 2, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 5)
            .frame(height: 42)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous)
                    .stroke(recordFlags.hasAny ? Color.yellow.opacity(0.42) : Color(.separator).opacity(0.26), lineWidth: 0.75)
            )
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.vertical, 2)
        .onAppear {
            syncFields(from: set)
        }
        .onDisappear {
            commit(isLogged: currentLoggedState)
        }
        .onChange(of: focusedField) { oldValue, newValue in
            if oldValue != nil, oldValue != newValue {
                commit(isLogged: currentLoggedState)
            }
        }
        .onChange(of: set) { _, newSet in
            guard focusedField == nil else { return }
            syncFields(from: newSet)
        }
    }

    private func commit(isLogged: Bool) {
        let reps = Int(repsText) ?? set.reps
        let normalizedWeight = weightText.replacingOccurrences(of: ",", with: ".")
        let displayWeight = Double(normalizedWeight)
        let weight = displayWeight.map { weightUnit.kilograms(fromDisplayValue: $0) } ?? set.weight
        store.updateSet(set, in: exercise, type: setType, reps: reps, weight: weight, rpe: rpe, isLogged: isLogged)
    }

    private var currentLoggedState: Bool {
        store.plan.exercises
            .first(where: { $0.id == exercise.id })?
            .sets.first(where: { $0.id == set.id })?
            .isLogged ?? set.isLogged
    }

    private func syncFields(from set: ExerciseSet) {
        repsText = String(set.reps)
        weightText = formatted(set.weight)
        setType = set.type
        rpe = set.rpe
    }

    private func formatted(_ value: Double) -> String {
        formattedWeightInput(value, unit: weightUnit)
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }
}

private struct FocusedSetInputField<FocusValue: Hashable>: View {
    let title: String
    @Binding var text: String
    let width: CGFloat
    let keyboardType: UIKeyboardType
    @FocusState.Binding var focusedField: FocusValue?
    let focusValue: FocusValue
    var showsIncreaseHint = false
    var isCompact = false
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: isCompact ? 3 : 4) {
            HStack(spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if showsIncreaseHint {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
            .fixedSize(horizontal: true, vertical: false)

            TextField(title, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .multilineTextAlignment(.trailing)
                .frame(width: width)
                .focused($focusedField, equals: focusValue)
                .onSubmit(onSubmit)
        }
        .padding(.horizontal, isCompact ? 4 : 6)
        .padding(.vertical, isCompact ? 4 : 7)
        .frame(height: isCompact ? 32 : nil)
        .standardFieldFrame(cornerRadius: isCompact ? AppLayout.cornerRadius - 2 : AppLayout.cornerRadius)
        .contentShape(Rectangle())
    }
}

private struct SetInputField: View {
    let title: String
    @Binding var text: String
    let width: CGFloat
    let keyboardType: UIKeyboardType
    var showsIncreaseHint = false
    var isCompact = false
    let onSubmit: () -> Void

    var body: some View {
        content
            .padding(.horizontal, isCompact ? 4 : 6)
            .padding(.vertical, isCompact ? 4 : 7)
            .frame(height: isCompact ? 32 : nil)
            .standardFieldFrame(cornerRadius: isCompact ? AppLayout.cornerRadius - 2 : AppLayout.cornerRadius)
    }

    private var content: some View {
        HStack(spacing: isCompact ? 3 : 4) {
            HStack(spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if showsIncreaseHint {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
            .fixedSize(horizontal: true, vertical: false)

            TextField(title, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .frame(width: width)
                .onSubmit(onSubmit)
        }
    }
}

private struct DeviceManagementView: View {
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @State private var searchText = ""
    @State private var mode: DeviceManagementMode = .devices

    var body: some View {
        List {
            Section {
                Picker(appLanguage.ui("Ansicht"), selection: $mode) {
                    ForEach(DeviceManagementMode.allCases) { mode in
                        Text(appLanguage.ui(mode.rawValue)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text(mode.helpText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if mode == .devices {
                Section {
                    NavigationLink {
                        MachineCreatorView()
                    } label: {
                        Label(appLanguage.ui("Gerät hinzufügen"), systemImage: "plus.square.dashed")
                    }
                }

                let customDevices = filteredCustomDevices
                if !customDevices.isEmpty {
                    Section(appLanguage.ui("Eigene Geräte")) {
                        ForEach(customDevices) { exercise in
                            HStack(spacing: 10) {
                                if let routine = routine(containing: exercise) {
                                    NavigationLink {
                                        DeviceSettingsRouteView(routine: routine, exerciseID: exercise.id)
                                    } label: {
                                        DeviceExerciseRow(
                                            category: exercise.category,
                                            title: exercise.device.visibleMachineName ?? exercise.localizedName(language: appLanguage),
                                            subtitle: "\(exercise.localizedName(language: appLanguage)) · MET \(exercise.metValue.formatted(.number.precision(.fractionLength(1))))",
                                            badge: appLanguage.ui("Eigenes Gerät")
                                        )
                                    }
                                } else {
                                    DeviceExerciseRow(
                                        category: exercise.category,
                                        title: exercise.device.visibleMachineName ?? exercise.localizedName(language: appLanguage),
                                        subtitle: "\(exercise.localizedName(language: appLanguage)) · MET \(exercise.metValue.formatted(.number.precision(.fractionLength(1))))",
                                        badge: appLanguage.ui("Eigenes Gerät")
                                    )
                                }

                                Button(role: .destructive) {
                                    store.deleteCustomExercise(catalogID: exercise.catalogID)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("\(exercise.localizedName(language: appLanguage)) \(appLanguage.ui("Löschen"))")
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.deleteCustomExercise(catalogID: exercise.catalogID)
                                } label: {
                                    Label(appLanguage.ui("Löschen"), systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                ForEach(store.routines) { routine in
                    let exercises = filteredDevices(in: routine)
                    if !exercises.isEmpty {
                        Section("\(routine.name) · \(appLanguage.ui("verwendet"))") {
                            ForEach(exercises) { exercise in
                                NavigationLink {
                                    DeviceSettingsRouteView(routine: routine, exerciseID: exercise.id)
                                } label: {
                                    DeviceExerciseRow(
                                        category: exercise.category,
                                        title: exercise.device.visibleMachineName ?? exercise.localizedName(language: appLanguage),
                                        subtitle: "\(exercise.localizedName(language: appLanguage)) · MET \(exercise.metValue.formatted(.number.precision(.fractionLength(1))))"
                                    )
                                }
                                .swipeActions(edge: .trailing) {
                                    if exercise.isCustom {
                                        Button(role: .destructive) {
                                            store.deleteCustomExercise(catalogID: exercise.catalogID)
                                        } label: {
                                            Label(appLanguage.ui("Löschen"), systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ForEach(DeviceCategory.allCases) { category in
                    let items = filteredCatalogItems(for: category, kind: .device)
                    if !items.isEmpty {
                        Section("\(category.localizedName(language: appLanguage)) · \(appLanguage.ui("Standardgeräte"))") {
                            ForEach(items) { item in
                                DeviceExerciseRow(
                                    category: item.category,
                                    title: item.device.machineName.isEmpty ? item.localizedName(language: appLanguage) : item.device.machineName,
                                    subtitle: "\(item.localizedName(language: appLanguage)) · MET \(item.metValue.formatted(.number.precision(.fractionLength(1))))",
                                    badge: catalogCount(for: item) > 0 ? "\(catalogCount(for: item))x \(appLanguage.ui("in Routinen"))" : nil
                                )
                            }
                        }
                    }
                }
            } else {
                Section {
                    NavigationLink {
                        DeviceExerciseCreatorView()
                    } label: {
                        Label(appLanguage.ui("Eigene Übung erstellen"), systemImage: "plus.square.dashed")
                    }
                }

                let customExercises = filteredCustomExercises
                if !customExercises.isEmpty {
                    Section(appLanguage.ui("Eigene Übungen")) {
                        ForEach(customExercises) { exercise in
                            HStack(spacing: 10) {
                                if let routine = routine(containing: exercise) {
                                    NavigationLink {
                                        DeviceSettingsRouteView(routine: routine, exerciseID: exercise.id)
                                    } label: {
                                        DeviceExerciseRow(
                                            category: exercise.category,
                                            title: exercise.localizedName(language: appLanguage),
                                            subtitle: "\(exercise.category.localizedName(language: appLanguage)) · MET \(exercise.metValue.formatted(.number.precision(.fractionLength(1))))",
                                            badge: appLanguage.ui("Eigene Übung")
                                        )
                                    }
                                } else {
                                    DeviceExerciseRow(
                                        category: exercise.category,
                                        title: exercise.localizedName(language: appLanguage),
                                        subtitle: "\(exercise.category.localizedName(language: appLanguage)) · MET \(exercise.metValue.formatted(.number.precision(.fractionLength(1))))",
                                        badge: appLanguage.ui("Eigene Übung")
                                    )
                                }

                                Spacer()

                                Button(role: .destructive) {
                                    store.deleteCustomExercise(catalogID: exercise.catalogID)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("\(exercise.localizedName(language: appLanguage)) \(appLanguage.ui("Löschen"))")
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.deleteCustomExercise(catalogID: exercise.catalogID)
                                } label: {
                                    Label(appLanguage.ui("Löschen"), systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                ForEach(DeviceCategory.allCases) { category in
                    let items = filteredCatalogItems(for: category, kind: .exercise)
                    if !items.isEmpty {
                        Section(category.localizedName(language: appLanguage)) {
                            ForEach(items) { item in
                                DeviceExerciseRow(
                                    category: item.category,
                                    title: item.localizedName(language: appLanguage),
                                    subtitle: "\(item.device.machineName) · MET \(item.metValue.formatted(.number.precision(.fractionLength(1))))",
                                    badge: catalogCount(for: item) > 0 ? "\(catalogCount(for: item))x \(appLanguage.ui("in Routinen"))" : nil
                                )
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(appLanguage.ui("Geräte und Übungen"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: appLanguage.ui("Gerät oder Übung suchen"))
        .themedPageBackground()
    }

    private func filteredDevices(in routine: WorkoutPlan) -> [Exercise] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let devices = routine.exercises.filter(\.isDeviceBased)
        guard !query.isEmpty else { return devices }
        return devices.filter {
            $0.localizedName(language: appLanguage).localizedCaseInsensitiveContains(query) ||
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.device.machineName.localizedCaseInsensitiveContains(query)
        }
    }

    private func filteredCatalogItems(for category: DeviceCategory, kind: ExerciseCatalogItemKind) -> [ExerciseCatalogItem] {
        let items = ExerciseCatalog.all.filter { $0.category == category && $0.kind == kind }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return items }
        return items.filter {
            $0.localizedName(language: appLanguage).localizedCaseInsensitiveContains(query) ||
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.device.machineName.localizedCaseInsensitiveContains(query)
        }
    }

    private var filteredCustomExercises: [Exercise] {
        var seenCatalogIDs = Set<String>()
        let exercises = store.routines.flatMap(\.exercises).filter { exercise in
            exercise.isCustom && !exercise.isDeviceBased && seenCatalogIDs.insert(exercise.catalogID).inserted
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return exercises }
        return exercises.filter {
            $0.localizedName(language: appLanguage).localizedCaseInsensitiveContains(query) ||
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.device.machineName.localizedCaseInsensitiveContains(query)
        }
    }

    private var filteredCustomDevices: [Exercise] {
        var seenCatalogIDs = Set<String>()
        let devices = store.routines.flatMap(\.exercises).filter { exercise in
            exercise.isCustom && exercise.isDeviceBased && seenCatalogIDs.insert(exercise.catalogID).inserted
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return devices }
        return devices.filter {
            $0.localizedName(language: appLanguage).localizedCaseInsensitiveContains(query) ||
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.device.machineName.localizedCaseInsensitiveContains(query)
        }
    }

    private func catalogCount(for item: ExerciseCatalogItem) -> Int {
        store.routines.reduce(0) { partial, routine in
            partial + routine.exercises.filter { $0.catalogID == item.id }.count
        }
    }

    private func routine(containing exercise: Exercise) -> WorkoutPlan? {
        store.routines.first { routine in
            routine.exercises.contains { $0.id == exercise.id }
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private enum DeviceManagementMode: String, CaseIterable, Identifiable {
    case devices = "Geräte"
    case exercises = "Übungen"

    var id: String { rawValue }

    var helpText: String {
        switch self {
        case .devices:
            "Hier findest du Maschinen, Kabelzüge und Cardiogeräte aus deinen Routinen sowie den Gerätekatalog."
        case .exercises:
            "Hier findest du freie Übungen mit Körpergewicht, Kurz-, Langhantel oder Kettlebell und kannst eigene Übungen anlegen."
        }
    }
}

private struct DeviceExerciseRow: View {
    let category: DeviceCategory
    let title: String
    let subtitle: String
    var badge: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            ExerciseArtwork(category: category, size: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let badge {
                    Text(badge)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }
        }
    }
}

private struct CustomExerciseIconOption: Identifiable {
    let id: String
    let title: String
    let category: DeviceCategory

    static let all: [CustomExerciseIconOption] = [
        CustomExerciseIconOption(id: "chest-press", title: "Brustpresse", category: .chest),
        CustomExerciseIconOption(id: "incline-press", title: "Schrägbrustpresse", category: .chest),
        CustomExerciseIconOption(id: "pec-deck", title: "Pec Deck", category: .chest),
        CustomExerciseIconOption(id: "cable-fly", title: "Kabelzug Fly", category: .chest),
        CustomExerciseIconOption(id: "machine-fly", title: "Machine Fly", category: .chest),
        CustomExerciseIconOption(id: "cable-chest-press", title: "Kabelzug Brust", category: .chest),
        CustomExerciseIconOption(id: "smith-bench-press", title: "Smith Bankdrücken", category: .chest),
        CustomExerciseIconOption(id: "push-up", title: "Liegestütze", category: .chest),
        CustomExerciseIconOption(id: "lat-pulldown", title: "Latzug", category: .back),
        CustomExerciseIconOption(id: "seated-row", title: "Rudern sitzend", category: .back),
        CustomExerciseIconOption(id: "seated-machine-row", title: "Rudermaschine", category: .back),
        CustomExerciseIconOption(id: "back-extension", title: "Rückenstrecker", category: .back),
        CustomExerciseIconOption(id: "assisted-pullup", title: "Assistierte Klimmzüge", category: .back),
        CustomExerciseIconOption(id: "low-row", title: "Low Row", category: .back),
        CustomExerciseIconOption(id: "t-bar-row-machine", title: "T-Bar Row", category: .back),
        CustomExerciseIconOption(id: "pullover-machine", title: "Pullover Maschine", category: .back),
        CustomExerciseIconOption(id: "cable-row", title: "Kabelrudern", category: .back),
        CustomExerciseIconOption(id: "face-pull", title: "Face Pull", category: .back),
        CustomExerciseIconOption(id: "shoulder-press", title: "Schulterpresse", category: .shoulders),
        CustomExerciseIconOption(id: "lateral-raise", title: "Seitheben", category: .shoulders),
        CustomExerciseIconOption(id: "rear-delt", title: "Reverse Butterfly", category: .shoulders),
        CustomExerciseIconOption(id: "cable-lateral-raise", title: "Seitheben Kabelzug", category: .shoulders),
        CustomExerciseIconOption(id: "front-raise", title: "Frontheben", category: .shoulders),
        CustomExerciseIconOption(id: "shrug-machine", title: "Shrug Maschine", category: .shoulders),
        CustomExerciseIconOption(id: "arnold-press", title: "Arnold Press", category: .shoulders),
        CustomExerciseIconOption(id: "leg-press", title: "Beinpresse", category: .legs),
        CustomExerciseIconOption(id: "leg-extension", title: "Beinstrecker", category: .legs),
        CustomExerciseIconOption(id: "leg-curl", title: "Beinbeuger", category: .legs),
        CustomExerciseIconOption(id: "hip-thrust", title: "Hip Thrust", category: .legs),
        CustomExerciseIconOption(id: "abductor", title: "Abduktor", category: .legs),
        CustomExerciseIconOption(id: "adductor", title: "Adduktor", category: .legs),
        CustomExerciseIconOption(id: "calf-raise", title: "Wadenheben", category: .legs),
        CustomExerciseIconOption(id: "hack-squat", title: "Hack Squat", category: .legs),
        CustomExerciseIconOption(id: "smith-squat", title: "Smith Kniebeuge", category: .legs),
        CustomExerciseIconOption(id: "glute-kickback", title: "Glute Kickback", category: .legs),
        CustomExerciseIconOption(id: "seated-calf-raise", title: "Wadenheben sitzend", category: .legs),
        CustomExerciseIconOption(id: "biceps-curl", title: "Bizepscurl", category: .arms),
        CustomExerciseIconOption(id: "triceps-press", title: "Trizepsdrücken", category: .arms),
        CustomExerciseIconOption(id: "dip-machine", title: "Dip Maschine", category: .arms),
        CustomExerciseIconOption(id: "preacher-curl", title: "Scottcurl", category: .arms),
        CustomExerciseIconOption(id: "hammer-curl", title: "Hammercurl", category: .arms),
        CustomExerciseIconOption(id: "cable-curl", title: "Kabelcurl", category: .arms),
        CustomExerciseIconOption(id: "overhead-triceps", title: "Trizeps über Kopf", category: .arms),
        CustomExerciseIconOption(id: "skull-crusher", title: "Skull Crusher", category: .arms),
        CustomExerciseIconOption(id: "ab-crunch", title: "Bauchpresse", category: .core),
        CustomExerciseIconOption(id: "crunch-press", title: "Crunch Maschine", category: .core),
        CustomExerciseIconOption(id: "rotary-torso", title: "Rumpfrotation", category: .core),
        CustomExerciseIconOption(id: "plank", title: "Plank", category: .core),
        CustomExerciseIconOption(id: "cable-crunch", title: "Cable Crunch", category: .core),
        CustomExerciseIconOption(id: "hanging-leg-raise", title: "Hanging Leg Raise", category: .core),
        CustomExerciseIconOption(id: "roman-chair", title: "Roman Chair", category: .core),
        CustomExerciseIconOption(id: "pallof-press", title: "Pallof Press", category: .core),
        CustomExerciseIconOption(id: "treadmill", title: "Laufband", category: .cardio),
        CustomExerciseIconOption(id: "bike", title: "Fahrrad", category: .cardio),
        CustomExerciseIconOption(id: "cross-trainer", title: "Crosstrainer", category: .cardio),
        CustomExerciseIconOption(id: "rowing", title: "Ruderergometer", category: .cardio),
        CustomExerciseIconOption(id: "stairmaster", title: "Stairmaster", category: .cardio),
        CustomExerciseIconOption(id: "skierg", title: "SkiErg", category: .cardio),
        CustomExerciseIconOption(id: "air-bike", title: "Air Bike", category: .cardio),
        CustomExerciseIconOption(id: "bench-press", title: "Bankdrücken", category: .freeWeights),
        CustomExerciseIconOption(id: "deadlift", title: "Kreuzheben", category: .freeWeights),
        CustomExerciseIconOption(id: "dumbbell-row", title: "Kurzhantelrudern", category: .freeWeights),
        CustomExerciseIconOption(id: "romanian-deadlift", title: "Rumänisches Kreuzheben", category: .freeWeights),
        CustomExerciseIconOption(id: "goblet-squat", title: "Goblet Squat", category: .freeWeights),
        CustomExerciseIconOption(id: "walking-lunge", title: "Ausfallschritte", category: .freeWeights),
        CustomExerciseIconOption(id: "dumbbell-bench-press", title: "Kurzhantel Bankdrücken", category: .freeWeights),
        CustomExerciseIconOption(id: "squat", title: "Kniebeuge", category: .freeWeights)
    ]

    static func defaultID(for category: DeviceCategory) -> String {
        all.first { $0.category == category }?.id ?? all[0].id
    }
}

private struct CustomExerciseIconPicker: View {
    @Binding var selectedID: String
    let appLanguage: AppLanguage

    private let columns = [
        GridItem(.adaptive(minimum: 72), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(CustomExerciseIconOption.all) { option in
                Button {
                    selectedID = option.id
                } label: {
                    VStack(spacing: 6) {
                        ExerciseArtwork(category: option.category, size: 46)

                        Text(appLanguage.ui(option.title))
                            .font(.caption2)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(selectedID == option.id ? Color.accentColor.opacity(0.16) : Color(.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(selectedID == option.id ? Color.accentColor : Color.clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(appLanguage.ui("Icon")) \(appLanguage.ui(option.title))")
            }
        }
    }
}

private struct DeviceSettingsRouteView: View {
    @EnvironmentObject private var store: WorkoutStore
    let routine: WorkoutPlan
    let exerciseID: UUID

    var body: some View {
        Group {
            if let exercise = store.plan.exercises.first(where: { $0.id == exerciseID }) {
                DeviceExerciseEditorView(exercise: exercise)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            store.selectRoutine(routine)
        }
    }
}

private struct DeviceExerciseEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let exercise: Exercise

    @State private var exerciseName: String
    @State private var target: String
    @State private var muscleDistribution: [MuscleDistributionShare]
    @State private var metValue: Double
    @State private var settings: DeviceSettings

    init(exercise: Exercise) {
        self.exercise = exercise
        _exerciseName = State(initialValue: exercise.name)
        _target = State(initialValue: exercise.target)
        _muscleDistribution = State(initialValue: exercise.effectiveMuscleDistribution)
        _metValue = State(initialValue: exercise.metValue)
        _settings = State(initialValue: exercise.device.withoutDashPlaceholders)
    }

    var body: some View {
        Form {
            Section(appLanguage.ui("Übung")) {
                TextField(appLanguage.ui("Name der Übung"), text: $exerciseName)
                TextField(appLanguage.ui("Ziel, z. B. 3 x 12"), text: $target)

                Stepper(value: $metValue, in: 1...12, step: 0.1) {
                    SettingsValueRow(title: "MET", value: metValue.formatted(.number.precision(.fractionLength(1))))
                }
            }

            MuscleDistributionEditor(shares: $muscleDistribution, appLanguage: appLanguage)

            if exercise.isDeviceBased {
                DeviceSettingsFields(settings: $settings)
            }
        }
        .navigationTitle(exercise.localizedName(language: appLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(appLanguage.ui("Fertig")) {
                    save()
                    dismiss()
                }
            }
        }
    }

    private func save() {
        let reps = exercise.sets.first?.reps ?? 12
        let weight = exercise.sets.first?.weight ?? 0
        store.renameExercise(exercise, name: exerciseName)
        store.updateExercise(
            exercise,
            target: target,
            setCount: exercise.sets.count,
            reps: reps,
            defaultWeight: weight,
            metValue: metValue
        )
        store.updateMuscleDistribution(exercise, shares: muscleDistribution)
        store.updateDevice(for: exercise, settings: settings)
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct DeviceCatalogEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let item: ExerciseCatalogItem

    @State private var exerciseName: String
    @State private var target: String
    @State private var metValue: Double
    @State private var settings: DeviceSettings

    init(item: ExerciseCatalogItem) {
        self.item = item
        _exerciseName = State(initialValue: item.name)
        _target = State(initialValue: item.target)
        _metValue = State(initialValue: item.metValue)
        _settings = State(initialValue: item.device.withoutDashPlaceholders)
    }

    var body: some View {
        Form {
            Section(appLanguage.ui("Übung")) {
                TextField(appLanguage.ui("Name der Übung"), text: $exerciseName)
                TextField(appLanguage.ui("Ziel, z. B. 3 x 12"), text: $target)

                Stepper(value: $metValue, in: 1...12, step: 0.1) {
                    SettingsValueRow(title: "MET", value: metValue.formatted(.number.precision(.fractionLength(1))))
                }
            }

            DeviceSettingsFields(settings: $settings)
        }
        .navigationTitle(item.localizedName(language: appLanguage))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct DeviceExerciseCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue

    @State private var exerciseName = ""
    @State private var category: DeviceCategory = .freeWeights
    @State private var target = "3 x 12"
    @State private var sets = 3
    @State private var reps = 12
    @State private var weightText = formattedWeightInput(0)
    @State private var metValue = 5.0
    @State private var iconTemplateID = CustomExerciseIconOption.defaultID(for: .freeWeights)
    @State private var muscleDistribution = MuscleDistributionShare.defaultShares(for: .freeWeights)

    var body: some View {
        Form {
            Section(appLanguage.ui("Übung")) {
                TextField(appLanguage.ui("Name der Übung"), text: $exerciseName)
                Picker(appLanguage.ui("Kategorie"), selection: $category) {
                    ForEach(DeviceCategory.allCases) { category in
                        Text(category.localizedName(language: appLanguage)).tag(category)
                    }
                }
                TextField(appLanguage.ui("Ziel, z. B. 3 x 12"), text: $target)

                Stepper(value: $metValue, in: 1...12, step: 0.1) {
                    SettingsValueRow(title: "MET", value: metValue.formatted(.number.precision(.fractionLength(1))))
                }
            }

            Section(appLanguage.ui("Icon")) {
                CustomExerciseIconPicker(selectedID: $iconTemplateID, appLanguage: appLanguage)
            }

            MuscleDistributionEditor(shares: $muscleDistribution, appLanguage: appLanguage)

            Section(appLanguage.ui("Startwerte")) {
                Stepper(value: $sets, in: 1...8) {
                    SettingsValueRow(title: appLanguage.ui("Sätze"), value: "\(sets)")
                }
                Stepper(value: $reps, in: 1...50) {
                    SettingsValueRow(title: appLanguage.ui("Wiederholungen"), value: "\(reps)")
                }
                WeightInputRow(title: appLanguage.ui("Gewicht"), text: $weightText)
            }

        }
        .navigationTitle(appLanguage.ui("Neue Übung"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(appLanguage.ui("Hinzufügen")) {
                    store.addCustomExercise(
                        name: exerciseName,
                        category: category,
                        target: target,
                        sets: sets,
                        reps: reps,
                        weight: parsedWeightInput(weightText),
                        metValue: metValue,
                        iconTemplateID: iconTemplateID,
                        device: .empty,
                        usesDedicatedDevice: false,
                        muscleDistribution: muscleDistribution
                    )
                    dismiss()
                }
                .disabled(exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || MuscleDistributionShare.normalizedShares(muscleDistribution).isEmpty)
            }
        }
        .onChange(of: category) { _, newCategory in
            iconTemplateID = CustomExerciseIconOption.defaultID(for: newCategory)
            muscleDistribution = MuscleDistributionShare.defaultShares(for: newCategory)
        }
        .themedPageBackground()
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct MachineCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WorkoutStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue

    @State private var machineName = ""
    @State private var exerciseName = ""
    @State private var category: DeviceCategory = .chest
    @State private var target = "3 x 12"
    @State private var metValue = 5.0
    @State private var iconTemplateID = CustomExerciseIconOption.defaultID(for: .chest)
    @State private var muscleDistribution = MuscleDistributionShare.defaultShares(for: .chest)
    @State private var seat = ""
    @State private var backrest = ""
    @State private var handle = ""
    @State private var range = ""

    var body: some View {
        Form {
            Section(appLanguage.ui("Gerät")) {
                TextField(appLanguage.ui("Gerätename, z. B. Chest Press"), text: $machineName)
                Picker(appLanguage.ui("Kategorie"), selection: $category) {
                    ForEach(DeviceCategory.allCases) { category in
                        Text(category.localizedName(language: appLanguage)).tag(category)
                    }
                }

                Stepper(value: $metValue, in: 1...12, step: 0.1) {
                    SettingsValueRow(title: "MET", value: metValue.formatted(.number.precision(.fractionLength(1))))
                }
            }

            Section(appLanguage.ui("Übung")) {
                TextField(appLanguage.ui("Übungsname, z. B. Brustpresse"), text: $exerciseName)
                TextField(appLanguage.ui("Ziel, z. B. 3 x 12"), text: $target)
            }

            Section(appLanguage.ui("Icon")) {
                CustomExerciseIconPicker(selectedID: $iconTemplateID, appLanguage: appLanguage)
            }

            MuscleDistributionEditor(shares: $muscleDistribution, appLanguage: appLanguage)

            Section(appLanguage.ui("Einstellungen")) {
                TextField(appLanguage.ui("Sitzposition"), text: $seat)
                TextField(appLanguage.ui("Rückenlehne oder Polster"), text: $backrest)
                TextField(appLanguage.ui("Griff oder Handle"), text: $handle)
                TextField(appLanguage.ui("Bewegungsumfang"), text: $range)
            }
        }
        .navigationTitle(appLanguage.ui("Gerät hinzufügen"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(appLanguage.ui("Hinzufügen")) {
                    addMachine()
                    dismiss()
                }
                .disabled(machineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || MuscleDistributionShare.normalizedShares(muscleDistribution).isEmpty)
            }
        }
        .onChange(of: category) { _, newCategory in
            iconTemplateID = CustomExerciseIconOption.defaultID(for: newCategory)
            muscleDistribution = MuscleDistributionShare.defaultShares(for: newCategory)
        }
        .themedPageBackground()
    }

    private func addMachine() {
        let trimmedMachineName = machineName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExerciseName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalExerciseName = trimmedExerciseName.isEmpty ? trimmedMachineName : trimmedExerciseName

        store.addCustomExercise(
            name: finalExerciseName,
            category: category,
            target: target,
            sets: 3,
            reps: 12,
            weight: 0,
            metValue: metValue,
            iconTemplateID: iconTemplateID,
            device: DeviceSettings(
                machineName: trimmedMachineName,
                seat: seat,
                backrest: backrest,
                handle: handle,
                range: range,
                notes: ""
            ),
            usesDedicatedDevice: true,
            muscleDistribution: muscleDistribution
        )
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct DeviceSettingsFields: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @Binding var settings: DeviceSettings

    var body: some View {
        Section(appLanguage.ui("Gerät")) {
            TextField(appLanguage.ui("Gerätename, z. B. Brustpresse"), text: $settings.machineName)
            TextField(appLanguage.ui("Sitzposition"), text: $settings.seat)
            TextField(appLanguage.ui("Rückenlehne oder Polster"), text: $settings.backrest)
            TextField(appLanguage.ui("Griff oder Handle"), text: $settings.handle)
            TextField(appLanguage.ui("Bewegungsumfang"), text: $settings.range)
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private extension DeviceSettings {
    var withoutDashPlaceholders: DeviceSettings {
        DeviceSettings(
            machineName: clean(machineName),
            seat: clean(seat),
            backrest: clean(backrest),
            handle: clean(handle),
            range: clean(range),
            notes: clean(notes)
        )
    }

    private func clean(_ value: String) -> String {
        ["-", "0"].contains(value.trimmingCharacters(in: .whitespacesAndNewlines)) ? "" : value
    }

    var hasVisibleContent: Bool {
        visibleMachineName != nil || !visibleSettingPairs.isEmpty || visibleNotes != nil
    }

    var visibleMachineName: String? {
        visible(machineName)
    }

    var visibleNotes: String? {
        visible(notes)
    }

    var visibleSettingPairs: [(title: String, value: String)] {
        [
            ("Sitz", visible(seat)),
            ("Lehne", visible(backrest)),
            ("Griff", visible(handle)),
            ("Weg", visible(range))
        ].compactMap { title, value in
            value.map { (title, $0) }
        }
    }

    private func visible(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed == "-" || trimmed == "0" ? nil : trimmed
    }
}

private struct CatalogItemRow: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let item: ExerciseCatalogItem
    var isAdded: Bool = false
    var countInPlan: Int = 0
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ExerciseArtwork(category: item.category, size: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.localizedName(language: appLanguage))
                    .font(.headline)
                Text("\(item.target) · \(item.device.machineName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if countInPlan > 0 {
                    Text("\(countInPlan)x \(appLanguage.ui("im Plan"))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            Button(action: action) {
                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(isAdded ? .green : Color.accentColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(item.localizedName(language: appLanguage)) \(appLanguage.ui("Hinzufügen"))")
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct PlanExerciseSettingsRow: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            ExerciseArtwork(category: exercise.category, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.localizedName(language: appLanguage))
                Text(planSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var planSubtitle: String {
        [exercise.target, startWeightText, exercise.device.visibleMachineName].compactMap { value in
            guard let value, !value.isEmpty else { return nil }
            return value
        }.joined(separator: " · ")
    }

    private var startWeightText: String? {
        guard let weight = exercise.sets.first?.weight else { return nil }
        return weight.formattedWeight(unit: weightUnit)
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }
}

private struct DeviceSummary: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let device: DeviceSettings

    var body: some View {
        if device.hasVisibleContent {
            VStack(alignment: .leading, spacing: 6) {
                if let machineName = device.visibleMachineName {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.secondary)
                        Text(machineName)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                    }
                }

                let settings = device.visibleSettingPairs
                if !settings.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(settings, id: \.title) { setting in
                            CompactSettingChip(title: appLanguage.ui(setting.title), value: setting.value)
                        }
                    }
                }

                if let notes = device.visibleNotes {
                    Text(notes)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct DeviceSettingsLine: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let device: DeviceSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(device.visibleMachineName ?? appLanguage.ui("Kein Gerät hinterlegt"))
            Text(detailText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var detailText: String {
        let parts = device.visibleSettingPairs.map { "\(appLanguage.ui($0.title)) \($0.value)" }

        return parts.isEmpty ? appLanguage.ui("Keine Einstellungen hinterlegt") : parts.joined(separator: " · ")
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct SettingChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CompactSettingChip: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WeightBadge: View {
    @AppStorage(WeightUnit.storageKey) private var weightUnitRawValue = WeightUnit.kilograms.rawValue
    let title: String
    let value: Double?

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(valueText)
                .font(.subheadline.bold())
                .monospacedDigit()
        }
        .frame(minWidth: 58)
    }

    private var valueText: String {
        guard let value else { return "-" }
        return value.formattedWeight(unit: weightUnit)
    }

    private var weightUnit: WeightUnit {
        WeightUnit.value(for: weightUnitRawValue)
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
                .frame(width: 22)
            Text(title)
                .font(.subheadline)
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MiniStatTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.accentColor)
                .frame(width: 16)

            Text(title)
                .font(.caption)
            Spacer(minLength: 6)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MuscleDistributionView: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let distribution: [(category: DeviceCategory, completedSets: Double, plannedSets: Double)]
    let showsCompletedProgress: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if distribution.isEmpty {
                Text(appLanguage.ui("Noch keine Übungen geplant."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(distribution, id: \.category.id) { entry in
                    HStack(spacing: 8) {
                        Label(entry.category.localizedName(language: appLanguage), systemImage: entry.category.iconName)
                            .font(.caption)
                            .frame(width: 112, alignment: .leading)

                        GeometryReader { proxy in
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous)
                                .fill(Color.accentColor.opacity(0.18))
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous)
                                        .fill(Color.accentColor)
                                        .frame(width: proxy.size.width * barFraction(for: entry))
                                }
                        }
                        .frame(height: 8)

                        Text(valueText(for: entry))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(width: showsCompletedProgress ? 78 : 44, alignment: .trailing)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var maxPlannedSets: Double {
        max(1, distribution.map { $0.plannedSets }.max() ?? 1)
    }

    private var totalPlannedSets: Double {
        max(1, distribution.reduce(0) { $0 + $1.plannedSets })
    }

    private func barFraction(for entry: (category: DeviceCategory, completedSets: Double, plannedSets: Double)) -> CGFloat {
        if showsCompletedProgress {
            return CGFloat(entry.completedSets) / CGFloat(max(1, entry.plannedSets))
        }

        return CGFloat(entry.plannedSets) / CGFloat(maxPlannedSets)
    }

    private func valueText(for entry: (category: DeviceCategory, completedSets: Double, plannedSets: Double)) -> String {
        if showsCompletedProgress {
            let percent = entry.plannedSets > 0 ? entry.completedSets / entry.plannedSets * 100 : 0
            return "\(formattedSetCount(entry.completedSets))/\(formattedSetCount(entry.plannedSets)) · \(formattedPercent(percent)) %"
        }

        return "\(formattedPercent(entry.plannedSets / totalPlannedSets * 100)) %"
    }

    private func formattedSetCount(_ value: Double) -> String {
        if abs(value.rounded() - value) < 0.05 {
            return "\(Int(value.rounded()))"
        }

        return value.formatted(.number.precision(.fractionLength(1)))
    }

    private func formattedPercent(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct ExerciseBadges: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 6) {
            if exercise.isFavorite {
                Label(appLanguage.ui("Favorit"), systemImage: "star.fill")
                    .foregroundStyle(.yellow)
            }

            if let group = exercise.supersetGroup {
                Label("\(appLanguage.ui("Superset")) \(groupLabel(group))", systemImage: "link")
                    .foregroundStyle(Color.accentColor)
            }

            if exercise.isCustom {
                Label(appLanguage.ui("Eigene Übung"), systemImage: "person.crop.square")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption.weight(.semibold))
    }

    private func groupLabel(_ group: Int) -> String {
        ["A", "B", "C"].indices.contains(group - 1) ? ["A", "B", "C"][group - 1] : "\(group)"
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
        }
    }
}

private struct InfoRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

private struct EmptyPlanView: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRawValue = AppLanguage.system.rawValue

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "plus.circle")
                .font(.largeTitle)
                .foregroundStyle(Color.accentColor)
            Text(appLanguage.ui("Noch kein Training zusammengestellt"))
                .font(.headline)
            Text(appLanguage.ui("Öffne die Einstellungen und füge Standardgeräte zu deinem Plan hinzu."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var appLanguage: AppLanguage {
        AppLanguage.value(for: appLanguageRawValue)
    }
}

private extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct SettingsValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}
