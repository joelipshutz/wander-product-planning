# AGENTS.md

Repo guidance for Codex, Claude Code, OpenClaw, and any developer joining Wander.

## Project Overview

Rec.me, formerly Wander, is a native iOS social map for remembering places worth returning to and discovering places through trusted people.

North Star: when someone needs a place, Wander shows where trusted people have actually been, what they thought, and whether it fits the moment.

Current wedge: trusted people's place memories become a searchable map you can actually use.

Do not reframe this as a lists app, public feed, travel-only app, check-in game, restaurant-only ranking app, or live-location product.

## Required Agent Work Log

All agents working in this repo must keep `docs/agent-log.md` current.

Before non-trivial work:

- Read the latest entries in `docs/agent-log.md`.
- Append a new entry with date/time, agent/tool name, goal, branch, current git status, and files you expect to touch.
- If another agent is already working on overlapping files, call that out before editing.

During work:

- Append meaningful checkpoints for long tasks, roughly every 30 minutes or whenever the plan materially changes.
- Log decisions, assumptions, commands run, test results, blockers, screenshots reviewed, and files changed.
- If you discover dirty worktree changes you did not make, log them and do not revert them.

At handoff or completion:

- Append final outcome, commit hash or PR, tests run, known issues, and concrete next steps.
- If work is incomplete, include exact restart instructions.
- Do not leave important decisions only in chat. Durable project decisions belong in `docs/decisions.md` or `docs/open-questions.md` as appropriate.

This log is coordination infrastructure. Treat it as part of the deliverable.

## Tech Stack

- Native iOS, iPhone-first.
- SwiftUI, Swift 6 mode, iOS 17+.
- SwiftData for local persistence and offline-first cache.
- MapKit/CoreLocation for maps and place lookup.
- PhotosUI later for photo capture/import.
- XcodeGen owns project generation through `project.yml`.
- Planned backend: Clerk for identity/account UX, Supabase Postgres/RLS/PostGIS/storage/functions for app data.
- Current M2 implementation uses local seeded data through `WanderStore` and deterministic fakes.

## How To Run Locally

Generate the Xcode project after changing source files or `project.yml`:

```bash
xcodegen generate
```

Build:

```bash
xcodebuild build -project Wander.xcodeproj -scheme Wander -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO
```

Test:

```bash
xcodebuild test -project Wander.xcodeproj -scheme Wander -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.6' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO
```

If Xcode plugin/CoreSimulator access fails under a sandbox, rerun from a normal terminal or with approved elevated access.

## Architecture

Important folders:

- `Wander/App/` - app entry point and root tab shell.
- `Wander/DesignSystem/` - SwiftUI tokens and shared components.
- `Wander/Features/Map/` - map surface and selected place sheet.
- `Wander/Features/Add/` - current-location/manual/link/photo add flow.
- `Wander/Features/Discover/` - smart filters, search, people/profile lookup.
- `Wander/Features/Profile/` - owner profile, other-user profiles, graph lists.
- `Wander/Features/Settings/` - settings gear surface from Profile.
- `Wander/Models/` - local models, enums, visibility/sync contracts.
- `Wander/Services/` - fixtures, local store, repository/parser/provider protocols.
- `WanderTests/` - unit and contract tests.
- `preview/follow-profile-settings-mocks/` - approved visual handoff source.
- `docs/` - spec, plans, decisions, handoff, setup, reviews, agent log.

Core rules:

- Views must not call Clerk or Supabase directly. Use repository/protocol boundaries.
- Supabase RLS is authoritative for social visibility; client visibility policy is UI-only.
- Four bottom tabs only: Map, Add, Discover, Profile. Settings opens from Profile gear.
- `project.yml` is the Xcode source of truth. Regenerate with XcodeGen instead of hand-editing project membership.
- Link/photo capture in M2 is an honest unresolved-draft shell until backend extraction jobs exist.
- Native Contacts permission is planned later; M2 uses `FakeContactProvider` plus username search.

