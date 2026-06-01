# Wander — Design Feedback → Source-of-Truth Docs

**From:** design/mocks workstream
**To:** agent that owns `DESIGN.md` + `docs/specs/wander-ios-product-spec.md`
**Date:** 2026-05-31 (supersedes the earlier 5-tab proposal)
**Status:** Approved in mocks · needs to be reflected in the source-of-truth docs
**Scope:** Information Architecture — bottom navigation + surface consolidation

---

## TL;DR

The bottom nav is now **4 tabs**: `map · add (+) · discover · profile`. Two structural changes from the current docs:

1. **The `you` surface is gone as its own concept and merges into `profile`.** Personal place memory (saved places, been/wanna, recent activity, stats) **and** the self-profile now live on a single **Profile** tab.
2. **The `+` is a tab, not a raised center FAB.** It keeps its terracotta treatment as the primary capture affordance but sits inline as one of the four tabs.

The **`your world` / `social world`** grouping labels are **removed** entirely.

---

## Before → After

**Before (current docs):**
```text
YOUR WORLD                    SOCIAL WORLD
map        you        +        discover
```

**After (this change):**
```text
map        add (+)        discover        profile
```

(No grouping labels. `add` is a normal tab. `profile` is rendered as the current user's avatar.)

---

## Tab definitions (after)

| Tab | Job |
|---|---|
| **map** | Home/explore. Your + visible social pins, search, multi-select filters, selected place sheet. Default surface. |
| **add (+)** | Capture. Source picker → confirm → questions → save. Terracotta-accented tab; primary capture affordance. |
| **discover** | Follow-powered discovery; people/username/contacts search; smart filters; result cards; save-to-my-map. |
| **profile** | **Merged "you" + profile.** Identity header (avatar, name, city, bio, edit), stats (been / wanna / friends), this-month activity, recent check-ins, and the gated place lists others see per visibility. **Settings opens from a gear here.** |

The old **You** surface (saved places, drafts, filters) is **not a separate tab** — its content is presented on **Profile** (and deep-links/filters from the stat tiles).

---

## Exact edits for the docs

### 1. `DESIGN.md` → `## Information Architecture`

Replace the nav block:
```text
YOUR WORLD                    SOCIAL WORLD
map        you        +        discover
```
with:
```text
map        add (+)        discover        profile
```

Remove the `You` screen section. Rewrite the `Profile`/`You` hierarchy as a single **Profile** screen:
- Identity header (name, handle/city, avatar, bio, edit).
- Stats: been / wanna / friends (tap-through to filtered lists & followers/following).
- This-month activity recap (non-gamified).
- Recent check-ins list (category thumb, name, area · time, rating; row → place sheet).
- Filters by status, city, category, attributes, custom tags (the former "You" jobs).
- Gated place visibility for other viewers (follower/mutual/self).
- Settings gear entry.

### 2. `DESIGN.md` → `### App Shell`

Change:
> Bottom nav has `map`, `you`, `+`, and `discover`; Settings opens from a gear in You/Profile. The center plus action is the primary capture affordance.

to:
> Bottom nav has `map`, `add (+)`, `discover`, and `profile`; the plus is a tab (terracotta-accented), still the primary capture affordance. Settings opens from a gear in Profile. No "your world / social world" grouping labels.

### 3. `DESIGN.md` → `### Settings Tab`

Change "Entry: gear in You/Profile, not a bottom tab." to **"Entry: gear in Profile, not a bottom tab."**

### 4. `wander-ios-product-spec.md` → `## Information Architecture` and `### You`

Apply the same nav-block swap. Fold the **### You** section into **### Profile** (jobs: review/filter/edit saved places, change visibility, see extraction status for drafts, view profile as others see it, open followers/following, stats, activity). Keep the constraint that Settings is a gear inside Profile, not a tab.

### 5. `wander-ios-product-spec.md` → `### Settings`

Change "opened from a gear in You/Profile" to **"opened from a gear in Profile."**

---

## Open questions / flags

1. **`profile` doing double duty.** Profile now carries both the public-facing shell and the owner's private place-memory tools. Confirm the owner's editing/filtering UI and the other-viewer's gated view are the same screen with role-based content (recommended) vs two screens.
2. **`add` as a tab vs center FAB.** Plus is now a normal (terracotta) tab. If thumb-reach/prominence testing favors a raised center button later, that's a visual change only — the IA stays 4 tabs.
3. **4-tab ceiling.** No further tabs; new surfaces (Discover sub-views, followers/following, settings) nest under these four.

---

## Mock references

- Updated 4-tab nav appears on every full-chrome screen in `screens.html` (Map · Source · Saved · Profile).
- **Profile screen is now mocked** (screen 06) — identity header, been/wanna/friends stat tiles, this-month recap, recent check-ins, settings gear.
- Still to mock (next pass): Discover + people/username/contacts search, other-user profiles (following / follows-you / mutual / not-following / blocked), followers/following lists, settings detail, onboarding, and all loading/empty/error/partial states.
