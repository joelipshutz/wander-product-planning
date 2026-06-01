# Wander Plan Eng Review

Date: 2026-06-01
Skill: plan-eng-review
Status: DECISIONS_LOCKED
Reviewed commit: 6e3a65a

## Inputs

- Product spec: `docs/specs/wander-ios-product-spec.md`
- Design system: `DESIGN.md`
- Design handoff: `preview/follow-profile-settings-mocks/`
- TODOs: `TODOS.md`
- Slate reference app: `/Users/joelipshutz/Developer/Slate`
- Platform references checked:
  - Supabase RLS: https://supabase.com/docs/guides/database/postgres/row-level-security
  - Supabase PostGIS: https://supabase.com/docs/guides/database/extensions/postgis
  - Supabase Swift auth: https://supabase.com/docs/reference/swift/v1/auth-api
  - Supabase third-party auth overview: https://supabase.com/docs/guides/auth/third-party/overview
  - Supabase Clerk provider: https://supabase.com/docs/guides/auth/third-party/clerk
  - Clerk iOS SDK: https://clerk.com/docs/ios/getting-started/quickstart
  - Clerk + Supabase integration: https://clerk.com/docs/guides/development/integrations/databases/supabase
  - Firebase offline persistence: https://firebase.google.com/docs/firestore/manage-data/enable-offline
  - Firestore rules and queries: https://firebase.google.com/docs/firestore/security/rules-query
  - Apple SwiftData CloudKit sync: https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
  - Apple Core Location authorization: https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services
  - Apple MKLocalSearch: https://developer.apple.com/documentation/mapkit/mklocalsearch

## Summary Verdict

Use a Supabase-backed architecture for the real social alpha, with SwiftData as the local app store and an explicit app-owned sync queue. Joe selected Clerk as the identity layer on top of Supabase. Clerk does not replace the Postgres/RLS/PostGIS recommendation; it owns identity/session/account surfaces while Supabase owns data, geo, RLS, functions, and storage.

Decisions and remaining open item:

1. Backend/auth: Clerk + Supabase/Postgres/RLS/PostGIS.
2. Guest mode: local guest save, auth required before sync/social.
3. Public visibility: "Everyone" maps to followers only, not global internet-public.
4. Extraction execution: backend extraction jobs for alpha; detailed production extraction design remains a later work item.
5. Share extension: defer and track as later TODO.
6. Places provider: MapKit-only v0.1 with provider-extensible IDs.
7. Block: hard block both ways.
8. Username: required, unique case-insensitive, editable later.
9. Delete/source retention: hard-delete active place/source artifacts, keep only minimal sync tombstones if needed.
10. Native Contacts: planned later; v0.1 uses `FakeContactProvider` plus username search.
11. Private profiles/follow requests: defer; open follow plus hard block.
12. iPad: phone-first compatibility only.
13. LLM Discover: include up front as a cheap structured-query parser over smart filters, not a broad agent.
14. Extra design variants: do not block eng plan; current handoff remains source of truth.
15. Implementation home: build Wander in this repo unless a later repo split is explicitly needed.
16. LLM privacy: send only the raw search phrase plus filter schema to the parser, not friend graph or user place data.
17. Visual gaps: do not block eng plan; missing states can be parallel design polish using the handoff style.
18. Sync conflicts: use simple `updated_at`/server-wins style conflict handling plus local retry queue for v0.1.
19. Backend environment: assume new Clerk and Supabase projects, with setup included in the eng plan.
20. Analytics: define event names now behind a vendor-neutral analytics interface.

## Step 0 Scope Challenge

### What Already Exists

| Sub-problem | Existing source | Reuse call |
|---|---|---|
| Local persistence | Slate `PersistenceController`, SwiftData/App Group pattern | Reuse shape, not exact schema. Wander needs server IDs, sync metadata, and social visibility fields. |
| Extraction orchestration | Slate `ExtractionService` | Reuse adapter ideas and failure handling, but split confidence scoring and candidate confirmation into first-class Wander concepts. |
| TikTok extraction | Slate `TikTokExtractor`, keyframe Vision, Whisper fallback | Strong reuse candidate. Wrap behind `SourceAdapter` and move API-key work backend-side for real alpha. |
| Generic URL/oEmbed | Slate `PageScrapeExtractor`, `OEmbedExtractor` | Reuse as fallback only. Instagram remains weak. |
| Location resolution | Slate `LocationResolver` using `MKLocalSearch` | Reuse concept, but return candidates with confidence instead of applying first result. |
| Share extension | Slate share extension/App Group import | Defer for Wander unless link capture is explicitly the top activation bet. |
| UI patterns | Handoff `.w-*` classes | Recreate natively as SwiftUI token/view layer. HTML is reference only. |

