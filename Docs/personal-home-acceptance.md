# Personal Home: consolidated local acceptance

22 October 2026 · [#9 / FACE-05](https://github.com/Olli0103/homeview/issues/9).

This closes the original local/synthetic profile-layout acceptance, not named household identity, personal accounts or exact original artwork. The previously implemented pieces are checked together on one current product build instead of treating each historical detail commit as an end point.

## Reference and content inventory

| Preset | Known reference | Default four favorites | Additional content |
| --- | --- | --- | --- |
| Photos | UI16 official device rendering | FaceTime, Home / Music, Messages | Selected own/approved photo preview, explicit Demo when none; two-line greeting and demo-profile selector |
| Media | UI42 perspective event photo | Music, FaceTime / Messages, Calendar | Podcast card; Music and secondary app grid below |
| Apps/weather | UI41 and its sampled S07 GIF | Music, Podcasts / Safari, FaceTime | Source-labeled weather card; four-column app rows reached by scrolling |

All six known demo profiles start with their own Photos/default favorites unless they have their own saved configuration. Guest and unknown profiles receive defaults and cannot edit a named profile. Presets/four favorites are independently saved per known profile; selecting an existing favorite swaps positions rather than creating a duplicate. Bad entries are normalized without borrowing another profile's settings. The editor closes on profile switch.

The ordinary profile tap opens demo selection. The long-press menu provides Edit Home Screen; that editor mechanism is a public adaptation, not an observed original interaction. All Apps remains below scroll content. Face return uses the existing explicit navigation; content scrolling is not a global home/face command.

## Empty, locked and connected contents

Unconnected content is clearly synthetic. The bundled podcast's current title is **A Quiet Morning**, with **Demo episode · Local audio** as its source. Playback requires an explicit Play action. Connected Music provides an Open Music entry, not private track names belonging to a demo profile. Real source access still requires its separate consent, permission and device authentication; demo names confer none.

The weather card keeps the real connected-cache state: unavailable values are `—` with an unavailable source, not substituted reference weather. The photo preview follows only the chosen own/explicitly approved source, not a different album. The separately completed [shared-panel contract](shared-panels.md) governs any consciously published communal content; it is not a license for personal Home to import arbitrary accounts.

Current screenshots and the source inventory were compared to UI16, UI41 and UI42 again. Those references contain housing/perspective and cannot establish native pixel geometry. Our images use independent demo assets and public runtime marks, not the original child photo, album art or Memoji. Exact icons/materials/transitions and unknown original variants remain #78 gaps; live named identities/accounts remain #66 and the service issues. F008 original parity remains false.

## Reproducible acceptance

[Combined receipt](verification/calendar-home-acceptance.json) · [source](verification/calendar-home-source.json) · [own Home images](screenshots/personal-home-acceptance). Existing [layout](personal-home-layouts.md) and [weather-grid](personal-weather-grid.md) documents retain their dated partial results and failures.

The current matrix covers default four-app geometry, Alex's media layout through process restart, unchanged Jamie/guest settings, explicit bundled podcast play/navigation, weather scrolling/navigation and unavailable connected values. The complete 375-test Core run includes personal configuration normalization/read-back and Snapshot recovery. Personal layout, podcast, source-policy and persistence implementation bytes are unchanged by the Calendar locale work.

The initial current Home selection passed three methods per device and failed two older test methods per device. One still expected the obsolete literal Demo episode as the episode title rather than the current title/source pair. The other used an old isHittable-only scroll loop and did not reach its expected Weather unavailable state. It now uses the established full-target-containment scroll helper, captures the target before the explicit tap, and retains the same unavailable/no-demo assertions. The exact original transport/overlap cause of that timeout was not established; a later passing helper does not prove it. Original failures stay in the receipt.

The affected podcast/weather cases are rerun separately. The receipt distinguishes these final executions from the earlier successful layout/restart cases; it is not a new final full suite or physical-account acceptance. No actual podcast feed, music account, calendar, Home, photo library, message or call is used.

### Final observed results

Both affected methods now pass on both devices: **four final executions**, alongside six earlier successful layout/restart/scroll executions. All five selected Home methods are covered: **ten successful executions and four preserved initial failures**, across two code pins. There is no new Home implementation change hidden in the helper fix. Five SDK builds at the final pin passed. The shared image receipt decodes 116 PNGs across all three Calendar/Home selections, with 16 selected own Home images and 16 current Calendar images; all final contact sheets were actually reviewed. Earlier source/layout documents retain their historical limits; the local original issue criteria are now complete.
