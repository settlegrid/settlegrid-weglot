# PHASE B–E — RENDER SHELL & META (just-in-time spec)

> **STATUS: UNVERIFIED.** Everything described here builds and runs only on **macOS + Xcode**
> (SwiftUI / SpriteKit / SpriteView / GameKit / StoreKit). It was written on Linux and has **never
> been compiled, run, or simulator-smoke-tested.** Treat all of `PipeBird/` as a scaffold to be
> compiled, fixed, and verified on a Mac. `PipeBirdCore` (Phase A) is the verified part; this is not.
>
> Authority order is unchanged: **SPEC.md wins.** This document only adds the shell/meta design that
> SPEC §10 deferred ("write the full Phase-B spec just-in-time at the A→B gate"). It folds in
> `PHASE_B_HAZARDS.md` (H1–H5) and `OPERATIONS_RUNBOOK.md` §6 (privacy sweep).

---

## 0. Cardinal rule for the shell
**No game logic in the shell.** Movement, collision, scoring, spawning, difficulty, RNG, and the state
machine all live in `PipeBirdCore`. The shell only: (a) computes `realDelta`, (b) reads the latest
touch as `targetGapY`, (c) calls `simulation.advance`, (d) positions nodes from `simulation.state`,
and (e) plays presentation for returned `GameEvent`s. If a code review finds an `if`/comparison in the
shell that decides gameplay, that is a BLOCKER — push it into the core.

---

## 1. Architecture (Phase B)

```
SwiftUI App (PipeBirdApp)
└─ GameView (SwiftUI)
   ├─ SpriteView(scene:)            // holds ONE GameScene instance (hazard H1)
   ├─ HUD overlay (SwiftUI)         // score, best, game-over card, mute, mode toggle, tip jar
   └─ observes GameModel            // ObservableObject mirror of score/status/mode/best (no logic)
GameScene (SpriteKit, the driver)
   ├─ owns: PipeBirdSimulation, lastUpdateTime, latest targetGapY
   ├─ update(_:) → realDelta → simulation.advance(realDelta:input:) → sync nodes → present events
   ├─ nodes: BirdNode, [PipeNode], floor, ghost-gap preview (render-only)
   └─ writes mirror values into GameModel each frame (score/status), persists best on crash
```

### 1.1 Coordinate mapping (SPEC §10)
The cleanest faithful mapping: **make the scene's coordinate space equal world space.**
- `scene.size = CGSize(width: config.width, height: config.height)` (400×700), `scene.anchorPoint = (0,0)`,
  `scene.scaleMode = .aspectFit`. SpriteKit then letterboxes to the device and **node positions are world
  positions directly** (`scale == 1`, `offset == 0` *inside* the scene).
- Touch → input: `targetGapY = touch.location(in: scene).y`. This is the §10 inverse map
  `(touchScreenY − offset)/scale` with the scene-space simplification. Y is up in both world and scene,
  so no flip. The engine clamps `targetGapY` authoritatively at spawn; the shell clamps only the
  render-only ghost preview.
- If you instead size the scene to the view and map manually, use `scale = sceneHeight / config.height`,
  `offsetX = (sceneWidth − config.width*scale)/2`, `worldToScreen(p) = (p.x*scale+offsetX, p.y*scale)`.
  The provided `GameScene` uses the scene-space approach; keep one mapping, not both.

### 1.2 Update loop (hazard H2)
```
func update(_ currentTime: TimeInterval) {
    if lastUpdateTime == 0 { lastUpdateTime = currentTime; return }   // seed; skip the spike frame
    let realDelta = currentTime - lastUpdateTime
    lastUpdateTime = currentTime
    let events = simulation.advance(realDelta: realDelta, input: Input(targetGapY: targetGapY))
    syncNodes(to: simulation.state)
    present(events)
    publishMirror()      // score/status into GameModel; persist best on first .crashed
}
```
Reset `lastUpdateTime = 0` on start and on returning from background so the first post-resume frame
isn't a giant `dt` (the core's `maxRealDelta` clamp also caps it, but reset anyway — H2).

### 1.3 Node sync (render-only)
- **Bird:** `bird.position = (config.birdX, state.birdY)`; rotate slightly from `state.birdVY` for feel.
- **Pipes:** keep a `[Int: PipeNode]` keyed by `Pipe.id`. For each `state.pipes`, create a node on first
  sight, move existing to `pipe.x`, remove nodes whose id is no longer present (culled by the core).
  Right edge = `pipe.x + config.pipeWidth` (computed, never stored — matches SPEC §3).
