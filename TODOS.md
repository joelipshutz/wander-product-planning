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
  - Follow-up: generating new visual variants was blocked pending explicit approval for the external gstack designer call.

- Refresh design review / mocks for follow graph, profiles, and settings. Redone 2026-06-01 with Rodeo-ish visual direction.
  - Why: the original mocks cover map, discover, and add flow, but the 2026-06-01 graph change adds profile pages, followers/following lists, block controls, settings, and a three-tier visibility picker.
  - Result: local storyboard added at `preview/follow-profile-settings-mocks/index.html` with my profile/You, other-user profile, followers/following, username/contact search, Discover smart filters, Settings, visibility picker, coffee/hike question flows, block flow, blocked users, non-follower shell, and access-changed state.
  - Follow-up: run design review against the storyboard and native implementation plan.

- Run plan-eng-review.
  - Why: backend, sync, privacy rules, extraction, and data model need architecture review before implementation.
  - Depends on: refreshed design coverage for follow/profile/settings and the updated product spec.

## P2

- Decide Supabase vs Firebase.
  - Why: follow graph, geo queries, offline sync, profile/block rules, and visibility policies are core to Wander.
  - Depends on: backend-neutral contracts in `docs/specs/wander-ios-product-spec.md`.

- Evaluate Slate extraction code against Wander requirements.
  - Why: Slate has useful extraction pieces, but Instagram and location extraction are known weak spots.
  - Depends on: extraction requirements in the Wander spec.

- Decide whether share extension ships in v0.1.
  - Why: share-sheet capture may be a major activation path, but can slow first implementation.
  - Depends on: add-flow design and extraction architecture.

- Decide whether native Contacts integration ships in v0.1. Done 2026-06-01.
  - Why: contacts are a recommended people-finding affordance, but native Contacts adds permission/privacy and App Store disclosure work.
  - Decision: prototype with `FakeContactProvider` and username search; add native Contacts before a real social beta once backend matching and privacy copy are ready.
  - Implementation path: test with `FakeContactProvider`, seeded users/follow edges, and username search; plug in native Contacts behind the same `ContactProvider`.

- Create `DESIGN.md` before implementation. Done 2026-06-01.
  - Why: the design review found no project-level design system, and implementation needs stable tokens/components.
  - Result: root `DESIGN.md` now captures product feel, IA, provisional tokens, components, onboarding rules, accessibility, and plan-eng-review dependencies.
  - Follow-up: final hex values, font package/licensing, and architecture-sensitive states still need validation.

- Decide whether to approve gstack designer variant generation.
  - Why: plan-design-review used the existing mocks but could not generate a new visual comparison board without external-call approval.
  - Depends on: Joe approving the privacy/export risk for design prompt content.
