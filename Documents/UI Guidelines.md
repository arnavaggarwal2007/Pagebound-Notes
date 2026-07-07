---
title: UI Guidelines
version: 1.0
status: canonical
last-updated: 2026-07-07
---

# PageBound Notes – UI and Visual Design Specification

## 1. Document Overview

This document defines the user interface (UI) and visual design specification for PageBound Notes on iPadOS. It is the canonical source of truth for **visual appearance, interaction patterns, and UI behavior**. Functional requirements and feature scope remain defined in the [Pagebound Notes Project Spec](Pagebound%20Notes%20Project%20Spec.md).

### 1.1 Scope

The specification covers:

- Visual identity (tone, colors, typography, iconography).
- Layout and component patterns across Library, Book, Page, Zoom Window, and import/export flows.
- Interaction patterns, motion, and feedback.
- Accessibility and platform consistency requirements, aligned with Apple’s Human Interface Guidelines (HIG).

Hardcoded design tokens (exact color values, corner radii, and asset filenames) are out of scope for this version and will be defined in a separate design-tokens document. However, the structural rules and behaviors defined here must remain stable regardless of future token updates.

### 1.2 Goals

- Deliver a clean, minimal, and visually sophisticated handwriting-first notes experience that feels native to iPadOS.
- Ensure a polished, professional look that matches expectations set by Apple Notes, GoodNotes, and other leading competitors.
- Provide clear, stable guidance so design and engineering can iterate without fragmenting the visual system.

### 1.3 Document Relationship

| Document | Role |
|----------|------|
| [Pagebound Notes Project Spec](Pagebound%20Notes%20Project%20Spec.md) | Functional requirements, accessibility NFRs, feature scope |
| **UI Guidelines** (this document) | Visual identity, layout, interaction, and component behavior |
| [Development Roadmap](Development%20Roadmap.md) | When UI surfaces ship (Phase 1–4) |
| Design Tokens (future) | Exact color, typography, spacing, and asset values |

When guidance conflicts: the Product Spec wins on **what** to build; this document wins on **how it looks and behaves**. Update both when a change affects requirements and presentation.


## 2. Design Principles

### 2.1 Content-First

- The user’s handwritten pages, PDFs, and library items are the primary visual focus; interface chrome exists only to support viewing, writing, and organizing.
- Tooling and system UI should visually recede, using neutral backgrounds, subtle depth, and restrained color so the canvas and document content always dominate the screen.

### 2.2 Clarity and Hierarchy

- Every screen must have a clear primary action and a visible hierarchy of elements (title, main content, primary controls, secondary controls).
- Components are grouped logically: navigation on the left or top, tools on bottom or top bars, content in the center.

### 2.3 Harmony and Consistency

- Typography, spacing, and component styles are consistent across screens and states, following Apple’s HIG harmony principle.
- Reusable patterns (e.g., cards, tool strips, sidebars, sheets) are preferred over custom one-off layouts.

### 2.4 Calm and Focused

- Visual noise is minimized: no heavy gradients, unnecessary borders, or multiple competing accent colors.
- Motion is subtle and functional: used primarily for zoom window transitions, page navigation, and context menus.

### 2.5 Platform-Native

- The app must feel like a first-class iPad citizen by respecting Apple’s design language, SF typography, system components, and input models.
- Custom elements should be built on recognizable conventions from Apple Notes, Markup tools, Files, and GoodNotes where appropriate.


## 3. Visual Identity

### 3.1 Brand Personality

- Personality: "Quietly expert" – the app should feel serious, reliable, and academic/professional, with subtle references to paper and ink but no overt skeuomorphism.
- Tone: Calm, focused, and modern; suitable for students and professionals who spend hours writing and annotating on iPad.

### 3.2 Color System (Conceptual)

PageBound Notes uses a limited, disciplined color system:

