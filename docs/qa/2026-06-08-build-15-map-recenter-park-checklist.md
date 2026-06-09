# Build 15 Map Recenter And Park Category Checklist

Date: 2026-06-08
Scope: Map recenter position/color/zoom, blue unsaved search-result pins, and MapKit park category handling.

Use this as a checkoff script for the next TestFlight build. Mark each item pass/fail and capture a screenshot for any fail.

## User Location And Recenter

- [ ] Open Map with location permission enabled and confirm your location marker appears in blue.
- [ ] Confirm the recenter button is blue and sits at the lower-right above the selected place sheet.
- [ ] Pan away, tap the recenter button, and confirm the map centers and zooms back near your location.
- [ ] Confirm the recenter control does not overlap the search bar, filter chips, selected sheet, or tab bar.

## Unsaved Map Search Results

- [ ] Search for an unsaved nearby POI and confirm the unsaved search-result pin is blue and visually distinct from saved pins.
- [ ] Tap the unsaved search-result pin and confirm the sheet says it is not saved yet.
- [ ] Tap `+` on the unsaved search result and confirm it is added to your map as `wanna`.

## Parks

- [ ] Search for Hotchkiss Park and confirm the result is categorized as `park`, not `hike`.
- [ ] Confirm park rows/sheets use the tree icon, not the hiking icon.

## Existing Action Rules

- [ ] Open a place already saved by you and confirm the `+` button is not shown.
- [ ] Open one of your saved `wanna` places and confirm the edit/pencil action can mark it as `been`.
- [ ] Open a social place you have not saved and confirm the `+` button is shown.

## Known Limits

- Directly tapping Apple's built-in POI labels is not supported in this SwiftUI Map pass. Explicit Map search returns tappable unsaved POI pins.
- Full saved-place editing is not implemented yet; the pencil action currently supports the important `wanna` -> `been` update.
