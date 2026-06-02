# Agent Log

This is the shared work log for all agents and developers working in this repo.

Rules:

- Add an entry before non-trivial work starts.
- Add checkpoints during long work or when direction changes.
- Add a completion/handoff entry with tests, commits, known issues, and next steps.
- Mention dirty worktree changes you did not make. Do not revert them without explicit instruction.
- Keep entries concrete enough that another agent can resume without reading the whole chat.

## 2026-06-01 - Codex - Morning Reset, M2 Local Loop, Handoff Docs

Agent: Codex
Branch: `main`
Status at start of this log entry: local `main` matched `origin/main` at `962efce`, with one uncommitted Xcode project signing/team diff in `Wander.xcodeproj/project.pbxproj`.

### What Happened

- Joe asked to audit/reset earlier low-pass implementation work and redo from a stronger plan.
- Low-pass native implementation was reset in commit `c3ac87f`.
- Audited plan/docs were locked in:
  - `7f12630 docs: lock reset audit contract`
  - `7edbea2 docs: complete m2 design gate`
- Rebuilt the native foundation and M2 local product loop:
  - `3b109ad feat: rebuild audited ios foundation`
  - `962efce feat: build local m2 product loop`
- Pushed `962efce` to GitHub `main`.
- Verified with `xcodebuild test`; latest successful run had 18 tests and 0 failures.

### M2 Implementation Summary

Built locally with deterministic fixtures:

- Four tabs: Map, Add, Discover, Profile.
- Settings from Profile gear only.
- MapKit map with seeded own/social pins and filters.
- Add flow with current-location/manual save, visibility picker, contextual questions, and honest link/photo unresolved drafts.
- Discover with smart filters, username/profile lookup, contacts-shaped UI, and social save.
- Profile/settings with follow/unfollow/block, followers/following lists, default visibility, blocked users, drafts, and local sync hints.
- `WanderStore` manages seeded local state, visibility filtering, follow/block behavior, discover parsing, drafts, and saves.

### Tests Run

Known successful command:

```bash
xcodebuild test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO
```

Result:

```text
18 tests, 0 failures
```

Coverage includes token values, tab navigation, visibility policy, sync state transitions, deterministic Discover parser, save merge behavior, drafts, profile search, block behavior, current-location metadata, and graph edge lists.

### Current Known Issue

Joe shared a simulator screenshot showing the M2 Map screen looks bad:

- App content is undersized/letterboxed inside the iPhone simulator.
- Map does not fill and orient naturally to the device screen.
- Search, chips, selected place sheet, and tab bar are too large/crowded.
- Bottom sheet and tab bar compete for vertical space.

Next implementation task: fix root/Map layout sizing and safe areas first, then sweep Add/Discover/Profile/Settings.

### Dirty Worktree Caveat

There is an uncommitted generated Xcode project diff:

- `Wander.xcodeproj/project.pbxproj`

Observed contents look like local Xcode signing/team churn, including `DEVELOPMENT_TEAM = Y7TVK75RZ8` and an `explicitFileType` change for `Wander.app`.

Do not include this in docs or UI commits unless Joe explicitly wants local signing settings committed.

### Token/Usage Sketch For The Morning

Exact token/billing usage is not visible inside the repo or terminal. Qualitatively, the morning spent a lot of context on:

- Reconstructing product decisions from the long thread.
- Running plan/design/engineering review workflows and writing durable specs.
- Rebuilding the native SwiftUI app foundation.
- Implementing the M2 local product loop across Map, Add, Discover, Profile, Settings, models, services, and tests.
- Iterating through Xcode build/test failures and long compiler logs.
- Verifying GitHub `main` and pushing commits.
- Diagnosing the simulator screenshot and creating this catch-up/handoff package.

The highest-token sinks were likely long repository/document reads, Swift/Xcode build output, multi-file diffs, and the large planning/spec context.

### Disk Space Note

While creating this handoff, the machine had only about 100 MB free on `/System/Volumes/Data`. Clearing generated Xcode build artifacts freed enough space:

- Removed repo-local `DerivedData`.
- Cleared global Xcode DerivedData cache under `/Users/joelipshutz/Library/Developer/Xcode/DerivedData`.

These were generated build caches, not source files.

### Next Steps

1. Commit the handoff docs and agent log rules.
2. Fix M2 native UI sizing/layout, starting with Map/root safe-area behavior.
3. Run build/tests.
4. Capture simulator screenshots if possible.
5. Commit and push the visual fix.

## 2026-06-01 - Codex - M2 Native UI Sizing Fix

Agent: Codex
Branch: `main`
Starting commit: `c452297`
Starting status: local `main` matches `origin/main`; `Wander.xcodeproj/project.pbxproj` has an unstaged local signing/team diff that should remain untouched unless Joe asks.

Goal: fix the simulator screenshot failure where the M2 Map UI is letterboxed/undersized and controls are crowded. Start by inspecting app/root launch configuration, safe-area handling, and Map screen layout. Then patch the smallest stable surface, run tests, capture screenshots if possible, commit, and push.

Expected files to inspect/touch:

- `Wander/Resources/Info.plist`
- `Wander/App/WanderRootView.swift`
- `Wander/Features/Map/MapScreen.swift`
- `Wander/DesignSystem/WanderTheme.swift`
- `docs/agent-log.md`

Checkpoint:

