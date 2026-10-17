# Development boundaries

Use synthetic personal data and MockHome in automated tests. Never construct HMHomeManager, discover real homes or operate real devices in this revision. The HomeKit adapter deliberately throws until its owner explicitly resumes setup.

Real calendar, reminders, photos, microphone, camera and music access require an explicit in-app connection. Never send messages or make calls automatically. Device authentication protects personal stores, demo profile selection is not authentication.

Generate the Xcode project with Scripts/generate_project.py. Do not add private Apple frameworks, extracted OS font contours, proprietary reference imagery or binary disassembly to this repository. Use original assets or assets with documented redistribution terms.

Build/test success does not establish visual or functional parity. Keep simulator, physical-device and live-account evidence separate. Track unresolved system-only capabilities as blocked, never silently replace them with a claimed live integration.
