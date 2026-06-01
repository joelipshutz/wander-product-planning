# Handoff: Wander — Map, Capture Flow & Design System

## Overview

Wander is a **native iOS social map** for remembering places worth returning to and discovering places through trusted people. This package is the design handoff for the **core screens** (Map / home, the Add capture flow, and Profile) and the **complete design system** (tokens, type, color, components, pin system).

Target platform per spec: **Swift 5.9+ / SwiftUI / iOS 17+ / SwiftData**, iPhone-first, light mode only for v0.1.

> This is a **core/approval pass**, not the full app. The exhaustive screen set (Discover, other-user profiles, followers/following, settings, onboarding) and all interaction states come in a later pass. See "Not yet mocked" below.

---

## About the Design Files

The HTML/CSS files in this bundle are **design references** — prototypes that show the intended look, layout, and component states. **They are not production code to ship.** The task is to **recreate these designs natively in SwiftUI** using the codebase's established patterns (this project is greenfield SwiftUI per the spec, so build the token layer and reusable views described below).

- `tokens.css` is the **literal source of truth** for all design values. Every value should be promoted **1:1** to a SwiftUI token layer (e.g. `Color` extensions, a `Typography` enum, spacing/radius constants).
- `styles.css` shows how each component is composed (the `.w-*` classes map to reusable SwiftUI views).
- The two HTML files are the rendered references. Open them in a browser (`tokens.css` + `styles.css` must sit alongside them — they do in this folder).

---

## Fidelity

**High-fidelity (hifi).** Final colors, typography, spacing, radii, and component states are specified. Recreate the UI faithfully using the tokens below. The one intentional placeholder: **category/nav icons are rendered as emoji** in the mock for fast scanning — swap these for **SF Symbols or custom glyphs** natively (see Assets).

---

## Files

| File | What it is |
|---|---|
| `index.html` | Design-system reference: brand voice, color, type scale, spacing/radii/elevation, component gallery with states, pin system. |
| `screens.html` | Annotated screen mocks with numbered redline callouts (Map + 4-step capture flow). |
| `tokens.css` | **Source of truth.** All design tokens as CSS custom properties. |
| `styles.css` | Document chrome + every app UI component (`.w-*`) and the iPhone frame. |
| `wander-ia-feedback.md` | IA change log (bottom-nav restructure) for whoever owns the source-of-truth docs. |
| `source-docs/DESIGN.md` | Full project design system (exhaustive token tables, component contracts, a11y, motion). |
| `source-docs/wander-ios-product-spec.md` | Full product spec: data model, flows, extraction, privacy, test plan. |

**Read `source-docs/DESIGN.md` and the product spec first** — they contain the complete component contracts, accessibility rules, motion specs, interaction-state matrix, and the backend-neutral data model (User, Follow, Block, Place, UserPlace, PlaceAttribute, ExtractionJob). This README covers what the mocks render; those docs cover everything else.

---

## Design Tokens

Promote these from `tokens.css` 1:1. These are the current handoff source of truth.

### Color — surfaces & text
| Token | Hex | Use |
|---|---|---|
| canvas.warm | `#F3DFCA` | App background, map-adjacent surfaces |
| surface.bone | `#FFF7EA` | Cards, sheets, forms |
| surface.raised | `#FFFFFF` | Inputs, selected cards, elevated controls |
| surface.sand | `#EFE3D0` | Recessed wells, pressed chips |
| text.ink | `#2C2118` | Primary text |
| text.muted | `#7B6555` | Secondary text |
| text.faint | `#A8957F` | Tertiary / placeholder |
| border.hairline | `#DBC2AA` | Dividers, outlines |
| border.strong | `#C9AC8F` | Stronger dividers, sheet grab |

### Color — action, pins, category, state
| Token | Hex | Use |
|---|---|---|
| terracotta | `#D46F4D` | Primary CTA · **you** pins |
| terracotta.dark | `#A94F35` | Pressed / strong state |
| terracotta.tint | `#F6E0D2` | Terracotta wash · been stat tile |
| sun.tint | `#F4E8C9` | Wanna stat tile background |
| sky.tint | `#DBEAF1` | Friends stat tile background |
| pin.social (sky) | `#69B8D7` | **Social** pins (been + wanna) |
| category.moss | `#6F8F5F` | Outdoors / nature |
| category.sun | `#E3B64B` | Warm highlight category |
| category.sage | `#A0B98A` | Calm supporting category |
| state.success | `#3F8F64` | Saved / confirmed |
| state.warning | `#B98528` | Needs attention |
| state.error | `#B84A3A` | Error / destructive |
| state.info | `#4F8EAD` | Informational / system |