- **Ghost gap:** a translucent preview rectangle at the right edge centered on the **clamped**
  `targetGapY` (render-only; not authoritative).

### 1.4 Lifecycle / restart (SPEC §6.9, hazards H1/H3)
- Hold the scene **once** in `@StateObject`/stored property; never build it in `body` or a computed var (H1).
- `ready`: show "tap to start"; first tap → `simulation.start()`.
- `crashed`: show the game-over card; tap → `simulation.reset(); simulation.start()` ("tap to restart").
- `@Environment(\.scenePhase)`: on `.inactive`/`.background`, pause the scene **and persist best score
  immediately** (the app may be killed in the background — H3).

### 1.5 Event presentation (`GameEvent` → feel; Phase C)
- `.spawned(pipeID:)` → optional whoosh.
- `.pipePassed(score:)` → score pop + tick sound; update HUD/best.
- `.crashed(reason)` → shocked face, crash poof particle, thud, light haptic; freeze; show card.

---

## 2. Phase C — game feel (SHOULD)
Googly eyes that lag the bird's velocity; a shocked face on crash; a crash "poof" `SKEmitterNode`;
sound effects + a global mute (persisted); subtle haptics (`UIImpactFeedbackGenerator`). All driven by
state/events only. **Gate C:** still 60fps on device AND 120fps on ProMotion with equivalent cadence
(H5) — verify with Instruments; never bake in a 60fps assumption.

## 3. Phase D — meta (SHOULD/COULD), behind FeatureFlags
The core is **mode-agnostic** (SPEC §4.3, audit I4): `setMode(_:)` only flips a stored flag the shell
reads for objective text/metric. Implement:
- **Evil mode** (SHOULD): same simulation; UI relabels objective (e.g. "Betrayals" / time-to-crash).
- **Game Center** (COULD): authenticate, submit best score to a leaderboard.
- **StoreKit tip jar** (COULD): consumable/non-consumable tips.
All gated by `FeatureFlags` so the app runs with each flag **ON and OFF** (Gate D requirement). Default
flags OFF where the feature needs server/Apple setup, so a fresh checkout still launches.

## 4. Phase E — ship assets (MUST: icon + launch; privacy manifest)
- `Assets.xcassets` with a complete `AppIcon` set and `AccentColor` (placeholder colors checked in;
  **final icon art is human-only**).
- Launch screen via `UILaunchScreen` in Info.plist (no storyboard).
- Bundle `PrivacyInfo.xcprivacy` (declares `UserDefaults` reason `CA92.1`). Before submission run the
  OPERATIONS_RUNBOOK §6 Required-Reason-API sweep and have `ios-researcher` confirm current reason codes.
- Release build config; ad-free; no analytics/backend (SPEC §4.5 WON'T).

---

## 5. Build (on a Mac)
The Xcode project is defined declaratively with **XcodeGen** (`PipeBird/project.yml`) so it is reviewable
as code instead of a hand-written `.pbxproj`.
```
brew install xcodegen          # one-time
make project                   # cd PipeBird && xcodegen generate  → PipeBird.xcodeproj
make app                       # xcodebuild -scheme PipeBird -destination 'iOS Simulator,...' build
```
Then open in Xcode, run on a simulator, and work the Gate-B checklist.

## 6. GATE B — acceptance (binary; run on a Mac)
- [ ] `make project` then `make app` build clean (zero warnings target).
- [ ] App launches in the simulator; ready → tap → playing; bird follows the gap; pipes scroll/spawn;
      score increments; crash shows the card; tap restarts.
- [ ] **H1:** toggling any overlay/menu does NOT reset the game (scene held once).
- [ ] **H2:** background→foreground does NOT teleport the bird (lastUpdateTime reset).
- [ ] **H3:** best score survives a background-kill (persisted on `.background`).
- [ ] **H4:** touch maps to gap placement; no gameplay decision in the shell (review).
- [ ] **H5:** 60fps and 120fps produce equivalent score/pipe cadence.
- [ ] `spec-auditor`: shell holds no logic that belongs in the core. `hostile-reviewer`: no BLOCKER/MAJOR.
- [ ] PROGRESS.md updated; checkpoint committed.

> Re-confirm every Apple API used here with the `ios-researcher` subagent at implementation time —
> signatures and requirements drift between iOS/Xcode versions, and this scaffold was written without a
> toolchain to check against.
