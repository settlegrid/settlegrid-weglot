// LinuxFoundationShim.swift — platform compatibility, additive only.
//
// On Linux, `import XCTest` re-exports Foundation, which declares its own `Pipe` (NSPipe). That
// collides with `PipeBirdCore.Pipe` (SPEC §6.5), making the unqualified `Pipe` used throughout the
// test suite — including the pre-written reference files — ambiguous. A module-level typealias
// declared in the test target shadows the imported Foundation type, so every `Pipe` reference
// resolves to the core type. This changes no test semantics and touches none of the provided test
// files; it only disambiguates a name clash that does not arise on Apple platforms.

@testable import PipeBirdCore

typealias Pipe = PipeBirdCore.Pipe
