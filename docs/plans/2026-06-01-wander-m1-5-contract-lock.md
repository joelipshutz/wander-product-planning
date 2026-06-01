# Wander M1.5 Contract Lock

Date: 2026-06-01
Status: Accepted baseline for implementation
Depends on:
- `docs/plans/2026-06-01-wander-ios-eng-plan.md`
- `docs/specs/wander-ios-product-spec.md`
- `DESIGN.md`
- `preview/follow-profile-settings-mocks/`

## Purpose

M1.5 freezes the contracts that the Swift app, Supabase backend, and design states must share before M2 UI work starts.

The first implementation pass showed the failure mode: fixture UI can accidentally become architecture. This document prevents that by making the schema, visibility rules, sync states, parser interface, and design gates explicit before rebuilding.

## Non-Negotiables

- Four bottom tabs only: Map, Add, Discover, Profile.
- Settings opens from Profile gear.
- `tokens.css` values become SwiftUI tokens 1:1.
- M2 map is real MapKit with seeded pins.
- M2 Add supports current-location/manual for real; link/photo are honest shells.
- No global people directory. People discovery is contacts, username, and visible profile links.
- Supabase RLS is authoritative for visibility. Client policy is UI-only.
- Clerk owns identity/session/account UX; Supabase owns data, RLS, PostGIS, functions, storage.
- Every milestone lands with tests.

## Identity Contract

Clerk session token claims are the auth input to Supabase.

Required:
- Supabase third-party auth integration for Clerk enabled.
- Clerk session tokens contain a role claim that Supabase can map to `authenticated`.
- Supabase policies read Clerk claims via `auth.jwt()`.
- `profiles.id` stores the Clerk user id / subject.
- A Clerk webhook or backend job mirrors Clerk users into `profiles`.

Open implementation detail for M3:
- Exact Clerk claim key for user id. Prefer the standard subject-style claim unless current Clerk/Supabase docs require a different key.

## Backend Schema Contract

Schema is SQL-shaped here, not a final migration.

Required Postgres extensions:
- `citext` for case-insensitive handles.
- `postgis` for geography/viewport queries.

```sql
profiles
  id text primary key                  -- Clerk user id / subject
  handle citext unique not null
  display_name text not null
  avatar_url text
  bio text
  home_area text
  default_visibility text not null     -- followers | mutuals | self
  search_handle text not null
  created_at timestamptz not null
  updated_at timestamptz not null
  deleted_at timestamptz

follows
  id uuid primary key
  follower_user_id text not null references profiles(id)
  followed_user_id text not null references profiles(id)
  source text not null                 -- username | contacts | profile | invite_link_future
  created_at timestamptz not null
  updated_at timestamptz not null
  unique(follower_user_id, followed_user_id)
  check(follower_user_id <> followed_user_id)

blocks
  id uuid primary key
  blocker_user_id text not null references profiles(id)
  blocked_user_id text not null references profiles(id)
  created_at timestamptz not null
  unique(blocker_user_id, blocked_user_id)
  check(blocker_user_id <> blocked_user_id)

places
  id uuid primary key
  canonical_name text not null
  category text not null
  address text
  locality text
  region text
  country text
  latitude double precision not null
  longitude double precision not null
  geog geography(point, 4326) generated/stored
  source_provider text not null        -- mapkit for v0.1
  source_provider_place_id text
  confidence double precision
  created_at timestamptz not null
  updated_at timestamptz not null
  unique(source_provider, source_provider_place_id)

user_places
  id uuid primary key
  user_id text not null references profiles(id)
  place_id uuid not null references places(id)
  status text not null                 -- been | wanna_go
  note text
  rating_signal text
  visibility text not null             -- followers | mutuals | self
  nearby_confirmed boolean not null default false
  visited_at timestamptz
  saved_at timestamptz not null
  source_type text not null            -- current_location | link | manual | photo | social_save
  source_artifact_id uuid
  source_user_place_id uuid
  attribution_user_id text
  created_at timestamptz not null
  updated_at timestamptz not null
  deleted_at timestamptz
  unique(user_id, place_id)

place_attributes
  id uuid primary key
  user_place_id uuid not null references user_places(id)
  question_key text not null
  value_type text not null             -- scale | boolean | enum | multi_tag | text
  value jsonb not null
  created_at timestamptz not null
  updated_at timestamptz not null
  unique(user_place_id, question_key)

source_artifacts
  id uuid primary key
  user_id text not null references profiles(id)
  type text not null                   -- url | image | text | current_location
  original_input text not null
  normalized_input text not null
  normalized_source_hash text not null
  local_asset_ref text
  remote_asset_ref text
  created_at timestamptz not null
  deleted_at timestamptz
  unique(user_id, type, normalized_source_hash)

extraction_jobs
  id uuid primary key
  source_artifact_id uuid not null references source_artifacts(id)
  owner_user_id text not null references profiles(id)
  source_type text not null
  normalized_source_hash text not null
  status text not null                 -- pending | running | needs_confirmation | complete | failed | no_place_found
  attempt_count integer not null default 0
  provider_steps_json jsonb not null default '[]'
  extracted_candidates_json jsonb not null default '[]'
  selected_place_id uuid references places(id)
  confidence double precision not null default 0
  error_code text
  error_message text
  created_at timestamptz not null
  updated_at timestamptz not null
  unique(owner_user_id, source_type, normalized_source_hash)

sync_tombstones
  id uuid primary key
  owner_user_id text not null
  entity_name text not null
  entity_id text not null
  reason text not null                 -- delete | block | server_denied | merge
  created_at timestamptz not null
  unique(owner_user_id, entity_name, entity_id)

analytics_events optional
  id uuid primary key
  user_id text
  name text not null
  properties jsonb not null default '{}'
  created_at timestamptz not null
```

