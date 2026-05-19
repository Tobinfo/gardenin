# Workflow

## Source Of Truth

Work from:

`C:\dev\plant watering`

Ignore OneDrive for this project unless the user explicitly says otherwise.

## Before Making Changes

1. Read `PROJECT_CONTEXT.md`.
2. Read `docs/NEXT_STEPS.md`.
3. Check `docs/DECISIONS.md` for past choices.
4. Inspect the files directly related to the change.

## After Meaningful Changes

Update docs when needed:

- `PROJECT_CONTEXT.md` if the product, architecture, or constraints changed.
- `docs/NEXT_STEPS.md` if priorities or handoff notes changed.
- `docs/DECISIONS.md` if a major choice was made.

## Local Prototype

The easiest way to start the browser prototype on this machine is to double-click:

```txt
Start GardenSnap Prototype.cmd
```

That launcher clears the old local server on port 5173, opens the browser, and starts the app.

The command-line fallback is:

```sh
npm.cmd start
```

Then open:

```txt
http://localhost:5173
```

## Checks

Use the existing package check when changing JavaScript:

```sh
npm.cmd run check
```

## Real Plant ID

The default provider is still demo mode. To test Pl@ntNet after getting an API key, start the prototype with:

```powershell
$env:PLANT_ID_PROVIDER="plantnet"
$env:PLANTNET_API_KEY="your-api-key"
npm.cmd start
```

Keep that PowerShell window open while testing.