- `Wander/Resources/Info.plist` had no launch-screen declaration. Added `UILaunchScreen` and portrait orientation, which should remove iOS compatibility letterboxing on modern simulators.
- `Wander/Features/Map/MapScreen.swift` was tightened for native scale: full-screen map ignores safe areas, smaller search bar, smaller map filter chips, smaller pins, and a more compact selected place sheet.

Completion checkpoint, 2026-06-01 11:28 PDT:

- Ran the full test suite after the sizing patch:

```bash
xcodebuild test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO
```

- Result: 18 tests, 0 failures.
- Captured simulator screenshots:
  - `DerivedData/wander-map-after-final-iphone16plus.png`
  - `DerivedData/wander-map-after-final-iphone16e.png`
- Visual result: the iOS letterboxing/undersized app frame is fixed on both targets. Map now fills the screen. Search, chips, pins, and selected-place sheet are materially more compact. On smaller phones the filter chips remain horizontally scrollable by design.
- Remaining local caveat: `Wander.xcodeproj/project.pbxproj` still has an unstaged local signing/team diff that was not part of this work and should remain uncommitted unless Joe explicitly wants it.

## 2026-06-01 - Codex - M2.1 Visual QA Sweep

Agent: Codex
Branch: `main`
Starting commit: `32e3edc`
Starting status: local `main` matches `origin/main`; `Wander.xcodeproj/project.pbxproj` has the same unstaged local signing/team diff and should remain untouched.

Goal: sweep the remaining M2 native screens after the Map letterboxing fix. Capture/navigate Add, Discover, Profile, Settings, and related profile/list/draft states where practical; patch obvious sizing, safe-area, truncation, and density issues; run tests; commit and push.

Expected files to inspect/touch:

- `Wander/App/WanderRootView.swift`
- `Wander/Features/Add/AddScreen.swift`
- `Wander/Features/Discover/DiscoverScreen.swift`
- `Wander/Features/Profile/ProfileScreen.swift`
- `Wander/Features/Settings/SettingsScreen.swift`
- `Wander/DesignSystem/WanderTheme.swift`
- `docs/agent-log.md`

Completion checkpoint, 2026-06-01 15:28 PDT:

- Added QA launch arguments in `WanderRootView`:
  - `-WanderInitialTab add|discover|profile`
  - `-WanderOpenSettings`
- Compact visual sweep:
  - Add: reduced row/card height, icon size, header/subtitle scale, and draft/saved state bulk.
  - Discover: reduced header/search density, people card height, smart-filter height, and place-row padding.
  - Profile: reduced owner card, stat tiles, month card, empty rows, and recent rows.
  - Settings: reduced row/card density and fixed visibility/blocked cards shrinking to content width.
- Captured screenshots under `DerivedData/visual-sweep/`:
  - iPhone 16 Plus: Add, Discover, Profile, Settings.
  - iPhone 16e: Add, Discover, Profile, Settings.
- Visual result: no iOS letterboxing, no obvious clipping, no tab-bar overlap on reviewed first-view screens. Discover remains the densest screen but now shows the first result fully and the second result partially on iPhone 16e.
- Ran full test suite:

```bash
xcodebuild test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO
```

- Result: 20 tests, 0 failures.
- Latest passing result bundle: `DerivedData/Logs/Test/Test-Wander-2026.06.01_15-29-13--0700.xcresult`.
- Remaining local caveat: `Wander.xcodeproj/project.pbxproj` still has the unrelated unstaged local signing/team diff and should remain uncommitted unless Joe asks.

## 2026-06-01 - Codex - Discover People Rail Fix

Agent: Codex
Branch: `main`
Starting commit: `89988a0`
Starting status: local `main` matches `origin/main`; `Wander.xcodeproj/project.pbxproj` has an unstaged local signing/team diff containing `DEVELOPMENT_TEAM = Y7TVK75RZ8`, generated app file type churn, and target-attribute cleanup. Treat as unrelated unless Joe explicitly wants signing metadata committed.

Goal: update Discover's people rail so it starts with an add-person affordance and only shows users who are actually on Wander. Non-Wander contact rows should not appear in the people rail.

Expected files to touch:

- `Wander/Features/Discover/DiscoverScreen.swift`
- `WanderTests/WanderStoreTests.swift` or related tests if store behavior needs coverage
- `docs/agent-log.md`

Completion checkpoint:

- Changed `WanderStore.contactMatches()` to exclude contacts without a matched Wander `userID`, so non-Wander contacts are not shown in social rails.
- Updated Discover people rail to show a fixed add-person card to the left of the horizontal people scroll. Tapping it seeds username search with `@` and focuses the search field.
- Deduplicated Discover profile search results against matched contact user IDs, so Maya does not appear twice when also returned from username search.
- Visual QA screenshots:
  - `DerivedData/visual-sweep/after-discover-add-rail-iphone16plus.png`
  - `DerivedData/visual-sweep/after-discover-add-rail-iphone16e.png`
- Tests: `xcodebuild test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Result: 21 tests, 0 failures.
- Latest passing result bundle: `DerivedData/Logs/Test/Test-Wander-2026.06.01_17-06-34--0700.xcresult`.
- Remaining local caveat: `Wander.xcodeproj/project.pbxproj` still has the unrelated unstaged local signing/team diff and should remain uncommitted unless Joe asks.
