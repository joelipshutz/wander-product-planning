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

## 2026-06-02 - Codex - M2 Interaction Punch List

Agent: Codex
Branch: `main`
Starting commit: `0d861f0`
Starting status: local `main` matches `origin/main`; `Wander.xcodeproj/project.pbxproj` has the same unrelated unstaged local signing/team diff and should remain untouched.

Goal: finish the M2 acceptance punch list Joe approved: Discover keyboard swipe dismissal, basic Map search, Discover places section with an embedded 3-stage `my`/`friends`/`everyone` switch, and Profile people section with the same 3-stage switch for `following`/`followers`/`friends`.

Expected files to touch:

- `Wander/DesignSystem/WanderTheme.swift`
- `Wander/Features/Discover/DiscoverScreen.swift`
- `Wander/Features/Map/MapScreen.swift`
- `Wander/Features/Profile/ProfileScreen.swift`
- `Wander/Services/DiscoverModels.swift`
- `Wander/Services/WanderLocalStore.swift`
- `WanderTests/WanderStoreTests.swift`
- `docs/decisions.md`
- `docs/agent-log.md`

Checkpoint:

- Joe added Map selected-place details feedback mid-pass.
- Discover:
  - Added `.scrollDismissesKeyboard(.interactively)`.
  - Moved source scope into the Places section as a 3-way `mine` / `friends` / `everyone` segmented switch.
  - Default Discover scope is now `everyone` under current follow/privacy visibility rules.
- Profile:
  - Reworked the people section into a 3-way `following` / `followers` / `friends` switch with inline rows.
- Map:
  - Added local search over visible place name/category/locality/owner/note/rating.
  - Removed the custom marker title pill so MapKit's outside annotation title is the only place label.
  - Changed selected place sheet expansion from tap-on-handle to vertical swipe/drag.
  - Added expanded sheet answer/detail chips from current local fixture fields because M2 does not yet persist Add-flow `LocalPlaceAttribute` answers.
- During final verification, found a transient dirty typo in `Wander/App/WanderRootView.swift` (`_initialPresentation` name mangled). Restored it to committed content; no RootView diff remains.
- Tests:
  - Initial sandboxed `xcodebuild test` could not access CoreSimulator; reran with approved elevated simulator access.
  - Final command: `xcodebuild test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
  - Result: 22 tests, 0 failures.
  - Latest passing result bundle: `DerivedData/Logs/Test/Test-Wander-2026.06.02_12-56-11--0700.xcresult`.
- No screenshots captured for this pass; Joe said he would test and wanted push/merge first.

## 2026-06-02 - Codex - Persist Add Question Answers

Agent: Codex
Branch: `main`
Starting commit: `eba2c70`
Starting status: local `main` matches `origin/main`; `Wander.xcodeproj/project.pbxproj` has the same unrelated unstaged local signing/team diff and should remain untouched.

Goal: wire Add-flow contextual question answers into `LocalPlaceAttribute`, show those persisted answers in the expanded Map place sheet, commit/push, then continue into M3 backend foundation.

Current question source:

- Code currently has starter blocks: `how's the vibe?`, `good for working?`, and `tags`.
- Spec defines category templates but does not enumerate all options. Implementing starter category-aware templates now:
  - Coffee: rating, work setup, coffee tags.
  - Hike: rating, strenuousness, hike tags.
  - Restaurant: rating, price, occasion, restaurant tags.
  - Bar/park/default: rating plus lightweight category tags.

Expected files to touch:

- `Wander/Features/Add/AddScreen.swift`
- `Wander/Features/Map/MapScreen.swift`
- `Wander/Models/LocalModels.swift`
- `Wander/Services/RepositoryProtocols.swift`
- `Wander/Services/WanderFixtures.swift`
- `Wander/Services/WanderLocalStore.swift`
- `WanderTests/WanderStoreTests.swift`
- `docs/decisions.md`
- `docs/agent-log.md`

Completion checkpoint:

- Added category-aware Add question templates while keeping answer persistence open-ended for future custom/user-created questions.
  - Coffee: rating/excitement, work setup, tags.
  - Hike: rating/excitement, strenuousness, tags.
  - Restaurant: rating/excitement, price, occasion, tags.
  - Bar/park/default: rating/excitement plus lightweight category tags.
- Added `PlaceAttributeDraft` and store-level `placeAttributes` state.
- `saveCandidate` now accepts optional answer attributes:
  - Add details passes attributes and persists them.
  - Existing callers that omit attributes preserve existing answers instead of wiping them.
  - Explicitly provided attributes replace the old answer set for that saved place.
- Seeded Woodcat, Griffith, and Larchmont with real `LocalPlaceAttribute` rows.
- Expanded Map place sheet now reads persisted attributes instead of category-derived placeholder chips.
- Social saves copy source place attributes into the saved place.
- `pendingSyncCount` now includes unsynced attributes.
- Locked the flexible-answer/custom-question decision in `docs/decisions.md`.
- Tests:
  - First run failed on a missing `return` in `saveVisiblePlace` after adding copied attributes; fixed.
  - Final command: `xcodebuild test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
  - Result: 24 tests, 0 failures.
  - Latest passing result bundle: `DerivedData/Logs/Test/Test-Wander-2026.06.02_13-12-47--0700.xcresult`.
- No screenshots captured for this pass.

## 2026-06-02 - Codex - M3 Supabase Foundation

Agent: Codex
Branch: `main`
Starting commit: `d0f624c`
Starting status: local `main` matches `origin/main`; `Wander.xcodeproj/project.pbxproj` has the same unrelated unstaged local signing/team diff and should remain untouched.

Goal: start M3 backend foundation with Supabase schema/RLS/RPC contract artifacts before wiring iOS Clerk UI. Include question-definition support so future user-created/custom questions can be added without changing answer columns.

Environment note:

- `supabase` CLI is not installed locally.
- `psql` is not installed locally.
- I can write migration and SQL policy test files, but cannot execute them in this environment until a Supabase/Postgres runner is available.

Expected files to touch:

- `supabase/migrations/20260602131500_m3_foundation.sql`
- `supabase/tests/rls_visibility.sql`
- `docs/backend/m3-supabase-foundation.md`
- `docs/agent-log.md`
- `docs/decisions.md` if M3 backend decisions need to be locked.

Checkpoint:

- Added first M3 migration under `supabase/migrations/`.
- Added pgTAP-style RLS visibility tests under `supabase/tests/`.
- Verified current official Clerk/Supabase docs: native Clerk Supabase integration uses Clerk session tokens, `role=authenticated`, and RLS can read the Clerk user id from `auth.jwt()->>'sub'`.
- Added explicit `question_definitions` support for future user-created questions/inputs:
  - System starter prompts are global.
  - User custom prompts are owner-authored.
  - Attached custom prompt metadata becomes readable only through visible place attributes.
  - Answers stay JSON-backed in `place_attributes`; do not add hardcoded answer columns for new prompts.
- Tightened profile/map RPCs so they return joined place rows with attributes, not raw `user_places` rows.
- Removed authenticated client update access for canonical `places`; future reconciliation should use service-role backend code.
- Added `docs/backend/m3-supabase-foundation.md`.
- Updated `docs/decisions.md` and `docs/open-questions.md` for Clerk `sub` mapping and M3 test-runner status.

## 2026-06-02 - Codex - M3 Project Setup And Verification

Agent: Codex plus sub-agents `Godel` and `Epicurus`
Branch: `main`
Starting commit: `08b7aca`
Starting status: local `main` matches `origin/main`; `Wander.xcodeproj/project.pbxproj` has the same unrelated unstaged local signing/team diff and should remain untouched.

Goal: proceed with M3 setup using new Supabase and Clerk projects, verify the Supabase migration/RLS tests, and document any account/credential blockers.

Coordination:

- Spawned Supabase setup explorer sub-agent `Godel`.
- Spawned Clerk setup explorer sub-agent `Epicurus`.
- Mission Control create-task attempt to `http://localhost:4000/api/tasks` failed because localhost:4000 was not reachable.

Expected files to touch:

- `docs/agent-log.md`
- `docs/backend/m3-supabase-foundation.md`
- `docs/setup.md` if local Supabase/Clerk setup commands are confirmed
- Supabase config files if CLI initialization succeeds

Initial local findings:

- `brew`, `npm`, and `npx` are available.
- `supabase`, `psql`, and `clerk` CLIs are not currently installed.
- Existing `supabase/` folder contains the M3 migration/test artifacts only.

Checkpoint:

- Supabase sub-agent `Godel` confirmed no existing Wander Supabase project was linked, no local Docker, no `psql`, no Supabase access token before login, and noted generated config expected missing `supabase/seed.sql`.
- Clerk sub-agent `Epicurus` confirmed no existing Wander Clerk app/config and found iOS bundle id `com.grayline.wander` in `project.yml`.
- Logged into Supabase CLI with Joe's browser verification.
- Created new Supabase hosted project:
  - Name: `wander`
  - Ref: `rugmtlgufrhlxwfkumhw`
  - Region: `us-west-2`
- Stored Supabase project ref, DB password, URL, anon key, and service role key in `/Users/joelipshutz/.openclaw/workspace/.env.keys`.
- Ran `npx supabase init` and normalized `supabase/config.toml` project id to `wander`.
- Disabled Supabase seed because generated config referenced missing `supabase/seed.sql`.
- Linked the repo to the new Supabase project.
- Ran migration dry-run: one migration detected, `20260602131500_m3_foundation.sql`.
- Pushed migration to hosted Supabase. PostGIS metadata privilege warnings appeared but migration completed successfully.
- Verified remote migration list: local and remote both have `20260602131500`.
- `npx supabase test db --linked supabase/tests/rls_visibility.sql` failed because the CLI still tried to use Docker.
- Installed temporary Node `pg` client under `/private/tmp/wander-pg-runner` and ran `supabase/tests/rls_visibility.sql` against hosted Postgres.
- Hosted RLS test result: 15 pgTAP assertions, 0 failures.
- Logged into Clerk CLI as `joe@bondaiapp.com`.
- Existing Clerk apps were TheEssayPress and Signal; no Wander app existed.
- Created new Clerk app:
  - Name: `Wander`
  - App id: `app_3Eb3JbpbMDjOA2qKUCqfsZwfct9`
  - Development instance: `ins_3Eb3Je6FO3qfUDIt5n3aTHMxYN1`
  - Development domain: `growing-pheasant-22.clerk.accounts.dev`
- Linked repo to new Clerk app.
- Patched Clerk development session token claims to include `role: authenticated`.
- Pulled Clerk env values into `/private/tmp/wander-clerk.env` and appended them to `.env.keys`.
- Added local Supabase Clerk third-party auth config in `supabase/config.toml`.
- Ran `npx supabase config push`; it pushed generated local auth defaults plus the Clerk config to the new hosted project. Review hosted auth settings before alpha.
- Spawned Edge Function review sub-agent `Fermat`, which flagged handle collision, replay/stale event, delete-event typing, and runtime secret issues before finalizing the webhook.
- Added Clerk profile mirroring migration `20260602140304_clerk_profile_mirroring.sql`:
  - Adds `clerk_updated_at` and `last_clerk_event_id` to `profiles`.
  - Adds `clerk_webhook_events` and `clerk_profile_mirror_state`.
  - Adds `app.mirror_clerk_profile` for duplicate, stale-event, handle-collision, delete-before-create, and soft-delete handling.
- Added public service-role wrapper migration `20260602143000_public_clerk_profile_mirror_rpc.sql` after direct PostgREST testing showed `/rest/v1/rpc/...` only searched the `public` schema.
- Added `supabase/tests/clerk_profile_mirroring.sql`; hosted pgTAP result is 14 assertions, 0 failures.
- Deployed Supabase Edge Function `clerk-profile-webhook`.
- Created Clerk/Svix endpoint `ep_3Eb5WlmjQlDav83RHa3hWxp07wd` pointing to `https://rugmtlgufrhlxwfkumhw.supabase.co/functions/v1/clerk-profile-webhook`.
- Stored the Svix signing secret local-only and set Supabase Edge Function secrets:
  - `CLERK_WEBHOOK_SIGNING_SECRET`
  - `WANDER_SUPABASE_URL`
  - `WANDER_SUPABASE_SERVICE_ROLE_KEY`
- Direct signed Edge Function test passed: Svix-style signature verification, RPC call, and `profiles` lookup all succeeded.
- Real Clerk/Svix create webhook test passed with disposable Clerk dev user `user_3Eb6hVABCXRiZ3tcbdvlu2NAh2j`.
- Real Clerk/Svix delete webhook test passed; the mirrored profile received `deleted_at`.
- Hosted SQL tests rerun through temporary Node `pg` runner:
  - `supabase/tests/rls_visibility.sql`: 15 assertions, 0 failures.
  - `supabase/tests/clerk_profile_mirroring.sql`: 14 assertions, 0 failures.
  - Total: 29 assertions, 0 failures.
- Redeployed the final formatted Edge Function and reran a signed smoke test against the deployed URL; `codex_redeploy_test` profile was created successfully.
- Updated `docs/setup.md`, `docs/backend/m3-supabase-foundation.md`, `docs/open-questions.md`, `docs/decisions.md`, and this log.

Known remaining M3 setup work:

- Add iOS Clerk/Supabase SDK dependencies and repository-boundary wiring.
- Add remote repository tests and auth-gated UI tests.
- Install Docker/OrbStack/Colima if we want the standard local Supabase stack and CLI pgTAP runner.
- Review hosted Supabase Auth settings before alpha because `npx supabase config push` pushed generated local auth defaults plus Clerk config.

## 2026-06-02 14:27 PDT - Codex - M3 iOS Clerk/Supabase Wiring

Agent: Codex plus parallel explorers `Socrates`, `Euclid`, and `Ohm`
Branch: `main`
Starting commit: `b8de80d`
Starting status: local `main` matches `origin/main`; `Wander.xcodeproj/project.pbxproj` has the same unrelated local signing/file-type diff and should remain unstaged unless Joe explicitly asks.

Goal: execute the next slice of the existing engineering plan, not create a new plan: add iOS Clerk/Supabase SDK wiring behind repository/auth boundaries, introduce auth gates at save/sync/follow/social-save intent points, and keep views from calling Clerk/Supabase directly.

Coordination:

- Source plan: `docs/plans/2026-06-01-wander-ios-eng-plan.md`, especially M3 Clerk + Supabase Foundation and D14 auth gates.
- Mission Control task creation to `http://localhost:4000/api/tasks` failed because localhost:4000 is not reachable.
- GBrain search for Wander Clerk/Supabase context timed out on a PGLite lock; proceeding from repo docs and this agent log.
- Spawned parallel explorers:
  - `Socrates`: project.yml/SwiftPM dependency mechanics.
  - `Euclid`: service/repository boundary recommendations.
  - `Ohm`: UI auth-gate insertion points.

Expected files to touch:

- `project.yml`
- `Wander/App/*`
- `Wander/Services/Auth/*`
- `Wander/Services/Remote/*`
- `Wander/Services/RepositoryProtocols.swift`
- Feature files only where auth gates are wired.
- `WanderTests/*` for auth/repository contract coverage.
- `docs/agent-log.md`, and docs/decisions/open-questions only if new durable decisions appear.

Initial implementation checklist:

- Add Clerk/Supabase SwiftPM packages through XcodeGen.
- Add auth session provider and minimal auth gate state.
- Add Supabase client factory using local non-secret config and Clerk session token boundary.
- Add remote repository shells/DTOs behind protocols.
- Gate save/sync/follow/social-save intents without implementing full onboarding.
- Regenerate Xcode project and run the full `xcodebuild test` command before committing.

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

## 2026-06-02 - Codex - Map Filter Label Alternatives

Agent: Codex
Branch: `main`
Starting commit: `7d58068`
Starting status: local `main` matches `origin/main`; `Wander.xcodeproj/project.pbxproj` has the same unrelated unstaged local signing/team diff and should remain untouched.

Goal: quickly mock alternate active/inactive treatments for the Map filter/label chips because the current selected state is not clear enough. Produce a reviewable HTML/PNG artifact, not production SwiftUI changes yet.

Expected files to touch:

- `preview/map-filter-label-alts/index.html`
- `preview/map-filter-label-alts/map-filter-label-alts.png` if rendering succeeds
- `docs/agent-log.md`

Checkpoint:

- Joe clarified this should be a focused color/border state study, not full phone mocks.
- Added focused artifact: `preview/map-filter-label-alts/states.html`.
- Rendered PNG: `preview/map-filter-label-alts/map-filter-state-options.png`.
- Recommendation in the mock: Option 2, active = white fill + terracotta ring/check, inactive = faded bone fill + muted border/hollow icon.

## 2026-06-02 - Codex - M2 Visual Acceptance Pass

Agent: Codex
Branch: `main`
Starting commit: `7d58068`
Starting status: local `main` matches `origin/main`; `Wander.xcodeproj/project.pbxproj` has the same unrelated unstaged local signing/team diff. Existing uncommitted work includes the map filter state mock artifacts and this log.

