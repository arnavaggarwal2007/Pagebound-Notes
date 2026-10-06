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
8. **Auto-advance:** Pure `ZoomViewportMath` / `AutoAdvanceEngine` in the ZoomWindow module. A wide blue **visual zone** (~28% of `viewportRect` width) is drawn by mapping page-space `advanceZone` into strip coordinates. **Advance runs on stroke end only** when the final point lies in the current viewport and past a trailing trigger (~20% of viewport width from `viewport.maxX`). Mid-stroke samples update zone highlighting only. Points outside the current viewport are ignored (prevents post-wrap bounce from stale right-edge samples). Near the right margin, horizontal advance **clamps** to `maxX`; the next stroke-end trigger **wraps** via template return height. Advance step is ~60% of viewport width.
9. **Dual-canvas sync guard:** The main `CanvasView` remains display-synced from `PKDrawing` but sets `acceptsUserDrawingChanges = false` while zoom is open. Programmatic `canvas.drawing = …` updates set `isApplyingExternalDrawing` so `canvasViewDrawingDidChange` does not echo to `PageViewModel`. Only the zoom strip canvas forwards user drawing changes. `BookViewModel` forwards `ZoomWindowViewModel.objectWillChange` so the main-page viewport overlay stays in sync. Main-canvas `UIPencilInteraction` is silenced while zoom is open (`handlesPencilInteraction = false`).
10. **Magnification resizes viewport:** Slider magnification inversely resizes `viewportRect` around its center (smaller rect = higher zoom). Strip `contentScale = stripHeight / viewportRect.height` with no separate magnification multiplier. After strip layout, **aspect-lock** sets `viewport.width = stripWidth / contentScale` so the main-page highlight, mini preview, and writable strip region stay aligned.
11. **Zoom render density:** The zoom `CanvasView` raises `contentScaleFactor` using `cappedRenderingScale(contentScale:screenScale:)` (cap 3×) so SwiftUI `scaleEffect` upscaling stays sharper at high zoom.
12. **Strip hit isolation + pencil tap:** Magnified strip content is hosted in `ZoomStripHitClip` (UIKit container with bounds-checked `hitTest`). The clip container owns `UIPencilInteraction` so Apple Pencil double-tap reaches `toolSession` reliably outside nested hosting.
13. **Manual reposition + keep-in-view:** The main-page viewport highlight is draggable (centers viewport on drag). User page panning stays disabled while zoom is open (`.scrollDisabled` never unlocked for keep-in-view). `PageView` holds a non-publishing `PageScrollRuntime` and drives the hosting `UIScrollView` via `setContentOffset` (works while `isScrollEnabled == false`) so highlight mid stays in the upper **usable** band above zoom chrome (~0.22 of height minus `zoomChromeClearance`). Drag updates are throttled on the runtime Task (no `@State` churn). Structured logs use `PageBoundLog` (Zoom/Persistence/Navigation).
14. **Page navigation zoom (Part 4):** Pinch, two-finger pan, and fit-to-screen belong to an outer `UIScrollView` (`PageCanvasScrollView` / `PageNavigationController`), not to `PKCanvasView`. PencilKit zoom stays locked at 1× so strokes remain in page space for the zoom strip, overlays, and PDF export. The scroll view’s pan gesture requires two touches, so one finger still draws or edits objects. Fit scale is `PageNavigationMath.fitScale` against the current visible bounds (navigation bar and thumbnail strip included); a **Fit Page** toolbar button and a finger double-tap apply it. Session zoom is not persisted. While the zoom window is open, page scale is forced to 1, pinch and pan gestures are disabled, and keep-in-view continues to use `setContentOffset` on that same scroll view. `updatePageContext` still runs before page-size or template changes inside the zoom strip. Phase 2 Part 5 immersive chrome hides the navigation bar and thumbnail strip; fit still uses these bounds, which are then larger, and `scaleAfterViewportChange` refits only while the session scale is still the last fit.

## Consequences

**Pros:**

- Reuses proven PencilKit bridge and MVVM drawing ownership
- Viewport math is unit-testable without SwiftUI
- Clear input ownership avoids dual-canvas sync bugs
- Book-level toggle already exists in the data model

**Cons:**

- Two `PKCanvasView` instances must stay in sync via shared `PKDrawing` binding
- Read-only overlay compositing in the zoom strip duplicates some page layering
- Page pinch and the zoom window must not both own scrolling; the zoom window forces scale 1 while it is open

## Related

- ADR – PencilKit Integration Strategy
- ADR – Content Object Layer
- ADR – Custom Tool Palette
- ADR – Immersive Writing Chrome
- Product Spec §4.4, §4.5, §6.2
- UI Guidelines §6.4, §8

## Change Log

| Date | Change |
|------|--------|
| 2026-09-01 | Accepted for Phase 2 Part 3 implementation |
| 2026-09-02 | Amended auto-advance trigger semantics (trailing-edge, stroke-active) and dual-canvas sync guard after device QA remediation |
| 2026-09-03 | Magnification resizes viewport; strip-local advance chrome; denser zoom `contentScaleFactor`; stroke-end advance race fix |
| 2026-09-03 | Third remediation: aspect-locked strip↔viewport; page-mapped advance zone; UIKit strip hit clip; clamp-then-wrap advance; drag-on-page highlight; programmatic keep-in-view scroll |
| 2026-09-04 | Fourth remediation: stroke-end-only advance; 20% trigger; viewport-bounded point check; strip-host pencil double-tap; keep-in-view padding + always scroll |
| 2026-09-04 | Fifth remediation: highlight-mid scroll marker + fixed upper-band anchor; hold programmatic scroll unlock for animation |
| 2026-09-04 | Sixth remediation: layout-valid focus marker (fix `.offset` regression); defer scroll unlock/`scrollTo` off view-update path |
| 2026-09-05 | Seventh remediation: UIKit `setContentOffset` keep-in-view while scroll stays disabled; remove unlock/`scrollTo`/marker; drop PageView viewport animation |
| 2026-09-05 | Eighth stabilization: non-publishing `PageScrollRuntime` (stop `@State` storm); chrome-aware usable height; leave-book flush; stale thumbnails during load; `PageBoundLog` |
| 2026-10-01 | Decision 14 fulfilled: outer scroll view owns pinch, two-finger pan, and fit; zoom window forces scale 1 |
| 2026-10-06 | Decision 14: immersive chrome changes the visible bounds `fitScale` already consumes |
