// AudioEngine.swift — UNVERIFIED. Tiny sound layer with a persisted global mute. Sound files are
// human-supplied assets: drop whoosh.wav / point.wav / thud.wav into the app bundle. If a file is
// missing the engine no-ops (never crashes). UserDefaults use is declared in PrivacyInfo.xcprivacy.

import AVFoundation
import Foundation

final class AudioEngine {
    static let shared = AudioEngine()

    enum Sound: String, CaseIterable { case whoosh, point, thud }

    private var players: [Sound: AVAudioPlayer] = [:]
    private let mutedKey = "pipebird.muted"

    var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: mutedKey) }
        set { UserDefaults.standard.set(newValue, forKey: mutedKey) }
    }

    private init() {
        guard FeatureFlags.audioEnabled else { return }
        for sound in Sound.allCases {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else {
                continue // asset not added yet → silent, not a crash
            }
            let player = try? AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            players[sound] = player
        }
    }

    func play(_ sound: Sound) {
        guard FeatureFlags.audioEnabled, !isMuted, let player = players[sound] else { return }
        player.currentTime = 0
        player.play()
    }
}