Goal: implement Joe's approved M2 visual feedback before M3: map filter active ring states, place labels on map, selected/tapped pin state, selected place expanded screen for Larchmont Noodles, facepile/social proof instead of "`Name`'s tip", simpler screen titles, Profile organization cleanup, and Discover hierarchy with places above filters plus my/friends place toggle.

Expected files to touch:

- `Wander/Features/Map/MapScreen.swift`
- `Wander/Features/Discover/DiscoverScreen.swift`
- `Wander/Features/Profile/ProfileScreen.swift`
- `Wander/Features/Settings/SettingsScreen.swift`
- `Wander/Services/WanderLocalStore.swift`
- `Wander/Services/DiscoverModels.swift`
- `Wander/App/WanderRootView.swift` only if QA launch support needs a selected map state
- `docs/decisions.md`
- `docs/agent-log.md`

Completion checkpoint:

- Locked M2 visual decisions in `docs/decisions.md`.
- Map:
  - Active filters now keep the bone/sand chip fill and add a terracotta ring/icon.
  - Removed the `friends` map filter chip per Joe; map scope now shows `you`, `social`, `been`, `wanna`.
  - Added vertical padding to the chip rail so active outlines do not clip.
  - Added map place labels and selected/tapped pin styling.
  - Added expandable selected place sheet and QA launch args for Larchmont Noodles.
  - Replaced "`Name`'s tip" with facepile/social proof copy like "Ryan saved it".
- Discover:
  - Simplified title to `discover`.
  - People section stays near the top under search.
  - Places are the primary content above filters.
  - Added `my places` / `friends' places` toggle and matching store scope.
- Profile:
  - Simplified title to `profile`.
  - Removed bio quote from the owner header.
  - Moved following/followers/friends into a lower `people` section.
- Settings:
  - Simplified title to `settings`.
- Tests: `xcodebuild test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Result: 22 tests, 0 failures.
- Latest passing result bundle: `DerivedData/Logs/Test/Test-Wander-2026.06.02_11-08-03--0700.xcresult`.
- Visual screenshots captured before final Joe stop:
  - `DerivedData/visual-sweep/m2-visual-acceptance-map-larchmont-expanded-iphone16plus.png`
  - `DerivedData/visual-sweep/m2-visual-acceptance-discover-iphone16plus.png`
  - `DerivedData/visual-sweep/m2-visual-acceptance-profile-iphone16plus.png`
  - `DerivedData/visual-sweep/m2-visual-acceptance-settings-iphone16plus.png`
- Remaining local caveat: `Wander.xcodeproj/project.pbxproj` still has the unrelated unstaged local signing/team diff and should remain uncommitted unless Joe asks.

## 2026-06-02 - Codex - M3 iOS Wiring Checkpoint

Agent: Codex
Branch: `main`
Starting commit: `b8de80d`
Starting status: local `main` matched `origin/main`; `Wander.xcodeproj/project.pbxproj` already had unrelated local generated/signing churn and should not be committed unless intentional.

Goal: continue the existing engineering plan's M3 iOS work, not create a new plan. Wire Clerk/Supabase behind service boundaries, gate account-required UI actions, add contract tests, then regenerate/build/test.

Checkpoint:

- Confirmed Mission Control was not reachable locally and GBrain was locked earlier; continued from repo docs and existing eng plan.
- Closed completed subagents after folding in their findings.
- Added Clerk/Supabase package/config entries in `project.yml`, app Info.plist keys, and associated-domain entitlements.
- Added `AuthSessionProviding`, `ClerkAuthService`, `AuthGateSheet`, `WanderSupabaseClient`, Supabase DTOs, and Supabase repository conformers.
- Wired auth gate state at `WanderApp` / `WanderRootView`.
- Gated Add sync intent, Discover follow/social save, Map social save, Profile follow/unfollow/block, graph-list follow/unfollow, Settings unblock/data-sync.
- Replaced the placeholder Supabase RPC shell with a REST RPC transport that attaches the Clerk/Supabase JWT through `Authorization`.
- Added tests:
  - `WanderTests/AuthSessionTests.swift`
  - `WanderTests/RemoteRepositoryTests.swift`
  - `WanderTests/BoundaryImportTests.swift`

Next: run `xcodegen generate`, inspect generated project churn carefully, then build/test and fix compile/API issues.

Completion checkpoint:

- Ran `xcodegen generate` successfully and confirmed the project churn is the intentional SwiftPM/package/entitlements wiring for Clerk and Supabase.
- SwiftPM resolved:
  - Clerk iOS at `1.1.4`
  - Supabase Swift at `2.46.0`
- Fixed the first full test failure by removing `convertFromSnakeCase` from the remote DTO decoder, since the DTOs already use explicit snake_case `CodingKeys`.
- Full test command:
  `xcodebuild test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Result: 32 tests, 0 failures.
- Latest passing result bundle: `DerivedData/Logs/Test/Test-Wander-2026.06.02_14-47-32--0700.xcresult`.
- Files changed for the commit include `project.yml`, generated `Wander.xcodeproj` package references/SwiftPM lockfile, backend config/auth/remote service files, auth gates across M2 UI surfaces, and the three new test files.
- Known caveat: project signing/team settings are local-machine state and should remain uncommitted if Xcode reintroduces them.

## 2026-06-02 18:54 PDT - Codex - M3 Remote Wiring Continuation

Agent: Codex
Branch: `main`
Starting commit: `1051878`
Starting status: local `main` matches `origin/main`; `Wander.xcodeproj/project.pbxproj` has only the expected uncommitted local `DEVELOPMENT_TEAM = Y7TVK75RZ8` signing diff and should remain uncommitted.

Goal: continue the existing M3 plan by moving from service-boundary scaffolding toward live app behavior. Add a backend container/fallback path so signed-in social actions can attempt Supabase RPCs without views importing Clerk/Supabase, keep local-first behavior when signed out/offline, and document local secret setup for the smoke test.

Expected files to touch:

- `Wander/App/WanderApp.swift`
- `Wander/App/WanderRootView.swift`
- `Wander/App/WanderBackend.swift`
- `Wander/Services/WanderLocalStore.swift`
- `Wander/Services/Remote/SupabaseRepositories.swift`
- `WanderTests/RemoteRepositoryTests.swift`
- `WanderTests/AuthSessionTests.swift` if auth store behavior needs a regression test
- `docs/setup.md`
- `docs/agent-log.md`

Initial findings:

- Mission Control is still unavailable on `localhost:4000`.
- GBrain timed out waiting for the PGLite lock, so this pass is using checked-in Wander docs as source of truth.
- The M3 exit criteria still missing in-app are: sign-in smoke test with local publishable keys, profile mirror confirmation from the app, local saved-place sync, and visible social pin fetch.

Completion checkpoint:

- Added `WanderBackend` as the app-level remote repository container.
- `AuthSessionStore` now conforms to `AuthSessionProviding`, so Supabase RPC transport can get Clerk-issued Supabase tokens without views importing Clerk/Supabase.
- Wired Map/Discover/Profile/Settings social actions through remote-aware `WanderStore` methods:
  - remote profile search can merge into Discover username results
  - remote visible places can refresh into a cache for the Map surface
  - follow/unfollow/block/unblock attempt remote calls when signed in/configured
  - social save attempts `save_visible_place` and marks local copy `synced` on success or `failed` on remote failure
