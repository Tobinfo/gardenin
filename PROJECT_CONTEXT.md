# GardenSnap Project Context

GardenSnap is a laptop-first prototype for plant identification and care tracking, with an iOS SwiftUI scaffold kept as the later native target.

The core workflow is:

1. Scan or photograph a plant.
2. Review likely plant matches.
3. Accept or edit a suggested name such as `Hosta 1`.
4. Save the plant with setting, sun exposure, and garden location.
5. Get care recommendations for watering, fertilizing, pruning, and health checks.
6. Log care over time per individual plant.

## Current Product Shape

The repo contains:

- A browser prototype in `prototype/`; this is the primary build target for now.
- A SwiftUI iOS app in `GardenSnap/`; this should follow the proven laptop workflow later.
- Unit tests in `GardenSnapTests/`.
- A local Node static server in `scripts/serve-prototype.js`.
- A local plant identification provider boundary in `scripts/plant-id-provider.js`.
- XcodeGen configuration in `project.yml`.

## Current Constraints

- `C:\dev\plant watering` is the project source of truth.
- Ignore OneDrive for this project.
- The plant identification service is currently deterministic demo logic.
- Weather is currently demo forecast data.
- Plant data is stored locally.
- The browser prototype is the source of truth for current product behavior.
- The iOS app should avoid racing ahead until the laptop workflow stabilizes.

## Architecture Notes

Important areas:

- Models: `GardenSnap/Models/PlantModels.swift`
- Sample plant profiles: `GardenSnap/Models/PlantSamples.swift`
- Plant persistence and app state: `GardenSnap/Services/PlantStore.swift`
- Identification abstraction: `GardenSnap/Services/PlantIdentificationService.swift`
- Weather abstraction: `GardenSnap/Services/WeatherService.swift`
- Care logic: `GardenSnap/Services/CareRecommendationEngine.swift`
- Main app views: `GardenSnap/Views/`
- Browser prototype: `prototype/index.html`, `prototype/app.js`, `prototype/styles.css`
- Laptop plant ID connector: `scripts/plant-id-provider.js`

## Current Direction

Keep building around the laptop garden-walk loop first:

scan -> confirm -> name -> save -> care recommendation -> log care.

Real identification and real weather should be connected to the laptop prototype first, then ported to iOS after the workflow feels solid. The browser should call local endpoints, and local server code should handle any provider keys or provider-specific response shapes.