Avatar seeds used in mocks: james `#D4623F`, ryan `#6F8F5F`, andrew `#E3B64B`, sofia/current-user `#69B8D7`.

**Rule:** color is never the only status indicator — pins also encode status via **fill (solid=been) / dash (dashed=wanna)**.

### Typography
- **Display/headings:** Funnel Display (playful grotesque). A close substitute is acceptable if licensing blocks embedding; keep metrics close.
- **Body/controls:** Funnel Sans.
- **Labels/redlines:** Space Mono (uppercase, letter-spaced) — these are *handoff annotations*, not necessarily in-app chrome.

| Token | Size / Weight | Use |
|---|---|---|
| display.lg | 36 / 700 | First-run headline only |
| display.md | 28 / 700 | Major screen heading / empty state |
| title.lg | 22 / 700 | Sheet title, place title |
| title.md | 18 / 650 | Section / card title |
| body | 16 / 400 | Default body |
| body.sm | 14 / 400 | Secondary body, helper |
| label | 13 / 600 | Chips, tabs, metadata |
| caption | 12 / 500 | Attribution, counts, quiet labels |

Rules: no negative letter-spacing; type does **not** scale with viewport; Dynamic Type must not break chips/sheets.

### Spacing — 8px base
`4 · 8 · 12 · 16 · 24 · 32 · 48 · 64`. Minimum tap target **44px**.

### Radius
| Token | px | Use |
|---|---|---|
| radius.sm | 8 | compact controls, thumbnails |
| radius.md | 12 | repeated result cards |
| radius.lg | 16 | larger cards, grouped panels |
| radius.sheet | 24 | bottom sheets |
| radius.pill | 999 | chips, compact buttons |

### Elevation
- shadow.card: `0 1px 2px rgba(44,33,24,.06), 0 6px 16px rgba(44,33,24,.08)`
- shadow.sheet: `0 -2px 8px rgba(44,33,24,.06), 0 -12px 40px rgba(44,33,24,.14)`
- shadow.pin: `0 2px 6px rgba(44,33,24,.22)`
- shadow.fab: `0 4px 14px rgba(169,79,53,.40)`

### Motion
Micro 80–120ms, short 150–250ms, medium 250–400ms. Allowed: pin appears after save, sheet height changes, button press/confirm, small loaders. Reduce Motion disables decorative pin drops.

---

## Reusable Components (`.w-*` → SwiftUI views)

| Mock class | SwiftUI view (suggested) | Key states |
|---|---|---|
| `.w-search` | `SearchField` | default · focused (terracotta ring) · loading (spinner) · empty · error · active-filter summary |
| `.w-chip` | `FilterChip` | off (bone + hairline) · on (ink fill) · `.dashed` for wanna |
| `.w-tag` | `TagChip` | off · on (ink fill) |
| `.w-seg` | `ChoiceRow` | single-select pills |
| `.w-emoji-scale` | `EmojiScale` | selected = 2.5px terracotta ring |
| `.w-price` | `PriceScale` | `$`–`$$$$`, selected = ink fill |
| `.w-visibility` | `VisibilityPill` | Everyone (success dot) · Friends (sun dot) · Self (muted dot) |
| `.w-note` | `NoteField` | label + italic placeholder |
| `.w-btn .primary/.ghost` | `WanderButton` | primary terracotta (active → terracotta.dark) · ghost |
| `.w-fab` | `CaptureFAB` | 56px, terracotta, bone border |
| `.w-source` | `SourceRow` | `.primary` (terracotta fill, detected place) · default |
| `.w-candidate` | `CandidateRow` | selected (terracotta ring + check) · option |
| `.q-block` | `QuestionBlock` | wraps one templated question |
| `.w-pin` | `MapPin` | `.you`/`.social` × solid/`.wanna` (dashed) × `.dot` (cluster) |
| `.w-sheet` | `PlaceSheet` | collapsed / medium / expanded detents |
| `.w-bottomnav` | `WanderTabBar` | 4 tabs: map · add · discover · profile (see nav spec below) |
| `.nav-add` | tab capture button | 30px terracotta circle inside the tab bar |
| `.w-avatar` / `.avatar-stack` | `Avatar` / `AvatarStack` | sm / default / lg; initials or photo |
| `.prof-card` | `ProfileHeader` | identity card: avatar + name + meta + edit + bio + stat tiles |
| `.stat` | `StatTile` | been (terracotta) / wanna (sun) / friends (sky) tinted count tiles |
| `.month-card` | `ActivityRecap` | this-month count + summary + dotted strip |
| `.recent-row` | `RecentPlaceRow` | thumb + name + area·time + star rating |
| `.status-badge` | `StatusBadge` | `.been` (success fill) · wanna (sand) |

