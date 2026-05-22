# PIPE BIRD — CANONICAL SPEC
### Single source of truth for `PipeBirdCore` (Phase A) and the game design.
**Status:** authoritative. Supersedes Build-Playbook §2 and the standalone Phase-A spec for any conflict. The `spec-auditor` diffs implementation against THIS file only. Reconciled by the consistency audit (`CONSISTENCY_AUDIT.md`) and the implementability sweep (`IMPLEMENTABILITY_AUDIT.md`, findings I1–I8 folded in below).

---

## 1. PRODUCT & CORE THESIS
Pipe Bird is Flappy Bird inverted: a trusting autonomous bird flaps forward on autopilot; **you control the gap.** You drag to place the gap of the *next* pipe; the bird, lagging, steers toward whatever gap you've given it. Survive (Good mode) — or betray it (Evil mode).

**Loseability mechanism (load-bearing):** the bird is an **underdamped spring** follower, not a perfect tracker. It overshoots and wobbles. As speed rises and gaps narrow, less settle-time remains between pipes, so a clip becomes inevitable — that is what makes it a score chase. A perfect tracker would be un-killable at steady input.

---

## 2. INVARIANTS (non-negotiable; also the hostile-reviewer's seed checklist)
1. `PipeBirdCore` imports **zero** Apple-UI frameworks (no SpriteKit/UIKit/SwiftUI) and **no Foundation** in `Sources/`. Stdlib only (`min`/`max`/`abs`/`.squareRoot()` on `Double`).
2. **All** movement, collision, scoring, spawning, difficulty, and randomness live in the core. The render shell holds none of it.
3. **No `SKPhysicsBody` for gameplay.** The core owns collision.
4. Physics integration is **dt-based** and uses a **fixed sub-step** (`fixedDt`); the result is frame-rate independent.
5. **All randomness routes through `DeterministicRNG`** (seeded, reproducible). `SystemRandomNumberGenerator` is forbidden.
6. The simulation is **deterministic**: same `(config, seed, input sequence, fixed dt)` → bit-identical state and events on a given platform/toolchain.
7. No force-unwraps (`!`) or unchecked array indexing in the per-frame hot path.

---

## 3. COORDINATE CONVENTIONS
- **World units**, resolution-independent. Origin **bottom-left, Y-up** (matches SpriteKit; the shell maps with one scale factor).
- Floor = `y = 0`; ceiling = `y = height`.
- Bird is a circle, center `(birdX, birdY)`, radius `birdRadius`; pinned at `x = birdX`. Only `birdY`/`birdVY` change.
- Pipe `x` = **left edge**, decreasing over time. The right edge is `x + pipeWidth` (computed in the engine; **not** stored on `Pipe`).
- Gap: `gapTop = gapCenterY + gapHeight/2`; `gapBottom = gapCenterY − gapHeight/2`. Solid regions: bottom rect `y ∈ [0, gapBottom]`, top rect `y ∈ [gapTop, height]`, both across `x ∈ [pipe.x, pipe.x + pipeWidth]`.
- **Collision is inclusive:** contact at distance `== radius` counts as a crash.

---

## 4. GAME DESIGN
### 4.1 Mechanic
- World scrolls left at `scrollSpeed(score)`. Pipes spawn at the right edge (`x = width`) every `pipeSpacing` world-units of scroll.
- Player input is a single value `targetGapY` — the desired gap center for the **next pipe to spawn**. At spawn the gap **locks** (`gapCenterY = clamp(targetGapY, gapHeight/2, height − gapHeight/2)`, `gapHeight = gapHeight(score)`), immutable thereafter.
- The bird's steering target = the gap center of the **nearest active pipe** (smallest `x` with `rightEdge > birdX − birdRadius`); if none, `height/2`.
- Bird dynamics — underdamped spring, semi-implicit (symplectic) Euler:
  ```
  a       = stiffness*(target − birdY) − damping*birdVY
  birdVY  = clamp(birdVY + a*dt, −maxBirdSpeed, +maxBirdSpeed)
  birdY   = birdY + birdVY*dt          // never clamp birdY; out-of-bounds = crash
  ```

### 4.2 Collision & failure
`collision(state, config)` returns the first solid contact, checked in order: **floor** (`birdY − birdRadius ≤ 0`), **ceiling** (`birdY + birdRadius ≥ height`), then **iterate all pipes** with the circle-vs-rectangle nearest-point distance test (`distance(center, rect) ≤ birdRadius`) against each pipe's top and bottom rect. First hit wins → `.crashed(reason)`; `.crashed` is terminal until `reset()`.

