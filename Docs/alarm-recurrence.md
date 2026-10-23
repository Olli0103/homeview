# Explicit alarm recurrence

23 October 2026 · bounded software work for [#52](https://github.com/Olli0103/homeview/issues/52). The issue's physical iPad acceptance remains open and paused. These are HomeView's own schedule choices, not a claim about the original product's exact repeat editor.

## Corrected inconsistency

The previous local foreground path matched hour/minute every day. Its day receipt suppressed another alert that day, but it never disabled a once-only alarm. The AlarmKit adapter constructed `Relative(time:)` with the SDK's default `repeats: .never`. Thus the same unqualified UI described daily local and once-only native behavior. This was found by source comparison, not by a claimed baseline device alarm.

New alarms explicitly choose **Once**, **Every day**, **Mon–Fri**, or **Sat–Sun**. The default is Once. The choice is shown on each row and saved with its identity. A fresh arming timestamp prevents creation or re-enabling during an already-started minute from immediately firing a foreground alarm. Changing a saved schedule is intentionally not added here; delete and recreate it.

Legacy files without a recurrence field retain daily foreground behavior. A legacy entry whose ID is already recorded as a native alarm migrates to Once, preserving that adapter's previous once-only schedule. Existing OS alarms are not silently rescheduled by migration. Invalid/unknown recurrence values are discarded as invalid items, without losing healthy siblings. Explicit current choices and receipts survive a subsequent read/write.

## Foreground time contract

The injected Calendar/time zone resolves each local civil date, not a fixed 86,400-second daily interval. Weekday numbers do not depend on the user's first-weekday preference. A nonexistent time advances to the first valid time after the gap. A repeated time is eligible only at its first occurrence. The foreground window lasts one minute; older missed occurrences are not replayed. A saved day receipt prevents repeated ticks or process restarts from ringing the same day again. Once disables only when the successful local receipt is committed, before the banner/chime request.

Foundation's `.nextTime` skipped the 30-minute Lord Howe gap to the following day in the first candidate. Two assertions failed in its 391-test pilot. The correction explicitly recognizes a forward offset gap using the time zone transition before ordinary calendar matching. The failed candidate source and log remain separate from the accepted checkpoint; no tolerance or expected date was relaxed.

Existing native IDs remain OS-owned rather than being disabled by the foreground tick. Once maps to AlarmKit `.never`; repeated presets map explicitly to public `.weekly` weekday lists. SDK compilation checks the adapter, **not** OS execution or its precise DST policy. The foreground calendar tests must not be presented as an AlarmKit DST-delivery test.

## UI correction and build boundary

The first UI selection passed four methods on iPad and three on iPhone. The iPhone edge case failed: the second row's lower delete edge was outside the scroll view's visible clip even though it remained inside the outer app viewport. The actual image confirmed clipping, not a false missing-model result. Hour/minute/repeat now share a compact editor row. The edge contract is strengthened to require the entire target inside the actual list clip as well as the viewport. The next run still found that the second entry required scrolling. The test now uses bounded real gutter drags to reveal each complete target before delivering the same two-points-inside edge tap; it does not fall back to a center tap or a model shortcut. This is normal scroll-list reachability, not a claim that all 24 possible alarms fit simultaneously.

The first SDK sweep built the four main targets but failed Watch: its deliberately reduced source allowlist did not yet include `AlarmRecurrence.swift`. The generator now includes the required Core dependency. This was a compile boundary, not a launched Watch or device failure.

The initial UI wrapper also attempted its installed-byte read-back after Xcode had returned initially shutdown simulators to Shutdown. The test results are retained (seven passes, one failure), and the same installed pilot app was read back after explicit boot without reinstalling it. The corrected selection starts with both simulators already booted and verifies installed app bytes after the runs.

## Accepted checks

Product/test commit `1d122d6048d96f3f0525144af1bdc6615398c491` and the linked source manifest bind 225 inputs. **391 Core tests** pass, including nine new recurrence methods. The actual macOS AppModel probe passes **39 assertions in four fresh processes**, including a forced write failure before acknowledgement, duplicate ticks, rearming, saved receipts, restart and deletion. Its native-ID control is synthetic; no AlarmManager was called. Current AppModel/Core/Core-test bytes are unchanged from these checks.

All five corrected SDK builds pass. Four UI methods are accepted on both simulators across two selections with byte-identical app products: three main-run methods per device plus the corrected edge method per device. These are **eight accepted executions, not one final eight-test suite**. Main-run edge history remains four passes on iPad / three passes and one failure on iPhone; the targeted edge rerun passes on both. Across all three UI selections: 18 executions, 16 passes, two retained failures. No skips or reported XCTest runtime warnings in the delivery selections. Installed app bytes were read back per device.

46 PNGs decoded; two current contact sheets and three additional full-resolution images inspected. Eight own images/contacts are published. Scrollable phone rows can be partially clipped until scrolled; that is not a claim that every alarm or row label is simultaneously visible. One external 355-entry input/archive file was fully read back (147,093,433 bytes); exact digest is in the receipt. No package cache or raw private log is published.

## Acceptance and boundaries

The linked [receipt](verification/alarm-recurrence.json) records the frozen sources, actual commands/results and inspected own UI images. Tests use synthetic owned UUID stores with `--uitesting` and without `--system-alarms`; no authorization, real system schedule, account, microphone, camera, message or Home access is requested. The separate native macOS AppModel probe has no bundled sound asset. A chime-request counter is not acoustic playback proof.

The device clock/time zone and user accessibility settings are not changed. Model time-zone injection is not a device travel test. The actual iPad alarm outside the app, native authorization revocation/relaunch, physical delivery/removal and exact original repeat scope are not accepted here. Other targets and unapproved native scheduling remain explicitly foreground-only. #52 stays open with its original acceptance criteria intact.