- Preserved local-first behavior for signed-out/offline flows and left full retry/claim queue for M4.
- Updated `docs/setup.md` with the local-only build setting injection pattern for live Clerk/Supabase smoke tests.
- Ran `xcodegen generate`.
- Full test command:
  `xcodebuild test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Result: 35 tests, 0 failures.
- Latest passing result bundle: `DerivedData/Logs/Test/Test-Wander-2026.06.02_19-03-34--0700.xcresult`.
- Remaining known gap: live sign-in/profile-mirror smoke test still needs to be run with local publishable keys injected into the simulator build.

## 2026-06-02 20:54 PDT - Codex - M3 Extra-High Audit

Agent: Codex
Branch: `main`
Starting commit: `89bca2f`
Starting status: local `main` matches `origin/main`; `Wander.xcodeproj/project.pbxproj` has only the expected uncommitted local `DEVELOPMENT_TEAM = Y7TVK75RZ8` signing diff and should remain uncommitted.

Goal: audit the M3 auth/remote wiring before live Clerk/Supabase smoke testing or deeper M4 sync work. Focus on code/SQL contract shape, Clerk token assumptions, local-first sync transitions, UI state/error gaps, and test coverage.

Parallel audit helpers:

- Backend contract audit: compare Swift RPC names/params/DTOs to Supabase migrations/functions.
- iOS app wiring audit: inspect environment object injection, auth/session behavior, async social actions, local-first state, and test gaps.

Expected files to touch:

- `docs/agent-log.md`
- Potentially `docs/open-questions.md` or implementation files only if the audit finds a clear mismatch that is safer to fix immediately.

Initial findings:

- Mission Control remains unavailable on `localhost:4000`.
- GBrain lookup is slow/locked again; this audit is using repo docs and code as source of truth.

Completion checkpoint:

- Parallel backend audit found:
  - app RPCs lived only under private `app.*`, while PostgREST exposes `public` by default.
  - `save_visible_place` returned `public.user_places` but Swift expected `{ "user_place_id": ... }`.
  - `unblock_user` had an app surface but no SQL/RPC implementation.
  - `block_user` likely could not delete reciprocal follow rows under the existing delete RLS policy.
  - Clerk default token path still needs live verification.
- Parallel iOS audit found:
  - social-save could call remote with local fixture IDs instead of backend UUIDs.
  - remote profile search shells were not cached, so tapping a remote-only search result could open a blank profile sheet.
  - failed unfollow/unblock removed local state even if remote mutation failed.
  - remote attributes, remote relationship filtering, and visible error/retry UI need later cleanup.
- Fixes made:
  - Added migration `20260602210000_public_app_rpc_wrappers.sql`.
  - Added public PostgREST wrappers for app-facing RPCs and a JSON response shape for `public.save_visible_place`.
  - Added `app.unblock_user` / `public.unblock_user`.
  - Redefined `app.block_user` as a guarded `security definer` so hard block cleanup can remove both follow directions.
  - Wired `SupabaseBlockRepository.unblock`.
  - Changed remote social-save to require real UUID `serverID`s and pass server IDs, not fixture IDs.
  - Cached remote profile shells from Discover search.
  - Changed remote unfollow/unblock failures to keep local rows marked `failed` instead of deleting them.
- Applied the new migration to hosted Supabase with `npx supabase db push --linked`; migration `20260602210000_public_app_rpc_wrappers.sql` completed successfully.
- Full test command:
  `xcodebuild test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Result: 39 tests, 0 failures.
- Latest passing result bundle: `DerivedData/Logs/Test/Test-Wander-2026.06.02_20-59-22--0700.xcresult`.
- Remaining known gaps before expanding M4:
  - live Clerk token/Supabase RLS smoke test
  - remote attributes hydration
  - remote relationship/filter hydration
  - explicit user-visible sync error/retry UI for failed follow/block/social-save

## 2026-06-02 21:08 PDT - Codex - M3 Live Smoke

Agent: Codex
Branch: `main`
Starting commit: `4b57c3e`
Starting status: local `main` matches `origin/main`; `Wander.xcodeproj/project.pbxproj` still has only the expected uncommitted local signing/team diff and should remain uncommitted.

Goal: run the M3 live Clerk + Supabase smoke path before adding more M4 sync work. Verify whether the current iOS token path can satisfy Supabase RLS/RPCs, then test the app/backend paths for profile/search/follow/block/social-save as far as local credentials and simulator access allow.

Expected files to touch:

- `docs/agent-log.md`
- Potentially `Wander/Services/Auth/ClerkAuthService.swift`, setup docs, or tests if the smoke exposes a fixable token/RPC/config mismatch.

Initial findings:

- Mission Control is unavailable on `localhost:4000`.
- GBrain lookup is still slow/locked; proceeding from repo docs and checked-in setup state.
- The app currently requests `Clerk.shared.auth.getToken()` without an explicit template, so the first smoke target is token acceptance by Supabase RLS/RPCs.

Checkpoint:

- Created temporary smoke runner at `/private/tmp/wander-m3-live-smoke.mjs` to avoid committing secrets or test-only code.
- The first run failed in the sandbox with `getaddrinfo ENOTFOUND api.clerk.com`; reran with approved network access.
- Hosted smoke results:
  - Clerk disposable user creation passed.
  - Clerk -> Svix -> Supabase Edge Function profile mirroring passed.
  - Clerk default session token minted successfully and decoded locally with:
    - `sub=<viewer Clerk user id>`
    - `role=authenticated`
    - `iss=https://growing-pheasant-22.clerk.accounts.dev`
    - `alg=RS256`
    - `kid=ins_3Eb3Je6FO3qfUDIt5n3aTHMxYN1`
  - Clerk JWKS at `https://growing-pheasant-22.clerk.accounts.dev/.well-known/jwks.json` returned HTTP 200 and contains that `kid`.
  - Supabase service-role seed setup passed.
  - First authenticated public RPC call with the Clerk token failed before RLS with `401 PGRST301 No suitable key was found to decode the JWT`.
  - Reran `supabase config push`; CLI reported remote API/DB/Auth/Storage config all up to date.
  - Reran the smoke after config push; same `PGRST301` Clerk token decode failure.
  - Control request using Supabase anon JWT against the same public RPC reached `42501 permission denied for function search_profiles_by_handle`, confirming PostgREST/RPC exposure is live and Supabase can decode its own JWT.
- Conclusion: do not proceed to M4 sync or simulator remote-action debugging yet. The current blocker is hosted Supabase Clerk third-party auth verification/key registration, not Swift app code or public RPC wrapper exposure.

## 2026-06-04 - Codex - M3 Auth Provider Follow-Up

Agent: Codex
Branch: `main`
Starting commit: `ce1c316`
Starting status: local `main` matches `origin/main`; `Wander.xcodeproj/project.pbxproj` still has only the expected local signing/team diff and should remain uncommitted.

Goal: answer whether the Clerk/Supabase verifier blocker can be fixed through CLI, and clarify whether Supabase OAuth Server must be enabled.

Checkpoint:

- Verified current docs: the relevant hosted Supabase path is **Authentication -> Sign In / Providers -> Add provider -> Clerk**, not the OAuth Server page.
- OAuth Server being enabled is unrelated to accepting Clerk third-party JWTs.
- Re-ran `supabase config push --project-ref rugmtlgufrhlxwfkumhw`; CLI reported remote Auth config up to date.
- Re-ran the hosted Clerk-token smoke after explicit config push; Supabase still returned `401 PGRST301 No suitable key was found to decode the JWT`.
- Ran `npx supabase@latest config push --project-ref rugmtlgufrhlxwfkumhw` using Supabase CLI `2.105.0`; it also reported remote Auth config up to date.
- Re-ran the hosted Clerk-token smoke again after latest CLI push; same `PGRST301` failure.
- Checked Clerk OIDC discovery and JWKS:
  - OIDC issuer: `https://growing-pheasant-22.clerk.accounts.dev`
  - JWKS URI: `https://growing-pheasant-22.clerk.accounts.dev/.well-known/jwks.json`
  - JWKS contains `kid=ins_3Eb3Je6FO3qfUDIt5n3aTHMxYN1`
- Conclusion: CLI config push is not resolving hosted PostgREST's Clerk verifier. Next action is to add/verify the Clerk provider row in Supabase Dashboard under Authentication -> Sign In / Providers, or use the authenticated browser to do that UI step.

## 2026-06-04 08:27 PDT - Codex - M3 Auth Provider Retest

Agent: Codex
Branch: `main`
Starting commit: `8517e08`
Starting status: local `main` matches `origin/main`; `Wander.xcodeproj/project.pbxproj` still has only the expected local signing/team diff and should remain uncommitted.

Goal: rerun the hosted Clerk-to-Supabase smoke after Joe added the Clerk provider connection in the Supabase dashboard using the `https://growing-pheasant-22.clerk.accounts.dev` domain.

Expected files to touch:

- `docs/agent-log.md`
- Potentially setup/open-question docs if the smoke result changes M3 status.

Completion checkpoint:

- Created temporary smoke runner at `/private/tmp/wander-m3-live-smoke.mjs`; no secrets or runner code committed.
- Hosted smoke passed after the Supabase Clerk connection was added:
  - Clerk disposable user creation passed.
  - Clerk profile mirroring passed.
  - Default Clerk session token had `alg=RS256`, `kid=ins_3Eb3Je6FO3qfUDIt5n3aTHMxYN1`, `iss=https://growing-pheasant-22.clerk.accounts.dev`, `role=authenticated`, and `sub` matched the viewer Clerk user id.
  - Supabase accepted the Clerk token.
  - Authenticated RPCs passed: `search_profiles_by_handle`, `follow_user`, `visible_places_in_view`, `save_visible_place`, `block_user`, `unblock_user`, and `unfollow_user`.
- Updated `docs/open-questions.md`, `docs/backend/m3-supabase-foundation.md`, and `docs/setup.md` from blocked to passed.
- Ran simulator build with local public Clerk/Supabase keys injected:
  `xcodebuild build -project Wander.xcodeproj -scheme Wander -destination "platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6" -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO ...`
