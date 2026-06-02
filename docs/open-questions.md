# Open Questions

Last updated: 2026-06-02

These are the known unresolved questions and risks. Some are intentionally deferred; do not reopen locked decisions unless Joe asks.

## Needs Answer Before M2 Is Accepted

| Question | Recommendation | Notes |
|---|---|---|
| What exact native layout should replace the oversized/letterboxed Map screen? | Fix in SwiftUI against simulator screenshots, using the handoff as visual direction but native scale/safe areas. | Active bug from 2026-06-01 screenshot. |
| Which iPhone sizes are required for visual QA? | Current simulator target plus one smaller iPhone. | Current failing screenshot is iPhone 17 Pro/iOS 26.2 simulator. |
| Should Add/Discover/Profile/Settings be visually reworked in the same pass as Map? | Start with Map/root layout, then sweep other screens after the root scale is fixed. | Map exposes the worst layout/orientation failure. |

## Needs Answer Before M3

| Question | Recommendation | Notes |
|---|---|---|
| Exact Clerk/Supabase dashboard config values? | Use native Clerk third-party auth integration, with Clerk session token `role=authenticated` and user ownership from `auth.jwt()->>'sub'`. | Claim mapping is now resolved in M3; remaining work is project-specific domain/provider setup. |
| Where does profile mirroring happen? | Backend webhook from Clerk into Supabase `profiles`. | Needs migration/function plan. |
| How are Supabase RLS policies tested? | Use repo SQL tests in `supabase/tests/`; run once Supabase CLI/Postgres test runner is installed. | RLS is authoritative for privacy. Local CLI is not installed yet. |
| Do we create Supabase migrations in this repo? | Yes. | M3 migration started under `supabase/migrations/`; revisit only if Joe creates a backend repo split. |
| Which analytics provider? | Keep vendor-neutral interface; choose provider later. | PostHog is likely but not locked. |

## Needs Answer Before M5

| Question | Recommendation | Notes |
|---|---|---|
| Which cheap LLM path parses Discover queries? | Use a cheap/swappable model behind `LLMFilterParser`. | Send only raw phrase + allowed filter schema. |
| What extraction providers are used for link/photo/social saves? | Evaluate Slate extraction first, then implement backend job lanes. | Known gaps: Instagram and location extraction are weak in Slate today. |
| What confidence and fallback UX should extraction use? | Keep candidate confirmation and manual rescue mandatory. | Never pretend extraction worked if confidence is low. |

## Deferred Product Questions

| Question | Recommendation | Notes |
|---|---|---|
| Native Contacts permission timing? | Later, after core loop and backend matching/privacy copy are ready. | M2 uses `FakeContactProvider`. |
| Share extension timing? | Later, after in-app add/map/social loop works. | Share extension can be a capture booster but should not block v0.1. |
| Private profiles/follow requests? | Defer. | v0.1 follow graph is open one-way follows with visibility per place. |
| Following users not on Wander yet? | Defer. | Needs invite/link/contact matching model. |
| Full onboarding? | Defer implementation; keep auth gates in critical flows. | Onboarding research exists under `research/screensdesign/`. |
| iPad layout? | Defer. | Later use map + side panel, not stretched iPhone UI. |

## Operational Risks

- Visual quality can regress if implementation copies HTML mock dimensions literally instead of adapting to native iPhone screens.
- Xcode project signing settings may churn when opened locally. Keep `project.yml` source-of-truth and avoid committing incidental signing changes.
- RLS mistakes are high-risk because privacy is part of the product wedge.
- Fake local visibility must not be treated as security. Supabase policy tests are required.
- Link/photo/social extraction is a moat only if it reduces capture work; it is not the first product wedge by itself.
