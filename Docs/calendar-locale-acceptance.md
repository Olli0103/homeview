# Calendar: date, locale and reference-state acceptance

22 October 2026 · [#22 / FACE-13](https://github.com/Olli0103/homeview/issues/22).

The remaining software gap was a fixed English/Sunday-first presentation. The calendar face and weekly agenda now use a shared Gregorian `CalendarPresentation`: regional week start, localized month/year, weekday labels and numerals, local Today label, and right-to-left layout where appropriate. Region **does not change the display time zone**, the actual Gregorian date or the user's inherited clock-format preference. No account/store read is added.

Normal launches use the OS locale. Fixed date/zone/locale inputs are test-only, require `--uitesting`, and the reference clock must be active for them to affect presentation. Reference tests default to the existing en_US April state. `MonthLayout` retains Sunday-first as its backward-compatible default; the new presentation passes the locale's explicit first weekday.

## Original versus test states

| State | Basis | What is accepted |
| --- | --- | --- |
| English April 2026 | Privately rechecked UI08, official P01 montage crop | Six rows, adjacent-month dates, local Today circle, month/time arrangement; existing own reference appearance retained |
| German February 2024 | Explicit synthetic localized variant | Monday-first, Februar/Heute, leap day, all 42 cells visible |
| Arabic/Egypt April 2026 | Explicit synthetic localized variant | Gregorian year, Arabic numerals, Saturday-first and correctly mirrored weekday/cell order |
| Japanese August 2026 | Explicit synthetic localized variant | Local month/year and weekday labels; all dates through 31 visible in the six-row presentation |
| Local year boundary/DST | Deterministic fixtures and Foundation IANA rules | Same instant may belong to December/January in different display zones; locale does not substitute its region's time zone |

UI08 is a 544×544 montage crop, **not** a native 600-point screenshot. Original media remain private. The custom background one and public runtime glyphs remain independently reconstructed; exact original contours/antialiasing/materials and unseen original locale/selection rules are not invented. They remain explicit visual gaps under #78. This is the original #22 date/locale/visible-cell acceptance, not a full original-pixel or hardware PASS.

The weekly agenda selects a day in its own current local week. Its selection never changes the face's local Today or the clock. Both now agree on locale week order, including weeks spanning a month/year or a 167-hour DST interval. This is our documented public adaptation, not a claimed private Apple recognizer or selection algorithm.

## Evidence

[Combined calendar/Home acceptance receipt](verification/calendar-home-acceptance.json) · [frozen final source](verification/calendar-home-source.json) · [own calendar images](screenshots/calendar-locale).

375 Core tests passed, including five new locale methods. Gregorian/region/zone boundaries are checked independently of rendering. Final caption-scoping changes no Core or Core-test bytes. Five SDK builds and generator byte-idempotence/Python AST checks passed.

The first 12 Calendar UI executions passed their functional assertions but image comparison found an unintended English AM/PM change: 17,135 / 7,823 changed pixels, entirely inside the clock region. The clock now explicitly inherits its previous environment rather than the date locale. That first checkpoint remains recorded, not relabeled as visual acceptance. The final selected tests, pixel comparison and image review are recorded separately in the receipt. No unchanged whole-image claim is made without the actual final comparison.

No EventKit account, photo library, camera/microphone, Home adapter, messages/calls or real alarms were used. Physical assistive technologies and real-device calendar service acceptance remain separate from these synthetic scenes.

### Final observed results

The final selected Calendar methods passed **six executions** on the unchanged final product/Core state. All 42 dates remain inside both native viewports for German leap day, Arabic RTL and Japanese six-week August; separate DE/AR agenda choices preserve local Today. The earlier 12 successful date/zone executions remain separately bound, not a final full-suite claim.

The final English April comparison is **zero changed RGB pixels and identical PNG SHA-256 on both devices** against our previously published catalogue images (1592² / 1134²). This proves preservation of our own reference rendering, not pixel equality with Apple's montage. 16 current Calendar viewports are published; older AM/PM-regression images remain only in external evidence. Source, actual app/test/launch inputs and installed app bytes are bound before/after every selection.
