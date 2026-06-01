# Wander iOS Engineering Plan

Date: 2026-06-01
Status: Audited for reset implementation
Inputs:
- Product spec: `docs/specs/wander-ios-product-spec.md`
- Design system: `DESIGN.md`
- Eng review: `docs/reviews/2026-06-01-plan-eng-review.md`
- Contract lock: `docs/plans/2026-06-01-wander-m1-5-contract-lock.md`
- Handoff source: `preview/follow-profile-settings-mocks/`
- Slate reference: `/Users/joelipshutz/Developer/Slate`

## Locked Decisions

- Build the implementation in this repo unless a later repo split is explicitly needed.
- Native iOS app: SwiftUI, SwiftData, MapKit/CoreLocation, PhotosUI, iOS 17+.
- XcodeGen `project.yml` is the project source of truth. Generated Xcode files may be committed only when useful for local opening/review, but `project.yml` owns target/file membership.
- Backend: Clerk identity + Supabase Postgres/RLS/PostGIS/storage/functions.
- Local-first UX: SwiftData cache, guest-local saves, explicit sync queue.
- v0.1 social graph: one-way follows; friends are mutual follows; no private profiles/follow requests.
- Visibility: `followers`, `mutuals`, `self`; UI copy can say Everyone/Friends/Self, but Everyone means followers only.
- People discovery: username search + `FakeContactProvider`; native Contacts is planned later behind the same provider contract.
- Places: MapKit-only v0.1 with provider-extensible IDs.
- Extraction: backend jobs for alpha; in M2 only current-location/manual are real, while link/photo are honest shells until backend extraction jobs exist.
- Discover: define parser interface and deterministic fixture parser early; add real cheap LLM parsing in M5. Send only raw search phrase + filter schema, never friend graph/place/contact/user data.
- Share extension: deferred until in-app add/map/social loop works.
- Sync conflicts: define the state machine in M1.5; implement full sync engine in M4. Use simple `updated_at`/server-wins style handling plus local retry queue for v0.1.
- Analytics: define event names now behind a vendor-neutral interface.
- Navigation is four bottom tabs only: Map, Add, Discover, Profile. Settings opens from Profile gear, not a fifth bottom tab.
- Design tokens from `preview/follow-profile-settings-mocks/tokens.css` must be promoted 1:1 into SwiftUI tokens before visual polish.
- Fonts are tokenized now using system fonts with matching metrics; add Funnel font assets only after packaging/licensing is clean.
- Full onboarding is deferred; auth gates still appear where flows need them: save/sync/follow/social personalization.

## Reset Audit Decisions

Low-pass implementation commits were reset on 2026-06-01. Rebuild from this plan only after the following audit decisions:

| ID | Decision |
|---|---|
| D1 | Revert low-pass Swift/Xcode implementation and redo from audited plan. |
| D2 | Add M1.5 Contract Lock before M2. |
| D3 | Settings is Profile gear only, no fifth tab. |
| D4 | Promote `tokens.css` 1:1 into SwiftUI tokens. |
| D5 | Use XcodeGen `project.yml` as source of truth. |
| D6 | Lock Supabase schema/RLS contract before Clerk iOS wiring. |
| D7 | Local models mirror backend domain schema plus local sync metadata. |
| D8 | Define sync state machine in M1.5; implement sync engine in M4. |
| D9 | Parser interface + deterministic parser early; real cheap LLM parser in M5. |
| D10 | M2 has real current-location/manual add; link/photo stay shells until backend jobs. |
| D11 | M2 uses real MapKit seeded map, not a list pretending to be a map. |
| D12 | Run design review after M1.5 before M2 polish. |
| D13 | Every milestone lands with matching tests. |
| D14 | Defer full onboarding but implement auth gates at save/sync/follow moments. |
| D15 | Tokenized system fonts now; Funnel assets later if packaged/licensed cleanly. |

## Milestones

### M0: Repo And Project Bootstrap

Goal: create a runnable iOS app foundation without real backend dependency.

Deliverables:
- XcodeGen `project.yml` plus generated Xcode project if needed for local opening.
- SwiftUI app shell with four tabs: Map, Add, Discover, Profile.
- Settings is reachable from the Profile gear, not bottom navigation.
- Token layer recreated 1:1 from `preview/follow-profile-settings-mocks/tokens.css`.
- Shared components: buttons, pills, chips, bottom tab bar, profile header, place sheet, visibility picker.
- Preview/test fixture data for users, follows, blocks, places, user places, and fake contacts.

