# Build 12 M6 Extraction Enqueue Checklist

Date: 2026-06-08
Scope: Build 11 Map/Add QA plus the first M6 extraction-job enqueue and nearby-ranking slice.

Use this as a checkoff script for the next TestFlight build. Mark each item pass/fail and capture a screenshot for any fail.

## Setup

- [ ] Install TestFlight build `0.1 (12)`.
- [ ] Test signed out on a fresh install if possible.
- [ ] Test signed in with Joe's account or another Clerk account.
- [ ] Test once with iOS Dark Mode enabled.
- [ ] Test once with iOS Light Mode enabled.

## Add Flow Navigation

- [ ] Tap Add tab from another tab and see `add a place`.
- [ ] Start current-location add, reach `is this the one?`, and confirm there are no extra `pick another nearby place`, `try a different link`, or `back to add` buttons.
- [ ] From `is this the one?`, tap the upper-left back control and return to the prior Add step.
- [ ] Reach quick-details and confirm there are no extra `change place` / `back to add` buttons.
- [ ] From quick-details, tap the upper-left back control and return to `is this the one?`.
- [ ] Leave Add for Map/Profile, return to Add, and confirm it has reset to Add home.

## Current Location Add

- [ ] Tap `I'm here now` from a real location and confirm candidates feel nearby and relevant.
- [ ] Confirm the top candidate is not a stale deterministic fake like Maru Coffee unless you are actually near it.
- [ ] Confirm candidates are still available when the very tight nearby radius has no results.
- [ ] Save one nearby candidate and confirm it appears on Profile and Map.

## Link And Photo Drafts

- [ ] Signed out: paste a weird or unsupported link and confirm it creates an honest draft/failure state instead of pretending a place was extracted.
- [ ] Signed in: paste a weird or unsupported link and confirm it creates the same honest draft/failure state without crashing.
- [ ] Signed in: import a photo and confirm it creates a draft without crashing.
- [ ] Expected for Build 12: link/photo drafts enqueue backend extraction jobs, but the app does not yet show extracted OCR/LLM candidates.

## Map Search

- [ ] Tap Map search, type an existing saved or network-visible place, and see matching pins/sheet.
- [ ] Tap Map search, type a random global place that no one has saved, press the keyboard Search key, and confirm no new candidate pin/sheet appears.
- [ ] For an unsaved global place query, confirm the recovery message tells the user to use Add for search-everywhere behavior.
- [ ] Clear search restores normal map pins.
- [ ] Plus button still saves visible social/network places that someone else already saved.

## Visual Readability

- [ ] Map search text is visible while typing in Dark Mode.
- [ ] Map selected place sheet title is visible on the cream sheet.
- [ ] Map selected place answer chips are visible and readable.
- [ ] Add confirmation screen text is visible in Dark Mode.
- [ ] Add quick-details question chips are visible and readable.
- [ ] Add note field typed text is visible.

## Regression Checks

- [ ] Discover search still dismisses keyboard on scroll.
- [ ] Profile tab still opens settings from the gear.
- [ ] Settings sign out is still visible when signed in.
- [ ] Existing short Google Maps links still resolve or show the short-link draft copy.
- [ ] Photo import still creates a draft.

## Known Out Of Scope For Build 12

- Backend worker execution for extraction jobs.
- Full Google Maps/TikTok/Instagram/photo OCR extraction.
- Native Contacts permission flow.
- Share extension.
