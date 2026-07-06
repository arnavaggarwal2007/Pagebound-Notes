Below is a complete set of guidelines for designing and maintaining an Obsidian knowledge base (KB) for the PageBound Notes project, using a hub/MOC‑style vault with MVVM‑oriented project notes and consistent templates.[^1][^2][^3]

***

## Vault goals and principles

- The vault is a **single source of truth** for the project: product spec, architecture, implementation plans, research, decisions, and operational notes all live here.
- Organization follows a hybrid of **hub/MOC notes + PARA‑style layers** (Projects / Areas / Resources / Archive), adapted for a single software project.[^2][^4][^3]
- Every new note is created from a template, enforced via Obsidian’s Templates or Templater plugin, to keep metadata and structure consistent over time.[^5][^6][^7]

***

## High-level structure: folders and hubs

Use a shallow folder structure and rely on **hub (MOC) notes** and links for navigation rather than deep nested folders.[^4][^8][^2]

### Root folders

Recommended top-level folders for this project vault:

- `00_Hub/` – central entry points and maps of content (MOCs).
- `10_Product/` – product spec, requirements, UX \& user stories.
- `20_Architecture/` – MVVM + SwiftUI architecture, data model, module design.
- `30_Implementation/` – feature specs, API integration notes, module detail docs.
- `40_Research/` – PencilKit, PDFKit, Drive API, Obsidian/KB meta-research.
- `50_Operations/` – roadmap, backlog, release notes, issues, risk register.
- `60_Meetings/` – meeting notes, stakeholder discussions, syncs.
- `70_Decisions/` – architecture decision records (ADRs) and key choices.
- `80_Daily/` – daily work logs and work sessions (optional).
- `90_Archive/` – completed milestones, deprecated specs, old experiments.
- `_Templates/` – all Obsidian templates in one place.[^6][^3][^5]


### Core hub notes (MOCs)

Create hub notes as central maps over these folders:[^9][^2][^4]

- `Project Hub – PageBound Notes` (in `00_Hub/`):
    - Links to all other hubs and major documents (product spec, architecture overview, roadmap).
- `Product Hub` (in `10_Product/`):
    - Links to spec, feature pages, UX flows, personas.
- `Architecture Hub` (in `20_Architecture/`):
    - Links to MVVM overview, module diagrams, data model, integration patterns.
- `Implementation Hub` (in `30_Implementation/`):
    - Links to feature-level specs, module notes, code examples.
- `Research Hub` (in `40_Research/`):
    - Links to each technology research note (PencilKit, PDFKit, Drive API, Obsidian KB strategy).
- `Operations Hub` (in `50_Operations/`):
    - Links to roadmap, backlog, sprints, release notes, risks.

Each hub note serves as a “table of contents” with sections grouping related notes, consistent with MOC/hub practices.[^2][^4][^9]

***

## Layered organization (PARA-style adapted)

Use **layers** inside the vault for clarity, inspired by PARA/Zettelkasten setups.[^10][^3][^1]

### Layer 1 – Project (current work)

- All PageBound Notes‑specific documents in `10_Product/`, `20_Architecture/`, `30_Implementation/`, `50_Operations/`.
- These are **living documents**: they evolve as the product spec and architecture change.


### Layer 2 – Areas (ongoing concerns)

- Operational “areas” like QA, Release Management, Documentation reside in `50_Operations/` and get their own notes (e.g., `Area – QA`, `Area – Release Process`).
- These notes describe policies, checklists, and processes that persist across versions.


### Layer 3 – Resources (reference \& research)

- Technical research and external references live in `40_Research/` (PencilKit, PDFKit, Drive API, SwiftUI MVVM best practices).[^11][^12][^13][^14][^15]
- Also store general iPadOS guidelines, Obsidian tricks, and relevant articles here.


### Layer 4 – Archive

- Once a spec/version is superseded, move its note to `90_Archive/` but keep links intact.
- Archive closed epics, old meeting notes, deprecated decisions while preserving context.[^3][^8]

***

## Update \& maintenance workflow

### Capture and processing

- **Capture:** new ideas or rough notes go to `80_Daily/` or an `Inbox` note in `00_Hub/`, using a simple “Daily Log” or “Scratch” template.[^16][^3]
- **Process:** at least once per workday, process captured items into the correct folders:
    - Turn a design idea into a `Feature Spec` in `30_Implementation/`.
    - Turn a tech link into a `Research Note` in `40_Research/`.
    - Turn a decision into an ADR in `70_Decisions/`.


### Keeping the spec and architecture “canonical”

- The **Product Spec** and **Architecture Overview** are canonical documents; all major changes must be reflected there.
- When implementing a feature or making a design change:
    - Update the relevant feature spec note in `30_Implementation/`.
    - Update higher‑level summaries in `Product Hub` or `Architecture Hub` if the change is impactful.
