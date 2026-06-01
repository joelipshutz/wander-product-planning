# Recommended Wander Onboarding Flow

## Thesis

Wander should be guest-first and map-first. The app should ask for location early because location is core to the product, but it should not ask for account creation until the user tries to save, share, sync, or follow. Notifications should be framed after the first save, when the user understands why a nearby reminder or friend recommendation is useful. The freemium paywall should appear only after the free map has real value, around saved place #21.

## Flow

### 1. Promise

Headline: "Your places, on a map."

Body: "Save spots you have been, want to try, or got from friends."

Primary CTA: "Start with the map"

Secondary: "Sign in later"

Why: This says what the app is without introducing lists, accounts, or setup work.

### 2. Location

Headline: "Make it local."

Body: "Use location to detect where you are and sort nearby recs."

Primary CTA: "Allow location"

Secondary: "Not now"

Why: Location is necessary for check-in and nearby discovery, so ask early with a plain value exchange.

### 3. Taste / Categories

Headline: "Tune Discover."

Body: "Pick what you actually save."

Inputs: coffee, restaurants, hikes, bars, parks, work cafes, wellness, nature.

Primary CTA: "Continue"

Why: One lightweight personalization step makes Discover feel smarter without creating quiz fatigue.

### 4. Add First Place

Headline: "Add a place."

Body: "Start from where you are, a link, manual search, or a photo."

Options: here now, paste link, add manually, from a photo.

Primary CTA: "Try the plus"

Secondary: "Explore first"

Why: This teaches the core capture loop but still lets people enter the map without committing.

### 5. Auth Gate

Trigger: User taps save, share, follow, sync, or tries to persist a place.

Headline: "Save Maru Coffee?"

Body: "Create a free account to keep it synced and share recs with friends."

Primary CTAs: Apple, Google, email.

Secondary: "Keep browsing"

Why: This aligns login with the user's intent to preserve something.

### 6. Notifications

Trigger: Immediately after the first successful save, or later when a user saves a "want to go" place.

Headline: "Want useful pings?"

Body: "Get reminders for saved spots and friend recs when you are nearby."

Primary CTA: "Turn on notifications"

Secondary: "Maybe later"

Why: Notification permission is easier to justify after the user has saved something worth being reminded about.

### 7. Freemium Paywall

Trigger: Attempted save #21, or a premium action like bulk import/private circles.

Headline: "Your map is filling up."

Body: "20 places are free. Go unlimited when Wander becomes your real map."

Primary CTA: "Go unlimited"

Secondary: "Not now"

Premium value stack: unlimited saves, link imports, private circles, backup/export.

Why: Paywall after value, not before activation.

## What Not To Do

- Do not force login before the first save.
- Do not show the paywall during first-run onboarding.
- Do not ask for notifications cold on screen two.
- Do not bring back a Lists tab or list-first language.
- Do not over-teach the pin legend before the user has used the map.
