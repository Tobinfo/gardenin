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

## Free/dev API key mode

For a free or development deployment, gardenin can require each user to bring their own Pl@ntNet API key instead of spending a shared hosted key.

Render environment variables:

- `PLANT_ID_PROVIDER=plantnet`
- `REQUIRE_USER_PLANTNET_API_KEY=true`
- Optional: leave `PLANTNET_API_KEY` unset if every user must provide their own key.
- Optional: `IDENTIFY_RATE_LIMIT=24` for shared-key requests.
- Optional: `IDENTIFY_USER_KEY_RATE_LIMIT=60` for user-key requests.

In this mode the browser Data panel accepts a personal Pl@ntNet key. The key is stored only in that browser, sent with plant ID requests, and excluded from local exports.

The user-facing walkthrough is in `docs/FREE_PLANTNET_KEY.md`.