## Index Contract

Required indexes:
- `profiles(handle)` unique case-insensitive.
- `profiles(search_handle)` for prefix/exact handle search.
- `follows(follower_user_id, followed_user_id)` unique.
- `follows(followed_user_id, follower_user_id)` for follower lists.
- `blocks(blocker_user_id, blocked_user_id)` unique.
- `blocks(blocked_user_id, blocker_user_id)` for reverse block checks.
- `places using gist(geog)` for viewport/nearby queries.
- `user_places(user_id, place_id)` unique.
- `user_places(place_id, visibility, status)` for visible social place queries.
- `user_places(user_id, visibility, status, updated_at)` for profile tabs.
- `source_artifacts(user_id, type, normalized_source_hash)` unique.
- `extraction_jobs(owner_user_id, source_type, normalized_source_hash)` unique.
- `sync_tombstones(owner_user_id, entity_name, entity_id)` unique.

## Visibility/RLS Matrix

Legend:
- Owner: row owner.
- Follower: viewer follows owner.
- Mutual: viewer follows owner and owner follows viewer.
- Blocked: either direction has a block.
- Shell: basic profile only: name, handle, avatar, bio, counts.

| Viewer state | Profile shell | `followers` places | `mutuals` places | `self` places | Follow list | Search result |
|---|---:|---:|---:|---:|---:|---:|
| Owner | yes | yes | yes | yes | yes | yes |
| Mutual | yes | yes | yes | no | yes filtered | yes |
| Follower one-way | yes | yes | no | no | yes filtered | yes |
| Non-follower authenticated | yes | no | no | no | counts only | exact/near-exact username only |
| Logged out | optional shell only | no | no | no | no | no |
| Blocked either way | no | no | no | no | no | no |

RLS/read rule:

```text
can_read_user_place(viewer, owner, visibility)
  if blocked(viewer, owner): false
  if viewer == owner: true
  if visibility == self: false
  if visibility == followers: viewer follows owner
  if visibility == mutuals: viewer follows owner AND owner follows viewer
```

Block rule:

```text
block_user(target)
  insert block current_user -> target
  delete follow current_user -> target
  delete follow target -> current_user
  hide both profiles/places/search/list entries from each other
```

Delete/source retention:

```text
delete user_place
  remove active user_place row or mark deleted_at
  remove active source_artifacts tied only to that row
  leave minimal sync_tombstone when needed
  do not retain raw artifact solely for debugging
```

## RPC/View Contract

Use RPCs or security-invoker views where direct client queries would be too easy to get wrong.

