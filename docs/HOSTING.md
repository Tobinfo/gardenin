# Hosting

GardenSnap needs a hosted Node web service because plant ID keys must stay server-side.

## Render

This repo includes `render.yaml` for Render.

Human steps:

1. Push this project to GitHub.
2. In Render, create a new Blueprint from the repo.
3. Add `PLANTNET_API_KEY` when Render asks for environment variables.
4. Deploy.

The hosted app will use `npm start`, which runs `scripts/serve-prototype.js`.

The local `.env` file is ignored by Git and should not be committed.
