import Foundation

@MainActor
final class PlantStore: ObservableObject {
    @Published var plants: [PlantInstance] = [] {
        didSet {
            savePlants()
        }
    }

    @Published var forecast: [DailyWeather] = []
    @Published var isRefreshingWeather = false

    private let nameSuggester = PlantNameSuggester()
    private let recommendationEngine = CareRecommendationEngine()
    private let weatherProvider: WeatherProvider
    private let plantsURL: URL

    init(weatherProvider: WeatherProvider = DemoWeatherProvider()) {
        self.weatherProvider = weatherProvider
        self.plantsURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("plants.json")
        loadPlants()
    }

    func suggestedName(for profile: PlantSpeciesProfile) -> String {
        nameSuggester.suggestedName(for: profile, existingPlants: plants)
    }

    func recommendations(for plant: PlantInstance) -> [CareRecommendation] {
        recommendationEngine.recommendations(for: plant, forecast: forecast)
    }

    func addPlant(
        from candidate: PlantIdentificationCandidate,
        nickname: String,
        setting: GrowthSetting,
        sunExposure: SunExposure,
        locationNote: String
    ) {
        let healthNotes = candidate.observedIssues.map { issue in
            PlantHealthNote(
                date: Date(),
                title: issue.title,
                detail: issue.detail,
                severity: issue.severity
            )
        }

        plants.insert(
            PlantInstance(
                nickname: nickname,
                species: candidate.profile,
                dateAdded: Date(),
                locationNote: locationNote,
                setting: setting,
                sunExposure: sunExposure,
                healthNotes: healthNotes,
                careLogs: []
            ),
            at: 0
        )
    }

    func logCare(for plantID: PlantInstance.ID, action: CareActionKind, notes: String = "") {
        guard let index = plants.firstIndex(where: { $0.id == plantID }) else {
            return
        }

        plants[index].careLogs.insert(
            CareLog(action: action, date: Date(), notes: notes),
            at: 0
        )
    }

    func addHealthNote(
        for plantID: PlantInstance.ID,
        title: String,
        detail: String,
        severity: HealthSeverity
    ) {
        guard let index = plants.firstIndex(where: { $0.id == plantID }) else {
            return
        }

        plants[index].healthNotes.insert(
            PlantHealthNote(date: Date(), title: title, detail: detail, severity: severity),
            at: 0
        )
    }

    func refreshWeather() async {
        isRefreshingWeather = true
        defer { isRefreshingWeather = false }

        do {
            forecast = try await weatherProvider.forecast(for: nil)
        } catch {
            forecast = []
        }
    }

    private func loadPlants() {
        guard FileManager.default.fileExists(atPath: plantsURL.path) else {
            plants = []
            return
        }

        do {
            let data = try Data(contentsOf: plantsURL)
            plants = try JSONDecoder.gardenSnap.decode([PlantInstance].self, from: data)
        } catch {
            plants = []
        }
    }

    private func savePlants() {
        do {
            let data = try JSONEncoder.gardenSnap.encode(plants)
            try data.write(to: plantsURL, options: [.atomic])
        } catch {
            assertionFailure("Unable to save plants: \(error)")
        }
    }
}

private extension JSONEncoder {
    static var gardenSnap: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var gardenSnap: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
