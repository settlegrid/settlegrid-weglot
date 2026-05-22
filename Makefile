PKG       := PipeBirdCore
TESTDIR   := $(PKG)/Tests/$(PKG)Tests
ARTIFACTS := .claude/artifacts
TESTLOG   := $(ARTIFACTS)/last-test.log
BUILDLOG  := $(ARTIFACTS)/last-build.log
GOLDEN    := $(TESTDIR)/GoldenTraceTests.swift
APP_DIR    := PipeBird
APP_SCHEME := PipeBird
SIM        := platform=iOS Simulator,name=iPhone 15

# Honor the documented "non-zero exit = fail" contract. Default /bin/sh has no pipefail, so a failing
# `swift test | tee` would be masked by tee's exit 0. Run recipes under bash with pipefail so the gate
# truly fails when build/test fails. (Decision logged in PROGRESS.md.)
SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

.PHONY: all init-dirs build test test-nogolden format format-check gate project app record-golden clean

all: gate

init-dirs:
	@mkdir -p $(ARTIFACTS)

build: init-dirs
	cd $(PKG) && swift build 2>&1 | tee ../$(BUILDLOG)

# Full suite (includes GoldenTrace — only green once the fixture is frozen).
test: init-dirs
	cd $(PKG) && swift test 2>&1 | tee ../$(TESTLOG)

# Iteration loop: skip GoldenTrace so the empty fixture doesn't fail the run during Phase A.
test-nogolden: init-dirs
	cd $(PKG) && swift test --skip GoldenTraceTests 2>&1 | tee ../$(TESTLOG)

format:
	swiftformat $(PKG)

format-check:
	swiftformat --lint $(PKG)

# HARD, DETERMINISTIC PHASE GATE. Non-zero exit = gate fail. Run by test-runner at every boundary.
gate: format-check build test
	@echo ">> Checking GoldenTrace is frozen..."
	@grep -q 'recordMode = false' $(GOLDEN) \
		|| { echo "GATE FAIL: GoldenTrace recordMode must be false"; exit 1; }
	@grep -q 'Checkpoint(step:' $(GOLDEN) \
		|| { echo "GATE FAIL: GoldenTrace fixture is empty — run 'make record-golden'"; exit 1; }
	@echo ">> GATE PASS"

# Generate the iOS app's Xcode project from PipeBird/project.yml (Phase B+; macOS only).
# Requires XcodeGen:  brew install xcodegen
project:
	cd $(APP_DIR) && xcodegen generate

# iOS app build (Phase B+). Requires macOS + Xcode + a generated project (run 'make project' first).
app: init-dirs
	cd $(APP_DIR) && xcodebuild -project PipeBird.xcodeproj -scheme $(APP_SCHEME) \
		-destination '$(SIM)' build 2>&1 | tee ../$(ARTIFACTS)/last-app-build.log

record-golden:
	@echo "One-time GoldenTrace freeze:"
	@echo "  1) set 'recordMode = true' in $(GOLDEN)"
	@echo "  2) cd $(PKG) && swift test --filter GoldenTraceTests   (prints fixture, fails on purpose)"
	@echo "  3) paste printed array into goldenCheckpoints, set recordMode = false, commit"
	@echo "  4) log the record in PROGRESS.md"

clean:
	cd $(PKG) && swift package clean
