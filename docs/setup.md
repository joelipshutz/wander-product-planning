# Setup

Last updated: 2026-06-01

## Requirements

- macOS with Xcode installed.
- iOS Simulator runtime available.
- XcodeGen installed and available as `xcodegen`.
- GitHub access to `joelipshutz/wander`.

## Clone

```bash
git clone git@github.com:joelipshutz/wander.git
cd wander
```

If you are working in Joe's local workspace, the repo path is:

```bash
/Users/joelipshutz/Developer/Wander (nametbd)
```

## Generate Project

`project.yml` is the source of truth for the Xcode project.

```bash
xcodegen generate
```

Run this after changing file membership, targets, or generated project settings.

## Open In Xcode

Open:

```text
Wander.xcodeproj
```

Do not commit incidental signing/team changes from Xcode unless intentional.

## Build

```bash
xcodebuild build -project Wander.xcodeproj -scheme Wander -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO
```

## Test

```bash
xcodebuild test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO
```

Known good result on 2026-06-01:

```text
18 tests, 0 failures
```

If CoreSimulator or Swift plugin server errors happen in a sandbox, rerun from a normal terminal or with approved elevated access.

## Visual QA

For UI work:

1. Run the app in the simulator.
2. Capture screenshots for Map, Add, Discover, Profile, and Settings.
3. Test at least the active iPhone target and one smaller iPhone target.
4. Verify safe areas, bottom nav, sheets, search/chips, text fitting, and home indicator spacing.

Current known visual failure:

- Map screen is undersized/letterboxed and the controls are too large/crowded on the simulator screenshot Joe shared on 2026-06-01.

## Main Files To Read First

```text
AGENTS.md
README.md
docs/codex-handoff.md
docs/roadmap.md
docs/decisions.md
docs/open-questions.md
docs/setup.md
docs/agent-log.md
docs/specs/wander-ios-product-spec.md
docs/plans/2026-06-01-wander-ios-eng-plan.md
DESIGN.md
```

## Common Commands

Status:

```bash
git status --short --branch
```

Recent commits:

```bash
git log --oneline -5
```

Verify remote main:

```bash
git ls-remote origin refs/heads/main
```
