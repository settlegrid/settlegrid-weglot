// PipeBirdApp.swift — UNVERIFIED (compiles/runs only on macOS + Xcode, iOS target).
// SwiftUI app entry point. The whole `PipeBird/` tree is a Phase B+ scaffold written on Linux without
// an Apple toolchain; build, fix, and verify it on a Mac (see docs/PHASE_B_SPEC.md).

import SwiftUI

@main
struct PipeBirdApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
        }
    }
}
