# Design System - Wander

Status: Draft
Created: 2026-06-01
Skill: design-consultation

This is the project-level design source of truth for Wander. Read it before making visual or UI decisions.

## Sources

- Product spec: `docs/specs/wander-ios-product-spec.md`
- Mock PDF: `docs/source/wander-mocks.pdf`
- Rendered mocks: `docs/source/wander-mocks-pages/`
- Follow/profile/settings mock storyboard: `preview/follow-profile-settings-mocks/index.html`
- Onboarding research: `research/screensdesign/2026-05-30-social-map-onboarding/report.md`

## Product Context

- **What this is:** Wander is a native iOS social map for remembering places worth returning to and discovering places through trusted people.
- **Who it is for:** People who save places from daily life, travel, people they follow, TikTok/Instagram links, photos, and memory, then want useful answers later.
- **Space/industry:** Social maps, place memory, trusted recommendations, lightweight local/travel discovery.
- **Project type:** Native iOS app, map-first, SwiftUI, iPhone-first for v0.1.
- **North Star:** When I need a place, Wander shows me where my trusted people have actually been, what they thought, and whether it fits the moment.
- **Wedge:** Wander turns trusted people's place memories into a searchable map you can actually use.

## Aesthetic Direction

- **Direction:** Warm utility map with a playful editorial edge.
- **Decoration level:** Intentional. The map, pins, sheets, profiles, and social proof carry the visual system. Avoid decorative filler.
- **Mood:** Useful before social. Informal but not slangy. Warm, sharp, low-friction, and privacy-aware.
- **Visual anchor:** Map first. No generic landing page, no card-grid marketplace feel, no public influencer feed language.

Principles:

- Map first, not list first.
- Trusted people, not strangers.
- Capture must feel faster than organizing.
- Privacy must be visible before social value expands.
- Discovery should answer the user's current place question.
- Do not use live-location language.
- Do not bring back manual lists.

Copy examples:

- Good: "worth a detour", "where's it from?", "a few quick details", "saved from Ryan", "people you follow have been".
- Avoid: generic travel-app language, cute slang, gamified check-in language, public feed language, long onboarding lectures.

## Information Architecture

Bottom navigation:

```text
YOUR WORLD                    SOCIAL WORLD
map        you        +        discover
```

Screen hierarchy rule:

- Each main screen gets at most three primary elements above the fold.
- Everything else moves into a sheet, secondary row, or edit state.

Map:

1. Search: place, vibe, area, contact, or username.
2. Map viewport with filtered pins and clusters.
3. Filter chips: you, social/following, friends, been, wanna go.
4. Selected place sheet.
5. Bottom nav.

You:

1. Saved places and unresolved drafts.
2. Filters by status, city, category, attributes, and custom tags.
3. Profile preview, followers/following entry points, place edit, and visibility controls.

Plus:

1. Source picker.
2. Candidate confirmation.
3. Been/wanna and visibility.
4. Contextual questions.
5. Save confirmation.

Discover:

1. Search.
2. People row.
3. Smart filters.
4. Follow-powered result cards.
5. Save-to-my-map action.

Settings:

Entry: gear in You/Profile, not a bottom tab.

1. Profile/account basics.
2. Privacy defaults and blocked users.
3. Contacts, notifications, data/account controls.

## Design Coverage

Existing Lovable mocks cover:

- Map with search, filters, pins, and selected place sheet.
- Discover with people row, smart filters, and result cards.
- Plus/source picker for current location, link, manual, and photo.
- Candidate/contextual question flow.
- Pin legend for you/social and been/wanna go.

Redone follow/profile/settings storyboard covers:

- My profile / You surface with followers/following entry points.
- Other-user profile with follow/unfollow, follows-you, mutual/friend, and block actions.
- Followers and Following lists.
- Username search and Contacts search results.
- Non-follower profile shell with no visible places.
- Discover smart filters in the Rodeo-ish visual direction.
- Block confirmation, blocked profile, and blocked users settings.
- Settings gear flow and settings rows.
- Add-flow visibility picker for Everyone/Friends/Self with helper copy.
- Coffee and hike contextual add-flow question examples.
- Social place detail states when follow/block/visibility changes mid-flow.