Exit criteria:
- App runs locally with seeded data.
- Tests pass for token values, tab shape, and fixture loading.
- Screens match the handoff direction closely enough for implementation, even if secondary visual states continue in parallel design polish.

### M1: Local Data And Repository Contracts

Goal: establish model and service boundaries before UI business logic spreads.

SwiftData models:
- `LocalProfile`
- `LocalFollow`
- `LocalBlock`
- `LocalPlace`
- `LocalUserPlace`
- `LocalPlaceAttribute`
- `LocalSourceArtifact`
- `LocalExtractionJob`
- `SyncOperation`

Repository protocols:
- `ProfileRepository`
- `FollowRepository`
- `BlockRepository`
- `PlaceRepository`
- `UserPlaceRepository`
- `SourceArtifactRepository`
- `ExtractionRepository`
- `DiscoverRepository`
- `AnalyticsClient`

Policy/services:
- `VisibilityPolicy`
- `FollowGraphService`
- `SyncStateMachine`
- `ContactProvider`
- `LLMFilterParser`
- `ExtractionCoordinator`

Rules:
- Views do not call Clerk/Supabase directly.
- Views do not compute social visibility.
- App-side visibility policy is for UI state only; Supabase RLS is authoritative.
- Mutations write locally first when guest/offline. Sync queue behavior is defined in M1.5 and implemented in M4.
- Local models mirror backend domain fields and add only local sync metadata: local id, server id, sync state, local/server timestamps, retry/error fields.

Exit criteria:
- Unit tests cover local CRUD, fake graph, visibility matrix, deterministic Discover parser, and basic sync state transitions.

### M1.5: Contract Lock

Goal: freeze contracts that M2 can build against without accidentally inventing architecture in fixture UI.

Supabase contract:
- Table definitions for profiles, follows, blocks, places, user places, place attributes, source artifacts, extraction jobs, sync tombstones, and optional analytics events.
- RLS matrix for owner, follower, mutual, non-follower, blocked, logged-out/profile-shell, and deleted/tombstoned rows.
- RPC/view signatures for viewport visible places, profile search, profile visible places, follow/unfollow/block, social save, and guest record claim.
- Clerk claim mapping: which Clerk session claim maps to Supabase owner fields and how profile mirroring happens.

Local contract:
- SwiftData models mirror backend fields plus local sync metadata.
- Sync state machine diagram and transition table.
- Repository protocols with async signatures and typed errors.
- Deterministic fake repositories for UI tests.

Product/UI contract:
- Four-tab shell only; Profile gear opens Settings.
- Real MapKit seeded map for M2.
- Current-location/manual add are real in M2; link/photo remain clearly marked shells until backend extraction jobs.
- Discover parser interface and deterministic local parser; real cheap LLM parser waits until M5.
- Analytics event names and typed interface.
- Visual state inventory for follow, block, visibility, auth gate, offline, parser failure, extraction shell, empty, loading, and error states.

Required diagrams:

```text
Save flow
  guest/local input
    -> SwiftData draft/UserPlace
    -> optional auth gate at sync/social intent
    -> sync queue claim/upsert
    -> Supabase RLS/RPC
    -> synced or visible retry/error
```

```text
Visibility read
  viewer
    -> block check both directions
    -> owner? yes: all rows
    -> follows owner? yes: followers rows
    -> mutual? yes: followers + mutuals rows
    -> self rows: owner only
```

Exit criteria:
- Schema/RLS contract reviewed and represented in tests or test stubs before implementation.
- Sync state machine covers create/update/delete/retry/tombstone/auth-claim/server-denied/blocked-stale cases.
- Design review is run against the handoff plus missing states before M2 polish. Completed 2026-06-01 in `docs/reviews/2026-06-01-plan-design-review.md`.
- No M2 UI code starts until M1.5 contracts are committed.

Design gate result:
- Use `preview/follow-profile-settings-mocks/` as the approved visual baseline; do not generate a competing direction for M2.
- Discover: search, people row, big smart-filter pills, follow-attributed results, parser fallback chips, no global people directory.
- Other-user profiles: shared Profile shell, relationship state, follow/unfollow, role-gated places, followers/following, overflow block.
- Followers/following: segmented lists with profile rows, inline relationship actions, and block overflow.
- Settings: Profile gear surface only, with account, default visibility, blocked users, contacts, notifications, and data/sync rows.
- Block/access changed/auth gates: required states before social polish is complete.

