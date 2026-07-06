This is a finalized, MVVM‑with‑SwiftUI product spec you can treat as the source of truth for the project.

***

## 1. Product Overview

**Working Name:** PageBound Notes
**Platform:** iPadOS (Apple Pencil–centric, iPad only)
**Architecture:** SwiftUI + MVVM + Apple frameworks (PencilKit, PDFKit, Core Data/SwiftData)

PageBound Notes is a handwriting‑first note‑taking app that combines the page‑oriented power of GoodNotes with the simplicity and Markup tools of Apple Notes, while remaining completely free and primarily local‑storage based. The app provides unlimited books and folders, clear paginated pages aligned to assignment‑ready PDFs, rich pen tools via PencilKit, a GoodNotes‑style zoom window with auto‑advance, PDF import/export, and optional user‑initiated cloud backup (e.g., Google Drive) with no subscription or custom backend.[^1][^2][^3][^4][^5][^6]

***

## 2. Goals, Scope, and Constraints

### 2.1 Product Goals

- Deliver a fully free alternative to GoodNotes/Apple Notes for handwritten note‑taking and assignment submission on iPad.[^2][^1]
- Guarantee that handwritten lines are never cut across page boundaries when exporting to PDFs, using fixed, visible page borders aligned to standard paper sizes (Letter, A4, etc.).[^1]
- Support unlimited books and nested folders, bounded only by device storage, with intuitive library navigation.[^7][^1]
- Provide a pen/tool catalog comparable to Apple’s Markup tools (pen, marker, pencil, crayon, fountain pen, reed pen, watercolor brush) via PencilKit.[^3][^8][^9][^10][^11]
- Implement a zoom window and auto‑advance writing behavior modeled on GoodNotes’s Zoom Window feature.[^12][^13][^14][^15][^2]
- Enable exporting and importing PDFs (single page, full book, full folder) using PDFKit.[^16][^1]
- Store all primary content locally; cloud interactions are limited to optional user‑initiated backup/export to third‑party providers (Files, Google Drive, etc.).[^4][^5][^6]


### 2.2 Non‑Goals (Initial Releases)

- Real‑time cross‑device sync with a custom backend.
- Support for non‑Apple platforms (Android, Web, Windows).
- Multi‑user collaborative editing within the same notebook.
- Full handwriting‑to‑text transcription and semantic search (treated as future enhancement).


### 2.3 Constraints

- Target iPad devices with Apple Pencil support (Pencil 1/2 and later).
- Target iPadOS 16+ baseline, with enhanced Markup tools (fountain pen, reed pen) available on newer releases like iPadOS 26.[^8][^11][^3]
- Must adhere to Apple’s App Store guidelines, PencilKit and PDFKit usage guidelines, and Google Drive API usage limits.[^5][^3][^4]

***

## 3. User Experience and Key Use Cases

### 3.1 Primary Use Cases

1. **Course Notes \& Assignments**
    - Student creates books per course (e.g., “Math 115A”), writes notes with Apple Pencil on ruled pages, and exports a subset of pages as a PDF to submit assignments.
2. **Lecture Slide Annotation**
    - User imports a lecture PDF, annotates using pen/highlighter tools on top of the slides, and exports the annotated PDF.
3. **Problem‑set and Grid‑based Work**
    - User selects graph paper templates for math/CS problem‑sets, uses zoom window for small handwriting, and auto‑advance to move across lines smoothly.[^13][^14][^2]
4. **Personal Knowledge System**
    - User organizes books and folders hierarchically (e.g., “School → UCLA → 2026 → Courses”), keeps content fully local, and optionally exports backups to Google Drive or Files.

***

## 4. Functional Requirements

### 4.1 Library and Organization

**Requirements:**

- Unlimited **Folders** and **Books** (notebooks) in a hierarchical library view, analogous to GoodNotes’ folder and notebook system.[^7][^1]
- Operations on folders: create, rename, move, delete, nested hierarchy.
- Operations on books: create, rename, move between folders, duplicate, delete.
- Metadata on books: title, cover style, default page size, default template, auto‑advance settings, creation/modification timestamps.
- Library view supports sorting (by name, date), simple filters (e.g., tag, template type).


### 4.2 Pages and Pagination

**Requirements:**

- Each book consists of an ordered sequence of pages with:
    - Fixed physical size (A4, US Letter, or custom), and orientation (portrait/landscape).[^1]
    - Visible border and optional “safe margin” lines indicating the precise clipping area for PDF export.
- Page templates:
    - Blank, college ruled (narrow spacing), wide ruled, dotted grid, fine and coarse graph paper, Cornell notes, music staff, checklists, planners—consistent with patterns seen in GoodNotes notebook templates.[^7][^1]
