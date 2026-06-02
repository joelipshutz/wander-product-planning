# M3 Supabase Foundation

Last updated: 2026-06-02

This is the backend contract started for M3. It should be reviewed and run before wiring Clerk UI or live Supabase calls into the iOS app.

## Files

- Migration: `supabase/migrations/20260602131500_m3_foundation.sql`
- RLS tests: `supabase/tests/rls_visibility.sql`
- Source plan: `docs/plans/2026-06-01-wander-ios-eng-plan.md`
- Contract lock: `docs/plans/2026-06-01-wander-m1-5-contract-lock.md`

## Current Local Status

The SQL artifacts are written, but not executed locally yet.

As of 2026-06-02, this machine does not have:

- `supabase`
- `psql`

Before M3 is considered verified, install/configure a Supabase/Postgres test runner and run the migration plus RLS tests.

Expected runner once Supabase CLI is available:

```bash
supabase db reset
supabase test db
```

If those commands differ after local project configuration, update this file and `docs/setup.md`.

## Clerk Mapping

Decision: use Clerk's native Supabase third-party auth integration.

Ownership fields store Clerk user ids as text:

- `profiles.id`
- `follows.follower_user_id`
- `follows.followed_user_id`
- `blocks.blocker_user_id`
- `blocks.blocked_user_id`
- `user_places.user_id`
- `source_artifacts.user_id`
- `extraction_jobs.owner_user_id`

RLS reads the Clerk user id from:

```sql
auth.jwt() ->> 'sub'
```

The migration helper is `app.current_user_id()`. It also falls back to `request.jwt.claim.sub` so local SQL tests can set a fake caller.

Official docs checked on 2026-06-02:

- [Supabase Clerk third-party auth](https://supabase.com/docs/guides/auth/third-party/clerk)
- [Clerk Supabase integration guide](https://clerk.com/docs/guides/development/integrations/databases/supabase)

Remaining setup work:

- Configure Clerk as a Supabase third-party auth provider.
- Ensure Clerk session tokens include `role=authenticated`.
- Mirror Clerk users into `profiles` through webhook or backend job.

## Schema

Core tables:

- `profiles`
- `follows`
- `blocks`
- `places`
- `source_artifacts`
- `user_places`
- `question_definitions`
- `place_attributes`
- `extraction_jobs`
- `sync_tombstones`
- `analytics_events`

PostGIS is enabled and `places.geog` is generated from latitude/longitude for map queries.

Authenticated clients may insert candidate canonical places. Updating/reconciling canonical `places` should be handled by service-role backend code, not directly by clients.

## Question And Input Model

The model is intentionally extensible because users will later be able to add their own questions and inputs.

Rules:

- Do not add new answer columns for new prompts.
- Add prompt metadata to `question_definitions`.
- Store answers in `place_attributes.value` as JSONB.
- Keep `place_attributes.question_key` as a stable string key for offline/local compatibility.
- Use `place_attributes.question_definition_id` when the backend knows the definition.

System starter prompts:

- `question_definitions.is_system = true`
- `owner_user_id = null`
- Readable to authenticated clients.

Future user-created prompts:

- `is_system = false`
- `owner_user_id = app.current_user_id()`
- Owner can create/update/delete.
- Other users can read the definition only when it is attached to a visible `place_attribute`.

This supports category-specific starter prompts now and custom questions later without schema churn.

## Visibility Contract

Supabase RLS is authoritative.

Visibility values:

- `followers`: readable by the owner and people who follow the owner.
- `mutuals`: readable by the owner and mutual follows.
- `self`: readable only by the owner.

Blocks are hard blocks. A block hides profiles, places, follows, search results, and attached attributes both ways.

## RPC Contract

Implemented in the migration:

- `app.visible_places_in_view(min_lat, min_lng, max_lat, max_lng, status_filter, category_filter, owner_scope)`
- `app.search_profiles_by_handle(query)`
- `app.profile_visible_places(profile_id, status_filter, category_filter)`
- `app.follow_user(profile_id, source)`
- `app.unfollow_user(profile_id)`
- `app.block_user(profile_id)`
- `app.save_visible_place(input_place_id, input_source_user_place_id)`
- `app.claim_guest_records(local_records)`

Notes:

- `visible_places_in_view` and `profile_visible_places` return joined place/profile rows with attached attributes.
- `save_visible_place` copies the visible source place into the caller's map as `wanna_go`, including source attribution and attached attributes.
- `claim_guest_records` is a stub until the sync worker/merge path is designed.

## Test Coverage Draft

`supabase/tests/rls_visibility.sql` covers:

- Owner can read own `followers`, `mutuals`, and `self` rows.
- One-way follower can read `followers` rows only.
- Mutual follow can read `followers` and `mutuals`.
- Non-follower can read profile shell but no places.
- Blocked viewer cannot read profile or places.
- Attributes inherit user-place visibility.
- Attached custom question definitions become readable with visible places.
- Unattached custom question definitions stay hidden from other users.
- `visible_places_in_view` and `search_profiles_by_handle` return expected rows.

Still needed after runner setup:

- Logged-out/anon behavior.
- Delete/tombstone behavior.
- `save_visible_place` copy behavior.
- `follow_user`, `unfollow_user`, and `block_user` mutation behavior.
- Profile mirroring webhook tests.
