// GameView.swift — UNVERIFIED. SwiftUI host: a SpriteView over a HUD overlay.
// Hazards handled here: H1 (the scene is built ONCE and held in @State — never in `body`/a computed
// var, which would reset the game on every state change) and H3 (persist best + pause on background).

import PipeBirdCore
import SpriteKit
import SwiftUI

struct GameView: View {
    @StateObject private var model = GameModel()
    @Environment(\.scenePhase) private var scenePhase

    /// Built exactly once (hazard H1). The scene's coordinate space == world space (see PHASE_B_SPEC §1.1).
    @State private var scene: GameScene = {
        let s = GameScene(size: CGSize(
            width: GameConfig.standard.width,
            height: GameConfig.standard.height
        ))
        s.scaleMode = .aspectFit
        s.anchorPoint = .zero
        return s
    }()

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            HUDView(model: model, scene: scene)
        }
        .onAppear { scene.model = model }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .inactive, .background:
                scene.isPaused = true
                model.persistNow() // H3: app may be killed in background
            case .active:
                scene.resumeAfterBackground() // H2: avoid a first-frame dt spike
                scene.isPaused = false
            @unknown default:
                break
            }
        }
    }
}

/// Pure presentation overlay — reads the model, sends intents to the scene/model. No gameplay logic.
private struct HUDView: View {
    @ObservedObject var model: GameModel
    let scene: GameScene

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("\(model.objectiveLabel): \(model.score)")
                        .font(.title2.bold())
                    Text("Best: \(model.best)").font(.subheadline)
                }
                .foregroundStyle(.white)
                .shadow(radius: 2)
                Spacer()
                VStack(spacing: 12) {
                    Button(action: model.toggleMute) {
                        Image(systemName: model.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    }
                    if FeatureFlags.evilModeEnabled {
                        Button(action: model.cycleMode) {
                            Image(systemName: model.mode == .evil ? "flame.fill" : "leaf.fill")
                        }
                    }
                }
                .font(.title2)
                .foregroundStyle(.white)
            }
            .padding()

            Spacer()

            switch model.status {
            case .ready:
                Text("Tap to start — drag to place the next gap")
                    .font(.headline).foregroundStyle(.white).shadow(radius: 2)
                    .padding(.bottom, 80)
            case .crashed:
                gameOverCard.padding(.bottom, 60)
            case .playing:
                EmptyView()
            }
        }
    }

    private var gameOverCard: some View {
        VStack(spacing: 12) {
            Text("Crashed").font(.largeTitle.bold())
            Text("\(model.objectiveLabel): \(model.score)   Best: \(model.best)")
            Text("Tap to play again").font(.subheadline).foregroundStyle(.secondary)
            if FeatureFlags.tipJarEnabled, !model.tipJar.products.isEmpty {
                TipJarButtons(tipJar: model.tipJar)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

#if canImport(StoreKit)
    import StoreKit

    private struct TipJarButtons: View {
        @ObservedObject var tipJar: TipJar
        var body: some View {
            HStack {
                ForEach(tipJar.products, id: \.id) { product in
                    Button(product.displayPrice) { Task { await tipJar.purchase(product) } }
                        .buttonStyle(.bordered)
                }
            }
        }
    }
#endif
