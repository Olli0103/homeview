# Music library, queue and interruptions

30 October 2026 · [#57](https://github.com/Olli0103/homeview/issues/57)

## Delivered software

- Explicit **Your Library** action and separate catalog selection. Public MusicKit `MusicLibraryRequest<Song>` reads up to 100 title-sorted songs; a library search narrows that bounded list. This is not an exhaustive album/playlist browser or an unlimited library export.
- No library read on connection, launch, demo profile selection or guest playback. Device authentication and the existing explicit Music connection remain required. Loading/replacing a list revokes prior guest queue consent. Cancellation, permission loss, locking and disconnect reject late results.
- Native playback receives the whole currently loaded result list, starting at the chosen song, rather than a one-song queue. Polling maps the native current song identifier back to the visible list. An unknown identifier stops owned playback instead of showing the old title or leaving unpausable audio. Previous/next stop at list boundaries. Selecting a stale result while a replacement list is loading is refused. A passive progress control uses the supplied duration and observed playback time; no duration is invented when it is absent.
- Creating the lazy native music service through a search/library read now registers it for playback observation and cleanup, including an explicitly reauthenticated restored connection.
- Beginning an audio interruption or removing the old output pauses all owned audio paths, including connected Music and bundled audio. Ending the interruption does not automatically resume playback.
- Public MusicKit is the existing maintained platform facility; no new media dependency, private API, receiver or account workaround.

## Audio output controls

[#61](https://github.com/Olli0103/homeview/issues/61): the connected player now supplies the public iOS `AVRoutePickerView` and reads the current `AVAudioSession` output names. It does not select a receiver, activate an audio session, change routing policy, control other apps, implement a receiver or infer multiroom support. Other targets point to system controls instead of offering an unsupported native picker. Synthetic tests do not construct the picker or query the route.

## Verification and limits

See [the compact result record](verification/music-library-queue-20261030.json). Core uses synthetic providers; the new mobile media flow uses a fresh UUID store and the existing regressions retain their original test fixtures. No test reads a real library, requests Music authorization, selects an AirPlay receiver or starts native playback.

Core: the final combined source passed 467 tests, including nine library/queue methods. The earlier library-only source passed 466 tests; its eight new methods also passed after test-only cleanup. The provider contract checks explicit access, bounded queries, empty/error distinction, late replies, cancellation, revocation, guest access/consent and native-identifier changes. It does not execute MusicKit.

Mobile: the first six executions produced five PASS and one retained iPad FAIL: tapping the library row did not expose the player title. The actual iPad image shows the row's empty middle; the final label uses a rectangular content shape across the full row. The final iPhone and iPad media flows both pass, covering the same selection, previous/next boundaries, supplied progress, no native route query in tests, pause, empty library search and catalog return. The required player-title existence is now asserted before reading it. The earlier Music/weather and search-snapshot regressions passed on the preceding source; they are not counted as final-source reruns.

Eight final native viewport PNGs were decoded and reviewed together; [phone library](screenshots/music-library-queue/phone-library.png), [phone player](screenshots/music-library-queue/phone-player.png), [iPad library](screenshots/music-library-queue/pad-library.png) and [iPad player](screenshots/music-library-queue/pad-player.png) are byte-verified copies of owned synthetic captures. No original Apple comparison or unchanged-pixel claim.

Five SDK builds passed: iOS, macOS, tvOS, visionOS and watchOS. The first successful iOS compilation had incomplete AppIntents metadata; the existing standard metadata clean/build recovery passed and is retained in the record. The 16 GiB build-storage reserve remained satisfied.

Native mobile and platform results are recorded separately, not inferred from Core. A compiled queue initializer or a synthetic Play state is not a native playback result. Interruption/route callbacks are software handling, not an acoustic/device acceptance.

**#57 and #61 stay open.** Signing/service provisioning, real subscription/region/offline/revocation behavior, native playback and interruptions on physical hardware, audible AirPlay delivery/volume/disconnect/multiroom behavior, and original UI acceptance remain unproven. The existing Home and device/signing holds remain unchanged.
