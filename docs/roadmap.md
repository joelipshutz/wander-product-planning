# Roadmap

Last updated: 2026-06-08

This is the durable milestone view. The detailed source plan is `docs/plans/2026-06-01-wander-ios-eng-plan.md`.

## Current Status

M2 local product loop and visual pass are good enough for TestFlight iteration. M3 Clerk + Supabase foundation is in place: hosted schema/RLS/profile mirroring and iOS auth wiring are working. M4 is accepted enough to move on: sign-in works, TestFlight is live, export compliance is set, external review is approved, and the direct signed-in own-place save path is wired. M5 Add UX/current-location/manual resolution is accepted enough to proceed. M6 is now in progress: signed-in link/photo drafts enqueue durable Supabase extraction jobs, while actual provider/OCR/LLM job execution remains next.

## Milestones

| Milestone | Status | Goal | Notes |
|---|---|---|---|
| M0 Repo and project bootstrap | Done | Runnable native iOS foundation. | SwiftUI app shell, four tabs, XcodeGen, token layer, tests. |
| M1 Local data and repository contracts | Done baseline | Model/service boundaries before UI logic spreads. | Local models, repository protocols, parser/provider contracts, sync state tests. |
| M1.5 Contract lock | Done baseline | Freeze schema/RLS/local/UI contracts before M2. | See `docs/plans/2026-06-01-wander-m1-5-contract-lock.md`. |
| M2 Core local product loop | Done baseline | Validate map/add/discover/profile/settings loop before backend. | Native UI has moved into TestFlight iteration. |
| M3 Clerk + Supabase foundation | Done baseline | Real identity, schema, RLS, and policy tests. | Supabase/Clerk projects created, hosted tests passed, profile mirroring and iOS sign-in smoke passed. |
| M4 Sync and remote repositories | Done baseline | Replace local-only store paths with local-first remote sync. | Remote visible places/profile search/follow/block/social-save/direct-own-save paths are wired. Public TestFlight is approved for external testers. |
| M5 Extraction and smart Discover | Accepted baseline | Make Add capture real and add cheap LLM parsing where it helps. | Add UX/navigation, current-location, manual place resolution, and map search scope were cleaned up for TestFlight; provider-backed link/photo extraction moves into M6. |
| M6 Backend extraction and alpha readiness | In progress | End-to-end alpha loop and provider-safe extraction foundation. | First slice enqueues signed-in link/photo extraction jobs in Supabase and improves nearby candidate ranking. Provider workers, OCR/LLM execution, analytics, privacy copy, onboarding/auth gates, and performance remain. |

## Immediate Next Steps

1. Ship Build 12 with Add redundant navigation removed, Map search scoped to saved/network places, improved current-location candidate ranking, and signed-in extraction job enqueue.
2. Build the M6 backend worker that consumes `extraction_jobs`, runs the correct provider adapter, writes extracted candidates, and never auto-saves low-confidence results.
3. Add provider adapters in order of expected alpha value: Google Maps links, generic web metadata, photo OCR/Vision, then TikTok/Instagram fallbacks.
4. Add cheap/swappable LLM parsing where it improves manual/Discover query interpretation without becoming the source of truth for canonical place identity.
5. Add alpha readiness basics: analytics events, privacy copy, onboarding/auth gates, performance pass, and final QA checklist.

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
- Backend extraction job workers and real photo/link extraction providers.
- Multi-device conflict resolution beyond simple server-wins/retry queue.
- iPad side-panel layout.
