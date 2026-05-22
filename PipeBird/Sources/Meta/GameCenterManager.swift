// GameCenterManager.swift — UNVERIFIED (Phase D / COULD). Game Center auth + best-score submission.
// Requires an Apple Developer team and a leaderboard configured in App Store Connect (human-only);
// gated by FeatureFlags.gameCenterEnabled (default OFF) so the app still launches without setup.
//
// TODO: (Mac): the authenticate handler hands back a sign-in view controller to PRESENT when the player
// isn't signed in. Present it from the active window scene's root VC (omitted here — needs a live UI).

#if canImport(GameKit)
    import GameKit

    final class GameCenterManager {
        /// Configure this exact ID as a leaderboard in App Store Connect.
        static let leaderboardID = "ai.settlegrid.pipebird.best"

        private(set) var isAuthenticated = false

        func authenticate() {
            GKLocalPlayer.local.authenticateHandler = { [weak self] _, error in
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                if let error { print("Game Center auth error: \(error.localizedDescription)") }
                // If `viewController` (first arg) is non-nil, present it to let the player sign in.
            }
        }

        func submit(best score: Int) {
            guard isAuthenticated else { return }
            Task {
                do {
                    try await GKLeaderboard.submitScore(
                        score, context: 0, player: GKLocalPlayer.local,
                        leaderboardIDs: [Self.leaderboardID]
                    )
                } catch {
                    print("Game Center submit error: \(error.localizedDescription)")
                }
            }
        }
    }
#else
    /// Non-GameKit platforms (e.g. the Linux scaffold check): a no-op shim so references still resolve.
    final class GameCenterManager {
        private(set) var isAuthenticated = false
        func authenticate() {}
        func submit(best _: Int) {}
    }
#endif
