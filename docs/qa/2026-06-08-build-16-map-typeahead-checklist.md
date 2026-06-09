# Build 16 Map Typeahead Checklist

Date: 2026-06-08
Scope: Map search typeahead suggestions.

Use this as a checkoff script for the next TestFlight build. Mark each item pass/fail and capture a screenshot for any fail.

## Typeahead

- [ ] Open Map and tap the search bar.
- [ ] Type `mcd` and confirm nearby McDonald's-style MapKit results start appearing in a suggestion list before pressing search.
- [ ] Type part of a saved/network place name and confirm saved/network matches appear above unsaved MapKit results.
- [ ] Confirm saved/network suggestions use the saved/check affordance and unsaved MapKit suggestions use the add affordance.
- [ ] Tap an unsaved MapKit suggestion and confirm the map centers on it, shows the blue unsaved pin, and the sheet says it is not saved yet.
- [ ] Tap a saved/network suggestion and confirm the map centers on the saved/social pin instead of showing it as a new unsaved result.
- [ ] Clear the search and confirm suggestions disappear.

## Regression

- [ ] Search submit still works from the keyboard.
- [ ] Searching Hotchkiss Park still categorizes it as `park`, not `hike`.
- [ ] The suggestion list does not cover the bottom selected-place sheet or tab bar.
