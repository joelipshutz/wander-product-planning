# Build 11 Pre-M6 Test Checklist

Date: 2026-06-08
Scope: pre-M6 UI/interaction cleanup from friend TestFlight feedback plus the Build 11 Map search scope fix.

Use this as a checkoff script for the next TestFlight build. Mark each item pass/fail and capture a screenshot for any fail.

## Setup

- [ ] Install TestFlight build `0.1 (11)`.
- [ ] Test signed out on a fresh install if possible.
- [ ] Test signed in with Joe's account or another Clerk account.
- [ ] Test once with iOS Dark Mode enabled.
- [ ] Test once with iOS Light Mode enabled.

## P0 Visual Readability

- [ ] Map search text is visible while typing in Dark Mode.
- [ ] Map selected place sheet title is visible on the cream sheet.
- [ ] Map selected place answer chips are visible and readable.
- [ ] Add confirmation screen text is visible in Dark Mode.
- [ ] Add quick-details question chips are visible and readable.
- [ ] Add note field typed text is visible.

## Add Flow Navigation

- [ ] Tap Add tab from another tab and see the Add home/source picker.
- [ ] Start current-location add, reach "is this the one?", then tap `back to add` and return to Add home.
- [ ] Start current-location add, reach "is this the one?", then tap `pick another nearby place` and return to Add home.
- [ ] Start manual add, reach "is this the one?", tap `search again`, and return to manual search with prior text preserved.
- [ ] Reach quick-details, tap `change place`, and return to the prior candidate/search step.
- [ ] Leave Add for Map/Profile, return to Add, and confirm it has reset to Add home.

## Add Quick Details

- [ ] Coffee `good for working?` chips have sane spacing with no huge blank gaps.
- [ ] Coffee `tags` chips wrap naturally and do not overlap.
- [ ] Selecting and unselecting multiple tags works.
- [ ] The note field accepts multi-line text without hiding the Save button.
- [ ] Save completes and shows the saved screen.

## Map Search

- [ ] Tap Map search, type an existing saved or network-visible place, and see matching pins/sheet.
- [ ] Tap Map search, type a random global place that no one has saved, press the keyboard Search key, and confirm no new candidate pin/sheet appears.
- [ ] For an unsaved global place query, confirm the recovery message tells the user to use Add for search-everywhere behavior.
- [ ] Clear search restores normal map pins.
- [ ] Plus button still saves visible social/network places that someone else already saved.

## Map Place Sheet

- [ ] Compact sheet title wraps or scales instead of becoming unreadable.
- [ ] Compact sheet social proof row is readable.
- [ ] Expanded sheet answer chips wrap and remain readable.
- [ ] Tapping/dragging the sheet still expands/collapses by swipe.
- [ ] Plus button still saves visible social places.

## Regression Checks

- [ ] Discover search still dismisses keyboard on scroll.
- [ ] Profile tab still opens settings from the gear.
- [ ] Settings sign out is still visible when signed in.
- [ ] Existing short Google Maps links still resolve or show the short-link draft copy.
- [ ] Photo import still creates a draft.

## Known Out Of Scope For Build 11

- Backend extraction execution for link/photo sources. M6 owns this.
- Full TikTok/Instagram/photo OCR extraction.
- Native Contacts permission flow.
- Share extension.
