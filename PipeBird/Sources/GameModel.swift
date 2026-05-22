// GameModel.swift — UNVERIFIED. UI-facing mirror of the simulation + meta (persistence, Game Center,
// tip jar). Holds NO gameplay logic: GameScene is the authoritative driver and pushes status/score
// here each frame. This object only mirrors, persists the best score, and surfaces meta state.

import PipeBirdCore
import SwiftUI

@MainActor
final class GameModel: ObservableObject {
    @Published var status: Status = .ready
    @Published var score: Int = 0
    @Published var best: Int = 0
    @Published var mode: Mode = .good
    @Published var muted: Bool = false

    private let highScores = HighScoreStore()
    let gameCenter = GameCenterManager()
    let tipJar = TipJar()

    init() {
        best = highScores.best
        muted = AudioEngine.shared.isMuted
        if FeatureFlags.gameCenterEnabled { gameCenter.authenticate() }
        if FeatureFlags.tipJarEnabled { Task { await tipJar.load() } }
    }

    /// Pushed by GameScene every frame. Pure mirror + best-score persistence — no gameplay decisions.
    func apply(status: Status, score: Int) {
        if status != self.status { self.status = status }
        if score != self.score { self.score = score }
        if score > best {
            best = score
            highScores.best = score
            if FeatureFlags.gameCenterEnabled { gameCenter.submit(best: score) }
        }
    }

    /// Defensive immediate persist on background (hazard H3); best is also saved the moment it improves.
    func persistNow() {
        highScores.best = best
    }

    func toggleMute() {
        muted.toggle()
        AudioEngine.shared.isMuted = muted
    }

    /// Evil mode is pure relabelling over the same simulation (SPEC §4.3). GameScene reads `mode` each
    /// frame and forwards it to `simulation.setMode`; no behavior change in the core.
    func cycleMode() {
        guard FeatureFlags.evilModeEnabled else { return }
        mode = (mode == .good) ? .evil : .good
    }

    var objectiveLabel: String {
        mode == .evil ? "Betrayals" : "Score"
    }
}