- Result: build succeeded.
- Next: app-level simulator smoke for actual Clerk sign-in UI and remote-backed social actions.

## 2026-06-04 10:18 PDT - Codex - Settings Sign Out

Agent: Codex
Branch: `main`
Starting commit: `7c30e20`
Starting status: local `main` matches `origin/main`; `Wander.xcodeproj/project.pbxproj` still has only the expected local signing/team diff and should remain uncommitted.

Goal: add a real sign-out path so simulator/device testing can leave Joe's restored Clerk session and exercise signed-out/sign-in flows.

Expected files to touch:

- `Wander/Services/Auth/AuthSessionProviding.swift`
- `Wander/Services/Auth/ClerkAuthService.swift`
- `Wander/Features/Settings/SettingsScreen.swift`
- `WanderTests/AuthSessionTests.swift`
- `docs/agent-log.md`

Initial findings:

- Current app has sign-in gates but no sign-out or account-switch surface.
- Clerk iOS SDK exposes `try await Clerk.shared.auth.signOut()`.

Completion checkpoint:

- Added `signOut()` to the auth session boundary and implemented it through `Clerk.shared.auth.signOut()`.
- Added Settings account state UI: signed-in identity summary, sign-out action with loading/error state, signed-out sign-in action, and loading/unavailable fallbacks.
- Added auth session tests for successful sign-out clearing the session and failed sign-out preserving the active session while surfacing an error.
- First test compile failed because Settings referenced a non-existent `WanderTheme.sky` token; fixed to use the existing social-pin token.
- Ran full test suite:
  `xcodebuild test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Result: passed, 41 tests, 0 failures. Result bundle: `DerivedData/Logs/Test/Test-Wander-2026.06.04_10-21-43--0700.xcresult`.
- Known remaining local diff: `Wander.xcodeproj/project.pbxproj` signing/team settings, intentionally uncommitted.

## 2026-06-04 10:24 PDT - Codex - TestFlight Readiness Check

Agent: Codex
Branch: `main`
Starting commit: `1517a4b`
Starting status: local `main` matches `origin/main`; `Wander.xcodeproj/project.pbxproj` still has only the expected local `DEVELOPMENT_TEAM = Y7TVK75RZ8` diff.

Goal: answer whether the current Wander repo can be pushed to TestFlight from this machine.

Findings:

- The app target bundle id is `com.grayline.wander`.
- `project.yml` intentionally has no committed `DEVELOPMENT_TEAM`; local generated project state has team `Y7TVK75RZ8`, still uncommitted.
- Local code-signing identity check returned `0 valid identities found`, so this machine cannot currently produce a signed App Store/TestFlight archive from CLI.
- Existing local App Store Connect env key `ASC_BUNDLE_ID` is not `com.grayline.wander`, so the current ASC env appears to be for another app/workflow and should not be reused blindly for Wander uploads.
- No repo TestFlight lane exists yet: no `ExportOptions.plist`, `Fastfile`, `.ipa`, or `.xcarchive` was found.
- Release hygiene issue: `project.yml` says `MARKETING_VERSION = 0.1`, but `Wander/Resources/Info.plist` hardcodes `CFBundleShortVersionString` to `1.0`; fix before first TestFlight upload so versioning is predictable.
- Sandbox-only `xcodebuild -list`/`-showBuildSettings` checks failed on cache/CoreSimulator permissions; this does not change the signing conclusion.

Conclusion:

- Not ready to upload to TestFlight from CLI yet.
- Next setup steps: add/use a Wander-specific App Store Connect app/bundle config, install or create an Apple Distribution signing identity/provisioning path for `com.grayline.wander`, add a release export/upload lane, fix Info.plist version build settings, then archive/upload.

## 2026-06-04 10:32 PDT - Codex - Simulator Auth Config And Sign-Out Visibility

Agent: Codex
Branch: `main`
Starting commit: `e01ca73`
Starting status: local `main` is ahead of `origin/main` by the TestFlight readiness log commit; `Wander.xcodeproj/project.pbxproj` still has the local signing/team diff.

Goal: fix Joe's simulator screenshot showing `Missing Clerk publishable key.` in Settings, then continue TestFlight setup.

Findings:

- The Settings sign-out implementation exists, but the simulator app was built without `WANDER_CLERK_PUBLISHABLE_KEY`.
- With missing Clerk config, `ClerkAuthService` sets auth state to `.unavailable("Missing Clerk publishable key.")`, so the account card cannot show the signed-in state or sign-out control.
- Immediate fix path: rebuild/install the simulator app with the local-only public Clerk/Supabase client keys injected via an xcconfig so the values are not printed in command output.
- UI improvement path: make Settings show a full-width account action button instead of relying on the small trailing `sign out` button.

Completion checkpoint:

- Updated Settings account UI so signed-in state shows a full-width `sign out` button and signed-out state shows a matching full-width `sign in` button.
- Added unavailable-state helper copy so missing auth config points to the local auth-config rebuild issue.
- Created temporary local auth xcconfig at `/private/tmp/wander-live-auth.xcconfig` from local env values; do not commit this file.
- First sandboxed configured test run failed due Xcode cache/CoreSimulator permissions and printed build settings; reran quietly with elevated Xcode access for subsequent runs.
- Fixed one compile issue from the UI tweak (`WanderTheme.cream` -> `WanderTheme.textOnAction`).
- Ran configured full test suite:
  `xcodebuild -quiet test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData -xcconfig /private/tmp/wander-live-auth.xcconfig CODE_SIGNING_ALLOWED=NO`
- Result: passed.
- Built configured simulator app and installed/launched it on iPhone 17 Pro simulator `066417CD-C3D5-4209-BA1F-46152B1A6AAC` into Settings.
- Verification screenshot: `/private/tmp/wander-settings-auth.png`; Settings now shows `Signed out` and a large `sign in` button instead of `Missing Clerk publishable key.`
- Expected behavior: after sign-in, the same account card shows the large `sign out` button.

## 2026-06-04 10:41 PDT - Codex - TestFlight Archive Attempt

Agent: Codex
Branch: `main`
Starting commit: `1a9887b`
Starting status: local `main` matches `origin/main`; `Wander.xcodeproj/project.pbxproj` still has the local signing/team diff.

Goal: attempt to prepare and upload a Wander TestFlight build after fixing the simulator auth configuration issue.

Expected files to touch:

- `Wander/Resources/Info.plist`
- `docs/agent-log.md`

Initial findings:

- Release metadata hygiene issue: `Info.plist` hardcoded `CFBundleShortVersionString` to `1.0` while `project.yml` uses `MARKETING_VERSION = 0.1`.
- Fixed `Info.plist` to read `$(MARKETING_VERSION)` and `$(CURRENT_PROJECT_VERSION)` so archives use project build settings.
- Next step is a signed `xcodebuild archive` with local public auth config injected through `/private/tmp/wander-live-auth.xcconfig`, automatic signing, and team `Y7TVK75RZ8`.

Checkpoint:

- Signed archive succeeded at `/private/tmp/Wander-0.1.xcarchive`.
- Export/upload attempt failed before package upload with `IDEDistribution.DistributionAppRecordProviderError.missingApp(bundleId: "com.grayline.wander")`.
- Distribution logs showed App Store Connect auth worked and queried provider `7f20b667-afd3-456b-b2bc-ca94ab295484`, but returned zero apps for `com.grayline.wander`.
- Conclusion: signing is now good enough to archive; the current blocker is that no App Store Connect app record exists for `com.grayline.wander`.
- Added release prep for the next attempt:
  - `TARGETED_DEVICE_FAMILY = 1`
  - `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`
  - `UIRequiresFullScreen = true`
  - generated a temporary/simple AppIcon asset catalog for validation unblock; replace with final brand icon later.

Completion checkpoint:

- Added tracked `Wander/Config/Auth.xcconfig`, ignored `Wander/Config/LocalAuth.xcconfig`, and project wiring so normal Xcode builds can use local public Clerk/Supabase client keys without committing key values.
- Created local ignored `Wander/Config/LocalAuth.xcconfig` from `/Users/joelipshutz/.openclaw/workspace/.env.keys`.
- Regenerated `Wander.xcodeproj` from `project.yml`; `DEVELOPMENT_TEAM = Y7TVK75RZ8` is now intentional project configuration.
- Verified no local public client key values are present in tracked files.
- Ran regenerated-project tests:
  `xcodebuild -quiet test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Result: passed.
