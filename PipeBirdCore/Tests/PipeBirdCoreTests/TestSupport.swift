// TestSupport.swift
// PipeBirdCoreTests — shared fixtures + drivers. Agent-written test files USE these so every test
// constructs state the same way the pre-written reference tests do. (The reference tests keep their
// own `private` helpers and are self-contained; `Fixtures` is namespaced to avoid any collision.)

import XCTest
@testable import PipeBirdCore

enum Fixtures {

    // MARK: configs & rng
    static func config() -> GameConfig { .standard }
    static func freshRNG(_ c: GameConfig = .standard) -> DeterministicRNG { DeterministicRNG(seed: c.seed) }

    // MARK: states
    static func ready(_ c: GameConfig = .standard) -> GameState { .initial(config: c) }

    static func playing(birdY: Double? = nil,
                        pipes: [Pipe] = [],
                        _ c: GameConfig = .standard) -> GameState {
        var s = GameState.initial(config: c)
        s.status = .playing
        s.birdY = birdY ?? c.height / 2
        s.pipes = pipes
        return s
    }

    static func pipe(id: Int = 0,
                     x: Double,
                     gapCenterY: Double,
                     gapHeight: Double = 220,
                     scored: Bool = false) -> Pipe {
        Pipe(id: id, x: x, gapCenterY: gapCenterY, gapHeight: gapHeight, scored: scored)
    }

    /// A .playing state with a single pipe horizontally centered on the bird (full overlap).
    static func straddlingPipeState(birdY: Double,
                                    gapCenterY: Double = 350,
                                    gapHeight: Double = 220,
                                    _ c: GameConfig = .standard) -> GameState {
        playing(birdY: birdY,
                pipes: [pipe(x: c.birdX - c.pipeWidth / 2, gapCenterY: gapCenterY, gapHeight: gapHeight)],
                c)
    }

    // MARK: drivers
    /// Run `PipeBirdEngine.step` `count` times from `state`, threading ONE rng. Returns final state + all events.
    static func steps(_ count: Int,
                      from state: GameState,
                      config c: GameConfig = .standard,
                      input: (Int) -> Input,
                      rng: inout DeterministicRNG) -> (GameState, [GameEvent]) {
        var s = state
        var events: [GameEvent] = []
        for i in 0..<count {
            let (next, evs) = PipeBirdEngine.step(state: s, config: c, input: input(i), rng: &rng)
            s = next
            events.append(contentsOf: evs)
        }
        return (s, events)
    }

    /// Drive a simulation `frames` times at a fixed realDelta. Returns all events.
    @discardableResult
    static func drive(_ sim: inout PipeBirdSimulation,
                      frames: Int,
                      realDelta: Double = 1.0 / 60.0,
                      input: (Int) -> Input) -> [GameEvent] {
        var events: [GameEvent] = []
        for i in 0..<frames { events.append(contentsOf: sim.advance(realDelta: realDelta, input: input(i))) }
        return events
    }

    /// A stable, trig-free input schedule reused across tests.
    static func varyingInput(at step: Int) -> Input {
        let ys: [Double] = [350, 250, 480, 180, 520, 300, 420, 360]
        return Input(targetGapY: ys[step % ys.count])
    }
}
