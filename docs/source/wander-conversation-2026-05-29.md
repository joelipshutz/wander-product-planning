# Wander Source Conversation

Date: 2026-05-29
Source: Joe + Lovable working conversation pasted into Codex
Mocks: [wander-mocks.pdf](./wander-mocks.pdf)

## Raw Notes

We are doing mocks for an iOS app. It is a map-based app for people to check in and add places.

People can capture places they have been in real time, with a few simple questions like "Are you here now?" or "Have you been here?" The app uses location to associate the user with a specific place, but the user experience is the important part: capture places, answer contextual questions, and later find or share those places.

The first idea included lists of places that could be shared with other users. That was later removed. The app should not be list-first.

Categories mentioned:
- Hikes
- Restaurants
- Coffee shops
- Bars
- Wellness centers
- Parks
- Playgrounds
- Cafes you can work from
- Nature spots such as lakes, mountains, waterfalls, hot springs

Core add flow:
- Plus button
- Add by current location
- Add manually
- Add from a link such as Instagram, TikTok, Google Maps, or a blog
- Add from a photo

Home/map experience:
- The map is the core surface.
- Users see their own places and friends' places.
- Distinguish "been" vs "wanna go".
- Distinguish "you" vs "friends".
- Filters should be multi-selectable.
- The user should be able to hide places they have already been when planning a trip.

Discover/social experience:
- There is a "you" world and a "social" world.
- Discover should be smart, not list-oriented.
- Examples: "hikes in LA", "coffee, eastside", "noodles near you", "patio bars", "weekend getaways", "work-friendly cafes".
- People horizontal scroll is good.
- Users should be able to ask or search for things like "show me all the places my friend has been in this place" or "best Thai restaurants in Santa Monica".
- Filters should support friend, category, and location.

Saving from friends:
- If a friend went to a restaurant in Croatia and the user wants to go, the user can save it to their own map.
- The user's map should distinguish places they have been vs places they want to go.
- Places added but not visited and places added and visited can be on the same map as long as they are visually distinct.

Design direction:
- Tan Rodeo-like palette.
- UI elements should pop.
- Font should be fun, sans serif, one click more playful than the first pass.
- Lovable tried Funnel Display + Funnel Sans.
- Tone should feel like a travel buddy but not too informal.
- "Where your friends at?" was too informal.
- Copy should be informal but tighter.

First pass mock feedback:
- Remove lists and the Lists tab.
- Keep Discover, but make it smarter.
- Keep people filter at the top.
- Map is good; do not change much.
- Use emojis/icons for categories.
- Add screens for plus flow.
- Add contextual questions by category.
- Questions can be emoji scales, yes/no, tag taps, and reusable building blocks.
- Users can add additional attributes per place.

Pin color system from mocks:
- You + Been: solid terracotta
- You + Wanna: dashed terracotta
- Friends + Been: solid sky
- Friends + Wanna: dashed sky
- Filters: you, friends, been, wanna go
- Future fifth dimension can use tone or transparency, for example recency.

Contextual question examples:
- Coffee shop:
  - How's the coffee? Emoji scale
  - Good for working? Yes / sometimes / nope
  - The vibe: wifi solid, outlets, quiet, cute, outdoor seats, cash only, food on point, dog friendly
- Hike:
  - How strenuous? Easy / moderate / hard / type 2 fun
  - Dog friendly? Yes / on leash / no
  - What will you see? Ocean view, waterfall, shade, wildflowers, scramble, loop trail, exposed, crowded
- Restaurant:
  - How was the food? Emoji scale
  - Best for: date night, group, solo, kid friendly, quick lunch, late night, walk-in, reservation
  - Price: $, $$, $$$, $$$$

## Codex Decision Packet Answers

Joe selected:
- D0: Proceed with CEO review/spec now. Office hours comes later.
- D1: Backend-first social app direction for spec, with friending designed inline based on competition.
- D2: Scope Expansion mode.
- D3: Mutual friends baseline.
- D4 original: saved places visible to accepted friends after explicit opt-in; live location never shared.
- D4 superseded on 2026-05-31: new places default public within the accepted-friends/social graph, with a private override in the add flow. Public does not mean globally searchable in v1.
- D5: Check-in meaning: "been / wanna go" self-report with optional nearby confirmation badge.
- D6: Template question system with starter categories and custom tags per place.
- D7: AI extraction from links/photos/manual notes; improve on Slate's current extraction, especially Instagram and location.
- D8: Defer Supabase vs Firebase until after spec; write backend-neutral contracts.
- D9: Save source material and spec under the Wander project.

## Mock Pages

Rendered PNG pages are saved in [wander-mocks-pages](./wander-mocks-pages/).
