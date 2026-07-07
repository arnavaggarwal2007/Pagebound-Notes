Running tests...
Update the Info.plist: Launch screens will soon be required.
    t =      nans Interface orientation changed to Portrait
Test Suite 'All tests' started at 2026-07-07 14:46:35.890.
Test Suite 'PageBoundNotesUITests.xctest' started at 2026-07-07 14:46:35.988.
Test Suite 'LibraryNavigationUITests' started at 2026-07-07 14:46:35.990.
Test Case '-[PageBoundNotesUITests.LibraryNavigationUITests testCreateFolderShowsEmptyFolderState]' started.
    t =     0.00s Start Test at 2026-07-07 14:46:35.994
    t =     0.44s Set Up
    t =     0.65s     Open com.pagebound.notes
    t =     0.74s         Launch com.pagebound.notes
    t =     2.47s             Setting up automation session
    t =     3.96s             Wait for com.pagebound.notes to idle
    t =     5.20s Waiting 5.0s for "Add" Button to exist
    t =     6.27s     Checking `Expect predicate `existsNoRetry == 1` for object "Add" Button`
    t =     6.28s         Checking existence of `"Add" Button`
    t =     9.44s Tap "Add" Button
    t =     9.44s     Wait for com.pagebound.notes to idle
    t =     9.45s     Find the "Add" Button
    t =     9.52s     Check for interrupting elements affecting "Add" Button
    t =     9.61s     Synthesize event
    t =    10.28s     Wait for com.pagebound.notes to idle
    t =    11.38s Waiting 3.0s for "New Folder" Button to exist
    t =    12.39s     Checking `Expect predicate `existsNoRetry == 1` for object "New Folder" Button`
    t =    12.39s         Checking existence of `"New Folder" Button`
    t =    12.53s Tap "New Folder" Button
    t =    12.53s     Wait for com.pagebound.notes to idle
    t =    12.54s     Find the "New Folder" Button
    t =    12.61s     Check for interrupting elements affecting "folder.badge.plus" Button
    t =    12.69s     Synthesize event
    t =    13.00s     Wait for com.pagebound.notes to idle
    t =    14.43s Waiting 3.0s for "Folder Name" TextField to exist
    t =    15.46s     Checking `Expect predicate `existsNoRetry == 1` for object "Folder Name" TextField`
    t =    15.46s         Checking existence of `"Folder Name" TextField`
    t =    15.62s Tap "Folder Name" TextField
    t =    15.62s     Wait for com.pagebound.notes to idle
    t =    15.63s     Find the "Folder Name" TextField
    t =    15.72s     Check for interrupting elements affecting "Folder Name" TextField
    t =    15.83s     Synthesize event
    t =    16.14s     Wait for com.pagebound.notes to idle
    t =    17.33s Type 'School' into "Folder Name" TextField
    t =    17.33s     Wait for com.pagebound.notes to idle
    t =    17.34s     Find the "Folder Name" TextField
    t =    17.57s     Check for interrupting elements affecting "Folder Name" TextField
    t =    17.69s     Synthesize event
    t =    18.00s     Wait for com.pagebound.notes to idle
    t =    18.01s Tap "Create" Button
    t =    18.01s     Wait for com.pagebound.notes to idle
    t =    18.02s     Find the "Create" Button
    t =    18.14s     Check for interrupting elements affecting "Create" Button
    t =    18.26s     Synthesize event
    t =    18.59s     Wait for com.pagebound.notes to idle
    t =    19.27s Waiting 5.0s for "Empty Folder" StaticText to exist
    t =    20.29s     Checking `Expect predicate `existsNoRetry == 1` for object "Empty Folder" StaticText`
    t =    20.29s         Checking existence of `"Empty Folder" StaticText`
    t =    20.42s Waiting 3.0s for "empty-folder-new-book" Button to exist
    t =    21.43s     Checking `Expect predicate `existsNoRetry == 1` for object "empty-folder-new-book" Button`
    t =    21.43s         Checking existence of `"empty-folder-new-book" Button`
    t =    21.54s Tear Down
