# Flow: numerically checked hybrid Metal compute

22 October 2026 · [#17](https://github.com/Olli0103/homeview/issues/17). Software integration, **not an iPad performance/energy acceptance**.

## The retained failure and targeted comparison

The earlier [numerical blocker](flow-metal-numerical-blocker.md) remains an actual failed checkpoint: four of eight cases exceeded the predeclared velocity/dye limits. No threshold was loosened and its CPU reference was not changed to accommodate the GPU.

A pass-by-pass diagnostic now compares identical CPU snapshots at steps 0, 5 and 19 on a 128-square grid, with original and seeded fields. Twelve stage fields per snapshot cover kick, boundaries, advection, curl, confinement, divergence, pressure, gradient and dye: **72 field comparisons**. The diagnostic's CPU trace is generated from the existing public step body with observation points; its final velocity/dye arrays must exactly equal the unmodified CPU step. GPU trace fields must equal the actor's returned final arrays. These checks prevent the diagnostic adapter from silently becoming a different reference implementation.

The first nonzero difference is already present at the kick, before projection. Each independently restored step differs only slightly, but successive steps amplify the difference. The controlled change evaluates the **existing own source functions** (kick contribution and three dye-injection weights) in CPU Float arithmetic and uploads those fields; Metal performs velocity transport, vorticity/confinement, divergence, all 16 Jacobi iterations with separate boundaries, gradient subtraction and dye advection/blending. With only that source-evaluation boundary changed, all 72 trace fields match exactly on this Mac. This isolates a viable correction; it does not prove that one particular transcendental instruction or compiler option was the sole cause.

The unchanged eight-case numerical pilot then matches CPU velocity and dye **exactly** on Apple M1 Max: sides 8/16/40/128, original and seeded fields, 20 steps except 100 at side40, clipped impulses/delta. The original maximum-error limits remain 0.0005/0.0001 through 20 steps and 0.001/0.0002 for 100 steps. Exact zero here is an observation on this device/compiler, not a portable bitwise guarantee.

## Production boundaries

The new backend is explicitly **hybrid**, not an all-GPU solver, zero-copy renderer or demonstrated speedup. Eleven Float32 textures include two additional source fields. The existing CPU solver remains unchanged as a byte prefix; only a validated snapshot initializer is appended. No dependency, proprietary shader, font data or original image is added. CGImage generation/read-back remains a CPU bridge.

One serial actor owns Metal resources and waits off MainActor for its command buffer. Its snapshot changes only after successful, uncancelled completion with finite returned fields. A failed/cancelled submission discards its resources. The view-owner session admits one pending operation, rejects invalid inputs and repeats, and uses generation checks to reject late success, late failure and stale cleanup after deactivation/replacement. CPU fallback begins from the last **accepted** field and applies the same requested step exactly once; it remains active for that session rather than retrying Metal every frame. A new activation may try a fresh backend.

SwiftUI requests frames from a task, not by mutating observable state during body evaluation. Scene inactivity, disappearance and the matte night branch revoke the owner. Reduced Motion keeps one accepted fixed-phase frame instead of repeatedly advancing a paused simulation. Cancellation cannot instantly stop already submitted GPU work; it rejects its result and releases that task's resources after it drains. This is not an OS-suspend, thermal/device-removal or hardware energy measurement.

## Acceptance and remaining gate

[Bound receipt](verification/flow-compute-acceptance.json) · [final source](verification/flow-compute-source.json) · [own images](screenshots/flow-compute).

The first broad app checkpoint passes four existing methods on each simulator (eight successful executions) but fails the new metadata check on both: the outer accessibility label replaced the diagnostic text with “Flow clock”. Exported native AX descriptions confirm that instrumentation issue, not a measured solver failure. The test-only diagnostic now exposes its separate AX value; the unchanged revision/pending/active requirements pass in two affected reruns. No solver arithmetic changed between these app checkpoints. Thus ten successful UI executions and two retained failures span two pins; this is not a single full ten-test final run. Five final SDK builds pass. Both actual reduced-frame viewports are pixel- and PNG-byte-identical to the prior CPU baseline. All 26 own PNGs are decoded and both sizes' final/contact pictures inspected; 28 labeled images/contact sheets are published.

The final receipt binds actual source, native/compiled inputs, Core results, simulator images and five SDK results. Seven added Core methods cover snapshot validation, inactive/invalid/duplicate/pending requests, late success, old failure while a new owner is pending, exact fallback/retry, the eight actual-Metal numerical cases, and precancelled/invalid allocation avoidance. The complete package has **382 successful tests**. The first preparation diagnostics had two compile-only adapter errors (missing newline, a helper shadowed by the existing palette name); no numerical assertions ran in those failed preparations.

No physical iPad is established by this host's inventory, and no Apple Development signing identity is installed. SDK builds or this actual Mac GPU are not substitute iPad measurements. **#17 remains open for its explicit iPad frame-time/energy acceptance.** The earlier arithmetic and missing software-path blockers can be resolved without pretending the hardware gate passed. Apple Home remains forbidden; all fields and interactions are synthetic, without accounts, capture, communication or alarms.