- **Base surfaces:** Neutral surfaces for Library and Page backgrounds to emphasize ink and documents; adapt to system light and dark appearance.
- **Primary accent:** A single primary accent color aligned with systemBlue (or equivalent) for primary actions, selection states, and key highlights.
- **Secondary accents:** A small set of secondary accents for success, warnings, and system status; these are used sparingly in non-writing contexts.
- **Tool colors:** Rich but organized pen color palette divided into neutrals, academic essentials (blue/black/red), and a limited set of bright colors.
- **Auto-advance zone:** Default to a blue highlight zone (GoodNotes-style) near the right edge of the zoom pane; may be overridden by design tokens later.

Exact color tokens and accessibility contrast validations will be specified in the design-tokens document; until then, colors must follow Apple’s contrast and accessibility guidance.

### 3.3 Typography

- **Type family:** Use San Francisco (SF Pro Display/Text) exclusively for UI text, aligning with iOS and iPadOS system typography.
- **Hierarchy levels:** Limit hierarchy to three main levels:
  - Level 1: Large titles (Library title, Book title).
  - Level 2: Section headings (folder names, template categories).
  - Level 3: Body and labels (buttons, metadata, tool labels).
- **Weights:** Use Regular, Medium, and Bold only; avoid light or ultra-heavy weights to preserve legibility.

Handwritten content (PencilKit strokes) should visually dominate on page surfaces, with UI text kept smaller and neutral to avoid competing with the handwriting layer.

### 3.4 Iconography

- Use simple, geometric icons with minimal detail and consistent stroke weight, reflecting Apple’s modern icon style.
- Icons should be meaningful and familiar: folder, notebook, pen, eraser, lasso, shapes, ruler, text box.
- Avoid illustrative or playful icon styles that conflict with the professional tone.


## 4. Layout and Spacing

### 4.1 Global Layout Principles

- **Grid:** All screens follow a consistent spacing system (e.g., 8-point increments) for margins, paddings, and gaps.
- **Margins:** Maintain generous outer margins around the main content (Library lists, page canvas) to create breathing room and focus.
- **Density:** For Library and Book views, prioritize readability over maximum item density; rely on scrolling rather than shrinking cards or thumbnails.

### 4.2 Library View Layout

- **Structure:** Library view uses a sidebar + content layout on large iPad sizes, with a left-aligned sidebar for folders and high-level navigation, and a main area for book cards.
- **Cards:** Each book appears as a card showing title, cover color/pattern, and minimal metadata (e.g., last opened date).
- **Grouping:** Folders are presented as grouped lists or sections, using simple icons and clear headings.

### 4.3 Book View Layout

- **Page thumbnails:** Display a horizontal or vertical strip of page thumbnails for navigation, similar to GoodNotes’ thumbnail strip.
- **Current page:** The active page is centered with visible borders aligned to the PDF export area, with optional safe margin indicators.
- **Tool placement:** Global page controls (add page, delete page, export) reside in a top bar (**Phase 1**). Reorder pages and fit-to-screen controls ship in **Phase 2**; zoom controls ship with the zoom window in **Phase 2**.

### 4.4 Page Canvas Layout

- **Page framing:** Each page is rendered with a crisp outline indicating its physical size and clipping area; safe margins may be shown as subtle guide lines.
- **Templates:** Ruled, grid, Cornell, and other templates use fine, low-contrast lines that do not visually compete with ink strokes.
- **Content overlays:** Text boxes, images, and shapes sit above the stroke layer and are manipulable via handles when selected; otherwise they visually integrate into the page.

### 4.5 Adaptive Layout

- Layout adapts to portrait and landscape orientations on iPad, maintaining consistent hierarchy while reflowing components as needed.
- On compact widths (iPad mini, narrow Split View column), the sidebar collapses to a single-column stack or slide-over navigation while preserving access to folders and books.
- Split view and multi-window scenarios (Phase 4) should preserve the core layout (canvas + tools) while scaling or hiding secondary elements.


## 5. Navigation and Information Architecture

### 5.1 High-Level Structure

The app is structured into the following primary contexts:

- Library (folders, books, and metadata).
- Book (ordered pages and thumbnail navigation).
- Page (canvas, tools, zoom window).
- Import/Export and Backup flows.

