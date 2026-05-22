# PHASE B — SILENT HAZARDS (fold into the just-in-time Phase-B spec)
*The render shell holds no game logic, so its bugs are mostly loud — except these, which are silent and well-documented. Pre-recording them so they don't get rediscovered the hard way.*

## H1 — The scene MUST be a stably-held instance, never a computed property
If the `SKScene` is created in a computed property (or rebuilt inside `body`), SwiftUI **re-evaluates it on every state change and recreates the scene**, resetting all game state (score, bird position, timers) to zero. With our ready/playing/crashed overlays toggling state constantly, this *will* manifest as "the game resets when a menu appears."
- **Fix:** hold the scene once in `@State`/`@StateObject` and pass the same instance to `SpriteView`. Build it exactly once.

## H2 — Reset `lastUpdateTime` on resume to avoid a delta-time spike
SpriteKit gives no delta time; you compute `dt = currentTime - lastUpdateTime`. After a pause/background or scene start, `currentTime` jumps, producing a huge first-frame `dt` → the bird teleports.
- **Fix:** reset `lastUpdateTime` to 0 (re-seed on the next frame) on start and on resume. Our core's `maxRealDelta` clamp already caps the damage, but still reset so the first post-resume frame isn't garbage.

## H3 — Pause and persist on background (scenePhase)
- Use `@Environment(\.scenePhase)`; on `.background`/`.inactive`, pause the scene and **persist the high score immediately** (don't wait for a clean exit — the app can be killed in the background, and an unsaved high score is lost). High-score persistence uses `UserDefaults` → see `PrivacyInfo.xcprivacy`.

## H4 — Touch → input mapping, render-only
- Map touch Y to world Y once: `targetGapY = (touchScreenY - offset) / scale` (the inverse of the §10 world→screen map). Clamp only for the render-only "ghost gap" preview; the engine clamps authoritatively at spawn. No gameplay decision lives in the shell.

## H5 — ProMotion / variable refresh
- Do not assume 60fps. The core is dt-based with a fixed sub-step, so 120Hz is handled — but verify with a 120Hz device/simulator that score/pipe cadence matches a 60Hz run (the `FrameRateIndependenceTests` property, observed on-device).

**Gate-B checklist additions:** menu/overlay toggles do NOT reset the game (H1); background→foreground doesn't teleport the bird (H2); high score survives a background-kill (H3); 60fps and 120Hz produce equivalent play (H5).
