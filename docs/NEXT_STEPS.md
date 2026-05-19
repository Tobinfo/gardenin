# Next Steps

## Current Priorities

1. Treat the laptop/browser prototype as the primary build target for now.
2. Choose and connect a real plant identification source behind a local/server-side connector.
3. Improve plant boxing for identified plants so the UI clearly shows what was recognized in the image.
4. Make care recommendations more complete by factoring in weather, recent pruning, watering, fertilizing, inspections, and plant-specific history.
5. Keep quick-add plant fast for plants the user already knows and does not need to scan.

## Recently Understood

- The app already has SwiftUI tabs for scanning and garden tracking.
- Plant records support nicknames, species, setting, sun exposure, health notes, and care logs.
- Recommendations account for species timing, setting, sun exposure, forecast, and health notes.
- The browser prototype stores plants in local storage and mirrors the same main loop.
- Git and Node are now available in the shell. In PowerShell, use `npm.cmd` when `npm` hits script execution policy.
- The prototype now has quick-add, identified-plant boxing, provider metadata, and care context from recent actions/weather.
- Plant identification now goes through `/api/identify`, backed by `scripts/plant-id-provider.js`; the current provider is still demo data, but the browser no longer owns the provider-specific identification logic.
- The camera starts from the Ready button inside the scan box. The live feed is framed with a focus box; captured ID sends the focused crop to the server and uses the focus box as the visual plant separation area.
- `scripts/plant-id-provider.js` now has a Pl@ntNet connector path. It needs `PLANT_ID_PROVIDER=plantnet` and `PLANTNET_API_KEY` before it can return real IDs.
- A local ignored `.env` now stores the Pl@ntNet provider settings for this machine.
- `Start GardenSnap Prototype.cmd` now clears the old local server on port 5173, opens the app, and starts the server with local `.env` settings.
- Scan mode is intended as walking mode: keep the camera live, identify the framed plant, and show the result. Add Plant is the freeze-frame point for reviewing and saving.
- Saved plants now include the provider metadata and scan crop needed to become future training data.

## Open Questions

- What real plant identification provider should be used: local model, API, or hybrid?
- What confidence threshold should be required before boxing and suggesting an identified plant?
- Should weather use WeatherKit or another provider?
- Should plant care schedules become user-adjustable?
- Should the app support garden zones/beds as first-class objects?
- Should photos be saved with each plant record?
- What is the fastest quick-add flow: type plant name first, choose from known samples, or add unknown plant and identify later?

## Suggested Next Work

1. Close old server windows, double-click `Start GardenSnap Prototype.cmd`, reload the app, and confirm Scan says Pl@ntNet.
2. Tune Scan/Add Plant button behavior after the first real Pl@ntNet run.
3. Add an explicit user-facing consent setting for saving scan crops as training data.
4. Add browser tests or lightweight interaction checks for real scan, quick-add, demo test, and care logging.
5. Expand recommendation tests for weather, pruning, watering, fertilizing, inspections, containers, indoor plants, and heat.