### 5.2 Navigation Patterns

- Use a sidebar or top-level navigation for Library on larger screens, aligning with iPadOS patterns for Files and Notes.
- Within Library, tap opens books or folders; long-press opens contextual menus for operations (rename, move, duplicate, delete).
- Within books, navigation between pages relies on the thumbnail strip and standard swiping gestures.

### 5.3 Context Indicators

- Every screen should display a clear title and, where appropriate, a breadcrumb or compact back affordance (e.g., Library → Book → Page).
- Import/export and backup flows must clearly indicate which scope is being acted on (page, book, folder).


## 6. Core UI Components

### 6.1 Library Components

- **Sidebar:** Contains folder hierarchy and sort controls (sort by name/date in **Phase 1**). Filter by tag or template type is **Phase 4+** (see Product Spec §4.1).
- **Quick access (Phase 4+, optional):** "Recent" or "Starred" sections may be added later; not in MVP scope.
- **Book cards:** Represent notebooks with title, cover style, and short metadata; interactions include tap (open), long-press (context menu).
- **Folder rows:** Represent folders with name and count of contained books; interaction model similar to Files/Notes.

### 6.2 Book Components

- **Thumbnail strip:** Scrollable strip of page thumbnails, allowing tap to navigate (**Phase 1**). Drag-and-drop reorder ships in **Phase 2**.
- **Page controls:** Buttons for adding and deleting pages, plus export (**Phase 1**). Duplicate page, reorder, and fit-to-screen ship in **Phase 2**.

### 6.3 Page Components

- **Canvas:** PencilKit canvas with page template background, capturing handwriting at low latency.
- **Tool palette:** Bottom or floating palette with pen and eraser (**Phase 1**). Full Markup-style catalog (lasso, shapes, ruler, text) ships in **Phase 2**.
- **Overlay panels:** Lightweight panels for color selection, size sliders, and template picker.

### 6.4 Zoom Window Components

- **Zoom pane:** Magnified writing strip anchored near the bottom of the screen, showing an enlarged portion of the page.
- **Mini page preview:** Small preview indicating the zoom pane’s position relative to the full page.
- **Auto-advance zone indicator:** Blue highlight zone near the right edge of the zoom pane to signal auto-advance (aligned with Product Spec §4.4 and GoodNotes UX).

### 6.5 Import/Export Components

- **Import preview (Phase 3):** Full-screen or sheet-style PDF preview with options to create a new book and configure initial settings (template overlay, page range).
- **Export sheet:** **Phase 1** — scope picker for Current Page / Entire Book, then `.fileExporter` save. **Phase 3** — Entire Folder export, share sheet, and Drive/cloud picker.
- **Backup card (Phase 3):** Simple settings card for exporting and restoring backup archives.


## 7. Tool Palette and Controls

### 7.1 Placement and Container

- The tool palette appears as a floating bar or docked bottom bar with rounded corners and subtle blur, visually similar to Apple Markup’s tool strip.
- Palette background is neutral and slightly translucent, so underlying page content remains subtly visible.

### 7.2 Tool Grouping

Tools are grouped logically:

- **Primary drawing tools:** Pen, marker/highlighter, pencil, crayon, fountain pen, reed pen (where supported), watercolor brush.
- **Editing tools:** Eraser (bitmap and vector), lasso selection.
- **Utility tools:** Shapes, ruler, laser pointer (optional), text box.

### 7.3 State Representation

- Active tools are clearly indicated via stateful styling (filled icon, pill highlight, subtle glow) while inactive tools remain understated.
- Color and stroke width selection states are visible at all times (e.g., small swatch and width indicator within the palette).

### 7.4 Parameter Controls

- Tool parameters (width, opacity, color) are adjusted via compact popovers or inline controls in the palette.
- Preset sizes and color swatches are provided, with support for user-saved presets.


## 8. Zoom Window and Auto-Advance UI

### 8.1 Zoom Window Behavior

