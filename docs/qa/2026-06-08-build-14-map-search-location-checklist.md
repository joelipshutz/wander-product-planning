# Build 14 Map Search And Location Checklist

Date: 2026-06-08
Scope: Map user location, recenter, unsaved MapKit search-result pins, and correct selected-place actions.

Use this as a checkoff script for the next TestFlight build. Mark each item pass/fail and capture a screenshot for any fail.

## User Location

- [ ] Open Map with location permission enabled and confirm your location marker appears.
- [ ] Pan away, tap the location/recenter button, and confirm the map centers back on your location.
- [ ] Confirm the recenter control does not overlap the search bar, filters, selected sheet, or tab bar.

## Map Search Results

- [ ] Search for a place already saved by you and confirm it selects the saved pin/sheet.
- [ ] Search for a place in your social graph and confirm it selects the social pin/sheet.
- [ ] Search for an unsaved nearby POI and confirm a visually distinct unsaved search-result pin appears.
- [ ] Tap the unsaved search-result pin and confirm the sheet says it is not saved yet.
- [ ] Tap `+` on the unsaved search result and confirm it is added to your map as `wanna`.

## Action Button Rules

- [ ] Open a place already saved by you and confirm the `+` button is not shown.
- [ ] Open one of your saved `wanna` places and use the edit/pencil action to mark it as `been`.
- [ ] Open a social place you have not saved and confirm the `+` button is shown.
- [ ] Open a social place that is already on your map and confirm the `+` button is not shown.

## Known Limits

- Directly tapping Apple's built-in POI labels is not supported in this SwiftUI Map pass. Explicit Map search returns tappable unsaved POI pins.
- Full saved-place editing is not implemented yet; the pencil action currently supports the important `wanna` -> `been` update.