### Minimum Viable Implementation Plan

```text
Phase 1: Local social prototype
  SwiftUI token layer + core screens
  SwiftData models with sync/server metadata
  Map/Add/Profile with fake follow graph
  FakeContactProvider + seeded handles
  MapKit candidate search + manual/link/photo extraction shell

Phase 2: Real social backend
  Clerk identity + Supabase backend
  Clerk-to-profile mirror via webhook
  Postgres tables + RLS policies
  PostGIS viewport queries
  Follow/block/visibility RPCs
  Sync queue + conflict policy

Phase 3: Extraction hardening
  Backend extraction jobs
  TikTok reuse from Slate
  Google Maps parsing
  Instagram screenshot/manual fallback
  Source metrics and confidence gates
```

### Scope Reduction

Defer these without hurting the core wedge:

- Share extension. Useful, but it creates App Group, background ingestion, auth, and sync edge cases before the core app is proven.
- Third-party places provider. MapKit is enough to validate map/capture; keep provider IDs extensible.
- Private profiles/follow requests. Open follow plus block is simpler and matches the locked direction.

### Complexity Check

Full v0.1 touches far more than 8 files and introduces more than 2 services. That is expected for a new native app, but it is a smell if attempted as one implementation slice.

Recommended slice boundary:

```text
Foundation
  Models + repositories + token layer + fake data

Capture
  Add flow + candidate confirmation + contextual questions

Social backend
  Auth + follows + blocks + visibility + sync

Discovery/Profile
  Map filters + profiles + Discover + settings
```

## Architecture Review

### Finding 1: Backend Choice Should Be Locked Now

`[P1] (confidence: 8/10) docs/specs/wander-ios-product-spec.md:92 — Backend remains deferred, but the data model depends heavily on graph, geo, and row-level visibility.`

Supabase is the better fit for the actual product shape:

- Postgres handles follows, mutuals, blocks, canonical places, and visibility as relational data.
- Row Level Security can enforce per-row access at the database boundary.
- PostGIS supports bounding-box and nearby map queries with indexes.
- Swift client exists for auth/API integration.

Firebase is still viable, but Firestore rules are not filters. Queries must be shaped so the potential result set is authorized, which makes “visible places from people I follow, excluding blocked users, split by followers/mutuals/self” more denormalized and Cloud Function-heavy. Firebase’s offline persistence is stronger out of the box, but Wander already needs app-level SwiftData for local UX and extraction drafts.

Clerk changes the auth sub-decision, not the backend sub-decision. Current Supabase and Clerk docs support Clerk as a third-party auth provider for Supabase, including Swift/iOS client setup and RLS policies that read Clerk session claims through `auth.jwt()`. The tradeoff is that Clerk gives better user-management/account UI and web parity, but adds another vendor, another billing surface, and a user-record sync/webhook requirement because Clerk does not automatically synchronize users into Supabase tables.

Decision: choose Clerk + Supabase. Supabase remains the backend/social data layer with SwiftData as local cache and queue. Clerk owns identity/session/account surfaces; Supabase RLS should key access to Clerk's user id from session claims, and app profile records must be mirrored from Clerk into Supabase.

#### Backend/Auth Tradeoff