---

## Screens

### 1. Map / home  (`#map` in screens.html)
- **Purpose:** Default surface. See your + visible social pins, filter, tap a pin to inspect, save a social place.
- **Layout (top→bottom):** status bar → search field (16px side padding) → filter chip row (12px gap) → full-bleed map canvas (pins absolutely positioned) → selected place sheet docked above the tab bar → tab bar.
- **Above-the-fold rule:** at most 3 primary elements — search+filters, map, place sheet.
- **Components & specs:**
  - **Search:** `radius.pill`, surface.raised, hairline border, `shadow.card`; leading magnifier, trailing current-user avatar (opens Profile); placeholder "search a place, vibe, or friend…".
  - **Filter chips (multi-select):** you · friends · been · wanna go. Selected = ink fill; wanna uses dashed border. Selection must **not** shift layout.
  - **Pins:** 40px circle, surface.raised, 3px ring. Owner=color (terracotta you / sky social), status=fill (solid been / dashed wanna), category emoji inside. 14px solid dot = distant/cluster pin.
  - **Place sheet:** `radius.sheet` top corners, `shadow.sheet`. Order: name (title.lg) + been/wanna badge → "area · category · distance" (body.sm muted) → note quote (italic) → social-proof avatar stack "+ N friends here" → terracotta `+` to save. Grab handle on top.
  - **Tab bar:** see below.
- **Copy:** "Maru Coffee · been ✓ · arts district · coffee · 0.3 mi · 'best oat latte, vibes 10/10' · + 3 friends here".

### 2. Capture · "where's it from?"  (`#source`)
- **Purpose:** Step 1 of capture — pick a source.
- **Layout:** mono kicker "ADD A PLACE" → display headline (italic terracotta accent) → helper → 4 stacked source rows (12px gap) → quiet privacy line → tab bar.
- **Rows:** `i'm here right now` (**primary**, terracotta fill, shows detected place inline) · `paste a link` · `add manually` · `from a photo`. Each: 44px icon well + title (title.md) + helper (caption) + chevron; maps to an extraction adapter.
- **Privacy line:** "location is used to find nearby places · not to broadcast you". No live-location language anywhere.

### 3. Capture · "is this the one?"  (`#confirm`)
- **Purpose:** Confidence-gated candidate confirmation + been/wanna + visibility.
- **Layout:** "← STEP 1 OF 2" → headline → candidate list → "I've…" been/wanna segmented → "who can see this" visibility pills + helper → docked primary "continue to details".
- **Confidence gates:** High = 1 candidate pre-selected (terracotta ring + check); Medium = 2–3 candidates; Low = ask for name/area; None = save as unresolved draft (no pin). Never auto-save low-confidence as complete.
- **Visibility helper:** "People who follow you can see this." Everyone→followers, Friends→mutuals, Self→only me. Sensitive categories default Self.

### 4. Capture · "a few quick details"  (`#questions`)
- **Purpose:** Templated contextual questions (Step 2 of 2).
- **Layout:** "← STEP 2 OF 2" → headline → place context strip (echoes confirmed place + badge) → mono section label "COFFEE QUESTIONS" → question blocks → docked primary "save to my map".
- **Question types (template system):** emoji scale · single choice (yes/sometimes/nope) · multi-tag cloud (category defaults + user-added tags) · price scale · short text note. Optional answers **never block saving**.
- **Coffee template shown:** "how's the coffee?" (emoji) · "good for working?" (yes/no) · "the vibe" (tags: wifi solid, outlets, quiet, cute, food on point, cash only) · "a note for future you" (text → becomes the sheet quote).

### 5. Capture · saved  (`#saved`)
- **Purpose:** Reward/success state.
- **Layout:** centered — large 72px pin (exact owner+status pin that now lives on the map) → headline "it's on your *map*" → recap ("saved as **been**, visible to **everyone who follows you**") → primary "see it on the map" + ghost "add another place" → visibility recap pill with one-tap change → tab bar.
- **Motion:** pin drop honors Reduce Motion.