- Page management:
    - Add new page at end or between pages.
    - Duplicate page.
    - Delete page (with confirmation).
    - Reorder via drag‑and‑drop in thumbnail strip.
- Thumbnail strip: horizontally or vertically scrollable preview of pages for quick navigation, similar to GoodNotes’ thumbnail view.[^14][^16]


### 4.3 Handwriting and Pen Tools

**Requirements:**

- Per‑page PencilKit canvas (`PKCanvasView`) capturing Apple Pencil input at low latency.[^17][^3]
- Tool palette inspired by Apple Markup, exposing at least:
    - Pen / monoline (standard ink).[^9][^8]
    - Marker / highlighter (semi‑transparent, wide stroke).[^10][^8]
    - Pencil (sketch texture).[^8][^9]
    - Crayon (rough textured strokes).[^9][^8]
    - Fountain pen (pressure‑sensitive calligraphic strokes).[^11][^10][^8]
    - Reed pen (angle‑dependent calligraphy, iPadOS 26+).[^3][^9]
    - Watercolor brush (soft, blended strokes).[^10][^8][^9]
- Stroke parameters:
    - Adjustable width, opacity, and color.
    - Preset sizes and color swatches; user‑saved presets.
- Eraser tools (bitmap and vector erasers) plus lasso selection, shapes tool, ruler, and laser pointer similar to GoodNotes toolbar.[^18][^14][^16]
- Palm rejection and pencil/ finger input policies using `drawingPolicy`.[^19][^20][^17]


### 4.4 Zoom Window and Auto‑Advance

**Requirements:**

- Zoom window mode provides a magnified writing strip over the current page, similar to GoodNotes’ Zoom Window.[^2][^13][^14]
- Zoom window shows:
    - Magnified area for writing.
    - Miniature page preview to indicate context.
- Auto‑advance logic:
    - A visual indicator (e.g., blue zone) appears near the right edge of the zoom pane when the stylus approaches that area, consistent with GoodNotes UX.[^15][^14][^2]
    - Writing within that zone causes horizontal sliding of the zoom window along the current line.[^13][^14][^2]
    - At page margin, zoom window moves down by a configurable “return height”, aligned to current template’s line spacing.[^2][^13]
- Settings:
    - Auto‑advance on/off at book and per‑document level, mirroring GoodNotes’ ability to disable auto‑advancing zoom.[^21][^12][^2]
    - Return height configuration per template type.


### 4.5 General Zoom and Navigation

**Requirements:**

- Global pinch‑to‑zoom and pan on each page canvas, consistent with PencilKit and GoodNotes behavior.[^17][^14][^16]
- Tap or gesture to “fit page to screen”.[^16]
- Optional split view for two books or two pages side‑by‑side for cross‑referencing.[^16]


### 4.6 Text, Images, and Shapes

**Requirements:**

- Text boxes overlaying pages, with:
    - Font, size, color, basic rich text (bold/italic).
    - Movable and resizable bounding boxes.
- Image insertion from Photos, Files, or drag‑and‑drop, with transform handles for scale/rotate.
- Shapes: rectangles, circles, arrows, straight lines, with “snap to straight” when appropriate.


### 4.7 PDF Import and Export

**Requirements:**

- **Export:**
    - Export current page as single‑page PDF.
    - Export entire book as multi‑page PDF (pages in order) via PDFKit.[^1][^16]
    - Export entire folder as:
        - Single PDF concatenating books, or
        - Archive (zip) of per‑book PDFs.
- **Import:**
    - Import PDF into a new book where each PDF page is a page with the PDF rendered as background and PencilKit annotation layer on top.[^16][^1]


### 4.8 Storage and Backup

**Requirements:**

- Primary storage: on‑device app sandbox with persistent store (Core Data or SwiftData backed by SQLite) plus file‑based blobs for drawings and assets.
- Local backup/export:
    - “Export backup” operation creating a compressed archive (e.g., `.pbn` bundle) containing metadata and serialized content (books, pages, strokes, templates).
    - Backup restore operation reading `.pbn` and reconstructing folders, books, and pages.
- Cloud backup/export:
    - Use system share sheet to export PDFs or backup archives to Files, iCloud Drive, Dropbox, etc.
    - Optional Google Drive integration via Drive API; user authenticates with Google account and chooses destination folder.[^6]
    - Google Drive API usage is free with quota‑based limits; official Drive usage limits documentation confirms that requests are constrained by quotas and pricing is only relevant if using larger Google Cloud services, but typical app usage remains within free allowances.[^22][^4][^5]
    - Requestly’s Drive API explorer corroborates that API access is free with defined per‑user and per‑project rate limits, and that storage quotas apply to the user’s Drive (e.g., 15 GB free), not to the app developer’s billing.[^23][^6]