This makes the app mock-complete for planning. Before implementation, run design review again against the storyboard and convert any chosen screens into native SwiftUI specs. The storyboard follows the warm Rodeo-ish direction: cream/sand surfaces, espresso text, terracotta user pins, sky social pins, chunky rounded controls, and casual travel-buddy copy.

## Typography

- **Display/Hero:** Funnel Display direction, or equivalent playful grotesque. Use for onboarding, major empty states, and top-level screen headings only.
- **Body:** Funnel Sans direction, or equivalent legible sans. Use for body, controls, sheets, cards, and settings.
- **UI/Labels:** Same as body, medium weight.
- **Data/Tables:** Same as body with tabular numerals where counts or distances align.
- **Code:** SF Mono if needed for internal/debug surfaces.
- **Loading:** Prefer bundled app fonts. If custom font licensing/package choice is not finalized, use iOS system font temporarily but keep metrics close.

Type scale, iPhone:

| Token | Size | Weight | Use |
|---|---:|---|---|
| `type.display.lg` | 36pt | 700 | First-run headline only |
| `type.display.md` | 28pt | 700 | Major screen heading or empty state |
| `type.title.lg` | 22pt | 700 | Sheet title, place title |
| `type.title.md` | 18pt | 650 | Section/card title |
| `type.body` | 16pt | 400 | Default readable body |
| `type.body.sm` | 14pt | 400 | Secondary body, helper copy |
| `type.label` | 13pt | 600 | Chips, tabs, metadata |
| `type.caption` | 12pt | 500 | Attribution, counts, quiet labels |

Rules:

- No negative letter spacing.
- Do not scale fonts with viewport width.
- Dynamic Type must not break chips, controls, or bottom sheets.
- Reserve display-scale type for true onboarding or major hierarchy moments.

## Color

Color values are provisional, derived from the current mocks and design review. Final hexes should be adjusted after implementation screenshots or explicit token extraction.

| Token | Hex | Use |
|---|---|---|
| `color.canvas.warm` | `#F3DFCA` | App background, map-adjacent surfaces |
| `color.surface.bone` | `#FFF7EA` | Cards, sheets, forms |
| `color.surface.raised` | `#FFFFFF` | Inputs, selected cards, elevated controls |
| `color.text.ink` | `#2C2118` | Primary text |
| `color.text.muted` | `#7B6555` | Secondary text |
| `color.border.hairline` | `#DBC2AA` | Dividers, card outlines, chip borders |
| `color.action.terracotta` | `#D46F4D` | Primary CTA, user pins |
| `color.action.terracottaDark` | `#A94F35` | Pressed/strong CTA state |
| `color.pin.youBeen` | `#D46F4D` | Solid user been pin |
| `color.pin.youWanna` | `#D46F4D` | Dashed user wanna-go pin |
| `color.pin.socialBeen` | `#69B8D7` | Solid visible social been pin |
| `color.pin.socialWanna` | `#69B8D7` | Dashed visible social wanna-go pin |
| `color.category.moss` | `#6F8F5F` | Outdoors/nature |
| `color.category.sun` | `#E3B64B` | Warm highlight/category marker |
| `color.category.sage` | `#A0B98A` | Calm/supporting category |
| `color.state.success` | `#3F8F64` | Saved/confirmed |
| `color.state.warning` | `#B98528` | Needs attention |
| `color.state.error` | `#B84A3A` | Error/destructive |
| `color.state.info` | `#4F8EAD` | Informational/system |

Rules:

- Color must never be the only status indicator.
- Pin state uses owner color plus fill/dash pattern.
- Avoid palettes that drift into all-beige, all-slate, all-purple, or generic travel blue.
- Dark mode is not required for v0.1 unless explicitly prioritized.

## Spacing

