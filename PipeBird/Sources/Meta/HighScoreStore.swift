// HighScoreStore.swift — UNVERIFIED. Local best-score persistence via UserDefaults (the MUST-scope
// "local high score"). UserDefaults is a required-reason API; declared in PrivacyInfo.xcprivacy (CA92.1).

import Foundation

struct HighScoreStore {
    private let key = "pipebird.best"

    var best: Int {
        get { UserDefaults.standard.integer(forKey: key) }
        nonmutating set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
