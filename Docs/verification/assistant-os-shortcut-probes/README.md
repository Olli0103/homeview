# Actual OS Shortcut probe

`executed-cold-warm-probe.swift.txt` is the exact temporary method used for the final iPad/iPhone checkpoint, including its imports. It relies on the existing `HomeViewUITests` class and `tap` helper; the complete frozen source/compiled/launch archive supplies those inputs. It is **not** retained as an unconditional test in the normal target.

The probe clears app fixture arguments and exercises the normal app sandbox. Therefore its explicit simulator-UUID guard restricts it to the two freshly created, account-free QA devices. A new reproduction must first create its own fresh devices, deliberately replace that allowlist, and freeze a new source/compiled manifest; it must not point this probe at an existing personal sandbox.

It uses only normal native UI: OS welcome/keyboard Continue, the own app's normal demo setup, Shortcuts sidebar, the labelled own provider's visible `text.bubble` action, and synthetic assistant text. No private framework, direct `perform()` call, OS settings override, user-created shortcut, microphone, account, Home command or call. Cold invocation asserts a terminated app; warm invocation waits for actual background and verifies clearing instead of assuming draft retention.

[Report and limits](../../assistant-os-shortcut.md) · [exact executed inputs](../assistant-os-shortcut-source.json) · [receipts and retained failures](../assistant-os-shortcut.json).
