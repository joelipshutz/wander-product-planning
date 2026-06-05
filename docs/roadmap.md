# Roadmap

Last updated: 2026-06-04

This is the durable milestone view. The detailed source plan is `docs/plans/2026-06-01-wander-ios-eng-plan.md`.

## Current Status

M2 local product loop and visual pass are good enough for TestFlight iteration. M3 Clerk + Supabase foundation is in place: hosted schema/RLS/profile mirroring and iOS auth wiring are working. M4 is in QA: remote visible places/profile search/follow/block/social-save paths are wired, and direct signed-in own-place save now has a Supabase RPC plus iOS local-first sync path.

## Milestones

| Milestone | Status | Goal | Notes |
|---|---|---|---|
| M0 Repo and project bootstrap | Done | Runnable native iOS foundation. | SwiftUI app shell, four tabs, XcodeGen, token layer, tests. |
| M1 Local data and repository contracts | Done baseline | Model/service boundaries before UI logic spreads. | Local models, repository protocols, parser/provider contracts, sync state tests. |
| M1.5 Contract lock | Done baseline | Freeze schema/RLS/local/UI contracts before M2. | See `docs/plans/2026-06-01-wander-m1-5-contract-lock.md`. |
| M2 Core local product loop | Done baseline | Validate map/add/discover/profile/settings loop before backend. | Native UI has moved into TestFlight iteration. |
| M3 Clerk + Supabase foundation | Done baseline | Real identity, schema, RLS, and policy tests. | Supabase/Clerk projects created, hosted tests passed, profile mirroring and iOS sign-in smoke passed. |
| M4 Sync and remote repositories | In QA | Replace local-only store paths with local-first remote sync. | Remote visible places/profile search/follow/block/social-save/direct-own-save paths are wired. Needs TestFlight device QA on build `0.1 (5)`. |
| M5 Extraction and smart Discover | Planned | Backend extraction jobs and cheap LLM query parser. | Link/photo become real extraction lanes; LLM parser sends only raw phrase + schema. |
| M6 Alpha readiness | Planned | End-to-end alpha loop and App Store/private beta prep. | QA, analytics, privacy copy, onboarding/auth gates, performance. |

## Immediate Next Steps

1. Device-smoke TestFlight build `0.1 (5)` once it finishes App Store Connect processing.
2. Re-run M4 QA: clean first-run, new signed-in account, existing signed-in account, direct current-location/manual save, sign out/sign back in.
3. If build `0.1 (5)` passes, mark M4 accepted and move to M5 extraction/query-parser planning.

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
