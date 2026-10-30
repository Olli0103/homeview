# Development boundaries

## Active backlog mandate

The owner has explicitly requested completion of the entire issue backlog, not a single fix or checkpoint. Continue to the next eligible issue after each verified delivery; a commit, green test batch or partial issue update is not a stopping condition. Involve the owner only for a concrete missing requirement or authorization that cannot be resolved from available sources. Preserve original acceptance criteria and the separate Home/device/signing holds; never close an unmet criterion to reduce the counter. Keep the current execution/blocker matrix in Docs/remaining-work.md.

The owner's 30 October efficiency correction is explicit: batch coherent remaining functionality and use shared relevant checks. Do not restart per-control focus/pixel microprobes merely because a broad issue is still open. A new probe must address a concrete material gap or an original closure criterion; stop at a demonstrated external blocker. After a green package gate, publish and proceed to the next eligible package instead of repeating unchanged suites or expanding receipt work.

Use synthetic personal data and MockHome in automated tests. Never construct HMHomeManager, discover real homes or operate real devices in this revision. The HomeKit adapter deliberately throws until its owner explicitly resumes setup.

Real calendar, reminders, photos, microphone, camera and music access require an explicit in-app connection. Never send messages or make calls automatically. Device authentication protects personal stores, demo profile selection is not authentication.

Generate the Xcode project with Scripts/generate_project.py. Do not add private Apple frameworks, extracted OS font contours, proprietary reference imagery or binary disassembly to this repository. Use original assets or assets with documented redistribution terms.

Build/test success does not establish visual or functional parity. Keep simulator, physical-device and live-account evidence separate. Track unresolved system-only capabilities as blocked, never silently replace them with a claimed live integration.

## Build storage after the 30 October capacity incident

Reuse one explicit DerivedData directory for the active worktree rather than creating
a new compiler/index/SDK cache for every report or UI selection. Never run concurrent
builds/tests against it. Before reusing compiled products, preserve the exact tested
app/test/launch inputs and manifests required by the checkpoint; keep distinct result
bundles and logs. A historical receipt must not depend on mutable current products.
Do not duplicate unchanged source/binary archives for each device/test selection.

Use the existing `Scripts/build_platforms.py` for SDK checks. It checks the actual
destination filesystem before each build/recovery and records capacity afterward;
the default reserve is 16 GiB (`HOMEVIEW_MIN_FREE_GIB` may explicitly select a positive
reserve). If the reserve is lost, stop the remaining SDKs. This is not a quota or a
guarantee that a single in-flight build cannot consume that reserve. Direct
`xcodebuild`/UI orchestration is not covered by this script: check the same destination
and reserve before those commands too. Prefer the verified external volume; never
create a missing `/Volumes/<name>` as a local substitute. No automatic deletion or
retention policy is authorized. The earlier 522-directory deletion approval applies
only to that frozen historical list, not to regenerated or future caches.

The main app project generator discovers Swift sources automatically; rerun `Scripts/generate_project.py` after adding or removing a source file. The generator maintains an explicit reduced Watch source allowlist. When adding a Core type referenced by shared models or AppModel, include that dependency in the Watch list and regenerate the project; an iOS build alone does not validate this boundary.

Direct simulator UI commands on these owned Apple Silicon devices must use `ONLY_ACTIVE_ARCH=YES ARCHS=arm64` for both build-for-testing and test-without-building, matching the common SDK builder. Do not accidentally request x86_64 against the existing arm64 FeedKit products and then treat the resulting preparation failure as an app regression. Preserve an actual failed preparation; correct the invocation without changing product sources.
