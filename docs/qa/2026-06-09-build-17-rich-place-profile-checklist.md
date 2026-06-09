# Build 17 QA - Rich Place Profile

Use this for the next TestFlight candidate. Mark pass/fail and capture screenshots for failures.

## Map Place Profile

- [ ] Tap an existing saved pin, then swipe up on the place sheet.
- [ ] Expanded sheet shows the place name, category/address or locality if known, social proof, and a Directions button.
- [ ] Share icon appears in the upper-right of the expanded profile.
- [ ] Directions opens Google Maps / browser directions for the selected coordinate.
- [ ] The sheet does not show empty website, phone, hours, price, cuisine, order, rating, or photo rows.
- [ ] If a place has no locality/address, the sheet does not fake "Los Angeles."
- [ ] Compact sheet still fits without title/action overlap.

## Your Save

- [ ] Your own saved place shows a "your save" section.
- [ ] Your note appears only if you actually saved a note.
- [ ] Your saved question answers/tags appear as chips.
- [ ] Visibility appears for your own save.
- [ ] If the place is already yours, the action icon is edit/pencil, not plus.

## Social Saves

- [ ] A social place shows who saved it with a facepile/social proof row.
- [ ] Friend notes and answer chips appear in "friends' thoughts" only when available from saved data.
- [ ] If you have not saved the social place, the plus action is still available.
- [ ] If you already saved the same place, plus is hidden.

## Unsaved Map Search Results

- [ ] Typeahead and submitted map search still show unsaved results as blue unsaved pins.
- [ ] Unsaved result cards still say "not saved yet" and offer plus.
- [ ] Saving an unsaved result adds it to your map and removes the unsaved candidate.

## Regression

- [ ] Map recenter button is bottom-right and blue.
- [ ] Parks show as park/tree category, not hike.
- [ ] Map search still prioritizes saved/network results before global MapKit results.
- [ ] Dark Mode does not invert the app into unreadable colors.
