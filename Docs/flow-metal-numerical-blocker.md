# Flow Metal: numerical gate still fails

20 October 2026. Issue #17 remains **open**. This checkpoint does not change or activate product code.

## Decision

An own Float32 Metal compute candidate transcribes the existing public CPU implementation. Velocity/dye use two textures each; curl/divergence use one each; pressure has two alternating textures plus a separate Jacobi scratch texture. Every Jacobi iteration has a separate boundary pass. There are nine textures and no in-place neighbor read/write race.

The candidate is retained under `Docs/verification` as **unlinked test input**, not under `Sources`. The unchanged CPU file remains the active renderer. It is also an unchanged byte prefix of the test snapshot file; only a finite-state restore initializer was appended. No private shader, binary disassembly or third-party implementation was copied.

## Existing options checked

- `hagmas/MobileFluidSimulation`: actual MIT license; last pushed 2017-10-30; old app demo, not a maintained solver dependency. Its historical simulator limitation is not treated as a current OS restriction.
- `swithmario/audio_reactive_fluid_visualizer`: recent public app, but actual COPYRIGHT reserves all rights and expressly does not provide an open-source license. No source adopted, microphone used or installation performed.
- `DRAZY/noctura-screensaver`: actual MIT license, recent desktop screensaver. Its native source uses a different line-blade solver, half-float targets, diffusion and pressure sequence; not a drop-in library for this CPU reference. No dependency or source adopted and no installer executed.

## Frozen acceptance and observed output

Maximum absolute velocity/dye errors were fixed before implementation: 0.0005/0.0001 through 20 steps and 0.001/0.0002 for a 100-step run. Each cell/component is compared with the independently stepped, unchanged CPU reference. The inputs include seeded fields, large/clipped impulses and clipped delta.

These are eight standalone actual-Metal diagnostic cases on **Apple M1 Max**, not XCTest, simulator UI, physical iPad performance or energy results.

| Side | Initial state | Steps | Max velocity error | Max dye error | Result |
|---|---|---:|---:|---:|---|
| 8 | original | 20 | 0.0000019073 | 0.0000002384 | PASS |
| 8 | seeded | 20 | 0.0000011921 | 0.0000002384 | PASS |
| 16 | original | 20 | 0.0000061989 | 0.0000002384 | PASS |
| 16 | seeded | 20 | 0.0000042319 | 0.0000004172 | PASS |
| 40 | original | 100 | 0.0021219254 | 0.0001724362 | FAIL, first at 76 |
| 40 | seeded | 100 | 0.0033283830 | 0.0000386834 | FAIL, first at 82 |
| 128 | original | 20 | 0.2170186 | 0.0020703673 | FAIL, first at 6 |
| 128 | seeded | 20 | 0.0006222725 | 0.0000059903 | FAIL, first at 20 |

The complete diagnostic intentionally finishes all cases; its process exit 0 is **not** acceptance. Four pass and four fail. Initial compiler failures and shorter fail-fast attempts remain historical evidence. Precise math and disabling floating-point contraction improved some results but did not meet the frozen gate; a compensated divide/sqrt attempt produced the same final output. No unproved single root cause is asserted.

## Reproduction and remaining work

Copy the three `.swift.txt` inputs from the [digest-bound receipt](verification/flow-metal-numerical-blocker.json) to temporary `.swift` paths outside the repository. Compile the reference snapshot, candidate and pilot together using `xcrun swiftc -swift-version 6 -O`, then run on a real Metal-capable Mac. No camera, microphone, Home, private data, external service or device-removal action is involved. The library compiles its own MSL string using public Metal APIs.

The pilot does not yet cover invalid inputs, cancellation, fallback, view lifetime or simulated device loss. Those are not PASS. They and the UI integration remain deferred until the arithmetic gate passes. A useful next investigation is pass-by-pass field comparison from identical snapshots, rather than more whole-run compiler-option guesses. Actual iPad frame time, energy and resource behavior remain unmeasured. The existing CPU-to-CGImage bridge remains; no zero-copy or acceleration claim is made.
