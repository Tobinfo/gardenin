import XCTest
@testable import GardenSnap

final class CareRecommendationEngineTests: XCTestCase {
    func testNameSuggesterCountsExistingPlantsBySpecies() {
        let suggester = PlantNameSuggester()
        let existing = [
            PlantInstance(
                nickname: "Hosta 1",
                species: PlantSamples.hosta,
                dateAdded: Date(),
                locationNote: "",
                setting: .gardenBed,
                sunExposure: .shade,
                healthNotes: [],
                careLogs: []
            )
        ]

        XCTAssertEqual(suggester.suggestedName(for: PlantSamples.hosta, existingPlants: existing), "Hosta 2")
    }

    func testSoakingRainDelaysGardenBedWatering() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.date(from: DateComponents(year: 2026, month: 5, day: 19))!
        let yesterday = calendar.date(byAdding: .day, value: -5, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let plant = PlantInstance(
            nickname: "Hosta 1",
            species: PlantSamples.hosta,
            dateAdded: yesterday,
            locationNote: "",
            setting: .gardenBed,
            sunExposure: .shade,
            healthNotes: [],
            careLogs: [CareLog(action: .water, date: yesterday, notes: "")]
        )
        let forecast = [
            DailyWeather(
                date: tomorrow,
                highFahrenheit: 78,
                lowFahrenheit: 61,
                precipitationInches: 0.5,
                humidity: 0.7,
                windMph: 5,
                condition: "Rain"
            )
        ]

        let recommendations = CareRecommendationEngine().recommendations(
            for: plant,
            forecast: forecast,
            today: today,
            calendar: calendar
        )

        let water = recommendations.first { $0.action == .water }
        XCTAssertEqual(water?.status, .scheduled)
        XCTAssertTrue(water?.detail.contains("Rain is expected soon") == true)
    }
}
