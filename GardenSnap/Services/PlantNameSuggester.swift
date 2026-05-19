import Foundation

struct PlantNameSuggester {
    func suggestedName(for profile: PlantSpeciesProfile, existingPlants: [PlantInstance]) -> String {
        let baseName = profile.commonName.trimmingCharacters(in: .whitespacesAndNewlines)
        let matchingCount = existingPlants.filter { plant in
            plant.species.commonName.caseInsensitiveCompare(profile.commonName) == .orderedSame
        }.count

        return "\(baseName) \(matchingCount + 1)"
    }
}