### 4.3 Scoring & modes
- **Good mode (default):** a pipe scores **once** when it has fully cleared the bird: `rightEdge ≤ birdX − birdRadius` and `!scored` → `scored = true`, `score += 1`, emit `.pipePassed(score:)`.
- **Evil mode (SHOULD, post-MUST):** identical simulation; only the objective text + score interpretation differ (e.g. "Betrayals" / time-to-crash). The **core is mode-agnostic** (audit I4): `step()` never branches on `mode` and always scores +1 per cleared pipe. `mode` is a stored flag the shell reads to choose objective text and which metric to surface. No core behavior change.
- High score persistence + Game Center: shell/meta concern, not core.

### 4.4 Difficulty (pure, clamped, overflow-safe)
```
scrollSpeed(score) = min(maxScrollSpeed, baseScrollSpeed + scrollSpeedPerScore * Double(score))
gapHeight(score)   = max(minGapHeight,   baseGapHeight   − gapShrinkPerScore   * Double(score))
```
Non-decreasing / non-increasing respectively; clamped; finite at extreme score.

### 4.5 Game feel (SHOULD) / MoSCoW
- **MUST:** core + tests green; render shell; Good mode; collision; restart loop; local high score; 60fps; ad-free.
- **SHOULD:** googly eyes / shocked face / crash poof; Evil mode; sound + mute; app icon + launch screen; privacy manifest.
- **COULD:** Game Center; StoreKit tip jar; haptics; daily seed.
- **WON'T (this session):** multiplayer, ads, accounts, analytics, any backend.
- **Rule:** if context tightens, finish MUST to a green ship audit and stop; never half-build COULD.

---

## 5. TUNING CONSTANTS — SINGLE SOURCE (`GameConfig.standard`)
| Field | Default | Unit | Note |
|---|---|---|---|
| `width` | 400 | u | playfield width |
| `height` | 700 | u | playfield height |
| `birdX` | 120 | u | ≈0.30·width |
| `birdRadius` | 14 | u | |
| `pipeWidth` | 60 | u | |
| `pipeSpacing` | 240 | u | scroll-distance between spawns |
| `baseGapHeight` | 220 | u | |
| `minGapHeight` | 120 | u | floor of gap shrink |
| `gapShrinkPerScore` | 2.0 | u/pt | |
| `baseScrollSpeed` | 140 | u/s | |
| `scrollSpeedPerScore` | 4.0 | u/s/pt | |
| `maxScrollSpeed` | 360 | u/s | cap |
| `stiffness` | 28.0 | 1/s² | spring k |
| `damping` | 6.0 | 1/s | ζ = 6/(2√28) ≈ **0.57** (underdamped) |
| `maxBirdSpeed` | 520 | u/s | velocity clamp |
| `fixedDt` | 1/120 | s | physics sub-step |
| `maxRealDelta` | 0.25 | s | anti spiral-of-death clamp |
| `seed` | `0xA5A5_5A5A_C0DE_F00D` | u64 | default PRNG seed |

All values tunable; feel finalized in Phase C. Phase A and the golden trace use these defaults verbatim.

---

## 6. PUBLIC API (implement exactly)

### 6.1 `Vec2` — OPTIONAL
Currently unused by the engine (bird state is scalar). Include only if the shell wants it; otherwise omit. Do not expose unused public surface.

### 6.2 `DeterministicRNG` — SplitMix64
```swift
public struct DeterministicRNG: RandomNumberGenerator {
    public init(seed: UInt64)
    public mutating func next() -> UInt64                       // SplitMix64
    public mutating func nextDouble(in range: ClosedRange<Double>) -> Double  // deterministic: top 53 bits of next() → [0,1) → scale into range
}
```

### 6.3 `GameConfig`
```swift
public struct GameConfig: Equatable {
    public var width, height, birdX, birdRadius: Double
    public var pipeWidth, pipeSpacing, baseGapHeight, minGapHeight, gapShrinkPerScore: Double
    public var baseScrollSpeed, scrollSpeedPerScore, maxScrollSpeed: Double
    public var stiffness, damping, maxBirdSpeed: Double
    public var fixedDt, maxRealDelta: Double
    public var seed: UInt64
    public init(/* all params defaulted to the §5 table */)
    public static let standard: GameConfig
}
```

### 6.4 `Difficulty`
```swift
public enum Difficulty {
    public static func scrollSpeed(score: Int, config: GameConfig) -> Double
    public static func gapHeight(score: Int, config: GameConfig) -> Double
}
```