### 4.9 Search (Later Phase)

**Requirements (Phase 2+):**

- Basic search across book titles, folder names, and tags.
- Optional handwriting search:
    - On‑device OCR using Vision/Core ML over rendered page images.
    - Index recognized text per page and allow navigation to relevant pages.

***

## 5. Non‑Functional Requirements

### 5.1 Performance

- Low‑latency PencilKit drawing at 60–120 Hz with responsive ink, consistent with PencilKit’s intended profile.[^20][^17]
- Smooth zoom and pan, including zoom window animations, on recent iPad hardware.
- PDF import/export operations should not block UI; use background queues.


### 5.2 Reliability

- Autosave on stroke completion, page transitions, and app backgrounding.
- Crash‑safe persistence via transactional writes (e.g., Core Data transactions, safe file rewrites).


### 5.3 Security \& Privacy

- All local data stored in app sandbox; no unsolicited uploads.
- Any cloud export requires explicit user action and consent; Google OAuth tokens stored securely (Keychain) and used only for user‑initiated backups.[^6][^22]


### 5.4 Battery and Resource Usage

- Efficient use of PencilKit and PDFKit; heavy operations (PDF rendering, backup compression, OCR) run off the main thread.


### 5.5 Accessibility

- VoiceOver support for library and book navigation.
- Respect Dynamic Type and high‑contrast modes for UI components.

***

## 6. Architecture: SwiftUI + MVVM

### 6.1 Architectural Pattern

The app uses MVVM with SwiftUI, separating concerns into **Model**, **ViewModel**, and **View**, leveraging SwiftUI’s state bindings and Combine.[^24][^25][^26]

- **Model:** Pure data and domain logic (Folder, Book, Page, templates, stroke metadata).
- **ViewModel:** `ObservableObject` classes exposing `@Published` state for SwiftUI views, containing business logic, navigation coordination, and persistence interactions.[^26][^24]
- **View (SwiftUI):** Declarative layout; binds to ViewModels via `@StateObject`, `@ObservedObject`, or `@EnvironmentObject`; no business logic other than simple presentation decisions.[^25][^24][^26]

Best practices applied:

- ViewModels remain UI‑framework agnostic (no SwiftUI imports), focusing on domain and state.[^25][^26]
- Dependency injection used to provide repositories/services into ViewModels, improving testability.[^24][^26]
- Complex views are broken into smaller composable SwiftUI views for clarity and reuse.[^27][^24]


### 6.2 Module-Level MVVM Structure

**Modules:**

1. `Library`
    - Models: `Folder`, `BookSummary`.
    - ViewModels: `LibraryViewModel`, `FolderViewModel`.
    - Views: `LibraryView`, `FolderDetailView`.
2. `Book`
    - Models: `Book`, `PageMetadata`.
    - ViewModel: `BookViewModel`.
    - Views: `BookView`, `PageThumbnailStripView`.
3. `Page`
    - Models: `Page`, `StrokeLayer`, `Template`.
    - ViewModel: `PageViewModel`.
    - Views: `PageView`, `ToolPaletteView`, `TemplatePickerView`.
4. `ZoomWindow`
    - Models: `ZoomSettings`, `ZoomState`.
    - ViewModel: `ZoomWindowViewModel`.
    - Views: `ZoomWindowView`.
5. `ExportImport`
    - Services: `PDFExportService`, `PDFImportService`, `BackupService`.
6. `CloudBackup`
    - Services: `DriveBackupService` (Google Drive integration), `ShareSheetService`.

### 6.3 SwiftUI + PencilKit Integration

PencilKit is UIKit‑based, so it is integrated into SwiftUI via `UIViewRepresentable`, following documented patterns and examples.[^28][^19][^20][^18][^17]

**Canvas wrapper (concept):**

- `CanvasView: UIViewRepresentable` wraps `PKCanvasView`.
- `makeUIView(context:)` creates and configures the canvas (`drawingPolicy`, background, tool picker, delegate).[^19][^28][^20]
- `updateUIView(_:context:)` updates canvas state when bindings change (e.g., tool, color, eraser mode).[^28][^18]
- Coordinator pattern: `Coordinator` implements `PKCanvasViewDelegate` to bridge changes back to SwiftUI (`canvasViewDrawingDidChange` updating `@Binding PKDrawing`).[^28]