- **Base unit:** 8px.
- **Density:** Comfortable for consumer iOS, compact enough for repeat map use.
- **Scale:** 4, 8, 12, 16, 24, 32, 48, 64.
- **Minimum tap target:** 44px.
- **Safe areas:** Bottom nav, plus action, and sheets must respect home indicator and keyboard.

## Layout

- **Approach:** Map-first, sheet-driven, iPhone-first.
- **Grid:** Use native SwiftUI layout primitives with 8px spacing. Do not invent a desktop-style grid for v0.1.
- **Max content width:** iPhone viewport. If iPad is allowed later, use a map plus side-panel pattern rather than stretching phone cards.
- **Border radius:**
  - `radius.sm`: 8px, compact controls and thumbnails.
  - `radius.md`: 12px, repeated result cards.
  - `radius.lg`: 16px, larger cards and grouped panels.
  - `radius.sheet`: 24px, bottom sheets.
  - `radius.pill`: 999px, chips and compact buttons.

Rules:

- Do not nest cards inside cards.
- Do not use floating page sections as decorative cards.
- Stabilize fixed-format UI with explicit dimensions or responsive constraints.
- Long text must wrap or truncate predictably without overlapping controls.

## Motion

- **Approach:** Minimal-functional.
- **Easing:** Use native iOS sheet/map transitions where possible.
- **Duration:** Micro 80-120ms, short 150-250ms, medium 250-400ms.

Allowed:

- Pin appears after save.
- Sheet changes height.
- Button press and saved confirmation.
- Small loading/progress indicators for extraction and search.

Avoid:

- Cinematic onboarding.
- Decorative motion that slows capture.
- Map movement that disorients users.

## Core Components

### App Shell

- Bottom nav has `map`, `you`, `+`, and `discover`; Settings opens from a gear in You/Profile.
- Center plus action is the primary capture affordance.
- Plus action must not hide critical map/place content.

### Search Field

Used on Map and Discover.

States:

- default
- focused
- loading
- empty result
- error
- active filter summary

Placeholder direction: "search a place, vibe, or username..."

### Filter Chips

Multi-select:

- you
- social
- friends
- been
- wanna go

Rules:

- Up to four pin states can show at once.
- Selected state must be readable by color, fill, and accessibility label.
- Filter selection must not shift the layout.

### Pin System

Pin states:

- You + Been: solid terracotta.
- You + Wanna go: dashed terracotta.
- Social + Been: solid sky.
- Social + Wanna go: dashed sky.

Rules:

- Clusters preserve owner/status breakdown.
- Mixed clusters open a grouped sheet.
- Recency may later use opacity/tone, not a new primary color.
- VoiceOver labels include owner, status, category, and place name.

### Place Sheet

Content order:

1. Place name, category, distance/area.
2. Been/wanna state.
3. Social proof.
4. Top attributes.
5. Primary action.
6. Attribution/privacy details.

Primary actions:

- Save to my map.
- Edit.
- Add details.
- Change visibility.

### Source Picker

Rows:

- I'm here right now.
- Paste a link.
- Add manually.
- From a photo.

Rules:

- One clear source per row.
- Current location may show detected place when available.
- Every source resolves into candidate confirmation.

### Candidate Confirmation

States:

- High confidence: candidate selected, one-tap continue.
- Medium confidence: show two or three candidates.
- Low confidence: ask for place name/area.
- None: unresolved draft, no map pin.

### Contextual Question Block

Question types:

- emoji scale
- single choice
- multi-tag
- price scale
- short note

Rules:

- Category templates ship with defaults.
- Users can add custom tags.
- Do not ship a full schema editor in v0.1.
- Optional questions never block saving.

Starter categories:

- Coffee shop
- Restaurant
- Hike
- Bar
- Park/nature
- Wellness
- Work-friendly cafe
- Event/pop-up

### Visibility Pill

Provisional pending plan-eng-review.

Recommended states:

- Everyone
- Friends
- Self
- Pending sync
- Error / retry

Rules:

- New normal places default to Everyone, meaning followers can see them.
- Friends means mutual follows only.
- Self means only me.
- Helper copy: "People who follow you can see this."
- Everyone is not a global public feed in v0.1.
- Users can switch visibility in add/edit before save.
- Do not bury privacy in settings.
- Do not use live-location language.
- Sensitive places may default Self even if normal places default Everyone.

### Profile Avatar Row

Used in Discover, place sheets, and social proof.

Rules:

- Use avatar circles or initials.
- Show place counts where useful.
- Do not expose content the viewer cannot access under follower/friend/self visibility.

### Follow/Profile Card

States:

- suggested
- following
- follows you
- mutual/friend
- not following
- blocked
- unavailable

### Followers / Following Lists

Rules:

- Separate Followers and Following tabs.
- Show follow state inline.
- Allow unfollow from Following.
- Allow block from overflow/profile actions.
- Blocked users should disappear from both users' visible graph lists.

### Settings Tab

Rows:

- Profile/account.
- Default place visibility.
- Blocked users.
- Contacts.
- Notifications.
- Data/sync.
- Sign out / account deletion later.

### Empty State Panel

Rule: short context plus one action. No explanation essays.

Examples:

- "No places here yet." + Add place.
- "Nothing from your people yet." + Find people.
- "This link needs a little help." + Add manually.

## Onboarding Rules

Flow:

1. Welcome / map promise.
2. Location pre-prompt.
3. Category preferences.
4. Add first place education.
5. Auth gate only at save/share/follow/sync intent.
6. Notifications after first save or wanna-go save.
7. Paywall later, not during first-run onboarding.

Rules:

- Guest-first.
- No forced login before first save intent.
- No paywall during first-run onboarding.
- Native permission prompts only after explicit CTA.
- Every permission screen has a skip path.
- Teach the pin legend lightly, not as a lecture.

## Interaction States

Every major surface must define:

- loading
- empty
- error
- success
- partial/offline

Required partial states:

- cached map while sync catches up
- some social pins hidden by privacy
- local custom tags pending sync
- extraction needs confirmation
- follow/block/visibility changes while detail is open

## Accessibility

- 44px minimum tap targets.
- VoiceOver labels for pins include owner, status, category, and place name.
- Dynamic Type must not break chips.
- Long tags truncate predictably.
- Reduce Motion disables decorative pin drops and long transitions.
- Color is not the only state indicator.
- Permission skips and secondary paths are accessible.
- Visibility controls must have explicit labels, not icon-only meaning.

## Provisional Areas For plan-eng-review

These design areas are intentionally provisional until architecture review locks the data and sync behavior:

- Backend-sensitive visibility states.
- Profile, follow, and block policy states.
- Sync/offline states.
- Contacts and follow matching states.
- Auth gate mechanics.
- Extraction confidence states.
- Paywall trigger configuration.
- Share extension scope.

## Do Not Do

- No Lists tab.
- No public global feed in v0.1.
- No live-location affordances.
- No badges, streaks, mayorships, or ranking people.
- No account wall before save intent.
- No early paywall.
- No generic card-grid marketplace feel.

## Decisions Log

| Date | Decision | Rationale |
|---|---|---|
| 2026-06-01 | Initial design system created | Created from the product spec, Lovable mocks, onboarding research, and mock-backed plan-design-review. |
| 2026-06-01 | iPhone-first v0.1 | The mocks, onboarding, and native map interactions are phone-centered. iPad can run phone-compatible unless explicitly prioritized. |
| 2026-06-01 | Use Strava-style follow graph | Following is one-way; friends are mutual follows; profiles, followers/following lists, and blocking are required surfaces. |
| 2026-06-01 | Use Everyone/Friends/Self visibility | Everyone means followers can see it, Friends means mutual follows, Self means only me. Helper copy must prevent global-public confusion. |
| 2026-06-01 | Contacts-first lookup, native Contacts deferred | People can be found through contacts or username; build against `ContactProvider` with fake contacts and username search, then add native Contacts later behind the same adapter. |
