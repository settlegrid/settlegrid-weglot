// FeatureFlags.swift — UNVERIFIED (compiles only on macOS+Xcode as part of the PipeBird app).
// Gate-D requires the app to run with each flag ON and OFF. Features needing Apple/server setup
// default OFF so a fresh checkout still launches; the human enables them after signing/ASC setup.

import Foundation

enum FeatureFlags {
    /// Evil mode is pure UI relabelling over the same simulation (SPEC §4.3, mode-agnostic core).
    static let evilModeEnabled = true

    /// Game Center needs an Apple Developer team + a leaderboard configured in App Store Connect.
    static let gameCenterEnabled = false

    /// StoreKit tip jar needs products configured in App Store Connect.
    static let tipJarEnabled = false

    /// Sound + haptics on by default; user can mute (persisted).
    static let audioEnabled = true
    static let hapticsEnabled = true
}