- Zoom window appears when invoked from the tool palette or gesture, presenting a magnified strip of the current page aligned to writing lines.
- The pane respects the page template’s line spacing, adjusting its vertical position with a configurable "return height".

### 8.2 Auto-Advance Indicator

- When the pencil approaches the right edge of the zoom pane, a **blue auto-advance zone** appears (consistent with GoodNotes and Product Spec §4.4).
- Writing into this zone triggers horizontal sliding of the pane along the current line; upon reaching the page margin, the pane moves down by the return height.

### 8.3 Controls and Settings

- Zoom window UI includes minimal controls: Close, zoom level slider, Auto-advance toggle.
- Auto-advance settings are configurable at book and document levels, accessible via a Settings or context menu.


## 9. Interaction, Feedback, and Motion

### 9.1 Touch and Pencil Interactions

- PencilKit provides responsive, low-latency drawing; the app preserves the natural feel of handwriting as expected on iPad.
- Tap, long-press, and drag interactions follow iPadOS conventions, including context menus and drag-and-drop for pages and books.
- When `drawingPolicy` restricts input to Apple Pencil only, provide a subtle toolbar indicator so users understand why finger input is ignored.

### 9.2 Visual Feedback

- Controls provide immediate feedback (highlight, subtle scale) on touch, and pages respond with smooth transitions when swiped or selected.
- Undo/redo actions should provide small visual cues (e.g., stroke fade in/out) to reinforce the change.

### 9.3 Motion and Animations

- Animations are short (on the order of a few hundred milliseconds) and use gentle easing curves; they are used for zoom window entry/exit, page navigation, and tool palette appearance.
- Excessive or decorative animations are avoided to preserve the calm, focused tone.


## 10. PDF Import, Export, and Backup UX

### 10.1 Import Flow

- Importing a PDF opens a preview where the user can confirm pages and create a new book, with options to set initial page templates and metadata.
- The UI clearly communicates the relationship between the original PDF pages and the new notebook pages.

### 10.2 Export Flow

- Export functions allow users to export the current page, entire book, or entire folder as PDFs, using PDFKit.
- **Export (Phase 1):** Scope picker for Current Page / Entire Book, then native file export.
- **Export (Phase 3):** Bottom sheet with folder export scope and handoff to iOS share sheet or cloud picker (e.g., Google Drive).

### 10.3 Backup Flow

- Backup operations create or restore app-specific archives (e.g., `.pbn` bundles), presented as simple actions within Library or Settings.
- Cloud backup uses standard authentication flows and document pickers, with UI that emphasizes privacy and user control.


## 11. Accessibility and Platform Guidelines

### 11.1 Accessibility

- All UI text and controls must respect Dynamic Type settings; font sizes scale appropriately without breaking layouts.
- The app supports **system light and dark appearance**; surfaces and chrome adapt while keeping page templates readable.
- Color usage must meet or exceed contrast requirements specified in Apple’s HIG for legibility in both appearances.
- Support **Increase Contrast / high-contrast mode** for UI chrome (toolbars, library lists, tool palette) per Product Spec §5.5 and Phase 4 exit criteria.
- VoiceOver labels describe controls and states clearly (e.g., "Fountain pen, blue, medium width"), and reading order is logical in Library, Book, and Page views.
- UI strings must use localizable patterns (`LocalizedStringKey` / `String(localized:)`) even if v1 ships English-only.

### 11.2 Platform Consistency

- Controls and interaction patterns follow Apple’s design guidelines for iPadOS, including touch targets, gestures, and use of system components (context menus, share sheets, document pickers).
- The app leverages system behaviors (e.g., split view, multi-window) without introducing custom paradigms that conflict with platform expectations.
- Prefer SwiftUI system constructs where HIG allows: `NavigationSplitView`, `.toolbar`, `.confirmationDialog`, `.sheet`, and system share/document pickers over custom chrome.


## 12. Non-Functional Visual Requirements

### 12.1 Performance Perception

- UI rendering and animations must feel smooth and responsive, especially during drawing, zooming, and PDF operations.
- Loading indicators (spinners, progress bars) are used sparingly and designed to be unobtrusive.

