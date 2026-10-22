# Shared panels: separate publication from private access

22 October 2026 · [#8 / FACE-04](https://github.com/Olli0103/homeview/issues/8).

Connecting a source or unlocking the device **does not publish its private cache on a shared face**. Shared Modular/Watch panels, their editor previews and the communal activity strip now use an explicit publication boundary. The private Calendar and Music apps retain their existing separate authentication and permission gates.

## What an approval actually exposes

| Content | Approval | Public fields | Revocation |
| --- | --- | --- | --- |
| Calendar | Authenticate, open Calendar, choose **Share this event** | Snapshot of that selected event's title, start/end, all-day flag and calendar source; display label | Settings: Stop sharing; anyone may hide a published card |
| Apple Music | Authenticate, choose current queue, explicitly **Share current queue with guests** | Existing approved queue metadata and playback, not search/account access | Existing Stop guest sharing; also pauses playback |
| Unconnected demo | No personal source | Clearly synthetic bundled examples | Not represented as private or connected data |

Calendar copies are RAM-only and are never written to Snapshot or UserDefaults. There is one copy per display label, maximum four. A compact panel shows two copies and explicitly counts additional copies; Settings lists every copy and its own revoke action. Location, attendees, notes, source record identifiers and account data are not in the published type. A publication does not enumerate any extra records, request permission or perform a remote write. Invalid input, missing/cancelled/zero-duration records, busy sources and unauthenticated callers cannot publish or evict an approved card.

Private refreshes do not silently replace the approved snapshot. The snapshot label is explicit: this is not a live subscription or a claim of current event state. Replacing it requires another conscious Share action. Reconnecting/disconnecting Calendar, observed source-permission loss, a source failure, local reset, background/Root exit and a new app process revoke calendar publication. Normal private lock/profile switch may retain **only the already approved** public copies; private event/reminder caches still clear and late reads remain fenced. Music keeps its existing stricter queue lifetime, including revocation before a new search.

Shared Music widgets now hide title/artist/play state unless the current queue was separately approved, even while its holder is authenticated. Their button opens the private app instead of starting an unshared queue. Connected Music uses a neutral source symbol rather than presenting demo artwork as actual cover art. Private app metadata is not relabeled or removed.

## Identity boundary

Alex/Jamie and the other demo names are **display labels, not authenticated household identities**. Device authentication proves a device holder, not ownership of a named person's account. A holder may approve a snapshot under the current demo label; that label grants no source access. There is no named-account federation, cross-device share, unattended access, real Home integration or claim that #66 is solved. The original #8 acceptance explicitly uses two synthetic users; the local publication mechanism is real, while those users and test sources remain synthetic.

## Evidence

[Bounded receipt](verification/shared-panels.json) · [frozen source](verification/shared-panels-source.json). The existing guest policy is extended only for these explicit calendar copies and stricter communal metadata display. Its historical test counts remain historical.

The completed receipt records the final model, independent boundary and actual app-interaction results separately. Neither a simulator permission fixture nor a successful SDK build establishes real accounts, device authentication hardware, App Switcher snapshot privacy, original visual equality or automatic presence detection. F006/F007 original parity and those live gates remain unaccepted.

### Completed checks

- **363 Core tests**, seven new publication methods; zero failures. Final caption-only revision changes no Core, Core-test or service bytes.
- **40 independent native assertions** against the actual committed controller, separate from repository tests: field minimization/canaries, invalid input zero effects, separate two-label approvals, lock, revocation, permission loss, late read and music queue isolation. Clean pinned review at `640ea4861c18fbe69031f8984aec8a6c1fd49dfa`. No Python/Node/shell or dependency implementation changed.
- **Eight UI executions** (four methods per iPad/iPhone) at the first implementation pin: two explicit calendar labels, locked/unapproved content, per-card revocation, editor preview, process restart, private Music, explicit sharing/background cleanup and connected Calendar/Music/weather regressions. Actual image review found a clipped source caption despite passing interactions.
- **Two affected Music UI executions** at the final caption pin. The short “Shared · Apple Music” and “Private · Not shared” captions are now visibly complete. Total **ten successful executions across two checkpoints**, not a new full-suite run of the final binary. Zero failures/skips/structured runtime warnings. Both source/compiled-input manifests and installed app bytes read back at each checkpoint.
- Five SDK builds at the final pin, all successful. 46 PNGs decoded, four contact sheets actually reviewed, 14 selected own viewports published with checkpoint-specific hashes. No original media.
