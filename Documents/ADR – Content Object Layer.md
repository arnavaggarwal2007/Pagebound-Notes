# ADR – Content Object Layer

**Status:** Accepted  
**Date:** July 12, 2026

## Context

Product Spec §4.6 requires text boxes, images, and manipulable shapes above the PencilKit stroke layer. Phase 0 reserved `objectsBlobId` on `Page`; repository save/load exists but no object schema or UI. Phase 2 Part 1 shipped stroke-committed shapes as ink; object-layer shapes are a separate deliverable.

## Decision

1. **Schema:** Versioned `PageObjectsDocument` (JSON via `Codable`) stored in `objectsBlobId`, containing an ordered array of `PageObject` cases: `.text`, `.image`, `.shape`.
2. **Image bytes:** Stored as separate blob files via `BlobStoreService`; `ImageObject` holds only `imageBlobId` and intrinsic size metadata.
3. **Layering:** SwiftUI `ContentObjectsOverlay` renders above `CanvasView`, below ephemeral tool overlays (laser, shape preview).
4. **Hit-testing:** When a content tool is active (text, image, object-shape mode) or an object is selected, canvas drawing is disabled. Pen/lasso/eraser can tap-to-select objects; selected objects disable canvas input until deselected. **Unfilled object shapes** use stroke-rim hit targets only — interior passes through to ink/eraser/lasso when unselected. Filled shapes, text, and images use full body hits. Selected objects use full body for move.
5. **Input policy (`PageInteractionPolicy`):** `isPencilOnly` applies **only** to `PKCanvasView.drawingPolicy` — never to object transforms. Finger and Apple Pencil both tap-to-select and drag-to-move/resize/rotate selected objects via body-level gestures in `pageCanvas` space. Finger drawing on the stroke canvas is allowed only when `isPencilOnly` is false.
6. **Dual shape modes:** Part 1 stroke-committed shapes remain unchanged. `ShapeCommitMode` (`.ink` | `.object`, default `.object`) on `ToolSessionState` controls whether the shapes tool commits to `PKDrawing` or the object layer. **Ink shapes** are ordinary `PKStroke`s — erasable with eraser/lasso; not object-resizable. Programmatic ink-shape commits must sync to `PKCanvasView` when `PKDrawing` mutates outside delegate callbacks (`CanvasView.Coordinator.sync` compares `dataRepresentation()`). **`ShapeDrawingOverlay` is hidden while an object is selected** — selection owns transforms and tap-outside deselect; draw another shape only when deselected. Micro-drags below ~12pt do not commit.
7. **Text tool phases:** `TextToolPhase` on `PageViewModel` — one-shot insert (`.insertPending` → tap canvas → `.editing`); tap outside or **Done** finishes and returns to pen; no insert-on-every-tap while selected. Text editor (`PageTextEditingLayer`) renders in `pageCanvas` space; canvas text preview hidden while editing. Keyboard focus when `UITextView` is windowed (`FocusableTextView.didMoveToWindow`).
8. **Transform handles:** Visual knobs ~12pt; hit targets ~44pt for corners and rotation (finger parity). Resize pins opposite corner at minimum size. **Images** resize with aspect locked to intrinsic ratio; selection chrome matches photo bounds (no letterbox slack). Line/arrow endpoints scale with frame on resize. Delete affordance for any selected object (text via `TextStyleBar`; image/shape via `SelectedObjectBar`).
9. **Rotation:** Object rotation uses angle-around-center (`atan2`), not vertical-drag scaling.
10. **Lasso scope:** `PKLassoTool` operates on `PKDrawing` strokes only — not content objects.
11. **Ownership:** `PageViewModel` owns object state and autosave; `ToolSessionState` owns tool selection; mutations via ViewModel APIs only.

## Consequences

- PDF export and thumbnails must composite objects via `PageContentRenderer`.
- Page/book delete and duplicate must walk object documents to delete/copy image blob references.
- Future multi-select, z-order UI, and character-level rich text can extend the schema with a version bump.

## Change Log

- 2026-07-14 – Part 2 QA remediation: stroke-rim hit for unfilled shapes; 12/44pt handle targets; opposite-corner resize pin; aspect-locked image resize; shared delete; windowed text focus.
- 2026-07-12 – UX Round 3: shape overlay yields to selection, atan2 rotation, text editor in page canvas, keyboard focus retry, cgImage-based image sizing.
- 2026-07-12 – UX Round 2: `PageInteractionPolicy`, pencil-only canvas-only, body drag transforms, ink-shape canvas sync, text tool phases, image aspect-fit bounds.
- 2026-07-12 – QA remediation: tap-to-select with pen, default Object shape mode, lasso stroke-only note.
- 2026-07-12 – Accepted for Phase 2 Part 2 (Content Overlays).
