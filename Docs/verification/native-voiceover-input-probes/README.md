# Exploratory native VoiceOver input probes

30 October 2026. These exact source excerpts preserve calibration experiments outside the normal UITest target. They are **not passing activation acceptance tests**. Their source digests and excerpt hashes are in [manifest.json](manifest.json).

| Checkpoint | Actual outcome |
|---|---|
| `pilot-phone` | Native service focus/reported speech reached “Show 9 Button”. Off-target coordinate double-tap did not change the grid to Show 4; one failed UI execution. |
| `keyboard-phone` | The same focused button did not activate through injected Control-Option-Space; one failed UI execution. Apple's keyboard guide documents VO-Space, but the injection/modifier route was not established. |
| `uikit-control-phone` | Independent UIKit/default UIButton: ordinary targeted tap changed button count 0→1; native runtime confirmed VoiceOver enabled and native speech focused the button. Off-target double-tap changed background count 0→1, not button count. Control-Option-Space changed neither count. One **observation** test passed; raw touch/key activation did not. |
| Original focus contract | Two recipe cases wrongly expected Garden Tomato Pasta in a fresh store whose existing default is Butternut Squash Soup. Native speech correctly named that default. Both failed executions and the exact original contract are retained; only the fixture name/precondition was corrected, not the product or accessibility acceptance scope. |

All three runs read back restoration of the simulator's original disabled VoiceOver state. The independent control uses no HomeView or SwiftUI. It contradicts an exclusively HomeView-specific explanation, but does not establish the underlying event interception, modifier or input-transport cause.

The normal target instead contains separately named bounded focus/reported-speech tests. They do not claim touch/key activation, acoustic quality, physical-device behavior, original-product order or complete flow acceptance. Ordinary XCTest routing before VoiceOver reading is fixture setup, not a VoiceOver action. The test-only reference-viewport marker remains explicitly identified in captured streams.

Keeping failed exploratory sources here avoids requiring a separately installed diagnostic app in normal regression runs; it does **not** waive the original accessibility criteria or relabel the two failures as passes. Full original result bundles, input archives and runtime/restoration receipts remain in private external evidence storage. No proprietary OS implementation, extracted assets or private APIs are included.