- Fresh signed archive succeeded at `/private/tmp/Wander-0.1.xcarchive` after the icon/full-screen/project config changes.
- Updated `docs/setup.md` with local auth config setup and the App Store Connect app-record blocker.
- Exact remaining TestFlight step: create an App Store Connect iOS app record for `com.grayline.wander` (suggested name `Wander`, SKU `wander-ios`). Then rerun upload.
- Follow-up correction: XcodeGen rewrites `Wander/Resources/Info.plist`, so version/full-screen keys now live in `project.yml` `info.properties`.
- Reran `xcodegen generate`.
- Reran tests after the final generated project/plist changes: passed.
- Rebuilt the final signed archive at `/private/tmp/Wander-0.1.xcarchive`: passed.

## 2026-06-04 11:03 PDT - Codex - TestFlight Upload Retry

Agent: Codex
Branch: `main`
Starting commit: `5cee10c`
Starting status: local `main` matches `origin/main`.

Goal: rerun App Store Connect upload after Joe created the `com.grayline.wander` app record.

Expected files to touch:

- `docs/agent-log.md`

Plan:

- Reuse `/private/tmp/Wander-0.1.xcarchive` from the successful signed archive.
- Recreate upload export options if needed.
- Run `xcodebuild -exportArchive` with `destination=upload`.
- Log the upload result or the next exact Apple validation blocker.

Completion checkpoint:

- Recreated `/private/tmp/WanderExportUpload.plist`.
- Ran:
  `xcodebuild -quiet -exportArchive -archivePath /private/tmp/Wander-0.1.xcarchive -exportPath /private/tmp/WanderTestFlightUpload -exportOptionsPlist /private/tmp/WanderExportUpload.plist -allowProvisioningUpdates`
- App Store Connect found the newly-created `com.grayline.wander` app record.
- Apple package analysis passed.
- Upload reached 100% and completed successfully.
- Final Xcode output: `Uploaded Wander`.
- Current state: build uploaded to App Store Connect and is processing before it can be used in TestFlight.

## 2026-06-04 17:49 PDT - Codex - M4 Fixture Opt-In Start

Agent: Codex
Branch: `main`
Starting commit: `ac9850d`
Starting status: local `main` matches `origin/main`.

Goal: start M4 by removing seeded demo people/places from default app launches. Joe confirmed TestFlight sign-in works, but external testers should not see Joe/Maya/Ryan/Woodcat fixture data unless a demo/test mode is explicitly requested.

Expected files to touch:

- `Wander/Services/WanderFixtures.swift`
- `Wander/Services/WanderLocalStore.swift`
- `Wander/Services/Auth/AuthSessionProviding.swift`
- `Wander/Services/Auth/ClerkAuthService.swift`
- `Wander/App/WanderRootView.swift`
- `WanderTests/NavigationContractTests.swift`
- `WanderTests/WanderStoreTests.swift`
- `docs/agent-log.md`

Plan:

- Add an empty/default fixture set with a generic local profile.
- Keep the existing seeded fixture set for tests and screenshots.
- Make `WanderRootView` choose fixtures from a launch argument; default to empty.
- Add a launch flag for seeded demo fixtures.
- Sync the local current profile shell from the authenticated Clerk session when present.

Completion checkpoint:

- Added `WanderFixtures.empty()` and changed `WanderRootView` to use empty fixtures by default.
- Preserved seeded Joe/Maya/Ryan fixture data behind the explicit `-WanderUseDemoFixtures` launch argument for screenshots/local demos/tests, and prevented auth refresh from overwriting seeded demo mode.
- Added session email to `AuthSession` and mapped Clerk `primaryEmailAddress` into the local profile shell.
- Added `WanderStore.apply(authState:)` so signed-in users see a local profile derived from the Clerk session instead of fixture Joe, and signed-out/default launches stay generic.
- Added tests for default-empty fixture mode, explicit demo-fixture mode, empty local stores, and signed-in profile-shell hydration.
- First sandboxed test run failed on CoreSimulator/SwiftPM cache permissions only.
- Elevated test run found one test compile issue (`VisiblePlace` is not `Equatable`); changed that assertion to `isEmpty`.
- Reran full test suite:
  `xcodebuild -quiet test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Result: passed.
- Bumped `CURRENT_PROJECT_VERSION` from `1` to `2` in `project.yml` and regenerated `Wander.xcodeproj` with `xcodegen generate`.
- Reran the full test suite after regeneration; result: passed.
- Built signed archive:
  `/private/tmp/Wander-0.1-build2.xcarchive`
- Result: archive succeeded.
- First `xcodebuild -exportArchive` upload attempt failed before packaging with `Failed to Use Accounts`; distribution logs said Xcode could not find App Store Connect access for team `Y7TVK75RZ8`.
- Retried export/upload with the local App Store Connect API key via `-authenticationKeyPath`, `-authenticationKeyID`, and `-authenticationKeyIssuerID`.
- Result: App Store Connect analysis passed, upload reached 100%, and Xcode output ended with `Uploaded Wander`.
- Made one follow-up root-flow correction so demo fixture mode stays stable after signed-out auth refresh.
- Bumped `CURRENT_PROJECT_VERSION` from `2` to `3`, regenerated `Wander.xcodeproj`, and reran the full test suite; result: passed.
- Built signed archive:
  `/private/tmp/Wander-0.1-build3.xcarchive`
- Uploaded build `0.1 (3)` through `xcodebuild -exportArchive` with the App Store Connect API key.
- Result: App Store Connect analysis passed, upload reached 100%, and Xcode output ended with `Uploaded Wander`.
- Current state: build `0.1 (3)` is uploaded and processing in App Store Connect. This build should remove fake seeded people/places from default/TestFlight launches while keeping sign-in available.

## 2026-06-04 18:19 PDT - Codex - M4 QA Pass Start

Agent: Codex
Branch: `main`
Starting commit: `2261cd4`
Starting status: local `main` matches `origin/main`.

Goal: run the M4 QA pass after Joe confirmed the first TestFlight smoke and M4 remote-sync slice are done.

Mission Control: `http://localhost:4000/api/tasks` is unreachable from this session, so this log is the active coordination record.

Expected files to touch:

- `docs/agent-log.md`
- `docs/roadmap.md`
- `Wander/Features/Map/MapScreen.swift`
- `project.yml`
- `Wander.xcodeproj/project.pbxproj`
- `docs/setup.md`
- possible small QA fixes if checks expose a concrete bug

QA scope:

- Fresh signed-out install behavior.
- New signed-in account behavior.
- Existing signed-in account behavior.
- Sign out and sign back in behavior.
- Build/test status and whether a new TestFlight upload is needed.

Checkpoint:

- Ran full Xcode test suite. First sandboxed run failed on CoreSimulator/SwiftPM cache permissions only. Elevated run passed:
  `xcodebuild -quiet test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Installed and launched the debug build on the previously-used iPhone 17 Pro simulator. It showed `JL`, but that simulator had a prior Clerk/keychain session, so it represented an existing-session path rather than true first-run.
- Created a temporary clean simulator `Wander-M4-QA` (`4252EC90-35A5-4018-82AA-4BFEBAD0289B`) to verify true first-run behavior.
- Clean first-run initially showed `JL` in the map search avatar even with no session. Root cause: `Wander/Features/Map/MapScreen.swift` hardcoded `WanderAvatar(initials: "JL", ...)`.
- Fixed the map search avatar to use `store.currentUser.initials`. On clean first-run it now shows generic `Y` from the default `You` profile and no seeded Joe/Maya/Ryan/Woodcat place content.
- Reran the full Xcode test suite after the avatar fix; result: passed.
- QA blocker found: direct signed-in own-place remote save is still not implemented in `SupabaseUserPlaceRepository.save(_:)` (`notImplemented("direct user place save RPC")`). Current remote wiring covers visible places, profile search, follow/unfollow, block/unblock, and social save, but not direct add/save to Supabase.

Completion checkpoint:

- Updated `docs/roadmap.md` to mark M3 as done baseline and M4 as in QA/blocked on direct signed-in own-place save.
- Bumped `CURRENT_PROJECT_VERSION` from `3` to `4` and regenerated `Wander.xcodeproj`.
- Reran full Xcode test suite after regeneration:
  `xcodebuild -quiet test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Result: passed.
- Built signed archive:
  `/private/tmp/Wander-0.1-build4.xcarchive`
- Uploaded build `0.1 (4)` through `xcodebuild -exportArchive` with the App Store Connect API key.
- Result: App Store Connect analysis passed, upload reached 100%, and Xcode output ended with `Uploaded Wander`.
- Current state: build `0.1 (4)` is uploaded and processing in App Store Connect. It includes the clean first-run avatar fix, but M4 QA is not green until direct signed-in own-place save is implemented and retested.

