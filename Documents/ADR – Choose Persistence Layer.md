# ADR – Choose Persistence Layer

**Status:** Accepted  
**Date:** 2026-07-06  
**Canonical:** Yes

## Context

PageBound Notes requires structured persistence for Folder, Book, and Page entities plus file-based blob storage for strokes and assets. Phase 0 cannot complete until this decision is made.

## Options

### Option A: Core Data

- Mature, well-documented, proven external storage for binary blobs
- Works on iPadOS 16+ without restriction
- More boilerplate than SwiftData

### Option B: SwiftData

- Swift-native, tighter SwiftUI integration
- Requires iPadOS 17+ for full feature set
- Newer; fewer production battle scars

## Decision

**Accepted: SwiftData** with a persistent on-disk `ModelContainer` stored in Application Support.

**Deployment target raised to iPadOS 17+** to support SwiftData reliably. Advanced Markup tools (reed pen, etc.) remain feature-detected at runtime on newer OS versions.

Repository interfaces (`LibraryRepository`, `BookRepository`, `PageRepository`) abstract SwiftData so the persistence layer can be swapped if needed.

## Consequences

**Pros:**

- Less boilerplate than Core Data; native Swift schema with `@Model`
- Aligns with SwiftUI ecosystem and modern Apple patterns
- Repository protocols preserve testability

**Cons:**

- Excludes devices stuck on iPadOS 16
- SwiftData is newer than Core Data; migration tooling is less mature
- Large stroke blobs still require separate file-based storage (unchanged)

## Related

- [Product Spec §7 — Data Model and Persistence](Pagebound%20Notes%20Project%20Spec.md#7-data-model-and-persistence)
- [Development Roadmap — Phase 0](Development%20Roadmap.md#phase-0--foundations)

## Change Log

| Date | Change |
|------|--------|
| 2026-07-06 | Accepted SwiftData; deployment target raised to iPadOS 17+ |
