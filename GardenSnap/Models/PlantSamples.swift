import Foundation

enum PlantSamples {
    static let hosta = PlantSpeciesProfile(
        commonName: "Hosta",
        scientificName: "Hosta",
        aliases: ["plantain lily"],
        minimumWateringDays: 4,
        maximumWateringDays: 7,
        fertilizeEveryDays: 45,
        pruneWindowMonths: [3, 4, 10, 11],
        droughtTolerance: 0.25,
        overwateringSensitivity: 0.45,
        diseaseWatchlist: ["slug damage", "leaf scorch", "crown rot"],
        careNotes: "Keep soil evenly moist, especially in heat. Avoid constantly wet crowns."
    )

    static let tomato = PlantSpeciesProfile(
        commonName: "Tomato",
        scientificName: "Solanum lycopersicum",
        aliases: ["tomato plant"],
        minimumWateringDays: 2,
        maximumWateringDays: 4,
        fertilizeEveryDays: 21,
        pruneWindowMonths: [5, 6, 7, 8],
        droughtTolerance: 0.2,
        overwateringSensitivity: 0.35,
        diseaseWatchlist: ["early blight", "leaf spot", "powdery mildew"],
        careNotes: "Keep watering consistent and avoid wetting leaves when possible."
    )

    static let hydrangea = PlantSpeciesProfile(
        commonName: "Hydrangea",
        scientificName: "Hydrangea macrophylla",
        aliases: ["bigleaf hydrangea"],
        minimumWateringDays: 3,
        maximumWateringDays: 5,
        fertilizeEveryDays: 60,
        pruneWindowMonths: [7, 8, 9],
        droughtTolerance: 0.15,
        overwateringSensitivity: 0.4,
        diseaseWatchlist: ["leaf spot", "wilting", "powdery mildew"],
        careNotes: "Water deeply in warm weather. Prune timing depends on bloom type."
    )

    static let basil = PlantSpeciesProfile(
        commonName: "Basil",
        scientificName: "Ocimum basilicum",
        aliases: ["sweet basil"],
        minimumWateringDays: 2,
        maximumWateringDays: 3,
        fertilizeEveryDays: 30,
        pruneWindowMonths: [5, 6, 7, 8, 9],
        droughtTolerance: 0.1,
        overwateringSensitivity: 0.3,
        diseaseWatchlist: ["downy mildew", "yellowing leaves", "aphids"],
        careNotes: "Pinch tips often and water before leaves droop."
    )

    static let knownProfiles = [hosta, tomato, hydrangea, basil]
}
