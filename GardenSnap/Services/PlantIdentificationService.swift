import Foundation
import UIKit

protocol PlantIdentificationService {
    func identify(image: UIImage) async throws -> [PlantIdentificationCandidate]
}

enum PlantIdentificationError: Error {
    case noPlantFound
}

final class DemoPlantIdentificationService: PlantIdentificationService {
    func identify(image: UIImage) async throws -> [PlantIdentificationCandidate] {
        try await Task.sleep(nanoseconds: 180_000_000)

        let imageShapeScore = Int(image.size.width + image.size.height) % PlantSamples.knownProfiles.count
        let primary = PlantSamples.knownProfiles[imageShapeScore]
        let secondary = PlantSamples.knownProfiles[(imageShapeScore + 1) % PlantSamples.knownProfiles.count]

        return [
            PlantIdentificationCandidate(
                profile: primary,
                confidence: 0.91,
                observedIssues: demoIssues(for: primary),
                observationBox: PlantObservationBox(x: 0.18, y: 0.14, width: 0.58, height: 0.66)
            ),
            PlantIdentificationCandidate(
                profile: secondary,
                confidence: 0.63,
                observedIssues: [],
                observationBox: PlantObservationBox(x: 0.28, y: 0.18, width: 0.48, height: 0.58)
            )
        ]
    }

    private func demoIssues(for profile: PlantSpeciesProfile) -> [DetectedIssue] {
        guard let firstIssue = profile.diseaseWatchlist.first else {
            return []
        }

        return [
            DetectedIssue(
                title: "Watch for \(firstIssue)",
                detail: "The scan did not confirm disease, but this plant commonly needs checks for \(firstIssue).",
                severity: .watch
            )
        ]
    }
}