## Current Priorities

1. Fix M2 visual QA issues on real simulator sizes, starting with Map screen scale/orientation/safe areas.
2. Keep M2 local loop working: map, add, discover, profile, settings, follow/unfollow/block, visibility, drafts.
3. Move next to M3 only after the UI baseline is acceptable: Clerk + Supabase schema/RLS foundation.
4. Preserve docs as source of truth for new contributors: start with `docs/codex-handoff.md`, `docs/roadmap.md`, and `docs/decisions.md`.

## Known Issues And Gotchas

- The first native M2 UI pass is functionally wired but visually poor on simulator screenshots: map content appears undersized/letterboxed and controls are oversized/crowded. Treat this as the active UI bug.
- `preview/follow-profile-settings-mocks/` is the approved visual baseline. Do not generate a competing design direction unless Joe explicitly asks.
- Existing handoff mocks are a reference, not production code. Recreate the intent natively in SwiftUI.
- UI copy says Everyone/Friends/Self, but backend values are `followers`/`mutuals`/`self`. "Everyone" means followers-visible in v0.1, not the public internet.
- Follow graph is one-way follows; friends are mutual follows.
- Blocks are hard blocks: blocked users should disappear from search, lists, profiles, map results, and stale views.
- There may be local Xcode signing/team edits in `Wander.xcodeproj/project.pbxproj` from opening the project. Do not commit project signing churn unless intentional.

## Style Rules

- Follow `DESIGN.md` before changing UI.
- Promote visual tokens from `preview/follow-profile-settings-mocks/tokens.css` into SwiftUI tokens 1:1.
- Warm, map-first, playful utility. Avoid sterile SaaS, generic travel blue, influencer-feed language, or all-beige drift.
- Use SF Symbols/native controls where appropriate. Emoji may appear in category/question affordances only if accessible and not structural.
- Respect safe areas, Dynamic Type, 44pt minimum tap targets, keyboard, and the home indicator.
- iPhone-first. Do not stretch phone UI into desktop/iPad layouts without a specific side-panel plan.

## Testing Rules

- Every milestone should land with matching tests.
- Run the full `xcodebuild test` command above before committing implementation changes.
- Current important test coverage:
  - design tokens
  - four-tab navigation contract
  - visibility policy
  - sync state machine
  - deterministic Discover parser
  - local store follow/block/search/save/draft behavior
- For visual work, also capture simulator screenshots across at least the current iPhone target and one smaller phone target before calling the UI ready.

## TestFlight Release Notes

Whenever an agent uploads a new TestFlight build, attaches it to the public group, or confirms it is available for testing, the agent must also post a short release note to the rec.me Slack feedback channel:

- Slack channel: `#testflight-feedback`
- Slack channel ID: `C0BAA7DG2AC`
- Public TestFlight link: `https://testflight.apple.com/join/knEhRa6t`

The Slack note must include:

- App name `rec.me`, the build number, and whether the build is live/approved or still processing.
- What changed, written for testers rather than engineers.
- What needs testing, as a concrete checklist.
- Known issues or intentionally deferred areas.
- A request to reply in-thread with device, account/email if relevant, screenshots, and exact repro steps.

For broad announcements only, `#all-recme` (`C0B9FU1QNG2`) exists, but TestFlight feedback prompts belong in `#testflight-feedback`.

## Useful References

- Product spec: `docs/specs/wander-ios-product-spec.md`
- Engineering plan: `docs/plans/2026-06-01-wander-ios-eng-plan.md`
- Contract lock: `docs/plans/2026-06-01-wander-m1-5-contract-lock.md`
- Design system: `DESIGN.md`
- Design review: `docs/reviews/2026-06-01-plan-design-review.md`
- Engineering review: `docs/reviews/2026-06-01-plan-eng-review.md`
- Handoff for new agents/developers: `docs/codex-handoff.md`
- Setup commands: `docs/setup.md`
- Agent coordination log: `docs/agent-log.md`
