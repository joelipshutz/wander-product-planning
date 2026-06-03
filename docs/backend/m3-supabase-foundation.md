# M3 Supabase Foundation

Last updated: 2026-06-02

This is the backend contract started for M3. It should be reviewed and run before wiring Clerk UI or live Supabase calls into the iOS app.

## Files

- Migrations:
  - `supabase/migrations/20260602131500_m3_foundation.sql`
  - `supabase/migrations/20260602140304_clerk_profile_mirroring.sql`
  - `supabase/migrations/20260602143000_public_clerk_profile_mirror_rpc.sql`
  - `supabase/migrations/20260602210000_public_app_rpc_wrappers.sql`
- Tests:
  - `supabase/tests/rls_visibility.sql`
  - `supabase/tests/clerk_profile_mirroring.sql`
- Edge Function: `supabase/functions/clerk-profile-webhook/index.ts`
- Source plan: `docs/plans/2026-06-01-wander-ios-eng-plan.md`
- Contract lock: `docs/plans/2026-06-01-wander-m1-5-contract-lock.md`

## Hosted Project Status

Created on 2026-06-02:

- Supabase project: `wander`
- Supabase ref: `rugmtlgufrhlxwfkumhw`
- Region: `us-west-2`
- Dashboard: `https://supabase.com/dashboard/project/rugmtlgufrhlxwfkumhw`
- Clerk app: `Wander`
- Clerk app id: `app_3Eb3JbpbMDjOA2qKUCqfsZwfct9`
- Clerk dev instance id: `ins_3Eb3Je6FO3qfUDIt5n3aTHMxYN1`
- Clerk dev domain: `growing-pheasant-22.clerk.accounts.dev`

Local-only secrets/config were stored in `/Users/joelipshutz/.openclaw/workspace/.env.keys`.

The migrations were pushed to the hosted Supabase project on 2026-06-02, including the public app RPC wrapper migration added during the M3 audit.

Webhook status:

- Supabase Edge Function: `clerk-profile-webhook`
- Function URL: `https://rugmtlgufrhlxwfkumhw.supabase.co/functions/v1/clerk-profile-webhook`
- Clerk/Svix endpoint id: `ep_3Eb5WlmjQlDav83RHa3hWxp07wd`
- Endpoint event scope: currently listening to all Clerk events; function ignores non-user events.
- Edge Function secrets set in Supabase:
  - `CLERK_WEBHOOK_SIGNING_SECRET`
  - `WANDER_SUPABASE_URL`
  - `WANDER_SUPABASE_SERVICE_ROLE_KEY`

Backend test status:

- `npx supabase test db --linked ...` could not run because the Supabase CLI still requires Docker for its pgTAP runner.
- A temporary Node `pg` runner executed SQL tests against hosted Postgres.
- Result:
  - `supabase/tests/rls_visibility.sql`: 15 assertions, 0 failures.
  - `supabase/tests/clerk_profile_mirroring.sql`: 14 assertions, 0 failures.
  - Total: 29 assertions, 0 failures.
- Direct signed webhook POST passed: Svix-style signature verification, Edge Function, PostgREST RPC, and profile lookup.
- Real Clerk create/delete passed: disposable Clerk dev user mirrored through Clerk -> Svix -> Supabase and then soft-deleted on `user.deleted`.

Local stack status:

- Supabase CLI is available through `npx supabase`.
- Docker is not installed/running, so `npx supabase start`, `npx supabase db reset`, and Supabase's built-in local/linked test runner are blocked.

Expected local runner once Docker-compatible runtime is available:

```bash
npx supabase start
npx supabase db reset
npx supabase test db supabase/tests/rls_visibility.sql
```

Use `--no-seed` if seed data is re-enabled before `supabase/seed.sql` exists.

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

- Confirm hosted Supabase Auth third-party Clerk config in the dashboard if auth wiring fails. `supabase/config.toml` contains the Clerk domain and `npx supabase config push` was run.
- Review hosted Supabase Auth settings before alpha because `npx supabase config push` pushed generated local auth defaults plus Clerk config.

