# Source and asset notices

HomeView's project-owned source, documentation and project-generated assets are
provided under the [MIT License](LICENSE). The owner selected MIT on 17 October
2026. Keep the copyright and permission notice when redistributing substantial
portions of the project.

The public repository contains no third-party Swift package dependencies.
The raster fixtures, app icon and demo tone are original project-generated
assets. The procedural DemoAlbumCover in Sources/App/HomeScreens.swift is also
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

Apple SDKs, system-provided fonts, SF Symbols and other system resources are not
redistributed or relicensed by this repository. Their use remains subject to
their respective terms. Product names and trademarks identify compatibility or
research targets; the MIT license grants no trademark rights or endorsement.
HomeView is an independent prototype, not affiliated with Apple.

Proprietary reference screenshots, original product icons, extracted OS fonts or
contours, binary disassembly and private research archives are excluded from the
public source publication. The license does not grant rights to that material.
The verification screenshots in this repository show our own synthetic
simulator states; incidental system UI remains its owner's material.

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
