# ADR – Custom Tool Palette over PKToolPicker

**Status:** Accepted  
**Date:** July 10, 2026

## Context

The Product Spec references PencilKit frameworks including `PKToolPicker`. UI Guidelines §7 specify a custom floating Markup-style tool strip with grouped tools, always-visible color/width indicators, and parameter popovers. Phase 1 shipped a custom `ToolPaletteView`.

## Decision

Use a **custom SwiftUI tool palette** (`ToolPaletteView`) as the primary drawing UI. Programmatically assign `PKTool` to `PKCanvasView` via `PencilKitToolFactory`. Do not adopt the system `PKToolPicker` as primary chrome.

## Consequences

- Full control over grouping, presets, and UI Guidelines compliance
- Must manually map tool selection to PencilKit types and keep in sync with new OS inks
- Spec framework list remains accurate (PencilKit capability) but UI is custom by design
- **Palette layout:** Four labeled quick-pick inks always visible; remaining inks in a labeled **More** popover — balances §7.2 discoverability with strip width (not a single hidden ink button, not eight unlabeled icons)
