# Setup

Last updated: 2026-06-02

## Requirements

- macOS with Xcode installed.
- iOS Simulator runtime available.
- XcodeGen installed and available as `xcodegen`.
- GitHub access to `joelipshutz/wander`.

## Clone

```bash
git clone git@github.com:joelipshutz/wander.git
cd wander
```

If you are working in Joe's local workspace, the repo path is:

```bash
/Users/joelipshutz/Developer/Wander (nametbd)
```

## Generate Project

`project.yml` is the source of truth for the Xcode project.

```bash
xcodegen generate
```

Run this after changing file membership, targets, or generated project settings.

## Open In Xcode

Open:

```text
Wander.xcodeproj
```

Do not commit incidental signing/team changes from Xcode unless intentional.

## Build

```bash
xcodebuild build -project Wander.xcodeproj -scheme Wander -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO
```

## Test

```bash
xcodebuild test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO
```

Known good result on 2026-06-01:

```text
18 tests, 0 failures
```

If CoreSimulator or Swift plugin server errors happen in a sandbox, rerun from a normal terminal or with approved elevated access.

## Supabase

The new Wander Supabase project was created on 2026-06-02.

- Project name: `wander`
- Project ref: `rugmtlgufrhlxwfkumhw`
- Region: `us-west-2`

Local-only credentials are stored in:

```text
/Users/joelipshutz/.openclaw/workspace/.env.keys
```

Useful commands:

```bash
npx supabase projects list
npx supabase migration list --linked
npx supabase db push --linked
npx supabase functions deploy clerk-profile-webhook --project-ref "$WANDER_SUPABASE_PROJECT_REF" --no-verify-jwt --use-api
```

Local Supabase requires Docker. Docker is not currently available in this environment, so the local stack commands are blocked until Docker/OrbStack/Colima is installed and running:

```bash
npx supabase start
npx supabase db reset
npx supabase test db supabase/tests/rls_visibility.sql
```

The hosted migrations and Clerk profile webhook have been pushed/deployed. The current SQL tests passed against hosted Postgres through a temporary Node `pg` runner because the Supabase CLI pgTAP runner still requires Docker.

Current hosted SQL test status:

```text
supabase/tests/rls_visibility.sql: 15 assertions, 0 failures
supabase/tests/clerk_profile_mirroring.sql: 14 assertions, 0 failures
```

## Clerk

The new Wander Clerk application was created on 2026-06-02.

- App name: `Wander`
- App id: `app_3Eb3JbpbMDjOA2qKUCqfsZwfct9`
- Development instance id: `ins_3Eb3Je6FO3qfUDIt5n3aTHMxYN1`
- Development domain: `growing-pheasant-22.clerk.accounts.dev`

Local-only Clerk env values are stored in `/Users/joelipshutz/.openclaw/workspace/.env.keys`.

The Clerk development instance has session token claims patched for Supabase:

```json
{"role":"authenticated"}
```

The repo is linked to the Clerk app through the Clerk CLI remote link:

```bash
npx clerk whoami --json
```

Clerk user profile mirroring is wired through Svix:

- Supabase Edge Function: `clerk-profile-webhook`
- Function URL: `https://rugmtlgufrhlxwfkumhw.supabase.co/functions/v1/clerk-profile-webhook`
- Clerk/Svix endpoint id: `ep_3Eb5WlmjQlDav83RHa3hWxp07wd`
- The endpoint currently listens to all Clerk events; the function handles only `user.created`, `user.updated`, and `user.deleted`.

The Svix signing secret and function service credentials are stored local-only and in Supabase Edge Function secrets. Do not commit them.

## Visual QA

For UI work:

1. Run the app in the simulator.
2. Capture screenshots for Map, Add, Discover, Profile, and Settings.
3. Test at least the active iPhone target and one smaller iPhone target.
4. Verify safe areas, bottom nav, sheets, search/chips, text fitting, and home indicator spacing.

Current known visual failure:

- Map screen is undersized/letterboxed and the controls are too large/crowded on the simulator screenshot Joe shared on 2026-06-01.

## Main Files To Read First

```text
AGENTS.md
README.md
docs/codex-handoff.md
docs/roadmap.md
docs/decisions.md
docs/open-questions.md
docs/setup.md
docs/agent-log.md
docs/specs/wander-ios-product-spec.md
docs/plans/2026-06-01-wander-ios-eng-plan.md
DESIGN.md
```

## Common Commands

Status:

```bash
git status --short --branch
```

Recent commits:

```bash
git log --oneline -5
```

Verify remote main:

```bash
git ls-remote origin refs/heads/main
```