### 6.5 `Pipe` — pure data (no `rightEdge` property; edges computed in engine)
```swift
public struct Pipe: Equatable, Identifiable {
    public let id: Int
    public var x: Double            // left edge (decreasing)
    public var gapCenterY: Double   // locked at spawn
    public var gapHeight: Double    // locked at spawn
    public var scored: Bool
    public init(id: Int, x: Double, gapCenterY: Double, gapHeight: Double, scored: Bool)
}
```

### 6.6 `Model`
```swift
public enum Status: Equatable { case ready, playing, crashed }
public enum Mode: Equatable { case good, evil }
public enum CrashReason: Equatable { case pipeBody, floor, ceiling }
public enum GameEvent: Equatable {
    case spawned(pipeID: Int)
    case pipePassed(score: Int)
    case crashed(CrashReason)
}
// audit I1: lifecycle transitions (start/reset) are CALLER-initiated — the shell already knows it
// called start()/reset(), so they need no events. The event stream carries ONLY simulation-emergent
// outcomes the caller cannot otherwise observe. (.started/.reset removed.)
public struct Input: Equatable {
    public var targetGapY: Double
    public init(targetGapY: Double)
}
```

### 6.7 `GameState` — all fields publicly settable (tests construct states directly)
```swift
public struct GameState: Equatable {
    public var status: Status
    public var mode: Mode
    public var birdY: Double
    public var birdVY: Double
    public var pipes: [Pipe]
    public var score: Int
    public var elapsed: Double
    public var spawnAccumulator: Double
    public var nextPipeID: Int
    public static func initial(config: GameConfig) -> GameState
    // audit I5 — initial = { status: .ready, mode: .good, birdY: height/2, birdVY: 0,
    //   pipes: [], score: 0, elapsed: 0, spawnAccumulator: 0, nextPipeID: 0 }
}
```

### 6.8 `PipeBirdEngine`
```swift
public enum PipeBirdEngine {
    public static func step(state: GameState, config: GameConfig,
                            input: Input, rng: inout DeterministicRNG) -> (GameState, [GameEvent])
    public static func birdTargetY(state: GameState, config: GameConfig) -> Double
    public static func collision(state: GameState, config: GameConfig) -> CrashReason?
    // Edge helper computed here (NOT on Pipe): rightEdge = pipe.x + config.pipeWidth
    // audit I2: in MUST scope the simulation is fully player-deterministic and step() does NOT
    // consume rng (gaps lock to player input, not randomness). The rng param is RESERVED for future
    // seeded variation and keeps the determinism harness uniform — keep it threaded; do NOT invent
    // randomness to "use" it.
}
```

### 6.9 `PipeBirdSimulation` — the driver the shell calls
```swift
public struct PipeBirdSimulation {
    public private(set) var state: GameState
    public let config: GameConfig
    public init(config: GameConfig = .standard)
    public mutating func start()    // ONLY .ready → .playing; no-op from other states (call reset() first)
    public mutating func reset()    // → initial(config) (status .ready); clear accumulator; re-seed rng to config.seed
    public mutating func setMode(_ mode: Mode)   // stored flag only; does not affect the simulation
    public mutating func advance(realDelta: Double, input: Input) -> [GameEvent]
    // private: rng: DeterministicRNG, timeAccumulator: Double
}
```

**Lifecycle (audit I3/I7):** canonical flow is `ready --start()--> playing --(crash)--> crashed --reset()--> ready`. `reset()` always returns to `.ready` (it does **not** auto-play); the shell's "tap to restart" calls `reset()` then `start()`. `advance()` always clamps `realDelta` to `maxRealDelta`, accumulates, and runs `floor(acc/fixedDt)` fixed steps regardless of status; outside `.playing` those steps are inert (a safe no-op), and the accumulator stays bounded (`< fixedDt` remainder carried per call). No lifecycle events are emitted (see §6.6).

---

## 7. `step()` — CANONICAL ORDER (the literal contract; spec-auditor checks this exact sequence)
1. If `status != .playing` → return `(state, [])` unchanged. *(`.ready` and `.crashed` are inert to `step`.)*
2. `elapsed += dt`.
3. Scroll: every pipe `x -= scrollSpeed*dt`; `spawnAccumulator += scrollSpeed*dt`.
4. Spawn (use `while`, not `if`): while `spawnAccumulator >= pipeSpacing` → append `Pipe(id: nextPipeID, x: width, gapCenterY: clamp(input.targetGapY, gh/2, height−gh/2), gapHeight: gh, scored: false)` where `gh = Difficulty.gapHeight(score, config)`; `nextPipeID += 1`; emit `.spawned(pipeID:)`; `spawnAccumulator -= pipeSpacing`.
5. Integrate bird (§4.1) toward `birdTargetY`.
6. Score: for each pipe with `!scored && (pipe.x + pipeWidth) <= birdX − birdRadius` → `scored = true`, `score += 1`, emit `.pipePassed(score:)`. *(Boundary unified at `birdX − birdRadius` so a pipe cannot both score and crash the bird in the same step — see audit F3.)*
7. Collision (§4.2): if hit → `status = .crashed`, emit `.crashed(reason)`, return (skip culling this step is fine; culling is cosmetic).
8. Cull: remove pipes with `pipe.x + pipeWidth < 0`.

