# Raw assistant keys: unsuccessful candidates retained

29 October 2026 · [#38 / AI-06](https://github.com/Olli0103/homeview/issues/38). **Open, not repaired or accepted.**

Two isolated UI methods against the unchanged production code reproduce the previously open raw Escape/Return boundary on iPhone 18 Pro, iOS Simulator 27.0 (24A434). Escape does not remove composer focus; raw Return does not submit the request. Both use XCTest `typeKey` and assert the resulting state, not its successful API acknowledgement.

Explicit native default/cancel shortcuts, SwiftUI key handlers and a UIKit first-responder candidate did not pass. A further probe targets the field itself: literal `3` is inserted, but literal Escape and Return still have no observed effect. The UIKit candidate uses ordinary State for its wrapped field rather than combining it with SwiftUI FocusState; its input is confirmed present, but its special-key checks still fail. **None of these candidate adapters/handlers is delivered.** Controls.swift, the generated project and the original assistant tests are restored byte-for-byte to the initial product state.

Five frozen input checkpoints contain ten unsuccessful test executions: baseline 2, native shortcuts 2, SwiftUI handlers 2, direct-field transport 1, UIKit responder 3. Their source/compiled archives were fully read back; inputs remained unchanged during each execution and the installed app was byte-verified. The first completed failure run's slow `simctl diagnose` child was stopped only after both methods finished; xcodebuild finalized its failed result normally. Later runs disable automatic diagnostic collection. No failed execution is relabeled PASS.

[Receipts and archive digests](verification/assistant-raw-key-transport.json). Raw logs, failed candidates and actual inputs are retained privately on the external research volume, not published with private host paths.

A separate [public report, auto-mobile #7439](https://github.com/kaeawc/auto-mobile/issues/7439), describes special `typeKey` commands accepted without editing an iOS simulator field; text entry succeeds. Its proposed cause is explicitly **probable**, and its fix uses the text-input path for deletion. Its follow-up also reports a literal forward-delete glyph regression. This is supporting context, not proof that HomeView has the same cause or that an actual hardware keyboard works.

The existing explicit software-keyboard Send and visible Dismiss paths remain separate supported paths. The current targeted delivery selection reruns that existing software-send case on both simulators. Real raw-key handling, physical assistive technologies, OS-edge behavior and original equivalence remain unaccepted. The owner's physical/signing hold remains in force. No account, real microphone/camera, Home connection, message or call is used.