### 6. Profile  (`#profile`)
- **Purpose:** The merged self-profile **and** personal place memory surface. Built on a **tall/scrolling** layout.
- **Layout (top→bottom):** settings gear (top-right) → identity header card → "this month" section → recent check-ins list → tab bar (profile active).
- **Components & specs:**
  - **Identity header card** (`prof-card`, surface.bone, `radius.lg`): 64px terracotta avatar (3px raised border), display name (`prof-name`, Funnel Display 26/800), "city · joined" meta, **edit** pill (`prof-edit`, surface.sand), italic bio.
  - **Stat tiles** (`prof-stats`, 3-col grid): **been** (terracotta-tint bg / terracotta number), **wanna** (sun-tint / warning number), **friends** (sky-tint / info number). Number = Funnel Display 30/800; label = Space Mono 11 uppercase. Tap-through to filtered lists / followers / following. Tabular numerals.
  - **This month** (`prof-section-head` + `month-card`): bold section title + mono date on the right; card with a big count (Funnel Display 44/800 terracotta), a plain-language summary, and a dotted activity strip (`month-dots` — terracotta `.on` / border-strong off). Non-gamified — no badges or streak pressure.
  - **Recent** (`recent-row` cards): category thumb (44px), name (16/700), "area · time" meta, star rating (`stars`, cat-sun; off stars border-strong). Rows open the place sheet.
  - **Settings gear** (`prof-gear`): the single entry to Settings.
- **Privacy:** non-followers see only the header shell; place lists below are gated by follower/mutual/self visibility.
- **Copy shown:** "sam r. · los angeles · joined apr '25 · 'always down for a detour' · 120 been / 34 wanna / 12 friends · 7 new check-ins, mostly coffee + 1 hike, 2 from friends' tips".

---

## Bottom Navigation (current spec — see `wander-ia-feedback.md`)

```text
map        add (+)        discover        profile
```

- **map** — home/explore (your + visible social pins). Default surface.
- **add (+)** — capture flow (source → confirm → questions → save). The plus is a **tab**, not a raised center FAB — kept terracotta as the primary capture affordance (`nav-add`, 30px terracotta circle).
- **discover** — follow-powered discovery + people/username/contacts search.
- **profile** — merged self-profile + place memory (stats, activity, recent, gated place lists). **Settings opens from a gear here**, not a tab. Rendered as the current user's avatar.

No `your world / social world` grouping labels. Profile owns the personal place-memory content and Settings opens from the Profile gear. Details + exact doc edits live in `wander-ia-feedback.md`.

---

## Interactions & Behavior (this pass)

- **Tap pin → place sheet** animates up (sheet height change, short). Sheet supports collapsed/medium/expanded detents.
- **Tap filter chip** toggles a pin layer; up to 4 pin states at once; no layout shift.
- **Capture flow** is linear: source → confirm (gate) → questions → save → pin appears on map. Back affordances on confirm/questions steps.
- **Save** writes `UserPlace` + `PlaceAttribute`s locally (SwiftData), enqueues sync. Twice-tapping save must be idempotent.
- Full interaction-state matrix (loading/empty/error/success/partial for every feature) is in `source-docs/wander-ios-product-spec.md` → "Interaction State Coverage" and "Error And Rescue Registry". Implement those states; the mock here shows the happy path.

## State (from the data model)

Core objects (see spec for full fields): `UserPlace { status: been|wanna_go, visibility: followers|mutuals|self, note, nearby_confirmed, source_type }`, `PlaceAttribute { question_key, value_type, value }`, `ExtractionJob { status: pending→running→needs_confirmation→complete | no_place_found | failed }`. Capture writes these; confidence drives the confirm-screen branch.

## Assets

- **No raster assets.** Category & nav icons are **emoji placeholders** in the mock (☕ coffee, 🥾 hike, 🌳 park, 🍸 bar, 💻 work-cafe, 🗺️ map, 📍 pin, ✦ discover). **Swap for SF Symbols or a custom icon set** natively.
- **Fonts:** Funnel Display + Funnel Sans (Google Fonts) — bundle the app font or use a close grotesque substitute if licensing blocks embedding. Space Mono is only used for handoff annotations.
- **Map:** the mock map is a CSS stylization — use **MapKit** for the real surface; only the pin styling transfers.

---

## Not yet mocked (next pass)

Discover + people/username/contacts search · other-user profiles (following / follows-you / mutual / not-following / blocked) · followers/following lists · settings detail (privacy, blocked, contacts, notifications, account) · onboarding (welcome → location → categories → first place → auth gate) · all loading/empty/error/partial states. The spec fully describes these; build the token + component layer now so they drop in cleanly.
