# ADR – Zoom Window Viewport Strategy

**Status:** Accepted  
**Date:** 2026-09-01

## Context

Phase 2 Part 3 requires a GoodNotes-style zoom writing strip with auto-advance. PencilKit integration is already standardized via `CanvasView` (`UIViewRepresentable` + Coordinator); `PageViewModel` owns `PKDrawing`. Content overlays (Part 2) use layered SwiftUI views with region-aware hit testing.

Open questions before implementation:

- Single canvas transform vs. secondary canvas for the magnified strip
- Stroke coordinate mapping under magnification
- Interaction with content overlays and `PageInteractionPolicy`
- Settings scope (book vs. per-document wording in Product Spec §4.4)

## Decision

1. **Secondary `CanvasView` instance** in `ZoomWindowView`, reusing the existing PencilKit bridge (no second `UIViewRepresentable` type).
2. **Page-space strokes:** The zoom canvas is laid out at full page dimensions inside a clipped, scaled, offset container so PencilKit strokes remain in page coordinates without manual remapping.
3. **Single drawing owner:** `PageViewModel` remains the sole owner of `PKDrawing`; both canvases bind to the same drawing; only the zoom canvas accepts ink while zoom mode is active.
4. **Ink-only input in zoom:** Text, image, and object-shape tools do not target the zoom strip. Overlays render read-only in the strip for context; editing stays on the main page.
5. **Book-level auto-advance:** `Book.autoAdvanceEnabled` is the persistence source. In PageBound Notes, a book is the user-facing document; per-document wording in §4.4 means book scope.
6. **Return height:** `ZoomSettingsStore` persists per-`TemplateType` return-height overrides (UserDefaults, injectable). Defaults derive from `Template.lineSpacing` or `Template.gridSize.height`, with a 24 pt fallback.
7. **Interaction policy:** `PageInteractionPolicy.zoomModeActive` disables main-canvas drawing, page scroll, and object interaction while zoom is open.
8. **Auto-advance:** Pure `ZoomViewportMath` / `AutoAdvanceEngine` in the ZoomWindow module. A wide blue **visual zone** (~28% of strip width) is drawn as a **strip-local trailing overlay** (not inside the scaled page ZStack). **Horizontal advance** fires when an active stroke crosses a trailing trigger (~8% of viewport width from `viewport.maxX`). Stroke-end processing runs before clearing the active flag so late PencilKit samples still advance. Advance step is ~60% of viewport width. Vertical wrap at the right margin uses template return height.
9. **Dual-canvas sync guard:** The main `CanvasView` remains display-synced from `PKDrawing` but sets `acceptsUserDrawingChanges = false` while zoom is open. Programmatic `canvas.drawing = …` updates set `isApplyingExternalDrawing` so `canvasViewDrawingDidChange` does not echo to `PageViewModel`. Only the zoom strip canvas forwards user drawing changes. `BookViewModel` forwards `ZoomWindowViewModel.objectWillChange` so the main-page viewport overlay stays in sync.
10. **Magnification resizes viewport:** Slider magnification inversely resizes `viewportRect` around its center (smaller rect = higher zoom). Strip `contentScale = stripHeight / viewportRect.height` with no separate magnification multiplier, so the main-page highlight, mini preview, and writable strip region stay aligned.
11. **Zoom render density:** The zoom `CanvasView` raises `contentScaleFactor` using `cappedRenderingScale(contentScale:screenScale:)` (cap 3×) so SwiftUI `scaleEffect` upscaling stays sharper at high zoom.

## Consequences

**Pros:**

- Reuses proven PencilKit bridge and MVVM drawing ownership
- Viewport math is unit-testable without SwiftUI
- Clear input ownership avoids dual-canvas sync bugs
- Book-level toggle already exists in the data model

**Cons:**

- Two `PKCanvasView` instances must stay in sync via shared `PKDrawing` binding
- Read-only overlay compositing in the zoom strip duplicates some page layering
- General pinch-zoom (Page Management) remains independent and deferred

## Related

- ADR – PencilKit Integration Strategy
- ADR – Content Object Layer
- ADR – Custom Tool Palette
- Product Spec §4.4, §6.2
- UI Guidelines §6.4, §8

## Change Log

| Date | Change |
|------|--------|
| 2026-09-01 | Accepted for Phase 2 Part 3 implementation |
| 2026-09-02 | Amended auto-advance trigger semantics (trailing-edge, stroke-active) and dual-canvas sync guard after device QA remediation |
| 2026-09-03 | Magnification resizes viewport; strip-local advance chrome; denser zoom `contentScaleFactor`; stroke-end advance race fix |