Test Case '-[PageBoundNotesUITests.LibraryNavigationUITests testCreateFolderShowsEmptyFolderState]' passed (21.826 seconds).
Test Case '-[PageBoundNotesUITests.LibraryNavigationUITests testDeleteFolderFromSidebarRemovesFolder]' started.
    t =     0.00s Start Test at 2026-07-07 14:46:57.824
    t =     0.03s Set Up
    t =     0.04s     Open com.pagebound.notes
    t =     0.04s         Launch com.pagebound.notes
    t =     0.04s             Terminate com.pagebound.notes:2348
    t =     2.59s             Setting up automation session
    t =     4.80s             Wait for com.pagebound.notes to idle
    t =     6.16s Waiting 5.0s for "Add" Button to exist
    t =     7.17s     Checking `Expect predicate `existsNoRetry == 1` for object "Add" Button`
    t =     7.17s         Checking existence of `"Add" Button`
    t =    10.60s Tap "Add" Button
    t =    10.60s     Wait for com.pagebound.notes to idle
    t =    10.62s     Find the "Add" Button
    t =    10.69s     Check for interrupting elements affecting "Add" Button
    t =    10.77s     Synthesize event
    t =    11.11s     Wait for com.pagebound.notes to idle
    t =    12.53s Waiting 3.0s for "New Folder" Button to exist
    t =    13.54s     Checking `Expect predicate `existsNoRetry == 1` for object "New Folder" Button`
    t =    13.55s         Checking existence of `"New Folder" Button`
    t =    13.67s Tap "New Folder" Button
    t =    13.68s     Wait for com.pagebound.notes to idle
    t =    13.69s     Find the "New Folder" Button
    t =    13.76s     Check for interrupting elements affecting "folder.badge.plus" Button
    t =    13.84s     Synthesize event
    t =    14.14s     Wait for com.pagebound.notes to idle
    t =    15.56s Waiting 3.0s for "Folder Name" TextField to exist
    t =    16.57s     Checking `Expect predicate `existsNoRetry == 1` for object "Folder Name" TextField`
    t =    16.58s         Checking existence of `"Folder Name" TextField`
    t =    16.73s Tap "Folder Name" TextField
    t =    16.73s     Wait for com.pagebound.notes to idle
    t =    16.74s     Find the "Folder Name" TextField
    t =    16.84s     Check for interrupting elements affecting "Folder Name" TextField
    t =    16.94s     Synthesize event
    t =    17.25s     Wait for com.pagebound.notes to idle
    t =    18.31s Type 'DeleteMe' into "Folder Name" TextField
    t =    18.31s     Wait for com.pagebound.notes to idle
    t =    18.39s     Find the "Folder Name" TextField
    t =    18.55s     Check for interrupting elements affecting "Folder Name" TextField
    t =    18.66s     Synthesize event
    t =    19.02s     Wait for com.pagebound.notes to idle
    t =    19.04s Tap "Create" Button
    t =    19.04s     Wait for com.pagebound.notes to idle
    t =    19.04s     Find the "Create" Button
    t =    19.17s     Check for interrupting elements affecting "Create" Button
    t =    19.30s     Synthesize event
    t =    19.62s     Wait for com.pagebound.notes to idle
    t =    20.28s Waiting 5.0s for "Empty Folder" StaticText to exist
    t =    21.31s     Checking `Expect predicate `existsNoRetry == 1` for object "Empty Folder" StaticText`
    t =    21.31s         Checking existence of `"Empty Folder" StaticText`
    t =    21.44s Checking existence of `"sidebar-folder-DeleteMe" Button`
    t =    21.50s Checking existence of `Cell (First Match)`
    t =    21.56s Waiting 5.0s for Cell (First Match) to exist
    t =    22.57s     Checking `Expect predicate `existsNoRetry == 1` for object Cell (First Match)`
    t =    22.57s         Checking existence of `Cell (First Match)`
    t =    22.67s Press Cell (First Match) for 1.0 seconds
    t =    22.67s     Wait for com.pagebound.notes to idle
    t =    22.68s     Find the Cell (First Match)
    t =    22.75s     Check for interrupting elements affecting Cell
    t =    22.83s     Synthesize event
    t =    24.10s     Wait for com.pagebound.notes to idle
    t =    24.65s Waiting 3.0s for "Delete" MenuItem to exist
    t =    25.68s     Checking `Expect predicate `existsNoRetry == 1` for object "Delete" MenuItem`
    t =    25.68s         Checking existence of `"Delete" MenuItem`
    t =    25.79s         Capturing element debug description
    t =    26.72s     Checking `Expect predicate `existsNoRetry == 1` for object "Delete" MenuItem`
    t =    26.72s         Checking existence of `"Delete" MenuItem`
    t =    26.83s         Capturing element debug description
    t =    27.65s     Checking `Expect predicate `existsNoRetry == 1` for object "Delete" MenuItem`
    t =    27.66s         Checking existence of `"Delete" MenuItem`
    t =    27.77s         Capturing element debug description
    t =    27.77s     Checking existence of `"Delete" MenuItem`
    t =    27.83s Collecting debug information to assist test failure triage
    t =    27.84s     Requesting snapshot of accessibility hierarchy for app with pid 2354
    t =    28.03s Waiting 3.0s for "Delete" Button to exist
    t =    29.04s     Checking `Expect predicate `existsNoRetry == 1` for object "Delete" Button`
    t =    29.05s         Checking existence of `"Delete" Button`
    t =    29.11s Tap "Delete" Button
    t =    29.11s     Wait for com.pagebound.notes to idle
    t =    29.12s     Find the "Delete" Button
    t =    29.15s     Check for interrupting elements affecting "trash" Button
    t =    29.26s     Synthesize event
    t =    29.60s     Wait for com.pagebound.notes to idle
    t =    30.40s Waiting 3.0s for Alert (First Match) to exist
    t =    31.41s     Checking `Expect predicate `existsNoRetry == 1` for object Alert (First Match)`
    t =    31.42s         Checking existence of `Alert (First Match)`
    t =    31.45s Tap "Delete" Button
    t =    31.45s     Wait for com.pagebound.notes to idle
    t =    31.46s     Find the "Delete" Button
    t =    31.53s     Check for interrupting elements affecting "Delete" Button
    t =    31.68s     Synthesize event
    t =    31.99s     Wait for com.pagebound.notes to idle
    t =    32.25s Waiting 2.0s for "Empty Folder" StaticText to exist
    t =    33.26s     Checking `Expect predicate `existsNoRetry == 1` for object "Empty Folder" StaticText`
    t =    33.27s         Checking existence of `"Empty Folder" StaticText`
    t =    33.38s         Capturing element debug description
    t =    34.25s     Checking `Expect predicate `existsNoRetry == 1` for object "Empty Folder" StaticText`
    t =    34.25s         Checking existence of `"Empty Folder" StaticText`
    t =    34.37s         Capturing element debug description
    t =    34.37s     Checking existence of `"Empty Folder" StaticText`
    t =    34.43s Collecting debug information to assist test failure triage
    t =    34.44s     Requesting snapshot of accessibility hierarchy for app with pid 2354
    t =    34.59s Waiting 8.0s for Cell (First Match) to exist
    t =    35.61s     Checking `Expect predicate `existsNoRetry == 1` for object Cell (First Match)`
    t =    35.61s         Checking existence of `Cell (First Match)`
    t =    35.71s         Capturing element debug description
    t =    36.64s     Checking `Expect predicate `existsNoRetry == 1` for object Cell (First Match)`
    t =    36.64s         Checking existence of `Cell (First Match)`
    t =    36.74s         Capturing element debug description
    t =    37.59s     Checking `Expect predicate `existsNoRetry == 1` for object Cell (First Match)`
    t =    37.59s         Checking existence of `Cell (First Match)`
    t =    37.69s         Capturing element debug description
    t =    38.64s     Checking `Expect predicate `existsNoRetry == 1` for object Cell (First Match)`
    t =    38.64s         Checking existence of `Cell (First Match)`
    t =    38.74s         Capturing element debug description
    t =    39.64s     Checking `Expect predicate `existsNoRetry == 1` for object Cell (First Match)`
    t =    39.64s         Checking existence of `Cell (First Match)`
    t =    39.74s         Capturing element debug description
    t =    40.62s     Checking `Expect predicate `existsNoRetry == 1` for object Cell (First Match)`
    t =    40.63s         Checking existence of `Cell (First Match)`
    t =    40.73s         Capturing element debug description
    t =    41.63s     Checking `Expect predicate `existsNoRetry == 1` for object Cell (First Match)`
    t =    41.63s         Checking existence of `Cell (First Match)`
    t =    41.73s         Capturing element debug description
    t =    42.59s     Checking `Expect predicate `existsNoRetry == 1` for object Cell (First Match)`
    t =    42.59s         Checking existence of `Cell (First Match)`
    t =    42.69s         Capturing element debug description
    t =    42.70s     Checking existence of `Cell (First Match)`
    t =    42.75s Collecting debug information to assist test failure triage
    t =    42.75s     Requesting snapshot of accessibility hierarchy for app with pid 2354
    t =    42.91s Tear Down
