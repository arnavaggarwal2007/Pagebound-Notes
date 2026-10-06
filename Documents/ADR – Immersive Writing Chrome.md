# ADR – Immersive Writing Chrome

**Status:** Accepted  
**Date:** 2026-10-06

## Context

Phase 2 Part 5 asks the page canvas to expand toward the top safe area, with an optional toggle that hides the navigation toolbar and thumbnail strip together. Add, export, and delete must stay reachable. Fit already consumes the scroll view’s visible bounds, but those bounds stay small until chrome stops reserving space. The sidebar toggle is removed inside a book, so the navigation bar is also the only Back control.

## Decision

1. **App-wide preference, default visible.** `WritingChromeSettings.isHidden` persists in `WritingChromeStore` (UserDefaults, injectable, same pattern as `ZoomSettingsStore`). It is not a field on `Book`. Default is chrome visible, so the Part 4 layout stays the default.
2. **Hidden chrome.** When the preference is on, `BookView` hides the navigation bar and omits `PageThumbnailStripView`. The page scroll view grows into that space and stops at the top safe area. `ToolPaletteView` stays a floating overlay and does not join the layout stack.
3. **Floating action bar.** A material capsule over the page keeps Back, the book title, Fit Page, Add, Delete, and Export reachable, plus Show Chrome. Hide Chrome lives on the navigation bar while chrome is visible. Reorder, duplicate, and thumbnail navigation return with the strip.
4. **Fit follow.** `PageNavigationMath.scaleAfterViewportChange` applies the new fit scale when the session scale is still the last fit. A pinched scale is kept and clamped to the new minimum and maximum. `PageNavigationController` does not publish during layout. The zoom window still forces scale 1×.

## Consequences

- The preference survives relaunch for every book.
- Fit math stays pure and unit-tested.
- Hiding the strip removes thumbnail navigation until the user shows chrome again.
- No new page-swipe gesture.

## Related

- ADR – Zoom Window Viewport Strategy (decision 14)
- Product Spec §4.5
- UI Guidelines §§4.3, 6.2, 7.1

## Change Log

| Date | Change |
|------|--------|
| 2026-10-06 | Accepted for Phase 2 Part 5 |