ViewModel owns the `PKDrawing` or serialized representation; SwiftUI view binds to it, and CanvasView wrapper synchronizes drawing state both ways.[^18][^17][^28]

***

## 7. Data Model and Persistence

### 7.1 Core Entities (Conceptual Schema)

- **Folder**
    - `id: UUID`
    - `name: String`
    - `parentFolderId: UUID?`
    - `createdAt`, `updatedAt: Date`
- **Book**
    - `id: UUID`
    - `folderId: UUID`
    - `title: String`
    - `coverStyle: Enum`
    - `pageSize: Enum` (A4, Letter, Custom)
    - `defaultTemplateId: String`
    - `autoAdvanceEnabled: Bool`
    - `createdAt`, `updatedAt: Date`
- **Page**
    - `id: UUID`
    - `bookId: UUID`
    - `index: Int`
    - `templateId: String`
    - `orientation: Enum`
    - `strokeBlobId: String` (reference to serialized `PKDrawing`)
    - `objectsBlobId: String` (text boxes, images, shapes)
    - `createdAt`, `updatedAt: Date`
- **Template**
    - `id: String`
    - `type: Enum` (ruled, grid, dotted, Cornell, etc.)
    - `lineSpacing: CGFloat`
    - `gridSize: CGSize`
    - `backgroundColor: Color`


### 7.2 Persistence Layer

- Use Core Data or SwiftData with SQLite for structured entities (`Folder`, `Book`, `Page`).
- Store large binary objects (stroke archives, images) separately:
    - Binary blobs in Core Data or files with external storage references.
- Repositories:
    - `LibraryRepository` (CRUD for folders/books).
    - `BookRepository` (book‑level operations).
    - `PageRepository` (page‑level reads/writes, stroke serialization).

***

## 8. External APIs and Integrations

### 8.1 Apple Frameworks

- **PencilKit** (`PKCanvasView`, `PKToolPicker`, `PKDrawing`, `PKInkingTool`, `PKEraserTool`).[^20][^19][^17][^18]
- **PDFKit** (`PDFDocument`, `PDFPage`) for rendering, import, export of PDFs.[^1][^16]
- **SwiftUI \& UIKit**: SwiftUI for views, `UIViewRepresentable` for bridging PencilKit and other UIKit views.[^19][^20][^17][^18]


### 8.2 Google Drive API (Optional Backup)

- REST API v3 for file operations (upload/ download backup files and PDFs).[^6]
- Authentication via OAuth 2.0 (Google Sign‑In or standard web flow), storing tokens in Keychain.[^22][^6]
- Main endpoints:
    - `files.create` (upload backup archive or PDF).
    - `files.get` / `files.list` (restore saved backups if implemented).
- Usage limits:
    - Drive API usage is subject to quotas; documentation clarifies that usage is free within default quotas and that higher quotas can be requested without direct per‑call charges for typical use.[^4][^5][^22]
    - Storage limits apply to the user’s Google Drive (e.g., free tier plus paid upgrades), not to the app developer’s account.[^23][^6]


### 8.3 iOS Share Sheet / Files Integration

- Use `UIActivityViewController` and `UIDocumentPickerViewController` for exporting PDFs and backups to Files, iCloud Drive, and other installed cloud providers.

***

## 9. Development Plan (MVVM‑Oriented)

### 9.1 Phase 0 – Foundations

- Set up project structure: base modules (Library, Book, Page, ZoomWindow, ExportImport, CloudBackup).
- Implement domain models and persistence schema.
- Wire Core Data/SwiftData repositories and dependency injection into ViewModels (e.g., initializer injection).[^26][^24][^25]


### 9.2 Phase 1 – MVP: Local Notebooks and Pagination

- Implement Library MVVM stack; list/create folders and books.
- Implement Book and Page MVVM stacks with basic templates and paginated canvases.
- Integrate PencilKit via `UIViewRepresentable` for basic pen and eraser tools.[^20][^17][^18][^19][^28]
- Implement single‑page and book‑level PDF export via PDFKit.[^16][^1]


### 9.3 Phase 2 – Tooling and Zoom

- Expand pen catalog to match Markup tools (marker, pencil, crayon, fountain, reed, watercolor).[^11][^3][^8][^9][^10]
- Implement ZoomWindow MVVM module: zoom pane view + auto‑advance logic.[^12][^14][^15][^13][^2]
- Add text boxes, image insertion, shapes, and thumbnail navigation.


### 9.4 Phase 3 – Import, Backup, and Cloud

- Implement PDF import into books with annotation layers.[^1][^16]
- Implement backup export/restore (local archive).
- Integrate DriveBackupService for optional Google Drive backups within free API quotas.[^5][^4][^22][^6]
- Add share sheet integration for flexible exports.


