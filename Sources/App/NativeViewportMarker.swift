import SwiftUI

// Test-only, transparent native geometry anchor. A SwiftUI accessibility container
// includes clipped decorative glyph bounds, so it is not a reliable screenshot crop.
#if os(macOS)
  import AppKit
  struct NativeViewportMarker: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
      let view = NSView()
      view.setAccessibilityElement(true)
      view.setAccessibilityIdentifier("reference.viewport")
      view.setAccessibilityLabel("Reference viewport")
      return view
    }
    func updateNSView(_ view: NSView, context: Context) {}
  }
#elseif canImport(UIKit) && !os(watchOS)
  import UIKit
  struct NativeViewportMarker: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
      let view = UIView()
      view.backgroundColor = .clear
      view.isAccessibilityElement = true
      view.accessibilityIdentifier = "reference.viewport"
      view.accessibilityLabel = "Reference viewport"
      view.isUserInteractionEnabled = false
      return view
    }
    func updateUIView(_ view: UIView, context: Context) {}
  }
#endif