## 2026-06-04 18:49 PDT - Codex - M4 Direct Own-Place Save Start

Agent: Codex
Branch: `main`
Starting commit: `436488d`
Starting status: local `main` matches `origin/main`.

Goal: close the M4 QA blocker by implementing direct signed-in own-place save to Supabase for current-location/manual add.

Mission Control: `http://localhost:4000/api/tasks` is still unreachable from this session, so this log is the active coordination record.

Expected files to touch:

- `supabase/migrations/*_save_own_place.sql`
- `Wander/Services/RepositoryProtocols.swift`
- `Wander/Services/Remote/SupabaseRepositories.swift`
- `Wander/Services/WanderLocalStore.swift`
- `Wander/Features/Add/AddScreen.swift`
- `WanderTests/RemoteRepositoryTests.swift`
- `WanderTests/WanderStoreTests.swift`
- `docs/agent-log.md`
- `docs/roadmap.md`
- `docs/setup.md`
- `project.yml`
- `Wander.xcodeproj/project.pbxproj`

Plan:

- Add a Supabase RPC for upserting a canonical place, current user's user_place row, and flexible question attributes.
- Add the public PostgREST wrapper and grants.
- Implement `SupabaseUserPlaceRepository.save(_:)`.
- Wire signed-in Add flow to local-first save, then remote save with synced/failed local state.
- Add contract tests for request shape and local success/failure fallback.
- Run full tests, apply hosted migration if possible, then upload a new TestFlight build.

Checkpoint:

- Added migration `20260604185000_save_own_place.sql` with `app.save_own_place` plus public PostgREST wrapper.
- Wired signed-in current-location/manual Add saves through local-first store save, `WanderBackend.saveUserPlace`, and `SupabaseUserPlaceRepository.save(_:)`.
- Added tests for `save_own_place` RPC body shape and local success/failure sync marking.
- Applied the hosted Supabase migration with `npx supabase db push --linked`; Supabase finished the migration successfully.
- Ran the full Xcode test suite after the direct-save changes:
  `xcodebuild -quiet test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Result: passed.
- Updated M4 docs to show direct-save is no longer the blocker; build `0.1 (5)` is the next TestFlight QA candidate.

Completion checkpoint:

- Bumped `CURRENT_PROJECT_VERSION` from `4` to `5` in `project.yml` and regenerated `Wander.xcodeproj` with `xcodegen generate`.
- Reran the full Xcode test suite after regeneration:
  `xcodebuild -quiet test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Result: passed.
- Built signed archive:
  `/private/tmp/Wander-0.1-build5.xcarchive`
- Uploaded build `0.1 (5)` through `xcodebuild -exportArchive` with the App Store Connect API key.
- Result: App Store Connect analysis passed, upload reached 90%, and Xcode output ended with `Uploaded Wander`.
- Current state: build `0.1 (5)` is uploaded and processing in App Store Connect. Next step is Joe device-smoke testing direct current-location/manual save on TestFlight after processing completes.

## 2026-06-05 09:47 PDT - Codex - Public TestFlight Link Setup

Agent: Codex
Branch: `main`
Starting commit: `89e22bd`
Starting status: local `main` matches `origin/main`.

Goal: create/find the public TestFlight share link for Wander.

Actions:

- Queried App Store Connect for app bundle `com.grayline.wander`; app id is `6776850787`, name is `Wander: Find Places`.
- Initial TestFlight beta group query returned no groups.
- Created external beta group `Wander Alpha` with public link enabled, feedback enabled, and 100-tester cap.
- Public link created: `https://testflight.apple.com/join/knEhRa6t`.
- Attempted to attach build `0.1 (5)` (`7fdc7c41-12e6-40ff-88cd-3348e2942c88`) to the group.
- App Store Connect rejected the build attach with `Build is not assignable` / `Build is not in an externally assignable state.`
- Follow-up query showed build `0.1 (5)` is `VALID`, but `usesNonExemptEncryption` is still null and beta app review contact fields are empty.

Current state:

- Public link exists, but it may show no available build until App Store Connect beta review/export compliance is completed and build `0.1 (5)` is attached to `Wander Alpha`.

## 2026-06-05 09:54 PDT - Codex - Attach Build 5 To Public TestFlight

Agent: Codex
Branch: `main`
Starting commit: `638e99a`
Starting status: local `main` matches `origin/main`.

Goal: get the latest build onto the public TestFlight link and handle export compliance if possible.

Actions:

- Attempted to patch build `0.1 (5)` export compliance to `usesNonExemptEncryption=false`; Apple returned that the value was already set and cannot be updated.
- Re-queried build `0.1 (5)` and confirmed `usesNonExemptEncryption=false`.
- Retried attaching build `0.1 (5)` (`7fdc7c41-12e6-40ff-88cd-3348e2942c88`) to external group `Wander Alpha`.
- App Store Connect accepted the attach.
- Final read-back showed public link enabled, cap 100, feedback enabled, and build `0.1 (5)` attached.
- Verified `https://testflight.apple.com/join/knEhRa6t` responds with HTTP 200.

Current state:

- Public TestFlight link is live: `https://testflight.apple.com/join/knEhRa6t`
- Attached build: `0.1 (5)`
- Export compliance: `usesNonExemptEncryption=false`

## 2026-06-05 15:03 PDT - Codex - TestFlight Link Not Accepting Testers

Agent: Codex
Branch: `main`
Starting commit: `4bf3c3f`
Starting status: local `main` matches `origin/main`.

Goal: investigate Joe seeing "not accepting new testers" on the public TestFlight link and open the link to anyone if App Store Connect allows it.

Plan:

- Query current `Wander Alpha` beta group settings, cap, public link state, and attached builds.
- Remove or raise the public-link cap if it is limiting joins.
- If group settings are already open, identify whether Apple beta review or build external availability is the remaining blocker.

Actions:

- Queried `Wander Alpha`; public link was enabled, build `0.1 (5)` was attached, export compliance was `usesNonExemptEncryption=false`, and the group still had `publicLinkLimitEnabled=true` with limit 100.
- Queried beta review submission for build `0.1 (5)`; Apple reports `betaReviewState=WAITING_FOR_REVIEW`, submitted `2026-06-05T09:53:38-07:00`.
- Patched `Wander Alpha` to keep public link enabled, keep feedback enabled, and set `publicLinkLimitEnabled=false`.
- App Store Connect accepted the patch. Read-back confirms `publicLinkLimitEnabled=false`, public link still `https://testflight.apple.com/join/knEhRa6t`, and build `0.1 (5)` remains attached.

Current state:

- Anyone with the link can join once Apple approves external TestFlight review.
- The remaining blocker is not group settings; it is Apple beta review pending for build `0.1 (5)`.

## 2026-06-05 20:49 PDT - Codex - M5 Add Capture Feedback Logged

Agent: Codex
Branch: `main`
Starting commit: `783c765`
Starting status: local `main` matches `origin/main`.

Goal: log Joe's TestFlight feedback and transition from M4 into M5.

Context:

- Joe confirmed sign-in is working and said to move to M5.
- Add flow feedback from TestFlight:
  - No back button once the user starts adding a place.
  - Title should be `add a place`.
  - Remove `where's it from` and `pick a source`; the app should feel like it will fill in what it can.
  - `I'm here now` needs a real location permission ask and nearby-place resolution.
  - Current build still returns deterministic `Maru Coffee`, which is not acceptable for M5.
  - Manual add should resolve real place candidates.
  - Paste link and photo add are still not real extraction.
  - Need clarity that LLM is for parsing/extraction hints, while canonical place identity/coordinates should come from MapKit/place-provider search.

Actions:

- Updated `docs/roadmap.md` to mark M4 as done baseline and M5 as in progress.
- Updated `docs/open-questions.md` with explicit M5 Add capture notes for navigation, copy, location, manual resolution, link extraction, and photo extraction.

## 2026-06-05 20:57 PDT - Codex - M5 Add UX And Place Resolution Start

Agent: Codex
Branch: `main`
Starting commit: `3d0c59a`
Starting status: local `main` matches `origin/main`.

Goal: implement the first M5 Add slice: clean Add copy/navigation, remove fake current-location/manual place candidates, and resolve candidates through real iOS location/place search services.

Expected files to touch:

- `Wander/Features/Add/AddScreen.swift`
- `Wander/Services/WanderLocalStore.swift`
- `Wander/Services/RepositoryProtocols.swift`
- new service files under `Wander/Services/`
- `project.yml`
- `Wander.xcodeproj/project.pbxproj`
- focused tests under `WanderTests/`
- `docs/agent-log.md`

Plan:

- Add back navigation/escape behavior inside Add after leaving the source state.
- Update Add title/copy to `add a place` and remove the confusing source-picker wording.
- Replace store-level fake candidate methods with async resolution through a place resolver.
- Implement current-location permission + nearby MapKit search for `I'm here now`.
- Implement manual MapKit search using name, area hint, and category hints.
- Keep link/photo as honest unresolved-draft shells until backend extraction jobs are built.

Checkpoint:

- Added `PlaceCandidateResolving` and `MapKitPlaceResolver`.
- `MapKitPlaceResolver` uses CoreLocation one-shot permission/location plus MapKit nearby POI search for `I'm here right now`.
- Manual add now resolves candidates through MapKit local search instead of fabricating a downtown LA candidate.
- `PlaceCandidate` now carries address/locality/region/country/provider metadata; local save preserves those fields.
- Add UI now uses stable title `add a place`, has an in-flow back button, removes `where's it from`/`pick a source` copy, and shows async resolving/error states.
- Added `NSLocationWhenInUseUsageDescription` through `project.yml` and regenerated `Wander.xcodeproj`.
- Added resolver-boundary tests and updated current-location save metadata coverage.
- Full Xcode test suite passed:
  `xcodebuild -quiet test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Bumped `CURRENT_PROJECT_VERSION` from `5` to `6`; build `0.1 (6)` is the next TestFlight candidate for this M5 Add slice.

Completion checkpoint:

- Regenerated `Wander.xcodeproj` after the build-number bump.
- Reran the full Xcode test suite after regeneration:
  `xcodebuild -quiet test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Result: passed.
- Built signed archive:
  `/private/tmp/Wander-0.1-build6.xcarchive`
- Uploaded build `0.1 (6)` through `xcodebuild -exportArchive` with the App Store Connect API key.
- Result: App Store Connect analysis passed, upload succeeded, and Xcode output ended with `Uploaded Wander`.
- App Store Connect build id for `0.1 (6)`: `7c34953e-f7ca-444b-93e2-413572c9b4c1`.
- Set export compliance to `usesNonExemptEncryption=false`.
- Attached build `0.1 (6)` to external group `Wander Alpha`.
- Submitted build `0.1 (6)` for external TestFlight review; Apple reports `betaReviewState=WAITING_FOR_REVIEW`.

Handoff checkpoint, 2026-06-05 21:12 PDT:

- Mission Control task update attempted with `curl -s http://localhost:4000/api/tasks`; local server was not reachable (`curl` exit 7), so this repo log is the active coordination surface for this work.
- Cleanup after review: Add source actions now clear stale resolution messages when switching to link/manual/photo.
- Current remaining M5 scope after this commit: real link extraction, photo extraction/capture, richer detail questions, and backend job plumbing. This slice only replaces fake current-location/manual candidates and cleans the first Add surface/navigation.

Final checkpoint, 2026-06-05 21:16 PDT:

- Implementation commit: `e082b63 feat: resolve add place candidates`; pushed to `origin/main`.
- Verified local `main` and `origin/main` matched `e082b63d022a04b6e3567acb5fd78efda04c8457` after push.
- Rechecked App Store Connect after upload: build `0.1 (6)` external TestFlight review is `APPROVED`.

## 2026-06-05 22:41 PDT - Codex - M5 Link Capture Candidate Flow

Agent: Codex
Branch: `main`
Starting commit: `d563730`
Starting status: local `main` matches `origin/main`; worktree clean.

Goal: continue M5 by turning paste-link Add from an immediate draft shell into a real candidate-resolution flow for map/location links, while preserving draft fallback for opaque or low-confidence links.

Expected files to touch:

- `Wander/Features/Add/AddScreen.swift`
- `Wander/Services/RepositoryProtocols.swift`
- `Wander/Services/WanderLocalStore.swift`
- new service/parser files under `Wander/Services/`
- focused tests under `WanderTests/`
- `project.yml` / `Wander.xcodeproj/project.pbxproj` if new source files require regeneration
- `docs/agent-log.md`

Plan:

- Add a link-entry step in Add instead of creating a draft immediately.
- Parse obvious place hints from Google Maps, Apple Maps, and Instagram location URLs.
- Resolve parsed hints through MapKit candidate search and require confirmation before save.
- If parsing/resolution fails, keep a draft and offer manual rescue.
- Leave backend extraction jobs and photo import/extraction as the next M5 slices.

Notes:

- Mission Control was checked with `curl -s http://localhost:4000/api/tasks`; it is still unreachable locally (`curl` exit 7), so this repo log remains the coordination record.

Checkpoint:

- Added `LinkPlaceInput` and `PlaceCandidateResolving.resolveLink`.
- Added `LinkPlaceParser` for deterministic local hints from Google Maps place paths, Apple Maps query links, Instagram location slugs, and plain text.
- Added Add `link` step with paste field, `find from link`, and explicit `save as draft` fallback.
- Link candidates now flow through MapKit search and reuse the existing confirm/details/save path with `sourceType = link`.
- Opaque/short links still become drafts instead of fake candidates.
- Added parser tests and store boundary tests.
- Ran full test suite after new files and again after build-number regeneration:
  `xcodebuild -quiet test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Result: passed both runs.
- Bumped `CURRENT_PROJECT_VERSION` to `7`, archived `/private/tmp/Wander-0.1-build7.xcarchive`, and uploaded build `0.1 (7)` with `xcodebuild -exportArchive`.
- Upload succeeded and App Store Connect reported `Uploaded Wander`; immediate API polls had not yet surfaced build `7`, so export compliance/public-group attachment remains pending until Apple indexes the build.
- Follow-up App Store Connect poll surfaced build `0.1 (7)` as build id `e7e0991e-bf35-4004-8a80-7bc6eef6e1e2`, processing state `VALID`.
- Set export compliance to `usesNonExemptEncryption=false`, attached build `0.1 (7)` to public group `Wander Alpha`, and submitted it for external TestFlight review.
- Apple reports build `0.1 (7)` beta review state `WAITING_FOR_REVIEW`.
- Final App Store Connect check after push: build `0.1 (7)` is `VALID`, `usesNonExemptEncryption=false`, and external beta review state is `APPROVED`.

## 2026-06-05 23:06 PDT - Codex - M5 Shared Test Checkpoint

Agent: Codex
Branch: `main`
Starting commit: `0bbc43b`
Starting status: local `main` matches `origin/main`; worktree clean.

Goal: continue through the remaining M5 work until there is a strong TestFlight checkpoint for Joe and external testers.

Plan:

- Keep backend extraction workers out of this slice because the eng plan marks backend extraction as M6.
- Add a real Add-photo import path using PhotosUI that creates local source-artifact/extraction-job state and a visible draft, instead of a dead source row.
- Add visible parsed Discover filter chips and strengthen the cheap/swappable parser boundary without sending user graph/place/contact data to an external model from the client.
- Add an analytics/event interface and cover it with focused tests/mocks, not a vendor SDK.
- Run full Xcode tests, upload a new TestFlight build, and provide a focused tester script.

Notes:

- Mission Control is still unreachable on `localhost:4000` (`curl` exit 7), so this repo log remains the coordination surface.

Checkpoint:

- Added local source-artifact and extraction-job creation for link/photo unresolved drafts. Backend execution remains M6; this M5 slice creates durable local artifact/job state and keeps draft/manual rescue visible.
- Added PhotosUI photo import in Add. Imported photos create a photo draft plus local image source artifact and pending extraction job; no fake AI candidate is shown.
- Added visible parsed Discover filter chips below the search field.
- Strengthened deterministic parser coverage for category aliases, tags, area, status, relationships, cache, and parser failure fallback behind the existing `LLMFilterParser` protocol.
- Wired parser analytics through the existing `AnalyticsClient` abstraction for `discover_query_parsed`, `discover_parse_failed`, `place_saved`, and `extraction_job_started`.
- Added tests for photo/link draft artifacts, idempotent artifact/job creation, Discover chips, parser cache, parser failure, and analytics events.
- Ran full test suite before and after the build number bump:
  `xcodebuild -quiet test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Result: passed both runs.
- Bumped `CURRENT_PROJECT_VERSION` to `8`, archived `/private/tmp/Wander-0.1-build8.xcarchive`, and uploaded build `0.1 (8)` with `xcodebuild -exportArchive`.
- App Store Connect build id for `0.1 (8)`: `0c4f9998-4f74-4491-9811-5a2e885c2677`; processing state `VALID`.
- Set export compliance to `usesNonExemptEncryption=false`, attached build `0.1 (8)` to public group `Wander Alpha`, and submitted it for external TestFlight review.
- Apple currently reports build `0.1 (8)` beta review state `WAITING_FOR_REVIEW`.