| Option | What it is | Best reason to choose it | Cost/risk | Eng implication |
|---|---|---|---|---|
| Supabase Auth + Supabase | One vendor for auth, Postgres, RLS, PostGIS, storage, functions. | Simplest MVP with the strongest fit for follow graph, visibility policies, and map queries. | Less polished account UI than Clerk; offline is app-owned through SwiftData/sync queue. | Not selected. Would build `profiles`, `follows`, `blocks`, `user_places`, RLS, and RPCs directly around Supabase user IDs. |
| Clerk + Supabase | Clerk handles identity/session/account UI; Supabase handles data, RLS, geo, storage, functions. | Better prebuilt auth/account surface and stronger future web parity if Wander becomes cross-platform. | Extra vendor, pricing surface, token/RLS configuration, and user-profile sync via webhooks. Clerk does not automatically mirror users into Supabase tables. | Selected. Build the same Supabase schema, key owner fields to Clerk `sub`, and add webhook-backed profile mirroring. |
| Firebase Auth + Firestore | Firebase handles auth, database, offline client cache, functions. | Best built-in offline behavior and familiar mobile backend ergonomics. | Graph + geo + visibility queries become denormalized. Firestore rules are not filters, so complex social map reads likely move behind Cloud Functions. | Only choose if offline-first simplicity outweighs relational visibility/geo simplicity. More duplication and backend functions expected. |
| Backend-neutral | Keep abstracting storage/auth until implementation. | Preserves optionality for one more review cycle. | Blocks schema, RLS/security tests, sync contracts, and repository interfaces. | Not recommended. The product shape is now specific enough to pick. |

### Finding 2: Guest/Auth Boundary Needs A Product Decision

`[P1] (confidence: 8/10) DESIGN.md:474 — Onboarding says auth only at save/share/follow/sync intent, but the backend model needs a durable user id for synced places and visibility.`

There are two viable choices:

- Guest local save: generate a local owner id, save in SwiftData, then migrate/claim local data after auth.
- Auth at first save: simpler backend model, but more friction before the first magic moment.

Recommendation: guest local save for the first personal place, auth required before any sync, follow, Discover personalization, or social visibility.

### Finding 3: Extraction Should Move Backend-Side For Social Alpha

`[P1] (confidence: 8/10) docs/specs/wander-ios-product-spec.md:563 — Extraction jobs are modeled, but the execution location is not locked.`

Slate runs extraction directly from the app because Slate is single-user and local. Wander is social, so production extraction should not expose AI/provider keys in the client or trust client-produced canonical place data. The client can still do local candidate search and store source artifacts, but real extraction jobs should run server-side.

Recommendation:

```text
iOS client
  -> creates SourceArtifact + local draft
  -> sends extraction request
  -> receives candidate set + confidence
  -> user confirms
  -> saves UserPlace

backend
  -> normalizes source
  -> calls adapters / AI / Places enrichment
  -> stores ExtractionJob + candidates
```

Phase 1 can use a local/mock extractor to move fast, but the alpha architecture should assume backend jobs.

### Finding 4: Visibility Needs Database-Level Tests, Not Just App Logic

`[P1] (confidence: 9/10) docs/specs/wander-ios-product-spec.md:735 — The spec requires follower/mutual/self privacy, block removals, and mid-flow revocation.`

If visibility is implemented only in Swift repositories, one bad query leaks private places. The plan needs RLS/security-rule tests as first-class tests.

Recommended visibility model:

```text
visible_user_places(viewer_id)
  includes owner rows
  includes followers rows where viewer follows owner
  includes mutual rows where both follow edges exist
  excludes self rows unless owner
  excludes any row if either side has blocked the other
```

For Supabase, implement this as SQL policies plus RPCs/views for complex reads. For Firebase, put complex reads behind Cloud Functions rather than direct client queries.

### Finding 5: SwiftData Sync Needs Explicit Conflict Rules

`[P2] (confidence: 7/10) docs/specs/wander-ios-product-spec.md:1042 — The plan says SwiftData + sync queue, but not the conflict policy.`

Concrete conflicts:

- User edits visibility offline, then deletes the same place from another device.
- User saves the same social place twice from two entry points.
- User follows someone, then blocks them while old Discover results are cached.
- Extraction completes after the user manually fixed the draft.

Recommendation:

```text
Local store fields:
  local_id
  server_id optional
  sync_state: local_only | pending_create | pending_update | synced | failed | tombstoned
  local_updated_at
  server_updated_at
  version / etag

Conflict policy:
  UserPlace text/attributes: last writer wins with visible conflict log
  visibility/delete/block: server wins for safety
  duplicate place save: merge by canonical place id + user id
  extraction result after manual edit: never overwrite user-confirmed fields silently
```

## Code Quality Review

### Finding 6: The Plan Needs Repository/Policy Boundaries Before Code Starts

`[P2] (confidence: 7/10) docs/specs/wander-ios-product-spec.md:1039 — System architecture lists components, but not the module boundaries that prevent UI from owning privacy/sync rules.`

Recommended app-side boundaries:

```text
Views
  -> ViewModels
      -> Repositories
          -> SwiftDataStore
          -> RemoteAPI
      -> Policy engines

Core services:
  PlaceRepository
  UserPlaceRepository
  FollowRepository
  VisibilityPolicy
  SyncEngine
  ExtractionCoordinator
  ContactProvider
```

Rules:

- Views never compute whether another user can see a place.
- ViewModels never call Supabase/Firebase directly.
- `VisibilityPolicy` exists in app for UI state, but backend/RLS remains authoritative.
- Extraction adapters return candidates; they do not mutate confirmed `UserPlace` fields directly.

### Finding 7: Slate Reuse Should Be Adapter-Level, Not Copy-Paste Service-Level

`[P2] (confidence: 8/10) /Users/joelipshutz/Developer/Slate/Shared/Services/ExtractionService.swift:6 — Slate's ExtractionService is a large MainActor singleton that mutates SwiftData models directly.`

That pattern was fine for a local single-user app, but Wander needs a clearer separation:

```text
SourceAdapter
  -> ExtractedCandidate[]

ConfidenceScorer
  -> high | medium | low | none

Confirmation UI
  -> selected PlaceCandidate

Repository
  -> UserPlace
```

Recommendation: copy proven adapter logic from Slate, not the singleton orchestration.

## Test Review

No project test framework exists yet because this repo is planning docs only. For implementation, use Xcode XCTest for unit/integration tests and XCUITest for critical UI flows.

### Coverage Diagram

```text
CODE PATHS                                                USER FLOWS
[+] Models / repositories                                  [+] First place save
  ├── [GAP] UserPlace create/update/delete                    ├── [GAP] [->E2E] guest save -> auth -> sync
  ├── [GAP] duplicate merge by user+place                     ├── [GAP] location denied -> manual fallback
  ├── [GAP] tombstone/delete sync                             └── [GAP] double-tap save idempotency
  └── [GAP] local/server id migration

[+] Visibility policy                                     [+] Social viewing
  ├── [GAP] owner sees followers/mutuals/self                 ├── [GAP] [->E2E] follow -> social pins appear
  ├── [GAP] follower sees followers only                      ├── [GAP] unfollow -> access revoked
  ├── [GAP] mutual sees followers+mutuals                     └── [GAP] block -> profile/search disappear
  ├── [GAP] non-follower sees profile shell only
  └── [GAP] blocked users see nothing

[+] Follow/block graph                                    [+] Contacts/user search
  ├── [GAP] follow/unfollow creates/removes edge              ├── [GAP] fake contacts matched/unmatched
  ├── [GAP] mutual computed from two edges                    └── [GAP] username exact/near-exact search
  └── [GAP] block removes both follow edges

[+] Extraction pipeline                                  [+] Add from link/photo/manual
  ├── [GAP] current location candidates                       ├── [GAP] [->E2E] Google Maps link confirm
  ├── [GAP] Google Maps redirect/name parse                   ├── [GAP] Instagram weak metadata fallback
  ├── [GAP] TikTok metadata/Vision/transcript fallback        └── [GAP] photo no-place rescue
  ├── [GAP] Instagram no metadata -> confirmation
  └── [GAP] malformed AI response -> retry/fail

[+] Sync queue                                           [+] Offline
  ├── [GAP] pending create/update retry                       ├── [GAP] offline save -> queued -> sync
  ├── [GAP] auth migration of guest local data                 └── [GAP] stale social detail -> unavailable
  └── [GAP] server-denied write rollback

COVERAGE: 0/31 paths tested, because implementation has not started.
QUALITY: expected target is all P1/P2 paths covered before beta.
```

### Required Test Artifacts For Implementation

- `VisibilityPolicyTests`: owner/follower/mutual/non-follower/blocked matrix.
- `FollowGraphTests`: follow, unfollow, mutual detection, block removing edges.
- `SyncEngineTests`: create/update/delete retries, duplicate merge, server denial rollback.
- `ExtractionCoordinatorTests`: high/medium/low/none confidence gates and malformed provider output.
- `ContactProviderTests`: fake contacts, username fallback, denied Contacts state.
- `AddFlowUITests`: location denied, manual fallback, double save, visibility picker.
- `ProfileAccessUITests`: profile shell, visible places, blocked state.
- `DiscoverUITests`: smart filter -> social place -> save to my map.
- Backend policy tests: SQL/RLS or Firebase emulator tests covering every visibility and block rule.

