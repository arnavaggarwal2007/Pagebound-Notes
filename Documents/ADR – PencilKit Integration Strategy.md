# ADR – PencilKit Integration Strategy

**Status:** Accepted  
**Date:** 2026-07-06

## Context

PencilKit is UIKit-based (`PKCanvasView`) but PageBound Notes uses SwiftUI for all views. Low-latency Apple Pencil input is a core product requirement.

## Decision

Integrate PencilKit via a `CanvasView: UIViewRepresentable` wrapper with the Coordinator pattern:

- `makeUIView` / `updateUIView` for canvas lifecycle and tool sync
- Coordinator implements `PKCanvasViewDelegate`
- ViewModel owns `PKDrawing`; bindings sync state both ways
- Palm rejection via `drawingPolicy`

## Consequences

**Pros:**
- Follows documented Apple and community patterns
- Clean separation: ViewModel owns drawing state, View wraps UIKit
- Testable ViewModel without SwiftUI dependency

**Cons:**
- Bridging layer adds complexity vs pure SwiftUI
- Must carefully manage state sync to avoid save/load bugs

## Related

- Product Spec §6.3 SwiftUI + PencilKit Integration
- Vault: `PencilKit Integration Pattern`, `Module – Page`, `Feature – Handwriting and Pen Tools`

## Change Log

| Date | Change |
|------|--------|
| 2026-07-06 | Accepted per product spec §6.3 |
| 2026-09-01 | Migrated to repo-primary documentation model |
