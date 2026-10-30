# Artwork and lyrics: supplied content vs public API surface · #58

**Historical checkpoint, 19 October.** The own bundled-video path described as missing below is now partially implemented and natively exercised: [30 October renderer, lifecycle/cache bounds, tests and remaining limits](demo-animated-artwork.md). Catalog lyric/animation access and system presentation remain unaccepted; the historical evidence and failures below are retained, not rewritten as current results.

19 October 2026. Public documentation and installed SDK 27.0 checked without executing catalog, library, authorization or Now Playing APIs. The new player information sheet uses no media request. Apple Home remains disconnected.

## Capability decision

| Path | What is public | What it does not prove / current app |
| --- | --- | --- |
| MusicKit `Artwork.url(width:height:)` | Image URL and sizing/color/alternate-text metadata | Current integration supplies a static image URL. No animated catalog-cover transport is documented in the inspected Artwork surface; a music-video relationship is not an animated album-cover asset. This is not a universal assertion that animated art is impossible through every licensed provider. |
| MusicKit `Song.hasLyrics` | Boolean: lyrics are available in the catalog | Not lyric text, timestamps, permission to scrape, or a synchronized lyrics renderer. The compile-only probe reads the property; the app has not added a new catalog lookup or lyric-data import. |
| `MPMediaItem.lyrics` | Optional text on an available media item, public on the checked iOS/tvOS/visionOS targets | Not a guaranteed non-nil value, Apple Music catalog lyric endpoint, line timing or rights to republish. A corresponding authorized library/item adapter is **not implemented**, rather than falsely classified impossible. The type is explicitly unavailable on checked macOS/watchOS. |
| `MPMediaItemAnimatedArtwork` + Now Playing animated-artwork keys | An app can supply its own preview and local video asset for system presentation | Not a getter/download entitlement for Apple's catalog animations, and not an in-app renderer. Current HomeView supplies no such asset or animated Now Playing entry. This possible software path remains unimplemented; it is not just a hardware blocker. |

Apple's animated-artwork article requires a local file URL (not a remote/streaming URL), lifetime tied to its Now Playing entry, a matching preview, appropriate aspect ratio and supported keys. It describes static fallback for Reduce Motion, disabled Auto-Play Animated Images, low-power/data and thermal conditions. Those are documented system behaviors, **not observed hardware results from this work**. Own/appropriately licensed video assets and a bounded adapter would still be required before any real animation acceptance.

The current player displays static images, including with Reduce Motion. It downloads/caches **zero animated cover videos**; no animation cache or animation renderer is introduced. Existing static image loading is not relabeled as a zero-byte general image cache. No lyrics are scraped, invented, imported or represented by demo prose. Apple App Review 4.5.2 distinguishes permissioned MusicKit playback from additional rights for deeper integrations and restricts cover/metadata use to music playback/playlists; API availability alone is not a license for republishing assets.

## Visible app behavior

An explicitly labeled information button on the cover opens “Artwork & lyrics” in both the bundled demo and connected Apple-Music player. It explains their different sources and missing lyric/animation data, with no account prompt, source permission, track change, playback command or media request. The sheet contains no selected-song title, artwork, account or personal source records. Closing it returns to the existing player.

This makes unavailable lyrics visible instead of silently implying that the existing static cover is the full original feature. It does not add a Lyrics button that invents text or an animation toggle with no asset. A synthetic static demo cover is not passed off as licensed catalog artwork.

## Evidence and scope

[Receipt](verification/music-artwork.json) · [source manifest](verification/music-artwork-source.json) · [public source locators](verification/music-artwork-sources.json) · [own compile-only probes](verification/music-artwork-api).

Three independent public-API probes across five SDKs: **15 typechecks**, 13 compile and two explicitly reject unavailable `MPMediaItem` on macOS/watchOS. Catalog-image/hasLyrics and own animated Now Playing metadata probes compile on all five. No function is executed and no MusicKit/MediaPlayer account, library, asset or Now Playing state is accessed or written. These typechecks do not add a Music UI to the reduced Watch. SDK public-interface/header digests are retained, not redistributed SDK header contents.

Initial functional UI selection: six successful executions, but manual inspection of the actual saved images failed the new sheet's title contrast (black text on dark background). This visual failure is preserved separately; functional PASS did not authorize acceptance. The corrected sheet sets a consistent light native/content color scheme. Final affected runs and image review are separately source-bound in the receipt.

Final revision `54b2727817cd8e7b43159d022860e2a80a982794` passes six UI executions (three methods on each iPad/iPhone). Actual final images show the corrected readable title/body and complete source-specific explanation. Across both checkpoints: twelve functional UI executions passed, one historical visual-failure checkpoint retained; zero UI failures/skips/structured runtime warnings. Every run freezes 190 source and 22 compiled inputs and reads back the installed app files; both 212-entry archives are fully read back. Five final SDK builds pass. Twelve PNGs decoded, four contact sheets reviewed, eight selected own images include the two historical black-title captures. The info button is measured at least 44 points wide on these two tested devices; no universal accessibility/contrast/Dynamic-Type acceptance is implied.

App/Simulator UI results, source/build/install hashes and selected own captures are recorded separately in the receipt. UI playback assertions use the synthetic provider; no real Apple Music subscription or acoustic playback is inferred. Core sources/tests are unchanged from the historical pinned **279-test PASS**; no redundant new Core run is claimed for these view-only changes.

**#58 and F079 remain OPEN/blocked and parity=false.** Actual catalog lyric access/line synchronization, rights-cleared animated assets, in-app animation/transport/cache handling and actual playback per supported source are not delivered by static cover images, a capability decision or successful typechecks. Original geometry, physical playback and system animated-artwork presentation remain unaccepted.