- Use “Change Log” sections inside spec/architecture notes to briefly record what changed, when, and why.


### Meeting and decisions hygiene

- Every substantive meeting gets a note in `60_Meetings/` using the meeting template; link it to the relevant project hub and feature/area notes.[^17][^5][^6]
- Every lasting decision (e.g., choose Core Data vs SwiftData, PencilKit integration strategy) gets an ADR note in `70_Decisions/`; the related spec/architecture notes link to that ADR.


### Versioning and archiving

- When a spec or architecture note changes significantly:
    - Add a version header (e.g., `v0.3`) and keep prior versions either inside the same note or as archived copies in `90_Archive/`.
- Use tags like `#deprecated`, `#superseded`, or status fields in frontmatter so Dataview or searches can filter out old material.[^7][^5][^3]

***

## Recommended plugins and conventions

These are optional but strongly helpful for a project KB.[^5][^1][^6][^7]

- **Templater or Templates:** enforce note structure and prefill frontmatter.
- **Dataview:** query notes by fields (e.g., all features with status “In Progress”).[^6][^7][^5]
- **Periodic Notes / Calendar:** manage daily logs and work sessions in `80_Daily/`.[^7]
- **Kanban:** optionally track backlog or sprint tasks in Kanban notes linked from `Operations Hub`.[^7]

Conventions:

- One primary project note per project (here, the `Project Hub – PageBound Notes`), plus one note per feature, research topic, meeting, and decision.[^5][^6]
- Use consistent frontmatter fields across note types (e.g., `type`, `status`, `area`, `up`) so Dataview queries remain simple.[^6][^7]

***

## Templates

Below are text structures you can adapt into Obsidian templates. Frontmatter is illustrative; adjust fields as needed.

### 1. Project Hub template (`_Templates/Project Hub.md`)

```markdown
---
type: project-hub
project: PageBound Notes
status: active
owner: Arnav
area: iOS
---

# Project Hub – PageBound Notes

## Overview
- Purpose
- High-level goals
- Links: [[product-spec]], [[architecture-overview]], [[operations-hub]]

## Product
- [[Product Hub]]
- Key docs: [[product-spec]], [[feature-list]]

## Architecture
- [[Architecture Hub]]
- Key docs: [[mvvm-architecture-overview]], [[data-model-overview]]

## Implementation
- [[Implementation Hub]]
- Modules: [[library-module]], [[book-module]], [[page-module]], [[zoom-window-module]]

## Operations
- [[Operations Hub]]
- Roadmap: [[roadmap]]
- Backlog: [[backlog]]
- Releases: [[release-notes]]

## Research
- [[Research Hub]]
- Tech topics: [[research-pencilkit]], [[research-pdfkit]], [[research-google-drive-api]]
```


### 2. Product Spec template (`_Templates/Product Spec.md`)

```markdown
---
type: spec
category: product
status: canonical
version: 0.1
---

# Product Specification – PageBound Notes

## Summary
Short paragraph describing the product, target users, and scope.

## Goals
- G1: ...
- G2: ...

## Functional Requirements
- Library & organization
- Pages & pagination
- Pens & tools
- Zoom window & auto-advance
- PDF import/export
- Storage & backup

## Non-functional Requirements
- Performance
- Reliability
- Security & privacy
- Accessibility

## Open Questions
- ...

## Change Log
- 2026-07-06 v0.1 – Initial spec.
```


### 3. Architecture Overview template (`_Templates/Architecture Overview.md`)

```markdown
---
type: spec
category: architecture
status: canonical
version: 0.1
---

# Architecture Overview – SwiftUI + MVVM

## Architectural Style
- SwiftUI for views
- MVVM for state and business logic
- Repositories for persistence
- Services for integrations (PDFKit, Drive API)

## Modules
- LibraryModule
- BookModule
- PageModule
- ZoomWindowModule
- ExportImportModule
- CloudBackupModule

## Data Model
- Entities: Folder, Book, Page, Template, StrokeLayer
- Relationships and invariants

## Integration Points
- PencilKit (PKCanvasView via UIViewRepresentable)
- PDFKit (PDFDocument/PDFPage)
- Google Drive REST API

## Change Log
- ...
```


### 4. Feature Spec template (`_Templates/Feature Spec.md`)

```markdown
---
type: feature
status: ideation
area: implementation
up: [[Implementation Hub]]
---

# Feature – Zoom Window & Auto-Advance

## Problem
Describe the user problem and rationale.

## Requirements
- Zoom pane with magnified writing area.
- Auto-advance horizontally when writing in the edge zone.
- “Return height” move to next line.
- On/off toggle per document.

## UX & Interactions
- Entry/exit points.
- Controls and visual cues.

## Technical Design
- ViewModel responsibilities.
- Canvas & viewport math.
- State transitions.

## Risks
- Performance issues.
- User confusion.

## Change Log
- ...
```


### 5. Research Note template (`_Templates/Research Note.md`)

