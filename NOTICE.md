# Source and asset notices

HomeView's project-owned source, documentation and project-generated assets are
provided under the [MIT License](LICENSE). The owner selected MIT on 17 October
2026. Keep the copyright and permission notice when redistributing substantial
portions of the project.

RSS parsing uses FeedKit 10.9.4, revision
545aba8b9357fb00ffe51483b659519d96a9d635, including its XMLKit target.
FeedKit is by Nuno Dias, licensed under MIT; the upstream notice is preserved in
[Resources/FeedKit-LICENSE.txt](Resources/FeedKit-LICENSE.txt) and bundled with the
app. SwiftPM resolves the pinned dependency; no third-party source archive is
copied into this repository.
The current geometric raster fixtures, independent-v2 app icon and demo tone
are project-generated assets. The current app icon is drawn from explicit
primitive paths in Scripts/make_icon.swift without a system-symbol/font image.
The procedural DemoAlbumCover in Sources/App/HomeScreens.swift is also
original project artwork under MIT, not a copied or connected album cover; its
source is bound by the relevant verification source manifest.
[asset-manifest.json](Docs/asset-manifest.json) records their provenance
and initial publication digests. Later original Flow glyphs are documented in
[flow-typography.md](Docs/flow-typography.md). Mathematical techniques and public
API use do not imply inclusion of the referenced products' implementation.

The tall photo-clock paths in Sources/App/PhotoTallGlyphs.swift are also
project-authored geometry under MIT, not extracted Apple font contours. Some
digits reuse our own cubic skeletons. Their bounded visual scope and native
atlas evidence are documented in [photo-glyphs.md](Docs/photo-glyphs.md).

Apple SDK binaries and font files are not bundled by this repository. Runtime
system fonts, SF Symbols and other system resources are not relicensed under
the project MIT notice; their use remains subject to their respective terms.
Historical rasterized system content is qualified below. Product names and trademarks identify compatibility or
research targets; the MIT license grants no trademark rights or endorsement.
HomeView is an independent prototype, not affiliated with Apple.

Proprietary reference screenshots, original product icons, extracted OS fonts or
contours, binary disassembly and private research archives are excluded from the
public source publication. The license does not grant rights to that material.
The verification screenshots in this repository show our own synthetic
simulator states; incidental system UI remains its owner's material.

Historical qualification: the earlier app-icon file named icon-1024.png,
present through commit 65a4210, rasterized Apple's house.fill system symbol
inside the project's own background. Its previous generic project-generated
description did not distinguish that component. Do not treat that historical
symbol component as independently authored or relicensed by this project's
MIT notice. The current icon-independent-v2.png replaces it with original
primitive geometry. The historical bytes remain in Git; this correction is
not a history rewrite or clearance of all historical material. See
Docs/asset-provenance.md and Docs/asset-current-manifest.json for scope.

Any future third-party source or bundled asset must retain its own applicable
license and attribution, with provenance documented before redistribution.

The four DemoCamera*V1 images are project-generated fictional AI stills, created
with the built-in image_gen tool without reference-image input. They are bundled
under the project license, not presented as real camera recordings. The complete
prompts, decoded dimensions and content hashes are recorded in
[demo-camera-assets.md](Docs/demo-camera-assets.md). No original reference
photographs or images of a real private home were supplied for their generation.

The DemoPhotoLandscapeV1 and DemoPhotoPortraitV1 fixtures are independently
AI-generated fictional images, created with the built-in image_gen tool without
reference-image input. They are bundled under the project license, not claimed
to be photographs of an actual known person or place. Selected files, hashes,
full prompts and limitations: [demo-photo-assets.md](Docs/demo-photo-assets.md).

DemoPortraitNativeAlphaReplayV1 is a deterministic grayscale copy of the alpha
channel produced by the public native Mac foreground adapter from our own
DemoPhotoPortraitV1. It is test-only replay data under the project license, not
an extracted Apple asset, an iOS native-extraction result or a production
segmentation fallback. Provenance: Docs/demo-photo-assets.json.

The podcast-test-audio.wav fixture is a project-generated 60-second 220-Hz sine
signal, mono PCM 16 kHz/16 Bit, under MIT. It contains no speech, borrowed music
or private recording. It is mapped only to the two explicitly enabled synthetic
RSS fixture episodes. Details: [public-podcast-feeds.md](Docs/public-podcast-feeds.md).
