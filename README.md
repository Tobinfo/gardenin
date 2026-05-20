# gardenin

gardenin is a laptop-first plant identification and care-tracking prototype, with an iOS SwiftUI scaffold kept as the later native target.

The app is designed around a quick garden walk: start the camera, frame one plant, identify it, confirm or correct the result, and save plant-specific care context.

## What is included

- Browser-based laptop prototype in `prototype/`.
- Local Node server in `scripts/serve-prototype.js`.
- Server-side plant ID boundary in `scripts/plant-id-provider.js`.
- Pl@ntNet provider path using server-side environment variables.
- Perenual plant data lookup path using server-side environment variables.
- Individual plant records with suggested names.
- Care logs for watering, fertilizing, pruning, and inspections.
- Weather-aware care recommendation logic.
- SwiftUI iOS scaffold in `GardenSnap/`.
- Unit tests for recommendation and naming logic.
- Render deployment config in `render.yaml`.

## Run locally

On this Windows machine, double-click:

```txt
Start GardenSnap Prototype.cmd
```

Then open:

```txt
http://127.0.0.1:5173
```

## Hosted deployment

Deploy as a Node web service. The repo includes `render.yaml` for Render.

Set these environment variables on the host:

```txt
PLANT_ID_PROVIDER=plantnet
PLANTNET_PROJECT=all
PLANTNET_API_KEY=<your Pl@ntNet key>
PERENUAL_API_KEY=<your Perenual key>
```

Do not commit `.env`; it is for local use only.

Perenual lookup test endpoint:

```txt
/api/perenual/search?q=hosta
```

## Checks

```sh
npm run check
```
