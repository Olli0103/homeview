# Development boundaries

## Active backlog mandate

The owner has explicitly requested completion of the entire issue backlog, not a single fix or checkpoint. Continue to the next eligible issue after each verified delivery; a commit, green test batch or partial issue update is not a stopping condition. Involve the owner only for a concrete missing requirement or authorization that cannot be resolved from available sources. Preserve original acceptance criteria and the separate Home/device/signing holds; never close an unmet criterion to reduce the counter. Keep the current execution/blocker matrix in Docs/remaining-work.md.

Use synthetic personal data and MockHome in automated tests. Never construct HMHomeManager, discover real homes or operate real devices in this revision. The HomeKit adapter deliberately throws until its owner explicitly resumes setup.

Real calendar, reminders, photos, microphone, camera and music access require an explicit in-app connection. Never send messages or make calls automatically. Device authentication protects personal stores, demo profile selection is not authentication.

Generate the Xcode project with Scripts/generate_project.py. Do not add private Apple frameworks, extracted OS font contours, proprietary reference imagery or binary disassembly to this repository. Use original assets or assets with documented redistribution terms.

Build/test success does not establish visual or functional parity. Keep simulator, physical-device and live-account evidence separate. Track unresolved system-only capabilities as blocked, never silently replace them with a claimed live integration.

The main app project generator discovers Swift sources automatically; rerun `Scripts/generate_project.py` after adding or removing a source file. The generator maintains an explicit reduced Watch source allowlist. When adding a Core type referenced by shared models or AppModel, include that dependency in the Watch list and regenerate the project; an iOS build alone does not validate this boundary.
