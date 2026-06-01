# Coding-Agent Prompt - Build Wander Onboarding

You are working on Wander, an iOS app for saving, checking in to, and discovering places on a social map. Build a high-converting onboarding flow inspired by the competitor patterns captured in:

`/Users/joelipshutz/Developer/research/screensdesign/2026-05-30-social-map-onboarding`

Use the screenshots as structural inspiration only. Do not copy exact artwork, brand, layout, or proprietary text.

## Context

- Target app: Wander
- Target user: people who save places they have been, want to go, or got from friends/TikTok/Instagram/Google Maps.
- Core promise: keep the places worth coming back to, then discover trusted spots through friends and smart filters.
- Business goal: activate users into saving places while delaying auth and paywall until the user has shown value intent.
- Current product direction: map-first, no Lists tab, tabs are map, you, plus, discover, with "your world" and "social world" framing.
- Monetization direction: freemium, roughly 20 saved places free; upgrade for unlimited saves and advanced social/import features.

## Required Flow

### Screen 1 - Welcome / Map Promise

- Goal: Establish the product in one beat and start guest onboarding.
- Draft headline: "Keep the places worth coming back to."
- Draft body: "Check in, save recs, and see what your people think is worth a detour."
- UI requirements:
  - Tan Rodeo-like background matching current mocks.
  - Soft map preview with a few category pins.
  - Primary terracotta button: "Start with the map".
  - Secondary text link: "Sign in".
- Data captured: none.
- Analytics: `onboarding_started`, `onboarding_screen_viewed` with `screen_id=welcome`.

### Screen 2 - Location Pre-Prompt

- Goal: Ask for location permission with exact utility.
- Draft headline: "Find what is nearby."
- Draft body: "Use location to show where you are, detect the place you are adding, and sort recs around you."
- UI requirements:
  - Centered map card with current dot and 2-3 pins.
  - Primary button: "Allow location".
  - Secondary button or text: "Not now".
  - Trigger native iOS location prompt only after the primary tap.
- Data captured: `locationPermissionStatus`.
- Analytics: `permission_preprompt_viewed`, `permission_requested`, `permission_result`.

### Screen 3 - Notifications Pre-Prompt

- Goal: Ask for notifications while making clear they are controlled and useful.
- Draft headline: "Only the useful pings."
- Draft body: "Saved-place reminders, friend recs near you, and trip ideas you asked for."
- UI requirements:
  - Three compact notification examples.
  - Primary button: "Turn on notifications".
  - Secondary: "Maybe later".
  - Trigger native iOS notifications prompt only after primary tap.
- Data captured: `notificationPermissionStatus`.
- Analytics: same permission events with `permission_type=notifications`.

### Screen 4 - Category Preferences

- Goal: Tune Discover and contextual plus questions.
- Draft headline: "What do you save most?"
- Draft body: "Pick a few. This shapes Discover and the questions we ask when you add a place."
- UI requirements:
  - Multi-select chips with emoji/category icons.
  - Categories: coffee, restaurants, hikes, bars, parks, work cafes, wellness, nature.
  - CTA: "Continue".
- Data captured: `preferredCategories[]`.
- Analytics: `onboarding_category_selected`, `onboarding_screen_completed`.

### Screen 5 - Add First Place

- Goal: Teach the plus flow and start activation.
- Draft headline: "Add your first place."
- Draft body: "Use where you are, paste a link, add manually, or pull from a photo."
- UI requirements:
  - Four rows matching current plus mock:
    - "I'm here right now"
    - "Paste a link"
    - "Add manually"
    - "From a photo"
  - Keep the current informal-but-tight voice.
  - Primary CTA can be "Try the +"; secondary "Explore first".
- Data captured: `firstAddSourceSelected` if a source is tapped.
- Analytics: `add_place_source_selected`, `onboarding_completed`.

### Screen 6 - Auth Gate at Save Intent

- Trigger: user taps Save, Share, Follow, Sync, or tries to persist a first place.
- Goal: Convert identity only after clear value intent.
- Draft headline: "Save Maru Coffee?"
- Draft body: "Create a free account to keep your places synced and share recs with friends."
- UI requirements:
  - Show the place card being saved at the top.
  - Auth options: Apple, Google, email.
  - Secondary: "Keep browsing".
  - Do not block browsing if dismissed.
- Data captured: account identity and `authGateReason`.
- Analytics: `auth_gate_viewed`, `auth_method_selected`, `auth_completed`, `auth_gate_dismissed`.

### Screen 7 - Freemium Paywall After Value

- Trigger: user attempts save #21 or another premium action.
- Goal: Upgrade from a proven usage moment.
- Draft headline: "Your map is filling up."
- Draft body: "20 places are free. Go unlimited when Wander becomes your real map."
- UI requirements:
  - Usage meter: `20/20 free saves used`.
  - Value checklist:
    - Unlimited saved places.
    - Unlimited link imports.
    - Private friend circles.
    - Trip packs and backup/export.
  - Primary CTA: "Go unlimited".
  - Secondary: "Not now".
- Data captured: paywall trigger, plan selection.
- Analytics: `free_save_limit_reached`, `paywall_viewed`, `paywall_cta_tapped`, `paywall_dismissed`, `purchase_completed`.

## Visual Requirements

- Match the existing Wander mocks in `images/wander-mocks-1.png` through `images/wander-mocks-5.png`.
- Use a tan/off-white base, dark espresso text, terracotta primary CTA, and sage/sky/gold supporting states.
- Use playful sans headings, but keep copy tighter than the first Lovable pass.
- Do not add a Lists tab or list-first language.
- Do not over-explain the app in visible instructional text.
- Use map fragments, place cards, pins, category chips, and friend initials as the main visual language.

## Technical Requirements

- State model:
  - `hasCompletedOnboarding`
  - `locationPermissionStatus`
  - `notificationPermissionStatus`
  - `preferredCategories`
  - `guestSessionId`
  - `savedPlaceCount`
  - `freeSaveLimit`
  - `authGateReason`
- Permissions:
  - Show app-owned pre-prompt first.
  - Trigger native prompt only from explicit primary CTA.
  - Support skip states and make the app usable after skip.
- Auth:
  - No login requirement during initial onboarding.
  - Gate only on save/share/follow/sync/persistent import.
- Paywall:
  - Do not show during initial onboarding.
  - Trigger after value: default at attempted save #21.
  - Make trigger configurable for A/B tests.
- Analytics:
  - Instrument every screen view, answer tap, permission prompt/result, auth gate, and paywall action.
- Accessibility:
  - 44px minimum tap targets.
  - Buttons and chips have semantic labels.
  - Color is not the only indicator for pin state.
  - Permission skip paths are accessible.

## Acceptance Criteria

- [ ] A new user can complete onboarding without creating an account.
- [ ] Location and notification permission pre-prompts appear with skip options.
- [ ] The user can choose preferred place categories.
- [ ] The plus/add-place education screen matches the existing product direction.
- [ ] Auth appears only when the user tries to save/share/follow/sync.
- [ ] Freemium paywall appears only after the configured saved-place limit or premium action.
- [ ] All required analytics events fire with correct properties.
- [ ] Visual style matches Wander mocks without copying competitor screens.
- [ ] The flow works on modern iPhone viewport sizes without text overflow.