Test Case '-[PageBoundNotesUITests.LibraryNavigationUITests testDeleteFolderFromSidebarRemovesFolder]' passed (43.139 seconds).
Test Case '-[PageBoundNotesUITests.LibraryNavigationUITests testOpenBookShowsWritingSurface]' started.
    t =     0.00s Start Test at 2026-07-07 14:47:40.963
    t =     0.03s Set Up
    t =     0.04s     Open com.pagebound.notes
    t =     0.04s         Launch com.pagebound.notes
    t =     0.04s             Terminate com.pagebound.notes:2354
    t =     2.54s             Setting up automation session
    t =     4.74s             Wait for com.pagebound.notes to idle
    t =     6.14s Waiting 5.0s for "Add" Button to exist
    t =     7.17s     Checking `Expect predicate `existsNoRetry == 1` for object "Add" Button`
    t =     7.17s         Checking existence of `"Add" Button`
    t =    10.67s Tap "Add" Button
    t =    10.67s     Wait for com.pagebound.notes to idle
    t =    10.69s     Find the "Add" Button
    t =    10.76s     Check for interrupting elements affecting "Add" Button
    t =    10.83s     Synthesize event
    t =    11.17s     Wait for com.pagebound.notes to idle
    t =    12.52s Waiting 3.0s for "New Folder" Button to exist
    t =    13.53s     Checking `Expect predicate `existsNoRetry == 1` for object "New Folder" Button`
    t =    13.53s         Checking existence of `"New Folder" Button`
    t =    13.67s Tap "New Folder" Button
    t =    13.67s     Wait for com.pagebound.notes to idle
    t =    13.68s     Find the "New Folder" Button
    t =    13.75s     Check for interrupting elements affecting "folder.badge.plus" Button
    t =    13.83s     Synthesize event
    t =    14.15s     Wait for com.pagebound.notes to idle
    t =    15.57s Waiting 3.0s for "Folder Name" TextField to exist
    t =    16.58s     Checking `Expect predicate `existsNoRetry == 1` for object "Folder Name" TextField`
    t =    16.58s         Checking existence of `"Folder Name" TextField`
    t =    16.73s Tap "Folder Name" TextField
    t =    16.74s     Wait for com.pagebound.notes to idle
    t =    16.75s     Find the "Folder Name" TextField
    t =    16.85s     Check for interrupting elements affecting "Folder Name" TextField
    t =    16.96s     Synthesize event
    t =    17.26s     Wait for com.pagebound.notes to idle
    t =    18.37s Type 'Science' into "Folder Name" TextField
    t =    18.37s     Wait for com.pagebound.notes to idle
    t =    18.38s     Find the "Folder Name" TextField
    t =    18.54s     Check for interrupting elements affecting "Folder Name" TextField
    t =    18.66s     Synthesize event
    t =    19.13s     Wait for com.pagebound.notes to idle
    t =    19.14s Tap "Create" Button
    t =    19.14s     Wait for com.pagebound.notes to idle
    t =    19.15s     Find the "Create" Button
    t =    19.42s     Check for interrupting elements affecting "Create" Button
    t =    19.58s     Synthesize event
    t =    19.90s     Wait for com.pagebound.notes to idle
    t =    20.57s Waiting 5.0s for "Empty Folder" StaticText to exist
    t =    21.59s     Checking `Expect predicate `existsNoRetry == 1` for object "Empty Folder" StaticText`
    t =    21.60s         Checking existence of `"Empty Folder" StaticText`
    t =    21.72s Waiting 3.0s for "sidebar-folder-Science" Button to exist
    t =    22.75s     Checking `Expect predicate `existsNoRetry == 1` for object "sidebar-folder-Science" Button`
    t =    22.75s         Checking existence of `"sidebar-folder-Science" Button`
    t =    22.86s         Capturing element debug description
    t =    23.76s     Checking `Expect predicate `existsNoRetry == 1` for object "sidebar-folder-Science" Button`
    t =    23.77s         Checking existence of `"sidebar-folder-Science" Button`
    t =    23.88s         Capturing element debug description
    t =    24.73s     Checking `Expect predicate `existsNoRetry == 1` for object "sidebar-folder-Science" Button`
    t =    24.73s         Checking existence of `"sidebar-folder-Science" Button`
    t =    24.85s         Capturing element debug description
    t =    24.85s     Checking existence of `"sidebar-folder-Science" Button`
    t =    24.92s Collecting debug information to assist test failure triage
    t =    24.92s     Requesting snapshot of accessibility hierarchy for app with pid 2357
    t =    25.09s Tap "Science" StaticText
    t =    25.09s     Wait for com.pagebound.notes to idle
    t =    25.09s     Find the "Science" StaticText
    t =    25.12s     Check for interrupting elements affecting "Science" StaticText
    t =    25.19s     Synthesize event
    t =    25.25s         Scroll element to visible
    t =    25.26s         Find the "Science" StaticText
    t =    25.35s         Computed hit point {-1, -1} after scrolling to visible
    t =    25.64s     Wait for com.pagebound.notes to idle
    t =    26.36s Waiting 5.0s for "empty-folder-new-book" Button to exist
    t =    27.37s     Checking `Expect predicate `existsNoRetry == 1` for object "empty-folder-new-book" Button`
    t =    27.37s         Checking existence of `"empty-folder-new-book" Button`
    t =    27.50s Tap "empty-folder-new-book" Button
    t =    27.50s     Wait for com.pagebound.notes to idle
    t =    27.51s     Find the "empty-folder-new-book" Button
    t =    27.59s     Check for interrupting elements affecting "empty-folder-new-book" Button
    t =    27.67s     Synthesize event
    t =    27.72s         Scroll element to visible
    t =    27.72s         Find the "empty-folder-new-book" Button
    t =    27.82s         Computed hit point {-1, -1} after scrolling to visible
    t =    28.11s     Wait for com.pagebound.notes to idle
    t =    28.43s Waiting 3.0s for "Title" TextField to exist
    t =    29.46s     Checking `Expect predicate `existsNoRetry == 1` for object "Title" TextField`
    t =    29.46s         Checking existence of `"Title" TextField`
    t =    29.54s         Capturing element debug description
    t =    30.45s     Checking `Expect predicate `existsNoRetry == 1` for object "Title" TextField`
    t =    30.45s         Checking existence of `"Title" TextField`
    t =    30.53s         Capturing element debug description
    t =    31.43s     Checking `Expect predicate `existsNoRetry == 1` for object "Title" TextField`
    t =    31.44s         Checking existence of `"Title" TextField`
    t =    31.51s         Capturing element debug description
    t =    31.52s     Checking existence of `"Title" TextField`
    t =    31.56s Collecting debug information to assist test failure triage
    t =    31.57s     Requesting snapshot of accessibility hierarchy for app with pid 2357
