# Roadmap

Last updated: 2026-06-01

This is the durable milestone view. The detailed source plan is `docs/plans/2026-06-01-wander-ios-eng-plan.md`.

## Current Status

M2 local product loop is implemented and test-green on `main`, but visual QA failed on the first simulator screenshot. Treat M2 as functionally landed and visually not accepted.

## Milestones

| Milestone | Status | Goal | Notes |
|---|---|---|---|
| M0 Repo and project bootstrap | Done | Runnable native iOS foundation. | SwiftUI app shell, four tabs, XcodeGen, token layer, tests. |
| M1 Local data and repository contracts | Done baseline | Model/service boundaries before UI logic spreads. | Local models, repository protocols, parser/provider contracts, sync state tests. |
| M1.5 Contract lock | Done baseline | Freeze schema/RLS/local/UI contracts before M2. | See `docs/plans/2026-06-01-wander-m1-5-contract-lock.md`. |
| M2 Core local product loop | Code complete, visual QA failing | Validate map/add/discover/profile/settings loop before backend. | Commit `962efce`; 18 tests pass. Needs visual polish and simulator screenshots. |
| M3 Clerk + Supabase foundation | Next after M2 visual acceptance | Real identity, schema, RLS, and policy tests. | Build schema/RLS first, then Clerk iOS wiring. |
| M4 Sync and remote repositories | Planned | Replace local-only store paths with local-first remote sync. | SwiftData cache, sync queue, conflict handling, retry/error states. |
| M5 Extraction and smart Discover | Planned | Backend extraction jobs and cheap LLM query parser. | Link/photo become real extraction lanes; LLM parser sends only raw phrase + schema. |
| M6 Alpha readiness | Planned | End-to-end alpha loop and App Store/private beta prep. | QA, analytics, privacy copy, onboarding/auth gates, performance. |

## Immediate Next Steps

1. Fix the Map screen visual failure from the simulator screenshot.
2. Verify root layout uses the full simulator screen and safe areas correctly.
3. Re-scale search, chips, bottom sheet, and tab bar.
4. Capture simulator screenshots for Map/Add/Discover/Profile/Settings.
5. Commit and push the visual QA fix.
6. Start M3 schema/RLS only after Joe accepts the native UI direction.

## M2 Acceptance Criteria

Functional:

- Guest can save a first place locally.
- Current-location and manual add are real local saves.
- Link/photo create unresolved drafts and do not fake extraction.
- User can follow, unfollow, block, and unblock seeded users.
- Visibility changes affect visible social content.
- Username search and fake contact results work.
- Discover smart filters are deterministic and local.

Visual:

- Map fills the full phone viewport and feels native.
- Top controls, chips, selected place sheet, and tab bar do not crowd each other.
- Safe areas and home indicator are respected.
- Text fits inside controls on current and smaller iPhone targets.
- Warm handoff style from `preview/follow-profile-settings-mocks/` is preserved without oversized mock chrome.

Testing:

- `xcodebuild test` passes.
- Simulator screenshots captured for at least the active target and one smaller phone.

## Later Backlog

- Native Contacts permission and backend hashed matching.
- Share extension.
- Private profiles/follow requests.
- Full onboarding implementation.
- Real photo/link extraction providers.
- Multi-device conflict resolution beyond simple server-wins/retry queue.
- iPad side-panel layout.