```text
visible_places_in_view(
  min_lat, min_lng, max_lat, max_lng,
  statuses text[],
  owner_scope text[]        -- you | following | friends
) -> visible place rows

search_profiles_by_handle(
  query text,
  limit int
) -> profile shells

profile_visible_places(
  profile_id text,
  statuses text[],
  categories text[]
) -> visible place rows for viewer

follow_user(profile_id text) -> follow row
unfollow_user(profile_id text) -> void
block_user(profile_id text) -> block row

save_visible_place(
  source_user_place_id uuid,
  status text,
  visibility text
) -> user_place row

claim_guest_records(
  local_records jsonb
) -> claim result with server ids and rejected rows
```

## SwiftData Local Model Contract

SwiftData mirrors backend fields, with local-only metadata:

```text
LocalEntity
  localID: String
  serverID: String?
  syncState: SyncState
  localUpdatedAt: Date
  serverUpdatedAt: Date?
  lastSyncError: String?
```

Domain models:
- `LocalProfile`
- `LocalFollow`
- `LocalBlock`
- `LocalPlace`
- `LocalUserPlace`
- `LocalPlaceAttribute`
- `LocalSourceArtifact`
- `LocalExtractionJob`
- `SyncOperation`

Rules:
- Use typed enums at the domain boundary, even if persisted as raw strings.
- Views never mutate SwiftData models directly except through ViewModels/repositories.
- Views never compute social visibility; they consume `VisiblePlace`/`ProfileVisibilityState`.
- Guest-local records do not enter social surfaces until claimed by an authenticated user.

## Sync State Machine

```text
local_only
  -> pending_create          auth/session available
  -> tombstoned              user deletes before sync

pending_create
  -> synced                  server accepts create
  -> failed                  retryable network/server error
  -> server_denied           RLS/validation failure, rollback visible
  -> tombstoned              user deletes while pending

pending_update
  -> synced                  server accepts update
  -> failed                  retryable error
  -> server_denied           rollback/merge according to policy
  -> tombstoned              user deletes

pending_delete
  -> tombstoned              server confirms delete
  -> failed                  retryable error

failed
  -> pending_create/update/delete  user or background retry
  -> tombstoned                    user discards local change

synced
  -> pending_update          user edits
  -> pending_delete          user deletes
  -> tombstoned              server delete/block revokes row

server_denied
  -> local_only              user keeps as private local draft if allowed
  -> tombstoned              user discards
```

Safety conflict policy:
- Server wins for delete, block, visibility denial, and rejected writes.
- Last writer wins for ordinary note/attribute updates in v0.1.
- Duplicate save merges by `user_id + place_id`.
- Extraction results never overwrite user-confirmed fields silently.
- A blocked/stale cached profile or place must disappear or show an access-changed state.

## Repository Protocol Contract

Swift names can change, but the boundary shape should not.

```swift
protocol ProfileRepository {
    func currentProfile() async throws -> LocalProfile?
    func profile(id: String) async throws -> ProfileViewState
    func searchProfiles(handleQuery: String) async throws -> [ProfileShell]
}

protocol FollowRepository {
    func follow(userID: String) async throws
    func unfollow(userID: String) async throws
    func followers(userID: String) async throws -> [ProfileShell]
    func following(userID: String) async throws -> [ProfileShell]
    func relationship(to userID: String) async throws -> ViewerRelationship
}

protocol BlockRepository {
    func block(userID: String) async throws
    func unblock(userID: String) async throws
    func blockedProfiles() async throws -> [ProfileShell]
    func isBlocked(userID: String) async throws -> Bool
}

protocol PlaceRepository {
    func places(in viewport: MapViewport) async throws -> [VisiblePlace]
    func resolveCurrentLocation() async throws -> [PlaceCandidate]
    func resolveManualEntry(_ input: ManualPlaceInput) async throws -> [PlaceCandidate]
}

protocol UserPlaceRepository {
    func userPlaces(for userID: String, filters: PlaceFilters) async throws -> [VisiblePlace]
    func save(_ draft: UserPlaceDraft) async throws -> SaveResult
    func updateVisibility(userPlaceID: String, visibility: PlaceVisibility) async throws
    func delete(userPlaceID: String) async throws
}

protocol DiscoverRepository {
    func parseFilters(query: String) async throws -> DiscoverFilters
    func search(filters: DiscoverFilters) async throws -> DiscoverResults
}

protocol ContactProvider {
    func matches() async throws -> [ContactMatch]
}
```