/Users/arnev/Desktop/Pagebound-Notes/PageBoundNotesUITests/LibraryNavigationUITests.swift:78: error: -[PageBoundNotesUITests.LibraryNavigationUITests testOpenBookShowsWritingSurface] : XCTAssertTrue failed
    t =    31.87s Tear Down
Test Case '-[PageBoundNotesUITests.LibraryNavigationUITests testOpenBookShowsWritingSurface]' failed (32.157 seconds).
Test Case '-[PageBoundNotesUITests.LibraryNavigationUITests testSelectFolderEnablesBookCreationFlow]' started.
    t =     0.00s Start Test at 2026-07-07 14:48:13.125
    t =     0.04s Set Up
    t =     0.04s     Open com.pagebound.notes
    t =     0.04s         Launch com.pagebound.notes
    t =     0.04s             Terminate com.pagebound.notes:2357
    t =     2.56s             Setting up automation session
    t =     4.50s             Wait for com.pagebound.notes to idle
    t =     5.88s Waiting 5.0s for "Add" Button to exist
    t =     6.88s     Checking `Expect predicate `existsNoRetry == 1` for object "Add" Button`
    t =     6.88s         Checking existence of `"Add" Button`
    t =    10.40s Tap "Add" Button
    t =    10.40s     Wait for com.pagebound.notes to idle
    t =    10.42s     Find the "Add" Button
    t =    10.49s     Check for interrupting elements affecting "Add" Button
    t =    10.57s     Synthesize event
    t =    11.00s     Wait for com.pagebound.notes to idle
    t =    12.30s Waiting 3.0s for "New Folder" Button to exist
    t =    13.31s     Checking `Expect predicate `existsNoRetry == 1` for object "New Folder" Button`
    t =    13.31s         Checking existence of `"New Folder" Button`
    t =    13.44s Tap "New Folder" Button
    t =    13.44s     Wait for com.pagebound.notes to idle
    t =    13.45s     Find the "New Folder" Button
    t =    13.53s     Check for interrupting elements affecting "folder.badge.plus" Button
    t =    13.60s     Synthesize event
    t =    13.91s     Wait for com.pagebound.notes to idle
    t =    15.32s Waiting 3.0s for "Folder Name" TextField to exist
    t =    16.32s     Checking `Expect predicate `existsNoRetry == 1` for object "Folder Name" TextField`
    t =    16.33s         Checking existence of `"Folder Name" TextField`
    t =    16.47s Tap "Folder Name" TextField
    t =    16.48s     Wait for com.pagebound.notes to idle
    t =    16.49s     Find the "Folder Name" TextField
    t =    16.58s     Check for interrupting elements affecting "Folder Name" TextField
    t =    16.68s     Synthesize event
    t =    16.99s     Wait for com.pagebound.notes to idle
    t =    18.13s Type 'Science' into "Folder Name" TextField
    t =    18.13s     Wait for com.pagebound.notes to idle
    t =    18.14s     Find the "Folder Name" TextField
    t =    18.32s     Check for interrupting elements affecting "Folder Name" TextField
    t =    18.44s     Synthesize event
    t =    18.76s     Wait for com.pagebound.notes to idle
    t =    18.78s Tap "Create" Button
    t =    18.78s     Wait for com.pagebound.notes to idle
    t =    18.80s     Find the "Create" Button
    t =    18.95s     Check for interrupting elements affecting "Create" Button
    t =    19.07s     Synthesize event
    t =    19.40s     Wait for com.pagebound.notes to idle
    t =    20.06s Waiting 5.0s for "Empty Folder" StaticText to exist
    t =    21.06s     Checking `Expect predicate `existsNoRetry == 1` for object "Empty Folder" StaticText`
    t =    21.06s         Checking existence of `"Empty Folder" StaticText`
    t =    21.19s Waiting 3.0s for "sidebar-folder-Science" Button to exist
    t =    22.22s     Checking `Expect predicate `existsNoRetry == 1` for object "sidebar-folder-Science" Button`
    t =    22.23s         Checking existence of `"sidebar-folder-Science" Button`
    t =    22.33s         Capturing element debug description
    t =    23.23s     Checking `Expect predicate `existsNoRetry == 1` for object "sidebar-folder-Science" Button`
    t =    23.23s         Checking existence of `"sidebar-folder-Science" Button`
    t =    23.35s         Capturing element debug description
    t =    24.19s     Checking `Expect predicate `existsNoRetry == 1` for object "sidebar-folder-Science" Button`
    t =    24.19s         Checking existence of `"sidebar-folder-Science" Button`
    t =    24.31s         Capturing element debug description
    t =    24.31s     Checking existence of `"sidebar-folder-Science" Button`
    t =    24.38s Collecting debug information to assist test failure triage
    t =    24.38s     Requesting snapshot of accessibility hierarchy for app with pid 2361
    t =    24.55s Tap "Science" StaticText
    t =    24.55s     Wait for com.pagebound.notes to idle
    t =    24.55s     Find the "Science" StaticText
    t =    24.58s     Check for interrupting elements affecting "Science" StaticText
    t =    24.65s     Synthesize event
    t =    24.71s         Scroll element to visible
    t =    24.72s         Find the "Science" StaticText
    t =    24.81s         Computed hit point {-1, -1} after scrolling to visible
    t =    25.09s     Wait for com.pagebound.notes to idle
    t =    25.82s Waiting 5.0s for "Empty Folder" StaticText to exist
    t =    26.82s     Checking `Expect predicate `existsNoRetry == 1` for object "Empty Folder" StaticText`
    t =    26.82s         Checking existence of `"Empty Folder" StaticText`
    t =    26.93s Waiting 3.0s for "empty-folder-new-book" Button to exist
    t =    27.96s     Checking `Expect predicate `existsNoRetry == 1` for object "empty-folder-new-book" Button`
    t =    27.96s         Checking existence of `"empty-folder-new-book" Button`
    t =    28.08s Tap "empty-folder-new-book" Button
    t =    28.08s     Wait for com.pagebound.notes to idle
    t =    28.09s     Find the "empty-folder-new-book" Button
    t =    28.17s     Check for interrupting elements affecting "empty-folder-new-book" Button
    t =    28.25s     Synthesize event
    t =    28.30s         Scroll element to visible
    t =    28.30s         Find the "empty-folder-new-book" Button
    t =    28.41s         Computed hit point {-1, -1} after scrolling to visible
    t =    28.71s     Wait for com.pagebound.notes to idle
    t =    29.04s Waiting 3.0s for "Title" TextField to exist
    t =    30.05s     Checking `Expect predicate `existsNoRetry == 1` for object "Title" TextField`
    t =    30.05s         Checking existence of `"Title" TextField`
    t =    30.13s         Capturing element debug description
    t =    31.06s     Checking `Expect predicate `existsNoRetry == 1` for object "Title" TextField`
    t =    31.06s         Checking existence of `"Title" TextField`
    t =    31.13s         Capturing element debug description
    t =    32.04s     Checking `Expect predicate `existsNoRetry == 1` for object "Title" TextField`
    t =    32.04s         Checking existence of `"Title" TextField`
    t =    32.12s         Capturing element debug description
    t =    32.13s     Checking existence of `"Title" TextField`
    t =    32.17s Collecting debug information to assist test failure triage
    t =    32.18s     Requesting snapshot of accessibility hierarchy for app with pid 2361
/Users/arnev/Desktop/Pagebound-Notes/PageBoundNotesUITests/LibraryNavigationUITests.swift:54: error: -[PageBoundNotesUITests.LibraryNavigationUITests testSelectFolderEnablesBookCreationFlow] : XCTAssertTrue failed
    t =    32.25s Tear Down
Test Case '-[PageBoundNotesUITests.LibraryNavigationUITests testSelectFolderEnablesBookCreationFlow]' failed (32.510 seconds).
Test Suite 'LibraryNavigationUITests' failed at 2026-07-07 14:48:45.634.
	 Executed 4 tests, with 2 failures (0 unexpected) in 129.632 (129.644) seconds
Test Suite 'PageBoundNotesUITests.xctest' failed at 2026-07-07 14:48:45.638.
	 Executed 4 tests, with 2 failures (0 unexpected) in 129.632 (129.649) seconds
Test Suite 'All tests' failed at 2026-07-07 14:48:45.640.
	 Executed 4 tests, with 2 failures (0 unexpected) in 129.632 (129.750) seconds