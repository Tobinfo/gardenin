# Decisions

This file records project choices so we do not keep reopening the same questions.

## 2026-05-19: Project Folder

Decision: `C:\dev\plant watering` is the source of truth for this project.

Reason: User explicitly selected this path and asked to ignore OneDrive.

## 2026-05-19: Demo Services First

Decision: Keep demo plant identification and demo weather while the product workflow is still being shaped.

Reason: The current architecture already separates identification and weather behind services, so real providers can be swapped in later without blocking workflow design.

## 2026-05-19: Browser Prototype Stays Useful

Decision: Keep the browser prototype as the fastest place to test the garden-walk workflow.

Reason: It can run on the laptop and exercise scan/review/save/care behavior faster than the full iOS build loop.

## 2026-05-19: Laptop First For Now

Decision: Treat the laptop/browser prototype as the primary build target until the workflow is proven.

Reason: The laptop prototype is faster to iterate, easier to verify on this Windows machine, and can answer the product questions before the workflow is ported to iOS.

## 2026-05-19: Local Plant ID Boundary

Decision: Browser scan flows call `/api/identify`; provider-specific identification code lives in the local server layer.

Reason: Real plant ID providers may require API keys and response normalization. Keeping that behind a local endpoint protects secrets and lets the UI work with one stable candidate shape.

## 2026-05-19: Scan Versus Add Plant

Decision: Scan mode should keep the camera live for walking around a garden. Add Plant should be the freeze-frame moment for reviewing, correcting, and saving.

Reason: Walking identification and plant record creation are different jobs. Freezing every scan makes garden walk mode feel broken.
