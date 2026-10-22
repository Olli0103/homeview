# Source-provided podcast captions

22 October 2026 · software portion of [#74](https://github.com/Olli0103/homeview/issues/74). **Not Live Captions, speech recognition, RTT, a new video service or completed assistive-technology acceptance.** Physical/signing acceptance remains on the [owner-requested hold](device-acceptance-hold.md).

## Existing media path, public APIs

The existing explicit-Play AVPlayer path now discovers the actual `.legible` AVMediaSelectionGroup after an episode is played. Its playable, native-named options are selectable alongside Automatic and Off. Selecting an episode or an unloaded caption control does not load/play media. Episodes without a legible group get a disabled selector and an honest no-captions status; no substitute transcript is generated. Current selection policy is RAM-only and resets on a source change. Automatic is an AVFoundation selection policy, not a promise that the OS will choose a particular language.

One AVPlayerItemLegibleOutput stays attached to the current item. The main-queue delegate copies plain strings into a bounded 4,096-character display; foreign text attributes, sample buffers, Markdown, URLs and source actions are not executed. Off immediately clears and ignores text. Seeking clears the old cue and uses the native output-sequence flush boundary; a no-op initial seek at zero is not expected to flush. Latest-seek completion and per-item generation/token checks fence old completions, source discovery and detached output. Stop removes the delegate/output and cancels discovery. The implementation does not claim instant cancellation inside AVFoundation.

The Audio RSS MIME allowlist is unchanged. An audio/mp4 enclosure may supply a native timed-text track; arbitrary external subtitle URLs, Podcasting 2.0 transcript attachments, embedded bitmap-caption decoding, ASR and downloaded transcript persistence were not added. No library dependency was introduced. The UI does not expose this AVPlayer path on Watch.

## Own, reproducible test media

`Resources/podcast-caption-test.mp4` contains **only an own synthetic tone and two own descriptive timed-text markers**, not speech, a real podcast transcript or borrowed lyrics. AVFoundation reports audio and subtitle tracks, no video. The native fixture happens to expose English and English Forced options; those are framework-provided names/options, not a claim that a second authored language exists.

[Generator](../Scripts/generate_podcast_caption_fixture.py) takes the existing own 60-second WAV and a caller-supplied development FFmpeg executable. FFmpeg is not bundled. Its output was generated twice and compared byte-for-byte. Caption fixtures and the mute switch require explicit UI-testing flags; ordinary playback keeps its existing sound behavior. Testing did not connect a personal service, capture microphone/camera audio, call, send a message, operate an alarm or access Home.

## Evidence and remaining scope

The [bound receipt](verification/podcast-source-captions.json) records **14 native controller assertions**, actual timed-text callbacks and **six accepted UI executions across three source pins**: four existing regression executions at the production-layout pin, the complete iPad caption scenario at the next test-only pin, and the complete iPhone scenario after the final test-only containment correction. All 19 actual App-bundle files are byte-identical across those three pins. Five SDK builds passed at the production-layout pin; only the UI-test source changes afterward. This is not one six-test final run.

All UI history is retained: 21 executions, 14 successful and seven earlier failures. Eight of those successful executions are repeated regressions on earlier implementation pins and are not added to the accepted six. The native failed experiments are separate. Eighty exported PNGs were decoded; six accepted own viewports and two inspected contact sheets are published. Four actual-input archives were fully read back. No rebuilt binary is presented as a previously executed input.

The receipt separates the native controller run, simulator interaction revisions and SDK builds. Earlier failed experiments are retained rather than reported as passes. The ordinary Core implementation/tests are unchanged; the prior 382-test checkpoint is not relabeled as a new run.

Source discovery, real timed-text callbacks and two source markers are not a broad format/streaming/language/caption-style compatibility claim. Neither an SDK build nor the muted synthetic tone proves acoustic usability, real-device energy/route behavior, Siri/Shortcuts invocation, Dictation, Type to Siri, Live Speech, OS Live Captions, Vocal Shortcuts or carrier RTT. Those retain their individual open entries in the [speech matrix](speech-feature-boundaries.md). #74 and F104/F105 remain open/unaccepted.
