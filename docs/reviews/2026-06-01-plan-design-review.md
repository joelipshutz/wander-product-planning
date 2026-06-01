# Wander Plan Design Review

Date: 2026-06-01
Skill: plan-design-review
Status: CLEAN
Reviewed commit: 3b109ad

## Inputs

- Engineering plan: `docs/plans/2026-06-01-wander-ios-eng-plan.md`
- Contract lock: `docs/plans/2026-06-01-wander-m1-5-contract-lock.md`
- Product spec: `docs/specs/wander-ios-product-spec.md`
- Design system: `DESIGN.md`
- Handoff source: `preview/follow-profile-settings-mocks/`
- Canonical tokens: `preview/follow-profile-settings-mocks/tokens.css`
- Annotated mocks: `preview/follow-profile-settings-mocks/screens.html`

## System Audit

The active UI scope is substantial: Map, Add, Discover, Profile, nested Settings, profiles for other users, follow/block actions, visibility states, auth gates, and stale-access recovery.

`DESIGN.md` exists and the handoff package is the visual source of truth. The gstack designer binary was available, but no competing generated visual direction was created because the product decision is to use `preview/follow-profile-settings-mocks/` as the approved baseline.

Prior review history:

- `plan-ceo-review` ran 2026-05-30 and was clean.
- `plan-design-review` ran 2026-05-30 against the older Lovable/PDF-backed mocks.
- `plan-eng-review` ran 2026-06-01 and reset low-pass implementation drift.

## What Already Exists

- Strong visual language for Map, Add, saved confirmation, and owner Profile.
- Literal token source in `tokens.css`.
- Four-tab IA: Map, Add, Discover, Profile.
- Settings gear from Profile only.
- Visibility model: Everyone/Followers copy maps to `followers`, Friends maps to `mutuals`, Self maps to `self`.
- M1.5 state inventory for Map/Add/Discover/Profile/Settings.

## Pass Results

| Pass | Initial | After fixes | Finding |
|---|---:|---:|---|
| Information Architecture | 8 | 9 | Core IA is locked; missing surfaces needed concrete hierarchy. |
| Interaction State Coverage | 7 | 9 | State inventory existed, but needed visual/user-facing prescriptions. |
| User Journey & Emotional Arc | 8 | 9 | Capture journey is strong; social trust journey needed explicit scenes. |
| AI Slop Risk | 8 | 9 | Warm map-first handoff avoids generic UI; Discover needed guardrails against card-grid drift. |
| Design System Alignment | 8 | 9 | Tokens/components are strong; missing social/settings components are now specified. |
| Responsive & Accessibility | 7 | 8 | iPhone-first is clear; accessibility requirements are now attached to missing states. |
| Unresolved Decisions | 8 | 9 | No new product decision required; plan can proceed with source-of-truth handoff style. |

Overall design score: 8/10 -> 9/10.

## Decisions Added

1. Discover uses search, active query/filter summary, people row, big smart-filter pills, and follow-attributed results. It must not become a curation-card grid or global people directory.
2. Other-user profiles share the owner Profile shell, but swap owner controls for relationship state, follow/unfollow, overflow block, and role-gated visible places.
3. Followers/following lists use segmented tabs and relationship-aware rows with inline follow/unfollow and overflow block.
4. Settings remains a Profile gear surface with grouped rows for account, default visibility, blocked users, contacts, notifications, and data/sync.
5. Block flow uses a destructive confirmation and then a quiet blocked/unavailable state; stale map/profile/detail views must show access changed or disappear.
6. Auth gates appear only at save/sync/follow/social-save intent and must preserve a local guest path where possible.
7. Native implementation swaps mock emoji chrome for SF Symbols/custom glyphs, while category symbols may remain compact category marks if they are accessible.
8. Link/photo in M2 are honest unresolved-draft shells until backend extraction jobs exist.

## NOT In Scope

- New visual direction or generated variants. The handoff package remains source of truth.
- Full onboarding implementation. Keep auth gates for save/sync/follow.
- Native Contacts permission. Use `FakeContactProvider` and username search first.
- Share extension.
- Private profiles and follow requests.
- iPad-specific layout beyond phone-compatible behavior.

## Completion Summary

```text
+====================================================================+
|         DESIGN PLAN REVIEW - COMPLETION SUMMARY                    |
+====================================================================+
| System Audit         | DESIGN.md exists; high UI scope             |
| Step 0               | 8/10; focus missing social/settings states  |
| Pass 1  (Info Arch)  | 8/10 -> 9/10                               |
| Pass 2  (States)     | 7/10 -> 9/10                               |
| Pass 3  (Journey)    | 8/10 -> 9/10                               |
| Pass 4  (AI Slop)    | 8/10 -> 9/10                               |
| Pass 5  (Design Sys) | 8/10 -> 9/10                               |
| Pass 6  (A11y)       | 7/10 -> 8/10                               |
| Pass 7  (Decisions)  | 8 resolved, 0 deferred                     |
+--------------------------------------------------------------------+
| NOT in scope         | written (6 items)                           |
| What already exists  | written                                     |
| TODOS.md updates     | 1 existing item updated                     |
| Approved Mockups     | existing handoff package approved           |
| Decisions made       | 8 added to plan/design system               |
| Decisions deferred   | 0                                           |
| Overall design score | 8/10 -> 9/10                                |
+====================================================================+
```

Plan is design-complete for M2 implementation. Run implementation visual QA with the simulator after M2 screens exist.
