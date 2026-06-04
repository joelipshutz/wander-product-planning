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