### M2: Core Local Product Loop

Goal: validate the app loop before real backend.

Build:
- Real MapKit surface with own/social filters, been/wanna status, and seeded social pins.
- Add flow with real current-location and manual entry.
- Link and photo entry points as honest shells that create unresolved drafts or explain backend extraction is not connected yet.
- Candidate confirmation with high/medium/low/none confidence states.
- Visibility picker on confirmation before save.
- Contextual question templates for starter categories.
- Profile with saved places, unresolved drafts, followers/following, settings gear.
- Settings shell opened from Profile with account, privacy, blocked users, notifications, and data controls.
- Discover smart filters, contacts results, and username/profile lookup against fixtures. Do not show a global people directory.
- `FakeContactProvider` for contacts-first UI without native permission.

Exit criteria:
- Guest can save a first place locally.
- User can follow/unfollow/block seeded users.
- Visibility changes affect visible seeded social content.
- Add flow supports unresolved drafts and manual rescue.
- UI tests cover guest first save, follow/unfollow/block, visibility effect, fake contacts matched/unmatched, and parser chips.

### M3: Clerk + Supabase Foundation

Goal: add real identity and social data contracts.

Supabase tables:
- `profiles`
- `follows`
- `blocks`
- `places`
- `user_places`
- `place_attributes`
- `source_artifacts`
- `extraction_jobs`
- `sync_tombstones`
- `analytics_events` optional if provider-neutral server event sink is useful

Clerk/Supabase integration:
- Implement Supabase schema, indexes, RLS policies, and policy tests before wiring the iOS Clerk UI.
- Configure Clerk as Supabase third-party auth provider.
- Mirror Clerk users into `profiles` through webhook or backend job.
- Store Clerk user id as profile/user owner key.
- Define username uniqueness as case-insensitive.

RLS/policy requirements:
- Owner can read/write own rows.
- Follower can read `followers` user places if not blocked.
- Mutual follow can read `followers` and `mutuals`.
- Non-follower can see profile shell only.
- `self` rows only return to owner.
- Block hides profiles, places, follower/following edges, username search, contacts results, and Discover results both ways.
- Deletes remove active product visibility; minimal tombstone can remain for sync.

RPC/query shapes:
- `visible_places_in_view(viewport, filters)`
- `search_profiles_by_handle(query)`
- `profile_visible_places(profile_id, filters)`
- `follow_user(profile_id)`
- `unfollow_user(profile_id)`
- `block_user(profile_id)`
- `save_visible_place(place_id, source_user_place_id)`
- `claim_guest_records(local_records)`

Exit criteria:
- RLS policy tests pass for owner/follower/mutual/non-follower/blocked/logged-out/profile-shell/delete cases.
- App can sign in, mirror profile, sync a local saved place, and fetch visible social pins.

### M4: Sync And Offline

Goal: make local-first behavior reliable enough for alpha.

Sync states:
- `local_only`
- `pending_create`
- `pending_update`
- `pending_delete`
- `synced`
- `failed`
- `tombstoned`

Conflict policy:
- Server wins for delete, block, visibility denial, and rejected writes.
- `updated_at`/last writer wins for ordinary notes/attributes.
- Duplicate save merges by `user_id + canonical_place_id`.
- Extraction never overwrites user-confirmed fields silently.

Required tests:
- Guest save -> auth -> claim/sync.
- Offline create/update/delete -> retry.
- Server-denied write rollback.
- Duplicate social save merge.
- Block while stale profile/place detail is cached.

Exit criteria:
- Offline save works without auth.
- Auth migration claims local records.
- Failed sync is visible and retryable.

### M5: Discover Parser And Analytics

Goal: ship the smart query wedge with measurable behavior.

LLM parser:
- Input: raw query string + allowed filter schema only.
- Output: structured filter JSON and editable chips.
- No user graph, saved places, notes, contacts, or profile data sent to the model.
- Cheap/swappable provider first; Sonnet-class fallback only if quality requires it.
- Cache repeated parse results.
- Fallback to static smart filters on failure.

Analytics interface events:
- `onboarding_started`
- `location_permission_result`
- `first_place_started`
- `place_candidate_shown`
- `place_saved`
- `visibility_changed`
- `follow_created`
- `follow_removed`
- `block_created`
- `discover_filter_used`
- `discover_query_parsed`
- `discover_parse_failed`
- `social_place_saved`
- `sync_failed`
- `extraction_job_started`
- `extraction_job_completed`
- `extraction_job_failed`