`scrollSpeed` and `gapHeight` are evaluated from the **current** `score` at the moment they're used.

*First-pipe timing (audit I6):* `spawnAccumulator` starts at 0, so the first pipe spawns after the world has scrolled one full `pipeSpacing`; the bird targets `height/2` during this brief opening runway. This is **intentional**, not a bug. (To start with a pipe sooner, seed `spawnAccumulator` in `initial` — not required for MUST.)

---

## 8. TEST CONTRACT
Full list lives here; four files are **pre-written** and must pass unchanged; the rest are agent-written to the same bar (header: property + trap + auditor-oracle note; discrete-exact vs continuous-tolerant discipline; one rng threaded per run; hand-built states for unit isolation; shared builders in `TestSupport.swift`).

**Pre-written (drop-in):** `DeterminismTests`, `CollisionBoundaryTests` (incl. the corner case), `FrameRateIndependenceTests`, `GoldenTraceTests` (record-then-freeze).
> Note (audit F7): `FrameRateIndependenceTests.testEngineStep_dtScaling_isConsistent` is intentionally weak as shipped and **must be strengthened** during Phase A into a real direct-stepping comparison (or removed in favor of a stronger engine-level dt test).

**Agent-written:** `RNGTests`, `SpawningTests`, `ScoringTests`, `DifficultyTests`, `StateMachineTests`, `EventTests`, `RobustnessTests` — covering: rng reproducibility & range; spawn cadence + remainder carry + locked-gap value; score-once + monotonic + no-score-while-crashed; difficulty monotonic/clamped/overflow-safe; ready-inert / start / crashed-terminal / reset-reproduces; event correctness (one crash, monotonic ids, elapsed only while playing); 10-min finiteness + bounded pipes array (`count ≤ ceil(width/pipeSpacing)+2`).

**Golden record step (once, after the rest are green):** set `recordMode=true`, run, paste fixture, set `recordMode=false`, commit. Log in `PROGRESS.md`.

---

## 9. GATE A — ACCEPTANCE (binary)
- [ ] `swift build` clean (zero warnings target).
- [ ] `swift test` green — all §8 tests present and passing; fresh log pasted by `test-runner`; `GoldenTraceTests` frozen (non-empty fixture, `recordMode=false`).
- [ ] `spec-auditor`: zero drift vs this file (signatures, §7 order, §3 conventions, invariants).
- [ ] `hostile-reviewer`: no open BLOCKER/MAJOR.
- [ ] Invariants §2 all hold (no Foundation/SpriteKit import; no SKPhysicsBody; rng seeded; dt-based).
- [ ] `PROGRESS.md` updated; git checkpoint committed.

---

## 10. PHASE B FORWARD-NOTES (write the full Phase-B spec just-in-time at the A→B gate)
Shell maps world→screen via `scale = screenHeight / height` (+offset); positions bird/pipes/floor `SKNode`s from `state` each frame; `GameScene.update` computes `realDelta`, builds `Input` from touch, calls `simulation.advance`, syncs nodes, plays event presentation. **No logic in the shell.** Touch→`targetGapY = (touchScreenY − offset)/scale`. Render-only "ghost gap" preview at `targetGapY` on the right edge.

---

## 11. OPEN TUNING QUESTIONS (honest; resolve on-device in Phase C, not now)
- `minGapHeight` (120) vs `2·birdRadius` (28): sets late-game punishment. Likely fine; confirm it doesn't feel impossible once speed caps.
- `maxBirdSpeed` (520) vs worst-case required traverse (~full height in `pipeSpacing/maxScrollSpeed ≈ 0.67s`): the bird intentionally *cannot* cross the whole playfield between adjacent pipes at max speed — this is the "unreachable gap" challenge, not a bug. Confirm it reads as fair, since the player authors the gaps.
- Spring `ζ ≈ 0.57`: enough wobble to be loseable, not nauseating. Tune `damping` relative to `2√stiffness` for feel.
