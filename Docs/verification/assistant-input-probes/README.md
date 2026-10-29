# Independent input probes · 29 October 2026

These are diagnostic source excerpts, **not members of the product or normal UI test target**.

- `NativeControl.swift.txt`: the complete separate UIKit control application, bundle `org.example.KeyTransportControl`. No HomeView code or SwiftUI focus binding. It records an ordinary UITextFieldDelegate Return and a UIKeyCommand Escape.
- `independent-uikit-probe-method.swift.txt`: exact XCTest method executed against that control app on iPhone and iPad with the same frozen compiled test inputs. The assertions establish ordinary-character and software-text delivery; raw-key values are **observations**, not a claim that those keys worked.
- `failed-command-return-method.swift.txt`: unsuccessful HomeView Cmd-Return candidate test. Neither that proposed shortcut nor a replacement field adapter is delivered.

The control was compiled for arm64 iOS Simulator, minimum 26.1 / SDK 27.0, and its actual installed bytes were checked. A compiler sysroot warning was observed; the resulting Mach-O reports IOSSIMULATOR and was executed on both simulators. No UIKit field is substituted into HomeView.

Full source/compiled/launch archives and original failed checkpoints remain on the external research volume. See [the acceptance report](../../assistant-input-acceptance.md) and [raw-key history](../../assistant-raw-key-transport.md). These probes neither authenticate a real device nor access accounts, audio input, cameras or Home.
