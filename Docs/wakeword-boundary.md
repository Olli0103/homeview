# Voice activation boundary · #37

19 October 2026. **F047 remains blocked and parity false.** The classification task closes with a documented continuing blocked state, as its acceptance criterion permits; no Siri/Hey Siri implementation is being claimed.

## Current user-facing behavior

Opening HomeView or Assistant does not start recording. The Assistant button, its app-local Cmd-Shift-S shortcut and the own viewport gesture open the UI, not the microphone. **Speak** explicitly starts permission checks and voice input; the transcript remains a draft until Send. The capabilities sheet now states that Siri, Hey Siri and custom wakewords are not connected and that no automatic/background wakeword listener is installed.

| Public option reviewed | Boundary in this prototype |
| --- | --- |
| App Intents and App Shortcuts | Public APIs can expose app actions and spoken shortcut phrases to Siri/Shortcuts. HomeView currently declares no AppIntent/AppShortcutsProvider. An app shortcut is not ownership of Siri's wake phrase or its conversation. Future intent/Shortcut work belongs to [#74](https://github.com/Olli0103/homeview/issues/74). |
| iPhone side-button conversation entry | Apple documents a Japan-specific iPhone route using the side-button entitlement and assistant activation schema. It is not a general iPad wakeword hook. No entitlement, regional setup or corresponding intent is added here. |
| OS Vocal Shortcuts | Apple's existing accessibility feature supports deliberately configured custom sounds/actions. It is OS-owned, not an app-installed wakeword engine. No setting, phrase training or always-listening feature is enabled by this work. Current physical setup/support was not accepted. |
| Own microphone/recognition capture | The existing capture is entered only by Speak, after speech/microphone checks; callbacks are generation-fenced and capture is cancelled when leaving/backgrounding. Real on-device recognition remains [#75](https://github.com/Olli0103/homeview/issues/75). |

A custom wakeword is a **separate opt-in product decision**, not an implementation hidden inside this task. The existing system features above were considered first; no custom always-on listener, model dependency or paid service was introduced. This decision does not assert that every public voice-entry API is impossible.

## Evidence

[Receipt](verification/wakeword-boundary.json) · [source manifest](verification/wakeword-source.json) · [native probe](verification/wakeword-idle-probe.swift) · [own-class accessors](verification/wakeword-idle-accessors.swift).

- A native macOS probe compiled the actual production VoiceInputController, without --uitesting. Nine assertions passed: initial idle/non-synthetic state, no SpeechCapture object, finish/cancel while idle remain idle, empty transcript, and unchanged speech/microphone authorization states. It never calls start(). This is controller-level idle proof, not a physical microphone trace or long-duration background test. The compile retained an existing macOS 27 installTap deprecation warning.
- Source audit finds voice.start only in the explicit Speak action; native capture construction follows the two permission checks. No AppIntent, AppShortcutsProvider or SiriKit registration exists in the delivered Sources. These are observations of this revision, not a claim about all Apple APIs.
- Two native UI executions passed on iPad/iPhone: viewing the activation explanation leaves the typed timer request unsent and voice idle. No failures/skips/runtime warnings. All 183 source/resource/test files and 22 compiled/runner inputs bound to the run, unchanged before/after; installed app bytes read back.
- Five SDK builds passed. Core source/tests are unchanged since the preceding 246-test PASS; no duplicate model-suite result is claimed. Generator regenerated externally byte-identically; Python AST checked. Eight PNGs decoded, two contacts visually reviewed, four selected images published. No real speech/microphone grant, account, call, message or Home operation was performed.

Code `5649b6ad11b778c04d168bc421adccbc3b4fb793`, source digest `e7d867680f382e931c5d6e66946c2529a7deca437b1527c09a30162a7cb20d72`. The 205-entry UI input archive and six-entry native probe archive were each read back fully. SHA-256: `faac7fe9defbf5391aaa728a7963bfa7b9e94a4329f115aae260f4c6f485f4a1` and `1cc39332cbb00e647d3c788dd3901c14bd0500841d522625ab8ec9fbb140d4c8`. External research storage retains commands, compiled products and results; [native inventory](verification/wakeword-idle-inputs.json).

Reproduce the native idle probe by appending the test-only accessor suffix to the exact production NativeVoice.swift, then compiling that file, production AssistantLimits.swift and the probe with `xcrun swiftc -swift-version 6 -parse-as-library` on macOS. Run without --uitesting. The accessors inspect our class only, not Apple private APIs.

## Dated public sources

Read on 19 October 2026:

- [Apple App Shortcuts](https://developer.apple.com/documentation/appintents/app-shortcuts): overview and provider/phrase definitions; relevant opening sections read, not a claim to have reviewed every linked API.
- [Apple: Launching a conversational app from the iPhone side button](https://developer.apple.com/documentation/appintents/launching-your-voice-based-conversational-app-from-the-side-button-of-iphone): full article, Japan/iPhone scope, entitlement and activation schema.
- [Apple: Recognizing speech in live audio](https://developer.apple.com/documentation/speech/recognizing-speech-in-live-audio): relevant overview explicitly starts recording with user action. Its current sample uses newer Speech APIs; it is not proof that this app uses that sample or that real recognition passed.
- [Apple's 15 May 2024 accessibility announcement](https://www.apple.com/newsroom/2024/05/apple-announces-new-accessibility-features-including-eye-tracking/): historical Vocal Shortcuts feature and explicit setup, not current-device acceptance. The current Support guide fetch was incomplete/navigation-only and is not relied on as a fresh setup proof.

No Siri invocation was registered or tested, no custom wakeword enabled, and no physical ownership/permissions acceptance added. Apple Home remains disconnected.
