# Decisions

Last updated: 2026-06-01

Durable product and engineering decisions for Wander. See the product spec and engineering plan for fuller rationale.

## Product Decisions

| Decision | Status | Notes |
|---|---|---|
| Map-first app | Locked | The map is the primary memory and discovery surface. |
| No manual lists | Locked | Lists were explicitly removed from product direction. |
| Trusted people, not strangers | Locked | Discovery should come from people the user follows/knows. |
| Cross-category places | Locked | Not restaurant-only; coffee, hikes, bars, parks, restaurants, etc. |
| No live location | Locked | Current location is for nearby place resolution, not broadcasting. |
| No gamified check-ins | Locked | Avoid mayorships, streaks, leaderboards, and public check-in framing. |
| Four bottom tabs | Locked | Map, Add, Discover, Profile. |
| Settings from Profile gear | Locked | Do not add Settings as a fifth tab. |
| Profile merges self memory and social profile | Locked | Owner and other-user profile states share the same conceptual surface. |
| Follow graph, not friend requests | Locked | One-way follows; mutual follows are friends. |
| Public/private copy | Locked | UI says Everyone/Friends/Self; data stores `followers`/`mutuals`/`self`. |
| Block behavior | Locked | Hard block; remove follow edges and hide profiles/content both ways. |
| People finding | Locked for v0.1 | Username search plus contacts-shaped UI. Native Contacts later. |
| Following not-yet-on-app users | Deferred | Track later; not in v0.1. |

## Technical Decisions

| Decision | Status | Notes |
|---|---|---|
| Native iOS | Locked | SwiftUI, iOS 17+, iPhone-first. |
| XcodeGen | Locked | `project.yml` is source of truth. |
| Clerk + Supabase | Locked | Clerk for identity/account, Supabase for data/RLS/PostGIS/storage/functions. |
| SwiftData local-first | Locked | Local cache, guest-local records, sync queue. |
| MapKit-only v0.1 | Locked | Keep provider-extensible place IDs. |
| Supabase RLS authoritative | Locked | Client policy is for UI behavior only. |
| Repository/protocol boundaries | Locked | Views should not call Clerk/Supabase directly. |
| Backend extraction jobs | Locked | Link/photo extraction should run on backend, not fake client-only extraction. |
| M2 extraction shells | Locked | Link/photo create unresolved drafts until backend jobs exist. |
| Discover parser interface early | Locked | Deterministic local parser now; cheap swappable LLM parser in M5. |
| LLM data minimization | Locked | Send raw query phrase + schema only, not graph/place/contact/user data. |
| Share extension | Deferred | Build after in-app add/map/social loop works. |
| Native Contacts | Planned later | Use `FakeContactProvider` in M2/v0.1 baseline. |
| Analytics provider | Deferred | Define vendor-neutral event interface first. |
| Sync conflict behavior | Locked v0.1 | Simple `updated_at`/server-wins plus local retry queue. |
| Full onboarding | Deferred | Auth gates at save/sync/follow/social-save intents still required. |

## Design Decisions

| Decision | Status | Notes |
|---|---|---|
| Handoff package is source of truth | Locked | Use `preview/follow-profile-settings-mocks/`. |
| `tokens.css` is canonical | Locked | Promote token values 1:1 into SwiftUI. |
| Warm utility map style | Locked | Cream/sand/espresso/terracotta/sky with useful map-first UI. |
| No competing visual direction | Locked unless Joe asks | Do not generate new variants as implementation blockers. |
| System fonts temporarily | Locked | Funnel Display/Sans direction is tokenized; add font assets when packaging/licensing is clean. |
| SF Symbols/native controls | Locked | Use native symbols instead of mock emoji chrome for structural UI. |
| iPhone-first visual QA | Locked | Verify real simulator screenshots before calling UI accepted. |

## Reset Decisions

| Decision | Date | Notes |
|---|---|---|
| Revert low-pass implementation | 2026-06-01 | Joe moved reasoning to very high and requested an audit/reset. |
| Add M1.5 contract lock before M2 | 2026-06-01 | Prevent fixture UI from becoming accidental architecture. |
| Run refreshed design review | 2026-06-01 | Completed clean; score 8/10 to 9/10. |
| M2 local product loop pushed | 2026-06-01 | Commit `962efce`, 18 tests passing, visual QA still pending. |
| Add agent work log protocol | 2026-06-01 | All agents must update `docs/agent-log.md` before, during, and after non-trivial work. |