## Discover Parser Contract

M1/M2:
- `LLMFilterParser` protocol.
- Deterministic fixture parser for tests and local UI.
- Parser accepts raw query + allowed schema only.

M5:
- Add real cheap/swappable LLM parser.
- Cache repeated parse results.
- Fallback to static chips.
- Never send friend graph, saved places, notes, contacts, profile data, or location history to the model.

Allowed output:

```json
{
  "query": "hikes in LA",
  "categories": ["hike"],
  "statuses": ["been"],
  "area": "LA",
  "relationship": "following",
  "tags": ["views"]
}
```

## M2 UI State Inventory

M2 may build only after these states have fixtures/tests:

Map:
- loading cached places
- empty own map
- empty social map
- seeded MapKit pins: you/social x been/wanna
- selected place sheet
- visibility changed while sheet is open
- blocked user disappears from pins

Add:
- current location candidate found
- current location denied/unavailable
- manual candidate found
- low-confidence/manual rescue
- link shell creates unresolved draft
- photo shell creates unresolved draft
- visibility picker before save
- double-tap save does not duplicate

Discover:
- smart filter chips
- deterministic parser success
- deterministic parser fallback
- contacts matched
- contacts unmatched future invite disabled
- username exact/near-exact search
- blocked users hidden
- no global people directory

Profile:
- owner profile
- other user profile: non-follower shell
- follower-visible places
- mutual-visible places
- follow/unfollow
- follows-you/mutual indicator
- block
- settings gear

Settings:
- profile/account basics shell
- default visibility shell
- blocked users
- contacts planned/permission status shell
- notifications shell
- data/sync shell

## Test Contract

Unit tests:
- token values map to `tokens.css`
- tab enum has Map/Add/Discover/Profile only
- visibility matrix
- block removes follow edges and hides search/list/map rows
- username normalization and uniqueness helpers
- sync state transitions
- deterministic parser schema validation
- duplicate save merge by `user_id + place_id`
- extraction confidence gate never auto-saves low confidence

Backend/RLS tests:
- owner can read/write own rows
- follower can read `followers`, not `mutuals` or `self`
- mutual can read `followers` and `mutuals`, not `self`
- non-follower can read shell only
- logged-out cannot read place rows
- block hides both directions
- delete/tombstone removes active product visibility
- `visible_places_in_view` excludes blocked/self-denied rows
- `search_profiles_by_handle` excludes blocked rows
- `save_visible_place` preserves attribution when allowed
- `claim_guest_records` maps local ids to server ids and rejects unauthorized rows

UI tests:
- guest first save local
- current location happy/denied
- manual add happy path
- link/photo unresolved draft shell
- visibility picker before save
- follow/unfollow/block from profile/search
- fake contacts matched/unmatched
- Discover query -> chips -> results
- blocked profile disappears from stale detail

Hostile tests:
- double-tap save
- navigate away mid-save
- background mid-extraction shell
- stale mutual relationship loses mutual-only access
- 10,000 dense viewport rows use clustered/limited query path

## Design Review Gate

Run plan/design review after this contract, before M2 polish, focused on:
- other-user profile states
- followers/following lists
- username/contact search results
- Discover smart filters/result cards
- block confirmation/blocked profile/blocked settings
- settings detail rows
- non-follower profile shell
- auth gates at save/sync/follow
- social place detail when access changes mid-flow

## Parallelization

Sequential until M1.5 is accepted.

After M1.5:

| Lane | Work | Modules | Depends on |
|---|---|---|---|
| A | M0/M1 Swift foundation | `Wander/`, `WanderTests/`, `project.yml` | M1.5 |
| B | Supabase schema/RLS draft | `supabase/`, `docs/` | M1.5 |
| C | Design review/polish spec | `DESIGN.md`, `preview/`, `docs/` | M1.5 |
| D | Deterministic parser tests | `Wander/Services`, `WanderTests` | M1 Swift foundation |

Execution order:
1. Finish M1.5.
2. Launch A + B + C in parallel if using worktrees.
3. Merge A, then D.
4. M2 UI proceeds after A + C and uses contracts from B.

Conflict flags:
- A and D both touch `Wander/Services`; D should wait for A.
- B and A must not invent conflicting model names. M1.5 schema names are canonical.
