# Wander iOS Engineering Plan

Date: 2026-06-01
Status: Draft for implementation review
Inputs:
- Product spec: `docs/specs/wander-ios-product-spec.md`
- Design system: `DESIGN.md`
- Eng review: `docs/reviews/2026-06-01-plan-eng-review.md`
- Handoff source: `preview/follow-profile-settings-mocks/`
- Slate reference: `/Users/joelipshutz/Developer/Slate`

## Locked Decisions

- Build the implementation in this repo unless a later repo split is explicitly needed.
- Native iOS app: SwiftUI, SwiftData, MapKit/CoreLocation, PhotosUI, iOS 17+.
- Backend: Clerk identity + Supabase Postgres/RLS/PostGIS/storage/functions.
- Local-first UX: SwiftData cache, guest-local saves, explicit sync queue.
- v0.1 social graph: one-way follows; friends are mutual follows; no private profiles/follow requests.
- Visibility: `followers`, `mutuals`, `self`; UI copy can say Everyone/Friends/Self, but Everyone means followers only.
- People discovery: username search + `FakeContactProvider`; native Contacts is planned later behind the same provider contract.
- Places: MapKit-only v0.1 with provider-extensible IDs.
- Extraction: backend jobs for alpha; prototype can reuse local Slate-style adapters.
- Discover: lightweight LLM parser up front, constrained to filter JSON. Send only raw search phrase + filter schema, never friend graph/place/contact/user data.
- Share extension: deferred until in-app add/map/social loop works.
- Sync conflicts: simple `updated_at`/server-wins style handling plus local retry queue for v0.1.
- Analytics: define event names now behind a vendor-neutral interface.

## Milestones

### M0: Repo And Project Bootstrap

Goal: create a runnable iOS app foundation without real backend dependency.

Deliverables:
- Xcode project or Swift Package layout inside this repo.
- SwiftUI app shell with four tabs: Map, Add, Discover, Profile.
- Token layer recreated from `preview/follow-profile-settings-mocks/tokens.css`.
- Shared components: buttons, pills, chips, bottom tab bar, profile header, place sheet, visibility picker.
- Preview/test fixture data for users, follows, blocks, places, user places, and fake contacts.

Exit criteria:
- App runs locally with seeded data.
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
- `SyncEngine`
- `ContactProvider`
- `LLMFilterParser`
- `ExtractionCoordinator`

Rules:
- Views do not call Clerk/Supabase directly.
- Views do not compute social visibility.
- App-side visibility policy is for UI state only; Supabase RLS is authoritative.
- Mutations write locally first when guest/offline, enqueue sync when authenticated.

Exit criteria:
- Unit tests cover local CRUD, fake graph, visibility matrix, and basic sync state transitions.

### M2: Core Local Product Loop

Goal: validate the app loop before real backend.

Build:
- Map surface with own/social filters, been/wanna status, and seeded social pins.
- Add flow for current location, manual entry, link, and photo shell.
- Candidate confirmation with high/medium/low/none confidence states.
- Visibility picker on confirmation before save.
- Contextual question templates for starter categories.
- Profile with saved places, unresolved drafts, followers/following, settings gear.
- Settings shell with account, privacy, blocked users, notifications, and data controls.
- Discover smart filters and username/profile lookup against fixtures.
- `FakeContactProvider` for contacts-first UI without native permission.

Exit criteria:
- Guest can save a first place locally.
- User can follow/unfollow/block seeded users.
- Visibility changes affect visible seeded social content.
- Add flow supports unresolved drafts and manual rescue.

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
- RLS policy tests pass for owner/follower/mutual/non-follower/blocked.
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
3. M2 local product loop.
4. M3 Clerk + Supabase schema/RLS.
5. M4 sync/offline.
6. M5 Discover parser + analytics.
7. M6 backend extraction jobs.

Parallelizable after M1:
- Backend schema/RLS and local UI can proceed in parallel if repository contracts are frozen.
- Visual polish can proceed against current handoff style.
- LLM parser can proceed as a pure service with fixtures.
- Extraction job design can proceed once source artifact schema is fixed.

Do not parallelize before M1:
- Capture/Profile/Discover implementations all depend on shared model and policy boundaries.
- Backend policy tests should be written with schema, not after UI.

## Implementation Review Gate

Before coding beyond M0/M1, review:
- Supabase schema and RLS test matrix.
- SwiftData model fields and sync states.
- Repository protocols.
- LLM parser schema.
- Analytics event names.
- Visual state follow-ups that may affect core navigation.
