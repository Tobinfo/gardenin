# Mobile Integration Plan

## Goal

Keep the browser prototype moving quickly while making sure every major workflow can become a native Android and iOS app without redesigning the product.

## Product Surfaces To Preserve

The mobile apps should support the same product modes as the browser prototype:

- Garden scan: identify or recognize a plant that belongs in the user's garden.
- Add plant: freeze, confirm, name, save, and start care tracking.
- Known plant sighting: recognize an existing saved plant, flash, and log an observation.
- Training photos: capture guided crop photos for future recognition.
- ID only: identify a non-garden plant without adding care tracking.
- Personal ID gallery: optional saved ID-only crop photos.
- Care dashboard: watering, fertilizing, pruning, inspection, weather context, and history.

## Shared Architecture Target

Use the browser prototype to prove behavior, but keep the logic portable:

- Shared server API for external providers: plant ID, weather, future care enrichment.
- Shared hosted database/object storage for plants, crop photos, care logs, ID-only gallery photos, weather snapshots, and recognition events.
- Shared data model names across web, Android, and iOS.
- Platform-specific camera, permissions, local storage/cache, and native UI.

## Mobile Permission Mapping

Camera:

- Required for scan, add plant, training photos, and ID-only.
- Always capture plant-box crops by default.
- Full-frame preview can be temporary, but durable storage should remain crop-only unless explicitly changed later.

Photos/media:

- Not required for the default camera flow.
- Add later for importing existing photos.

Location:

- Optional and scoped.
- Garden weather should prefer ZIP/manual location first.
- ID-only can request one-time device location and save rounded coordinates only if the user saves the ID-only photo.
- No reverse geocoding by default.

Notifications:

- Add later for watering/care reminders.

## Android Notes

Likely native pieces:

- CameraX for camera preview/capture.
- Runtime permissions for camera and optional location.
- Local cache via Room or platform storage.
- Background reminders through WorkManager/notifications later.
- API calls through a small repository layer matching the server endpoints.

## iOS Notes

Likely native pieces:

- AVFoundation or PhotosUI/camera capture depending on workflow.
- Core Location only for explicit one-time location requests.
- Local cache via SwiftData/Core Data or simple file-backed storage until hosted sync is ready.
- Local notifications for reminders later.
- Existing SwiftUI scaffold should follow the browser workflow after it stabilizes.

## API Boundaries Needed Before Serious Mobile Work

Do not let mobile clients hold provider secrets. Mobile apps should call gardenin server endpoints:

- `POST /api/identify`
- `GET /api/weather?zip=#####`
- `GET /api/mobile-contract`
- Future `POST /api/plants`
- Future `POST /api/photos`
- Future `POST /api/care-logs`
- Future `POST /api/recognition-events`
- Future `GET /api/sync`

The detailed shared data contract is tracked in `docs/API_CONTRACT.md`. The server also exposes a machine-readable summary at `GET /api/mobile-contract` so native clients can verify the contract version they are targeting.

## Mobile Readiness Rules For Browser Work

When adding browser features, keep these constraints in mind:

- Avoid browser-only data shapes.
- Keep user-visible modes explicit: garden tracking versus ID-only.
- Keep permissions scoped and optional where possible.
- Keep photo records crop-first.
- Avoid provider calls unless the workflow really needs them.
- Keep local-only features ready to move behind hosted sync.

## First Native Milestone

Do not port everything at once. The first mobile milestone should be:

1. Camera preview with plant-box crop.
2. ID-only flow with three photos and best-photo selection.
3. Server-backed Pl@ntNet identification.
4. Optional save to personal ID gallery.
5. No garden tracking yet.

This gives a small Android/iOS proof while the deeper garden-care model keeps evolving in the browser.