### 12.2 Reliability Perception

- Autosave and backup operations provide subtle feedback (e.g., status messages) so users trust that their work is preserved.
- Error states (e.g., failed export or backup) are clear, concise, and visually integrated with the app’s tone.


## 13. Governance and Change Management

### 13.1 Ownership

- This specification is owned jointly by product design and engineering leads; changes require review from both disciplines.

### 13.2 Versioning

- Major visual or interaction changes must be documented as new versions of this specification, with a change log summarizing differences.

### 13.3 Dependencies

- A separate design-tokens document will define exact color values, typography scales, spacing units, corner radii, and asset references.
- Component libraries (e.g., shared SwiftUI views) must align with this specification and reference the design tokens once available.


## 14. Common UX Patterns

### 14.1 Empty States

- **Empty library:** Encourage creating a first folder or book with a clear primary action and brief guidance text.
- **Empty book:** Prompt adding a first page; show template picker if appropriate.
- **No search results (Phase 4):** Explain no matches and suggest broadening the query.

### 14.2 Destructive Actions

- Delete page, book, or folder requires confirmation via `.confirmationDialog` or equivalent system pattern.
- Destructive actions use system-destructive styling; recovery is not offered after confirmation.

### 14.3 Progress and Feedback

- PDF export, import, and backup show non-blocking progress (toolbar status, subtle banner, or inline indicator) per §12.1.
- Long operations must not freeze the canvas or block navigation.

### 14.4 Compact iPad Widths

- On iPad mini or narrow Split View columns, collapse sidebar into slide-over or stacked navigation.
- Thumbnail strip may switch orientation (horizontal vs vertical) to fit available space.


## 15. Implementation Phases

UI work aligns with the [Development Roadmap](Development%20Roadmap.md):

| Phase | UI scope |
|-------|----------|
| **Phase 1** | Library sidebar/cards, book shell, page canvas framing, basic tool palette (pen + eraser), thumbnail strip, page borders and safe margins |
| **Phase 2** | Full tool palette, zoom window + auto-advance UI, text/image/shape overlays, pinch-zoom and fit-to-screen |
| **Phase 3** | Import preview, export sheet, backup card, share sheet flows |
| **Phase 4** | Split view layout, search UI, custom templates UI, accessibility audit polish, optional Recent/Starred sidebar |

Do not build Phase 2+ UI chrome while implementing an earlier phase unless explicitly prototyping behind a feature flag. If component-level bullets and this phase table appear to conflict, the [Development Roadmap](Development%20Roadmap.md) phase gating controls implementation.


## 16. Summary

This specification establishes PageBound Notes as a clean, minimal, Apple-inspired handwriting app with a disciplined visual and interaction system that can evolve without losing coherence. By grounding UI decisions in content-first design, platform guidelines, and best practices from leading note-taking apps, it serves as the canonical guide for **how** the app looks and behaves across Library, Book, Page, Zoom Window, and import/export flows — with functional scope defined in the Product Spec.

---

## References

1. [Pagebound Notes Project Spec](Pagebound%20Notes%20Project%20Spec.md) — functional requirements and architecture
2. [Development Roadmap](Development%20Roadmap.md) — phased implementation sequencing
3. [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines) — Apple HIG
4. [Designing for iPadOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-ipados) — iPad-specific HIG guidance
5. [Add drawings and handwriting in Notes on iPad](https://support.apple.com/guide/ipad/add-drawings-and-handwriting-ipada87a6078/ipados) — Apple Notes Markup reference
6. [Use handwriting in Notes on your iPad](https://support.apple.com/en-us/121259) — Apple Notes handwriting reference

---

## Change Log

| Date | Version | Change |
|------|---------|--------|
| 2026-07-07 | 1.1 | Phase-scoped component bullets (§4.3, §6.1–6.3, §6.5, §10.2); roadmap gating clarifier in §15 |
| 2026-07-06 | 1.0 | Initial UI Guidelines refined: document hierarchy, spec alignment, phase mapping, common UX patterns, stable references |