## Profile Mirroring

Clerk user mirroring is implemented through the `clerk-profile-webhook` Edge Function.

Flow:

1. Clerk emits `user.created`, `user.updated`, or `user.deleted`.
2. Svix delivers the signed webhook to the Supabase Edge Function.
3. The Edge Function verifies `svix-id`, `svix-timestamp`, and `svix-signature`.
4. The function calls `public.mirror_clerk_profile` through PostgREST using service-role credentials.
5. `public.mirror_clerk_profile` is a service-role wrapper around private `app.mirror_clerk_profile`.

The database function handles:

- duplicate Svix event ids
- stale event ordering
- handle normalization and collision suffixes
- delete-before-create events
- soft-deleting profiles on `user.deleted`

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

- `app.mirror_clerk_profile(event_id, event_type, event_timestamp, profile_id, desired_handle, desired_display_name, desired_avatar_url)`
- `public.mirror_clerk_profile(...)` service-role PostgREST wrapper
- `app.visible_places_in_view(min_lat, min_lng, max_lat, max_lng, status_filter, category_filter, owner_scope)`
- `app.search_profiles_by_handle(query)`
- `app.profile_visible_places(profile_id, status_filter, category_filter)`
- `app.follow_user(profile_id, source)`
- `app.unfollow_user(profile_id)`
- `app.block_user(profile_id)`
- `app.unblock_user(profile_id)`
- `app.save_visible_place(input_place_id, input_source_user_place_id)`
- `app.claim_guest_records(local_records)`
- `public.visible_places_in_view(...)` authenticated PostgREST wrapper
- `public.search_profiles_by_handle(query)` authenticated PostgREST wrapper
- `public.profile_visible_places(...)` authenticated PostgREST wrapper
- `public.follow_user(profile_id, source)` authenticated PostgREST wrapper
- `public.unfollow_user(profile_id)` authenticated PostgREST wrapper
- `public.block_user(profile_id)` authenticated PostgREST wrapper
- `public.unblock_user(profile_id)` authenticated PostgREST wrapper
- `public.save_visible_place(input_place_id, input_source_user_place_id)` authenticated PostgREST wrapper returning `{ "user_place_id": ... }` for iOS
- `public.claim_guest_records(local_records)` authenticated PostgREST wrapper

Notes:

- The hosted/local API exposes `public`, not the private `app` schema. iOS calls the `public.*` wrapper names through PostgREST; core logic stays under `app.*`.
- `visible_places_in_view` and `profile_visible_places` return joined place/profile rows with attached attributes.
- `save_visible_place` copies the visible source place into the caller's map as `wanna_go`, including source attribution and attached attributes.
- `claim_guest_records` is a stub until the sync worker/merge path is designed.
- `block_user` is a guarded `security definer` so it can remove both directions of the follow edge when a hard block is created.

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

`supabase/tests/clerk_profile_mirroring.sql` covers:

- profile create/update mirroring
- handle collisions
- duplicate event id ignoring
- soft delete
- stale update after delete
- delete-before-create ordering
- public PostgREST wrapper write-through

Still needed:

- Logged-out/anon behavior.
- Delete/tombstone behavior.
- `save_visible_place` copy behavior.
- `follow_user`, `unfollow_user`, `block_user`, and `unblock_user` mutation behavior.
- Public wrapper RPC behavior for the app-facing functions.
- Standard Supabase CLI test runner once Docker/OrbStack/Colima is available.

## Notes From Project Setup

`npx supabase config push` pushes the whole local auth config, not only the Clerk third-party auth section. This was acceptable for the new dev project, but before alpha the hosted auth settings should be reviewed in the Supabase dashboard.

The local config has:

```toml
[auth.third_party.clerk]
enabled = true
domain = "growing-pheasant-22.clerk.accounts.dev"
```

Clerk development session tokens were patched with:

```json
{
  "session": {
    "claims": {
      "role": "authenticated"
    }
  }
}
```
