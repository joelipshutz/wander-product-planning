# Build 13 M6 Worker Checklist

Date: 2026-06-08
Scope: M6 extraction worker/result path on top of Build 12 Add/Map cleanup.

Use this as a checkoff script for the next TestFlight build. Mark each item pass/fail and capture a screenshot for any fail.

## Setup

- [ ] Install TestFlight build `0.1 (13)`.
- [ ] Test signed in with Joe's account or another Clerk account.
- [ ] Test signed out once to confirm guest Add behavior still creates local drafts/manual saves.

## Link Extraction

- [ ] Paste a Google Maps link that contains a place name and coordinates.
- [ ] Confirm the app processes it through the backend and lands on `is this the one?` if a coordinate-backed candidate is found.
- [ ] Confirm saving the candidate still requires tapping through confirmation/details; it is not auto-saved.
- [ ] Paste a short/unsupported link that cannot be coordinate-resolved.
- [ ] Confirm unsupported links stay as drafts with manual rescue instead of creating a fake map pin.

## Photo Extraction

- [ ] Import a photo while signed in.
- [ ] Confirm it does not crash and remains an honest draft/manual-rescue state if OCR returns no result.
- [ ] Confirm no fake place is created from the photo.

## Regression Checks

- [ ] `I'm here now` still returns nearby/relevant candidates.
- [ ] Manual Add still resolves candidates via MapKit.
- [ ] Map search still searches saved/network places only, not global Apple Maps.
- [ ] Add flow still has only the upper-left back control, with no redundant `try a different link` / `back to add` buttons.
- [ ] Settings sign out still works.

## Known Out Of Scope For Build 13

- Photo OCR/Vision extraction.
- TikTok and Instagram extraction.
- Generic web extraction without explicit coordinate metadata.
- Scheduled/background worker cron.