```markdown
---
type: research
topic: PencilKit
source-type: docs+articles
status: ongoing
---

# Research – PencilKit in SwiftUI

## Question
What is the best way to integrate PencilKit with SwiftUI for low-latency inking?

## Findings
- UIViewRepresentable wrapper for PKCanvasView.
- Use Coordinator for PKCanvasViewDelegate.
- Manage PKDrawing in ViewModel.

## References
- [Link 1]()
- [Link 2]()

## Implications for Project
- ...

## Next Steps
- Prototype canvas wrapper.
- Evaluate performance.
```


### 6. Meeting template (`_Templates/Meeting.md`)

Based on common project templates for Obsidian project management.[^17][^5][^6]

```markdown
---
type: meeting
project: PageBound Notes
date: {{date}}
participants: [Arnav, ...]
up: [[Project Hub – PageBound Notes]]
---

# Meeting – {{date}} – Topic

## Agenda
- ...

## Notes
- ...

## Decisions
- ...

## Action Items
- [ ] Task one
- [ ] Task two
```


### 7. Decision / ADR template (`_Templates/ADR.md`)

```markdown
---
type: decision
status: accepted
up: [[Architecture Overview – SwiftUI + MVVM]]
---

# ADR – Choose Core Data for Persistence

## Context
Describe the situation and constraints.

## Decision
We choose Core Data (or SwiftData) for local persistence of folders/books/pages.

## Consequences
- Pros: ...
- Cons: ...

## Related
- [[data-model-overview]]
- [[research-core-data-vs-swiftdata]]
```


### 8. Daily Log / Work Session template (`_Templates/Daily.md`)

```markdown
---
type: daily
date: {{date}}
project: PageBound Notes
---

# Daily Log – {{date}}

## Focus
- ...

## Work Sessions
- WS1 – [[Feature – Zoom Window & Auto-Advance]]
- WS2 – [[Research – PencilKit in SwiftUI]]

## Notes
- ...

## Next Day
- ...
```


***

## How someone navigates and maintains the vault

- New contributors start at `Project Hub – PageBound Notes` in `00_Hub/`, which links to product, architecture, implementation, operations, and research hubs.
- From a hub, they drill down into feature specs, architecture notes, or research notes via well‑named links instead of hunting through folders.[^4][^9][^2]
- To update the KB, they:
    - Use the appropriate template for any new note (feature, research, meeting, ADR, daily).
    - Update canonical spec/architecture notes when making substantive changes.
    - Log decisions as ADRs and link them from affected specs and hubs.
    - Archive old material into `90_Archive/` using version and status fields rather than deleting.

With this structure, templates, and update workflow, an Obsidian vault for the PageBound Notes project stays legible, navigable, and maintainable over the full lifecycle of the app.[^8][^1][^3]
<span style="display:none">[^18][^19][^20]</span>

<div align="center">⁂</div>

[^1]: https://www.aitechworlds.com/category/software-reviews/productivity-tools/obsidian-knowledge-management-guide

[^2]: https://www.natecue.com/en/learn/productivity/map-of-content/

[^3]: https://github.com/berteaux/obsidian-vault-template

[^4]: https://pjordan.substack.com/p/new-obsidian-setup-using-hub-notes

[^5]: https://vaultorial.com/project-management-template/

[^6]: https://constructbydee.substack.com/p/the-project-templates-i-use-in-obsidian

[^7]: https://github.com/Ashkaar-gh/obsidian-project-automation

[^8]: https://ubos.tech/news/mastering-obsidian-vaults-a-comprehensive-guide-to-organizing-your-digital-knowledge/

[^9]: https://publish.obsidian.md/aidanhelfant/Spaces/🪐Content+Creation/📸YouTube+Videos/How+I+Organize+Obsidian+with+Maps+of+Content+(MOCs)

[^10]: https://medium.com/@shehab2003magdy/how-to-create-your-own-knowledge-base-with-obsidian-cc16e2e206f5

[^11]: https://swiftprogramming.com/pencilkit-swiftui/

[^12]: https://nicoladefilippo.com/pencilkit-in-swiftui/

[^13]: https://zthh.dev/blogs/swiftui-mvvm-best-practices-tips-techniques

[^14]: https://medium.com/@chavdajinali/building-a-swiftui-app-with-mvvm-a-practical-guide-5eccbceb83cb

[^15]: https://fera-tech.com/blog/swiftui-mvvm-architecture/

[^16]: https://medium.com/@petermilovcik/note-taking-strategies-in-obsidian-permanent-vs-fleeting-notes-dd5be202d381

[^17]: https://publish.obsidian.md/eriktuck/base/Project+Management/project+management

[^18]: https://bryanhogan.com/blog/obsidian-vault

[^19]: https://www.youtube.com/watch?v=KK4e1puhaEw

[^20]: https://www.youtube.com/watch?v=vAwS-js2iB0

