# M3 Supabase Foundation

Last updated: 2026-06-08

This is the backend contract started for M3. It should be reviewed and run before wiring Clerk UI or live Supabase calls into the iOS app.

## Files

- Migrations:
  - `supabase/migrations/20260602131500_m3_foundation.sql`
  - `supabase/migrations/20260602140304_clerk_profile_mirroring.sql`
  - `supabase/migrations/20260602143000_public_clerk_profile_mirror_rpc.sql`
  - `supabase/migrations/20260602210000_public_app_rpc_wrappers.sql`
  - `supabase/migrations/20260608174400_enqueue_extraction_job.sql`
  - `supabase/migrations/20260608175500_fix_enqueue_extraction_job_variable.sql`
  - `supabase/migrations/20260608193200_extraction_worker_rpcs.sql`
  - `supabase/migrations/20260608194600_fix_extraction_worker_helper_grants.sql`
- Tests:
  - `supabase/tests/rls_visibility.sql`
  - `supabase/tests/clerk_profile_mirroring.sql`
  - `supabase/tests/extraction_jobs.sql`
- Edge Functions:
  - `supabase/functions/clerk-profile-webhook/index.ts`
  - `supabase/functions/extraction-worker/index.ts`
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
  - `supabase/tests/extraction_jobs.sql`: 16 assertions, 0 failures.
  - Total: 45 assertions, 0 failures.
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

- Review hosted Supabase Auth settings before alpha because `npx supabase config push` pushed generated local auth defaults plus Clerk config.

Verified hosted auth status:

- 2026-06-04 live smoke passed after adding the Supabase Clerk provider connection with domain `https://growing-pheasant-22.clerk.accounts.dev`.
- Default Clerk session tokens are accepted by Supabase PostgREST/RLS.
- Authenticated RPCs passed for profile search, follow, visible places, social save, block, unblock, and unfollow.

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
- `app.enqueue_extraction_job(input_source_artifact, input_job)`
- `app.get_extraction_job(input_job_id)`
- `app.claim_extraction_job(input_job_id)`
- `app.claim_next_extraction_job()`
- `app.complete_extraction_job(input_job_id, input_status, input_candidates, input_confidence, input_provider_steps, input_error_code, input_error_message)`
- `public.visible_places_in_view(...)` authenticated PostgREST wrapper
- `public.search_profiles_by_handle(query)` authenticated PostgREST wrapper
- `public.profile_visible_places(...)` authenticated PostgREST wrapper
- `public.follow_user(profile_id, source)` authenticated PostgREST wrapper
- `public.unfollow_user(profile_id)` authenticated PostgREST wrapper
- `public.block_user(profile_id)` authenticated PostgREST wrapper
- `public.unblock_user(profile_id)` authenticated PostgREST wrapper
- `public.save_visible_place(input_place_id, input_source_user_place_id)` authenticated PostgREST wrapper returning `{ "user_place_id": ... }` for iOS
- `public.claim_guest_records(local_records)` authenticated PostgREST wrapper
- `public.enqueue_extraction_job(input_source_artifact, input_job)` authenticated PostgREST wrapper returning `{ "source_artifact_id", "extraction_job_id", "status", "attempt_count" }` for iOS
- `public.get_extraction_job(input_job_id)` authenticated PostgREST wrapper returning job status, candidate JSON, confidence, and error fields.
- `public.claim_extraction_job(input_job_id)` authenticated PostgREST wrapper used by the Edge Function with the caller's auth token to claim only that user's job.
- `public.claim_next_extraction_job()` service-role wrapper for scheduled/manual worker runs.
- `public.complete_extraction_job(...)` service-role wrapper for writing worker results.

Notes:

- The hosted/local API exposes `public`, not the private `app` schema. iOS calls the `public.*` wrapper names through PostgREST; core logic stays under `app.*`.
- `visible_places_in_view` and `profile_visible_places` return joined place/profile rows with attached attributes.
- `save_visible_place` copies the visible source place into the caller's map as `wanna_go`, including source attribution and attached attributes.
- `claim_guest_records` is a stub until the sync worker/merge path is designed.
- `block_user` is a guarded `security definer` so it can remove both directions of the follow edge when a hard block is created.
- `enqueue_extraction_job` idempotently upserts `source_artifacts` and `extraction_jobs` for the authenticated user.
- `extraction-worker` is the first M6 worker. App-triggered calls use the user's auth token to claim only their own job, then the function completes the job with service-role credentials. Current worker scope is conservative: coordinate-backed Google Maps/link/web metadata candidates can return as `needs_confirmation`; photo OCR and unsupported sources return `no_place_found` and remain manual drafts. The worker never auto-creates `places` or `user_places`.

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

`supabase/tests/extraction_jobs.sql` covers:

- Authenticated enqueue returns an extraction job id.
- First enqueue creates one source artifact and one extraction job.
- Duplicate enqueue returns the existing job and does not duplicate rows.
- Retrying a failed job resets status to `pending`, increments attempt count, and clears the error code.
- Authenticated owner claim moves the job to `running`.
- Service completion writes confirmation candidates, confidence, and worker steps.
- Completion does not auto-create canonical places.
- Owner result fetch returns status, candidates, and confidence.

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