### 9.5 Phase 4 – Advanced Features

- Handwriting OCR and search module.
- Split view / multi‑window support.
- User‑defined templates and more granular customization.

***

## 10. Risks and Mitigations

- **API/Quota Changes:**
    - Google Drive limits or policies may change; monitor official “Usage limits” and “APIs and billing” docs and keep integration optional.[^4][^5][^22]
- **OS Feature Variance:**
    - New Markup tools like reed pen and advanced fountain pen behavior may be available only on newer OS versions; feature‑detect and gracefully degrade.[^3][^8][^11]
- **Performance with Large Books:**
    - Large notebooks with many pages require lazy loading and efficient stroke serialization; implement page‑level loading and caching.
- **UX Complexity of Zoom Window:**
    - Auto‑advance behavior can be confusing; provide clear onboarding, inline help, and an easy toggle, following GoodNotes user feedback about disabling auto‑advancing zoom.[^21][^12][^2]

This spec is intended to be stable and comprehensive enough to guide design, implementation, and future iteration for PageBound Notes using SwiftUI + MVVM on iPadOS.
<span style="display:none">[^29][^30][^31][^32][^33][^34]</span>

<div align="center">⁂</div>

[^1]: https://apps.apple.com/ae/app/goodnotes-6/id1444383602?l=ar

[^2]: https://support.goodnotes.com/hc/en-us/articles/7353756826383-Write-with-the-Zoom-Window

[^3]: https://appleinsider.com/articles/25/06/18/the-ipados-26-reed-pen-tool-is-a-great-calligraphy-addition

[^4]: https://developers.google.com/drive/api/guides/limits?hl=fr

[^5]: https://developers.google.com/workspace/drive/api/guides/limits?authuser=610

[^6]: https://requestly.com/api-explorer/google-drive

[^7]: https://thebeigejournal.com/organization/digital-planning/new-goodnotes-6-update-all-you-need-to-know/

[^8]: https://www.iphonemod.net/how-to-use-markup-tool-on-macos-27.html

[^9]: https://joelfeld.com/apple-tutorials/apple-markup-tool-palette-guide

[^10]: https://education.apple.com/story/250010991

[^11]: https://www.instagram.com/reel/DVKOQc1kUJk/

[^12]: https://support.goodnotes.com/hc/en-us/articles/7353743272719-The-Zoom-Window-is-not-advancing-automatically-when-I-write

[^13]: https://www.oreateai.com/blog/mastering-the-goodnotes-zoom-window-a-guide-to-enhanced-notetaking/553939f037b2fde36e0c08a374e136d0

[^14]: https://www.youtube.com/watch?v=9vx5Is8bKeo

[^15]: https://www.reddit.com/r/GoodNotes/comments/gsccem/anyone_know_why_this_highlight_keeps_happening_in/

[^16]: https://www.youtube.com/watch?v=H12_OEy139g

[^17]: https://swiftprogramming.com/pencilkit-swiftui/

[^18]: https://nicoladefilippo.com/pencilkit-in-swiftui/

[^19]: https://note.com/dngri/n/nff46a24c853f

[^20]: https://qiita.com/KaitoMuraoka/items/e3ddf0e81ffb4f938df6

[^21]: https://feedback.goodnotes.com/forums/191274-customer-suggestions-for-goodnotes-apple/suggestions/40668082-have-the-option-to-disable-the-auto-advancing-zoom

[^22]: https://support.google.com/googleapi/answer/6158867?hl=en

[^23]: https://cloud.google.com/free

[^24]: https://medium.com/@chavdajinali/building-a-swiftui-app-with-mvvm-a-practical-guide-5eccbceb83cb

[^25]: https://fera-tech.com/blog/swiftui-mvvm-architecture/

[^26]: https://medium.com/icommunity/how-to-implement-mvvm-in-swiftui-best-practices-56e06b98438b

[^27]: https://zthh.dev/blogs/swiftui-mvvm-best-practices-tips-techniques

[^28]: https://github.com/cis1951/Paint

[^29]: https://medium.com/@thakurneeshu280/understanding-mvvm-architecture-in-swiftui-ddc10f7f92fa

[^30]: https://www.youtube.com/watch?v=VIATIjMiEC0

[^31]: https://www.youtube.com/watch?v=ellNNYTJBwg

[^32]: https://www.sagarunagar.com/blog/create-signature-canvas-in-ios

[^33]: https://www.youtube.com/watch?v=9ISY4yfc7iU

[^34]: https://github.com/heyflavio/SwiftUI-MVVM-C-Best-Practices

