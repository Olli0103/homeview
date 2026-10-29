# Daylight across local midnight

29 October 2026 · [#53 / DAY-07](https://github.com/Olli0103/homeview/issues/53).

## Reproduced boundary

The existing solar model places Reykjavik's summer sunset just after local midnight and its sunrise later in the same calendar day. On 21 June 2026, `sunsetFraction < sunriseFraction`, with more than 85% of the local day illuminated. The former renderer subtracted sunrise from sunset and clamped a negative result to zero: an entirely dark bar for a mostly light day. A model probe against the unchanged implementation confirmed the reversed ordering; it was a passing boundary probe, not a failing renderer test.

The old renderer also substituted 0.25/0.75 when a local day contained only one crossing, inventing a second endpoint. Neither behavior was a measured original Apple rule.

## Correction

`DaylightWindow` now retains the actual illuminated intervals between its existing horizon crossings, including the initial state at midnight and the final state at the next midnight. A day may have zero, one or two illuminated spans. A sunrise-only or sunset-only day uses its actual local-day boundary; no guessed crossing is added. Polar day covers the whole day, polar night and unavailable coordinates have no light interval. The renderer clips these intervals to one capsule and provides its existing textual status as an accessibility value. The unavailable state now uses an opaque neutral fill: image review found that the previous translucent gray overlay left the purple night color visible underneath. A decoded-channel test checks neutrality instead of only reading the explanatory text.

Fractions describe elapsed time in the actual local calendar day, including 23-/25-hour DST days. The existing IANA catalog, clock times, offset/date distance, persistence and solar-altitude model are unchanged. This does not improve the physical accuracy of that low-order solar model.

## Verification

See [bound receipt](verification/world-clock-midnight-daylight.json) and [own screenshots](screenshots/world-clock-midnight-daylight).

- 397 Core tests passed, including 13 WorldClock methods. New checks cover the reversed Reykjavik ordering, interval endpoints and sampled light/dark agreement on 24 city/date combinations: polar transition dates, both solstices, northern DST changes and a southern-hemisphere city. At least one single-crossing day is required, rather than assumed.
- The UI case captures the actual bar and checks decoded pixels: night at 5% of the local day and daylight at 50%. It is not only an accessibility-tree assertion.
- Current per-device results, compiled/source hashes, installed-app read-back and SDK results are recorded in the receipt. These targeted selections are not a complete app regression or a new hardware acceptance.

**#53 remains open.** The correction fixes our own demonstrable rendering error. It supplies neither a missing Apple HomeView world-clock reference nor accepted original geometry/animation or an ephemeris accuracy claim. Fresh public searches on 29 October returned app listings and general first impressions, not a reviewed world-clock detail view; this is not proof that no such source exists.
