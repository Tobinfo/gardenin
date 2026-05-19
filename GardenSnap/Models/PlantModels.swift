import Foundation

enum SunExposure: String, Codable, CaseIterable, Identifiable {
    case fullSun
    case partSun
    case shade

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fullSun: "Full sun"
        case .partSun: "Part sun"
        case .shade: "Shade"
        }
    }
}

enum GrowthSetting: String, Codable, CaseIterable, Identifiable {
    case gardenBed
    case raisedBed
    case container
    case indoor

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gardenBed: "Garden bed"
        case .raisedBed: "Raised bed"
        case .container: "Container"
        case .indoor: "Indoor"
        }
    }
}

enum HealthSeverity: String, Codable, CaseIterable {
    case none
    case watch
    case action
}

enum CareActionKind: String, Codable, CaseIterable, Identifiable {
    case water
    case fertilize
    case prune
    case inspect

    var id: String { rawValue }

    var label: String {
        switch self {
        case .water: "Water"
        case .fertilize: "Fertilize"
        case .prune: "Prune"
        case .inspect: "Inspect"
        }
    }
}

enum CareStatus: String, Codable {
    case dueNow
    case dueSoon
    case scheduled
    case paused

    var label: String {
        switch self {
        case .dueNow: "Due now"
        case .dueSoon: "Soon"
        case .scheduled: "Scheduled"
        case .paused: "Paused"
        }
    }
}

struct PlantSpeciesProfile: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var commonName: String
    var scientificName: String?
    var aliases: [String]
    var minimumWateringDays: Int
    var maximumWateringDays: Int
    var fertilizeEveryDays: Int
    var pruneWindowMonths: [Int]
    var droughtTolerance: Double
    var overwateringSensitivity: Double
    var diseaseWatchlist: [String]
    var careNotes: String

    var averageWateringDays: Int {
        max(1, (minimumWateringDays + maximumWateringDays) / 2)
    }
}

struct DetectedIssue: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var detail: String
    var severity: HealthSeverity
}

struct PlantObservationBox: Codable, Hashable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}

struct PlantIdentificationMetadata: Codable, Hashable {
    var providerName: String
    var providerPlantID: String?
    var source: String

    static let demo = PlantIdentificationMetadata(
        providerName: "GardenSnap demo",
        providerPlantID: nil,
        source: "local-demo"
    )
}

struct PlantIdentificationCandidate: Identifiable, Hashable {
    var id: UUID = UUID()
    var profile: PlantSpeciesProfile
    var confidence: Double
    var observedIssues: [DetectedIssue]
    var observationBox: PlantObservationBox?
    var metadata: PlantIdentificationMetadata = .demo
}

struct CareLog: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var action: CareActionKind
    var date: Date
    var notes: String
}

struct PlantHealthNote: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var title: String
    var detail: String
    var severity: HealthSeverity
}

struct PlantInstance: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var nickname: String
    var species: PlantSpeciesProfile
    var dateAdded: Date
    var locationNote: String
    var setting: GrowthSetting
    var sunExposure: SunExposure
    var healthNotes: [PlantHealthNote]
    var careLogs: [CareLog]

    var lastWatered: Date? {
        mostRecentDate(for: .water)
    }

    var lastFertilized: Date? {
        mostRecentDate(for: .fertilize)
    }

    var lastPruned: Date? {
        mostRecentDate(for: .prune)
    }

    var lastInspected: Date? {
        mostRecentDate(for: .inspect)
    }

    private func mostRecentDate(for action: CareActionKind) -> Date? {
        careLogs
            .filter { $0.action == action }
            .map(\.date)
            .max()
    }
}

struct DailyWeather: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var highFahrenheit: Double
    var lowFahrenheit: Double
    var precipitationInches: Double
    var humidity: Double
    var windMph: Double
    var condition: String

    var isSoakingRain: Bool {
        precipitationInches >= 0.35
    }
}

struct GardenCoordinate: Codable, Hashable {
    var latitude: Double
    var longitude: Double
}

struct CareRecommendation: Identifiable, Hashable {
    var id: UUID = UUID()
    var action: CareActionKind
    var status: CareStatus
    var title: String
    var detail: String
    var dueDate: Date
    var priority: Int
}