Exit criteria:
- Discover parses common queries into visible chips.
- Parser failure degrades to smart filters.
- Event interface is covered by tests/mocks and not tied to a vendor.

### M6: Backend Extraction Jobs

Goal: move production extraction behind backend jobs before real social alpha.

Server job shape:
- `source_artifact_id`
- `owner_user_id`
- `source_type`
- `normalized_source_hash`
- `status`
- `attempt_count`
- `provider_steps_json`
- `extracted_candidates_json`
- `selected_place_id`
- `confidence`
- `error_code`

Idempotency:
- Key: `owner_user_id + source_type + normalized_source_hash`.
- Pending/running returns existing job.
- Complete returns existing candidate set.
- Retryable failures increment attempt count.

Adapters:
- Current location: MapKit candidate search.
- Manual text: local/manual candidate.
- Google Maps: redirect/name/coordinate extraction where available.
- TikTok: reuse Slate adapter shape where useful.
- Instagram: screenshot/manual fallback; link metadata is unreliable.
- Photo: OCR/Vision + EXIF if permissioned.
- Web page: metadata/body extraction fallback.

Exit criteria:
- Backend jobs protect provider keys.
- Low-confidence extraction never auto-saves a complete place.
- Duplicate jobs do not duplicate AI spend or candidate rows.

## Test Plan

Unit tests:
- Visibility matrix.
- Follow/block graph.
- Username normalization and uniqueness helpers.
- Local model/repository CRUD.
- Sync queue state transitions.
- LLM parser schema validation.
- Extraction confidence gates.

Integration/backend tests:
- Supabase RLS matrix.
- Clerk token claim handling.
- Profile mirror webhook.
- PostGIS viewport query shape.
- RPC behavior for follow/unfollow/block/save social place.
- Guest record claim.

UI tests:
- Guest first save.
- Add manual/current location/link/photo.
- Visibility picker before save.
- Discover query -> chips -> results.
- Profile follow/unfollow/block.
- Fake contacts matched/unmatched.
- Offline save and retry.

Hostile tests:
- Double-tap save.
- Background mid-extraction.
- Block while viewing stale profile.
- `self` place in social query.
- `mutuals` place for one-way follower.
- Blocked user in username/contact search.
- 10,000 places in dense viewport.

## Sequencing

Recommended order:

1. M0 app shell + token layer.
2. M1 models/repositories/policies/fakes.
3. M1.5 contract lock.
4. M2 local product loop.
5. M3 Clerk + Supabase schema/RLS/auth foundation.
6. M4 sync/offline.
7. M5 Discover parser + analytics.
8. M6 backend extraction jobs.

Parallelizable after M1.5:
- Backend schema/RLS and local UI can proceed in parallel if repository contracts are frozen and tests target the same contract.
- Visual polish can proceed against current handoff style after design review catches missing states.
- LLM parser can proceed as a pure service with fixtures.
- Extraction job design can proceed once source artifact schema is fixed.

Do not parallelize before M1.5:
- Capture/Profile/Discover implementations all depend on shared model and policy boundaries.
- Backend policy tests should be written with schema, not after UI.

## Implementation Review Gate

Before coding beyond M0/M1, complete M1.5:
- Supabase schema and RLS test matrix.
- SwiftData model fields and sync states.
- Repository protocols.
- LLM parser schema.
- Analytics event names.
- Visual state follow-ups that may affect core navigation.

## NOT In Scope For Reset Rebuild

- Fifth Settings tab. Settings is a Profile gear surface.
- Global people directory. Discovery is contacts, username, and visible profile links only.
- Native Contacts permission. Build `FakeContactProvider` and username search first.
- Share extension. Revisit after in-app add/map/social loop works.
- Real link/photo extraction. Backend extraction jobs own this before social alpha.
- Full onboarding. Only auth gates needed by save/sync/follow are in scope before onboarding implementation.
- Private profiles/follow requests. Open follow plus hard block remains v0.1.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 1 | clean | 0 critical gaps |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | - | Not run |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | clean | Reset audit completed; M1.5 contract lock added |
| Design Review | `/plan-design-review` | UI/UX gaps | 2 | clean | score: 8/10 -> 9/10, 8 decisions |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | - | Not run |

- **UNRESOLVED:** 0 across the current eng/design plan gates.
- **VERDICT:** CEO + ENG + DESIGN CLEARED for M2 implementation.