## Performance Review

### Finding 8: Map Queries Need Explicit Indexing And Query Shape

`[P2] (confidence: 8/10) docs/specs/wander-ios-product-spec.md:229 — Map pins can filter owner/status/person/visibility/geography, but query shape is not locked.`

Recommendation for Supabase:

- Store `places.location` as PostGIS geography/geometry with GiST index.
- Query by viewport bounding box first, then status/owner filters.
- Use RPC for `visible_places_in_view(viewer_id, bbox, filters)` so RLS and query shape stay consistent.
- Limit returned pins and cluster server-side once density grows.

### Finding 9: Extraction Needs Rate Limits And Job Idempotency

`[P2] (confidence: 8/10) docs/specs/wander-ios-product-spec.md:1158 — Hostile QA includes double save/backgrounding, but extraction job idempotency is not specified.`

Recommendation:

```text
idempotency key = user_id + source_type + normalized_source_hash

If same key is pending/running:
  return existing job

If complete:
  return existing candidate set

If failed_retryable:
  allow retry with attempt count
```

This prevents duplicate AI spend and duplicate candidate rows.

## Failure Modes

| Codepath | Failure | Test? | Handling needed | User sees |
|---|---|---:|---|---|
| Follow graph | Block/unfollow while detail is open | Gap | Revalidate detail before save | "This place is no longer available." |
| Visibility | `self` place returned in social query | Gap | Backend policy test + deny | Silent leak if missed: critical |
| Sync | Offline visibility edit conflicts with server delete | Gap | Server safety wins | Place removed / change not applied |
| Extraction | AI returns malformed JSON | Gap | Retry once, repair, then fail visible | "Try again or add manually." |
| Places | MapKit returns wrong same-name place | Gap | Candidate confirmation, no auto-save low confidence | Candidate picker |
| Contacts | Raw phone/email uploaded | Gap | Hash-only matching contract | No visible leak, but privacy risk |
| Search | Username search too broad | Gap | exact/near-exact, rate limited | Fewer results, safer graph |
| Map | 10,000 places in viewport | Gap | bbox + clustering + limits | Clustered pins or refine prompt |

Critical gap: visibility/backend policy tests are non-negotiable. A silent leak of `self` or `mutuals` places is the highest-risk failure.

## Performance Notes

- Firestore offline persistence is attractive, but its rules/query model makes graph visibility harder: rules do not filter query results.
- Supabase/PostGIS better matches viewport map queries and relational visibility, but local offline UX must be app-owned with SwiftData.
- SwiftData CloudKit sync is not the right social backend. It is for a person syncing their own data across devices, not follower visibility and social discovery.

## NOT In Scope

- Manual lists: explicitly removed from product direction.
- Public global feed: conflicts with trusted-people wedge and privacy model.
- Live location/presence: not required for place memory and increases trust risk.
- Native Contacts in first prototype: planned later; v0.1 uses fake provider and username search.
- Share extension in first prototype: defer unless Joe makes link capture the top activation bet.
- Third-party Places provider: keep schema extensible, start with MapKit.
- Private profiles/follow requests: defer; open follow + block is simpler.
- LLM-heavy agentic Discover/trip boards: not in scope; lightweight LLM query parsing into structured filters is in scope.
- iPad custom layout: phone-compatible unless explicitly prioritized.

## Worktree Parallelization Strategy

| Step | Modules touched | Depends on |
|---|---|---|
| Token/UI foundation | SwiftUI theme/components | none |
| Local data foundation | models/repositories/sync metadata | none |
| Capture flow | Add UI, extraction coordinator, repositories | local data foundation |
| Social backend | backend schema/RLS/RPC, remote API | local data foundation |
| Profiles/settings | profile UI, follow/block repos | local data + social backend contracts |
| Discover/map social | map query, filters, social place cards | social backend contracts |
| Tests | XCTest/XCUITest/backend policy tests | each lane's contracts |

Parallel lanes:

- Lane A: Token/UI foundation.
- Lane B: Local data foundation.
- Lane C: Backend schema/RLS/RPC.
- Lane D: Extraction adapter spike from Slate.

Then merge contracts and proceed:

- Lane E: Capture flow.
- Lane F: Profiles/settings.
- Lane G: Discover/map social.

Conflict flags:

- Capture, profiles, and Discover all touch repositories and models; do not run those until the model contracts are stable.
- Backend policy tests should be built alongside schema, not after UI.

## Open Decisions For Joe

### Accepted Before Eng Plan

| ID | Question | Joe decision | Other viable options | Why it matters |
|---|---|---|---|---|
| Q1 | Backend/auth stack | Clerk + Supabase. | Supabase Auth + Supabase; Firebase Auth + Firestore; keep backend-neutral. | Defines user IDs, schema, RLS/security tests, sync contracts, and backend SDK work. |
| Q2 | Guest first save | Allow local guest save, then require auth before sync/social. | Require auth at first save; allow unlimited local-only guest mode; create a backend anonymous session then upgrade later. | Preserves activation, but requires migration/claiming local records after sign-in. |
| Q3 | Meaning of "Everyone/public" | Followers-only public. Default new places to `followers`; helper copy says followers can see it. | True internet-public/global discoverability; rename UI from Everyone to Followers; no followers tier, only Friends/Self. | Affects privacy copy, visibility enum semantics, RLS policies, and user trust. |
| Q4 | Extraction execution | Backend extraction jobs for alpha; detailed production extraction design can follow as a later work item. | Client-only extraction; hybrid client hints/backend canonicalization; manual-only first prototype. | Protects provider keys and keeps canonical place creation observable and controlled. |
| Q5 | Share extension in v0.1 | Defer and track as TODO. | Include full share extension; include read-only/import-later extension; defer all link capture and only support manual/map add. | Share extension adds App Group, background import, auth, and sync edge cases. |
| Q6 | Places provider | MapKit-only with provider-extensible IDs. | Add Google Places/Foursquare now; use own canonical place table with weak provider matching; manual places only. | Keeps place search simple while preserving room for better place identity if quality fails. |
| Q7 | Block behavior | Hard block: remove/prevent follow edges, hide profiles/content both ways, exclude search/discover, preserve only private local history. | One-way block only; mute/hide only; report-only with no graph effect. | Safety behavior must be enforced in database policies and UI affordances. |
| Q8 | Username rules | Required at auth/profile creation; case-insensitive unique; editable later, no handle history/redirect in v0.1. | Auto-generate handles; optional username with contacts-only search; reserve old handles and redirect. | Username search is one of only two discovery paths besides contacts. |
| Q9 | Delete/data retention | Hard-delete saved places and source artifacts from active product surfaces; keep only minimal server tombstone if needed for sync. | Soft-delete/archive; retain source artifacts for debugging/extraction quality; delete place but keep anonymized aggregate metrics. | Needed for privacy, sync conflict handling, and extraction source storage. |

### Accepted Deferrables

| ID | Question | Joe decision | Other viable options | Why |
|---|---|---|---|---|
| Q10 | Native Contacts permission in v0.1? | Planned later. v0.1 uses `FakeContactProvider` plus username search; native Contacts comes after the core graph loop once matching/privacy/App Store copy are ready. | Ship native Contacts in v0.1; invite links first; username-only social discovery. | Native now is viable, but it adds permission copy, denied-permission UX, hashed matching, backend privacy rules, App Store disclosure, seeded/contact fixtures, and contact-import QA before the graph loop is proven. |
| Q11 | Private profiles/follow requests? | Defer; open follow plus block. | Private profiles; follow requests for private users; approve followers manually. | Current Strava-style model is simpler and already matches spec direction. |
| Q12 | iPad-specific layouts? | Defer; phone-first compatibility only. | Responsive iPad layouts; iPad unsupported beyond compatibility mode. | Current mocks and use case are iPhone-first. |
| Q13 | LLM-powered Discover query UX? | Include up front as a cheap structured-query parser over smart filters. | Pure structured filters only; natural-language search later; AI-generated trip boards; editorial cards. | This can strengthen the wedge if constrained to parsing into the same filter model instead of becoming a broad agent. |
| Q14 | Additional visual variants from gstack designer? | Do not block eng plan; current mock package is source of truth. | Run variant generation; run another design review; freeze current design without more variants. | Useful for polish, not blocking engineering architecture. |

### Accepted Eng-Plan Assumptions

