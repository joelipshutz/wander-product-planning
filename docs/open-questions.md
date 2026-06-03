# Open Questions

Last updated: 2026-06-02

These are the known unresolved questions and risks. Some are intentionally deferred; do not reopen locked decisions unless Joe asks.

## Needs Answer Before M2 Is Accepted

| Question | Recommendation | Notes |
|---|---|---|
| What exact native layout should replace the oversized/letterboxed Map screen? | Fix in SwiftUI against simulator screenshots, using the handoff as visual direction but native scale/safe areas. | Active bug from 2026-06-01 screenshot. |
| Which iPhone sizes are required for visual QA? | Current simulator target plus one smaller iPhone. | Current failing screenshot is iPhone 17 Pro/iOS 26.2 simulator. |
| Should Add/Discover/Profile/Settings be visually reworked in the same pass as Map? | Start with Map/root layout, then sweep other screens after the root scale is fixed. | Map exposes the worst layout/orientation failure. |

## M3 Remaining Questions

| Question | Recommendation | Notes |
|---|---|---|
| Where does profile mirroring happen? | Resolved: backend webhook from Clerk/Svix into Supabase `profiles`. | Edge Function `clerk-profile-webhook` handles `user.created`, `user.updated`, and `user.deleted`. Real create/delete webhook path verified on 2026-06-02. |
| How are Supabase RLS policies tested going forward? | Keep repo SQL tests and run them through standard Supabase CLI once Docker is installed. Until then, use hosted Postgres plus a temporary `pg` runner. | Current hosted SQL tests passed: 29 pgTAP assertions, 0 failures. |
| Do we create Supabase migrations in this repo? | Yes. | New Supabase project exists and is linked; migrations `20260602131500`, `20260602140304`, `20260602143000`, and `20260602210000` are applied remotely. |
| Do hosted Supabase auth settings need review before alpha? | Yes. | `npx supabase config push` pushed generated local auth defaults plus Clerk config to the new dev project. Fine for M3, but review before alpha. |
| Does Clerk's default iOS token work for Supabase RLS? | Verify in live smoke before more sync work. | Swift currently calls `Clerk.shared.auth.getToken()` with no explicit template. Confirm Supabase accepts it and `auth.jwt()->>'sub'` equals the Clerk user id; if not, request the configured Supabase token template explicitly. |
| How should remote row attributes hydrate local UI? | Defer to the next remote data slice. | Current remote `attributes` decode but are not upserted into `placeAttributes`, so expanded map sheets/social-save copies may omit backend answers until hydration is implemented. |
| How should remote relationship/filter metadata hydrate local UI? | Push filters to RPC and/or return viewer relationship in DTO. | Current remote visible-place cache still applies some local relationship filtering, which can hide backend-authorized rows if local follow cache is stale. |
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
- App-facing Supabase RPCs must stay available through `public.*` wrappers unless `app` is explicitly added to exposed PostgREST schemas.
- Link/photo/social extraction is a moat only if it reduces capture work; it is not the first product wedge by itself.
- The Clerk CLI disposable-user test stored `username` differently than the flag passed in that command. The current webhook mirrors Clerk's stored `username`; product username claim/edit UX still needs to be explicit later.
