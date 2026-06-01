# Wander TODOs

Date: 2026-05-29

## P1

- Integrate onboarding spec before eng plan review. Done 2026-05-31.
  - Why: onboarding decides how privacy defaults, first place capture, and first follow are introduced.
  - Result: main spec now references `research/screensdesign/2026-05-30-social-map-onboarding/` and adopts map-first guest onboarding with auth at save intent.

- Run office-hours on the product direction.
  - Why: validate the problem framing before architecture work hardens the direction.
  - Depends on: current product spec.

- Run plan-design-review. Done 2026-05-30 as a mock-backed review using the Lovable PDF mocks.
  - Why: the app has significant UI scope and the mocks need product/design stress testing.
  - Result: design spec now includes information hierarchy, state coverage, journey, tokens, accessibility, and unresolved design decisions.
  - Follow-up: extra visual variants are not blocking; current handoff package is the source of truth.

- Refresh design review / mocks for follow graph, profiles, and settings. Updated 2026-06-01 from `wander.zip` design handoff.
  - Why: the original mocks cover map, discover, and add flow, but the 2026-06-01 graph change adds profile pages, followers/following lists, block controls, settings, and a three-tier visibility picker.
  - Result: `preview/follow-profile-settings-mocks/` now holds the design handoff package. `tokens.css` is the literal source of truth; `index.html` and `screens.html` cover the core design system, Map, Add, saved, and merged Profile surfaces.
  - Follow-up: run design review against the handoff plus the missing visual states: Discover, other-user profiles, followers/following, settings details, onboarding, and block/access-change states.

- Run plan-eng-review. Done 2026-06-01.
  - Why: backend, sync, privacy rules, extraction, and data model need architecture review before implementation.
  - Result: `docs/reviews/2026-06-01-plan-eng-review.md` captures Clerk + Supabase, guest-local save, followers-only public visibility, backend extraction jobs, deferred share extension, MapKit-only places, hard block, username rules, and delete/source retention.
  - Result: native Contacts is planned later; v0.1 uses fake contacts and username search.

- Create iOS engineering implementation plan. Done 2026-06-01.
  - Why: locked product/design decisions need a build sequence before code starts.
  - Result: `docs/plans/2026-06-01-wander-ios-eng-plan.md` defines milestones, modules, schema, RLS, sync, LLM parser, analytics, extraction jobs, and tests.

- Start M0/M1 iOS implementation foundation. In progress 2026-06-01.
  - Why: app shell, local models, service boundaries, fakes, and tests unblock the product loop.
  - Result: generated Xcode project with SwiftUI four-tab shell, token layer, SwiftData model skeleton, repository/service protocols, fake fixtures, visibility policy, Discover parser, and initial tests.

## P2

- Decide backend/auth stack. Done 2026-06-01.
  - Why: follow graph, geo queries, offline sync, profile/block rules, and visibility policies are core to Wander.
  - Decision: Clerk + Supabase. Clerk owns identity/session/account surfaces; Supabase owns Postgres/RLS/PostGIS/storage/functions; SwiftData owns local cache and sync queue.

- Evaluate Slate extraction code against Wander requirements.
  - Why: Slate has useful extraction pieces, but Instagram and location extraction are known weak spots.
  - Decision so far: backend extraction jobs are the alpha direction; detailed provider/job architecture still needs a focused pass before real social alpha.

- Decide whether share extension ships in v0.1. Done 2026-06-01.
  - Why: share-sheet capture may be a major activation path, but can slow first implementation.
  - Decision: defer. Track as a later TODO after in-app add, map, and social loop work.

- Decide whether native Contacts integration ships in v0.1. Done 2026-06-01.
  - Why: contacts are a recommended people-finding affordance, but native Contacts adds permission/privacy and App Store disclosure work.
  - Decision: native Contacts is planned later, not in v0.1. Build the contacts-first UI against `FakeContactProvider` plus username search.
  - Later native scope: add pre-permission copy, denied-permission UX, hashed matching, backend privacy rules, App Store disclosure, seeded/contact test fixtures, and contact-import QA.

- Add lightweight LLM Discover query parser up front.
  - Why: Joe wants natural-language/smart query UX early, but execution should stay constrained to structured filters.
  - Implementation path: parse only the raw search phrase plus filter schema into filter JSON via a cheap/swappable model path, render editable chips, cache repeated parses, and fall back to smart filter chips on failure.

- Define v0.1 sync conflict behavior.
  - Why: offline save/edit/delete must be predictable before implementing repositories and sync queue.
  - Decision: simple `updated_at`/server-wins handling plus local retry queue; field-level multi-device merge is out of scope.

- Define analytics events behind a vendor-neutral interface.
  - Why: capture, social graph, Discover parse quality, extraction quality, and sync failures need instrumentation, but provider choice should not block the plan.
  - Decision: name events now; choose PostHog/Amplitude/etc. later.

- Create `DESIGN.md` before implementation. Done 2026-06-01.
  - Why: the design review found no project-level design system, and implementation needs stable tokens/components.
  - Result: root `DESIGN.md` now captures product feel, IA, handoff token source, components, onboarding rules, accessibility, and plan-eng-review dependencies.
  - Follow-up: font package/licensing and architecture-sensitive states still need validation.

- Decide whether to approve gstack designer variant generation. Done 2026-06-01.
  - Why: plan-design-review used the existing mocks but could not generate a new visual comparison board without external-call approval.
  - Decision: do not block eng plan. Current handoff package remains the source of truth.