| ID | Question | Joe decision | Eng-plan implication |
|---|---|---|---|
| Q15 | Implementation home | Build in `/Users/joelipshutz/Developer/Wander (nametbd)` unless a later repo split is explicitly needed. | Plan assumes this repo gets the iOS project, docs, schema, and tests. |
| Q16 | LLM Discover privacy | Parser receives only the raw search phrase plus filter schema; no friend graph or user place data. | LLM service contract is parse-only and returns editable filter JSON/chips. |
| Q17 | Visual gaps | Proceed with eng plan; missing states are parallel design polish in the current handoff style. | Eng plan can reference existing tokens/components and note missing screens as design follow-ups. |
| Q18 | Sync conflicts | Use simple `updated_at`/server-wins style conflict handling plus a local retry queue for v0.1. | Avoids heavy multi-device merge; tests cover queued create/update/delete and failed retry. |
| Q19 | Backend environment | Assume new Clerk and Supabase projects; include setup from scratch. | Plan includes environment setup, schema, RLS, Clerk provider config, and profile mirroring. |
| Q20 | Analytics | Define event names now behind a vendor-neutral interface. | Avoids provider commitment while preserving funnel and quality instrumentation. |

### D1: Backend/Auth Stack

Decision: Clerk + Supabase/Postgres/RLS/PostGIS.

Options:

- A: Supabase Auth + Postgres/RLS/PostGIS. Best fit for graph, geo, policy enforcement, and implementation simplicity. More app-owned offline work.
- B: Clerk + Supabase/Postgres/RLS/PostGIS. Same data/backend recommendation, stronger prebuilt auth/account UI and possible web parity. Adds vendor, pricing, user sync/webhook, and token/RLS configuration complexity.
- C: Firebase Auth + Firestore. Best built-in offline story. More denormalization and Cloud Functions for visibility queries.
- D: Keep backend-neutral for another round. Preserves optionality but blocks real architecture and test design.

### D2: Guest First Save

Recommendation: allow one or more local-only guest saves, require auth before sync/social.

Options:

- A: Guest local save, migrate data after auth. Best activation, more sync migration work.
- B: Require auth at first save. Simpler data model, worse first-run friction.

### D3: Extraction Execution Location

Decision: backend extraction jobs for alpha. Use local/mock extraction only for prototype and table detailed production extraction design as a later work item before real social alpha.

Options:

- A: Backend extraction jobs. Better key safety, observability, and canonical place control.
- B: Client-side extraction. Faster prototype, not acceptable for production social alpha.

### D4: Places Provider

Recommendation: MapKit-only v0.1, extensible provider fields.

Options:

- A: MapKit-only now. Lower complexity, enough for prototype.
- B: Add Google Places/Foursquare now. Better place identity, higher integration cost.

### D5: Share Extension Scope

Recommendation: defer share extension until core map/add/social loop works.

Options:

- A: Defer. Keeps implementation focused on capture confirmation, map, and social graph.
- B: Include in v0.1. Better link capture, but expands App Group/auth/sync complexity immediately.

## Spec Edits Applied / Remaining

Applied to the product/design/TODO artifacts:

- Replaced deferred backend decision with Clerk + Supabase.
- Marked share extension deferred and third-party places provider out for v0.1.
- Locked backend extraction jobs as alpha direction and tabled detailed job architecture as TODO before real social alpha.
- Added hard block/search/profile enforcement semantics.
- Added username and deletion/source-retention rules.
- Added lightweight LLM Discover query parsing up front.
- Updated `TODOS.md` with deferred share extension, extraction architecture, design variants, and planned-later native Contacts.

Remaining for eng plan:

- Include `FakeContactProvider` + username-search implementation in v0.1.
- Track native Contacts as planned later, with permission copy, denied-permission UX, hashed matching contract, backend privacy rules, App Store disclosure, and test fixtures.

## Completion Summary

- Step 0: Scope Challenge — scope should be phased, not reduced below the core loop.
- Architecture Review: 5 issues found.
- Code Quality Review: 2 issues found.
- Test Review: diagram produced, 31 gaps identified because implementation has not started.
- Performance Review: 2 issues found.
- NOT in scope: written.
- What already exists: written.
- TODOS.md updates: applied.
- Failure modes: 1 critical gap flagged: backend visibility leakage.
- Outside voice: not run yet.
- Parallelization: 7 workstreams, 4 initial parallel lanes.
- Lake Score: complete-option recommendations for backend policy tests, sync conflict rules, and extraction idempotency.
