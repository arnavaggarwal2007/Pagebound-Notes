Running tests...
Update the Info.plist: Launch screens will soon be required.
    t =      nans Interface orientation changed to Portrait
Test Suite 'All tests' started at 2026-07-21 13:59:01.127.
Test Suite 'PageBoundNotesUITests.xctest' started at 2026-07-21 13:59:01.128.
Test Suite 'LibraryNavigationUITests' started at 2026-07-21 13:59:01.128.
Test Case '-[PageBoundNotesUITests.LibraryNavigationUITests testCreateFolderShowsEmptyFolderState]' started.
    t =     0.08s Start Test at 2026-07-21 13:59:01.205
    t =     0.46s Set Up
    t =     0.66s     Open com.pagebound.notes
    t =     0.71s         Launch com.pagebound.notes
    t =     2.28s             Setting up automation session
    t =     3.67s             Wait for com.pagebound.notes to idle
    t =     5.13s Waiting 5.0s for "sidebar-add-menu" Button to exist
    t =     6.13s     Checking `Expect predicate `existsNoRetry == 1` for object "sidebar-add-menu" Button`
    t =     6.14s         Checking existence of `"sidebar-add-menu" Button`
    t =     9.14s Find the "sidebar-add-menu" Button
    t =     9.28s Tap "sidebar-add-menu" Button
    t =     9.28s     Wait for com.pagebound.notes to idle
    t =     9.28s     Find the "sidebar-add-menu" Button
    t =     9.77s     Check for interrupting elements affecting "sidebar-add-menu" Button
    t =     9.90s     Synthesize event
    t =    10.29s     Wait for com.pagebound.notes to idle
    t =    11.35s Waiting 3.0s for "add-menu-new-folder" Button to exist
    t =    12.35s     Checking `Expect predicate `existsNoRetry == 1` for object "add-menu-new-folder" Button`
    t =    12.35s         Checking existence of `"add-menu-new-folder" Button`
    t =    12.49s Tap "add-menu-new-folder" Button
    t =    12.49s     Wait for com.pagebound.notes to idle
    t =    12.50s     Find the "add-menu-new-folder" Button
    t =    12.70s     Check for interrupting elements affecting "add-menu-new-folder" Button
    t =    12.83s     Synthesize event
    t =    13.14s     Wait for com.pagebound.notes to idle
    t =    14.58s Waiting 3.0s for "Folder Name" TextField to exist
    t =    15.59s     Checking `Expect predicate `existsNoRetry == 1` for object "Folder Name" TextField`
    t =    15.59s         Checking existence of `"Folder Name" TextField`
    t =    15.76s Tap "Folder Name" TextField
    t =    15.77s     Wait for com.pagebound.notes to idle
    t =    15.78s     Find the "Folder Name" TextField
    t =    15.88s     Check for interrupting elements affecting "Folder Name" TextField
    t =    15.99s     Synthesize event
    t =    16.31s     Wait for com.pagebound.notes to idle
    t =    17.47s Type 'School' into "Folder Name" TextField
    t =    17.47s     Wait for com.pagebound.notes to idle
    t =    17.64s     Find the "Folder Name" TextField
    t =    17.81s     Check for interrupting elements affecting "Folder Name" TextField
    t =    18.17s     Synthesize event
    t =    18.49s     Wait for com.pagebound.notes to idle
    t =    18.50s Tap "Create" Button
    t =    18.50s     Wait for com.pagebound.notes to idle
    t =    18.51s     Find the "Create" Button
    t =    18.68s     Check for interrupting elements affecting "Create" Button
    t =    18.81s     Synthesize event
    t =    19.14s     Wait for com.pagebound.notes to idle
    t =    19.85s Waiting 3.0s for "Folder Name" TextField to exist
    t =    20.87s     Checking `Expect predicate `existsNoRetry == 1` for object "Folder Name" TextField`
    t =    20.87s         Checking existence of `"Folder Name" TextField`
/Users/arnev/Desktop/Pagebound-Notes/PageBoundNotesUITests/LibraryNavigationUITests.swift:110: error: -[PageBoundNotesUITests.LibraryNavigationUITests testCreateFolderShowsEmptyFolderState] : XCTAssertFalse failed
    t =    21.22s Tear Down
Test Case '-[PageBoundNotesUITests.LibraryNavigationUITests testCreateFolderShowsEmptyFolderState]' failed (21.415 seconds).
Test Case '-[PageBoundNotesUITests.LibraryNavigationUITests testOpenBookShowsWritingSurface]' started.
    t =     0.00s Start Test at 2026-07-21 13:59:22.624
    t =     0.03s Set Up
    t =     0.04s     Open com.pagebound.notes
    t =     0.04s         Launch com.pagebound.notes
    t =     0.04s             Terminate com.pagebound.notes:5953
    t =     2.56s             Setting up automation session
    t =     4.36s             Wait for com.pagebound.notes to idle
    t =     5.72s Waiting 5.0s for "sidebar-add-menu" Button to exist
    t =     6.75s     Checking `Expect predicate `existsNoRetry == 1` for object "sidebar-add-menu" Button`
    t =     6.75s         Checking existence of `"sidebar-add-menu" Button`
    t =     9.99s Find the "sidebar-add-menu" Button
    t =    10.54s Tap "sidebar-add-menu" Button
    t =    10.54s     Wait for com.pagebound.notes to idle
    t =    10.63s     Find the "sidebar-add-menu" Button
    t =    10.76s     Check for interrupting elements affecting "sidebar-add-menu" Button
    t =    10.84s     Synthesize event
    t =    11.17s     Wait for com.pagebound.notes to idle
    t =    12.25s Waiting 3.0s for "add-menu-new-folder" Button to exist
    t =    13.26s     Checking `Expect predicate `existsNoRetry == 1` for object "add-menu-new-folder" Button`
    t =    13.26s         Checking existence of `"add-menu-new-folder" Button`
    t =    13.41s Tap "add-menu-new-folder" Button
    t =    13.41s     Wait for com.pagebound.notes to idle
    t =    13.42s     Find the "add-menu-new-folder" Button
    t =    13.50s     Check for interrupting elements affecting "add-menu-new-folder" Button
    t =    13.60s     Synthesize event
    t =    13.91s     Wait for com.pagebound.notes to idle
    t =    15.33s Waiting 3.0s for "Folder Name" TextField to exist
    t =    16.35s     Checking `Expect predicate `existsNoRetry == 1` for object "Folder Name" TextField`
    t =    16.35s         Checking existence of `"Folder Name" TextField`
    t =    16.53s Tap "Folder Name" TextField
    t =    16.53s     Wait for com.pagebound.notes to idle
    t =    16.53s     Find the "Folder Name" TextField
    t =    16.64s     Check for interrupting elements affecting "Folder Name" TextField
    t =    16.75s     Synthesize event
    t =    17.06s     Wait for com.pagebound.notes to idle
    t =    18.13s Type 'Science' into "Folder Name" TextField
    t =    18.13s     Wait for com.pagebound.notes to idle
    t =    18.14s     Find the "Folder Name" TextField
    t =    18.29s     Check for interrupting elements affecting "Folder Name" TextField
    t =    18.48s     Synthesize event
    t =    18.95s     Wait for com.pagebound.notes to idle
    t =    18.96s Tap "Create" Button
    t =    18.96s     Wait for com.pagebound.notes to idle
    t =    18.97s     Find the "Create" Button
    t =    19.14s     Check for interrupting elements affecting "Create" Button
    t =    19.28s     Synthesize event
    t =    19.60s     Wait for com.pagebound.notes to idle
    t =    20.28s Waiting 3.0s for "Folder Name" TextField to exist
    t =    21.29s     Checking `Expect predicate `existsNoRetry == 1` for object "Folder Name" TextField`
    t =    21.29s         Checking existence of `"Folder Name" TextField`
    t =    21.39s         Capturing element debug description
    t =    22.30s     Checking `Expect predicate `existsNoRetry == 1` for object "Folder Name" TextField`
    t =    22.30s         Checking existence of `"Folder Name" TextField`
    t =    22.40s         Capturing element debug description
    t =    23.28s     Checking `Expect predicate `existsNoRetry == 1` for object "Folder Name" TextField`
    t =    23.28s         Checking existence of `"Folder Name" TextField`
    t =    23.38s         Capturing element debug description
    t =    23.39s     Checking existence of `"Folder Name" TextField`
    t =    23.44s Collecting debug information to assist test failure triage
    t =    23.45s     Requesting snapshot of accessibility hierarchy for app with pid 5966
    t =    23.56s Waiting 5.0s for "Empty Folder" StaticText to exist
    t =    24.57s     Checking `Expect predicate `existsNoRetry == 1` for object "Empty Folder" StaticText`
    t =    24.57s         Checking existence of `"Empty Folder" StaticText`
    t =    24.68s Waiting 5.0s for "Empty Folder" StaticText to exist
    t =    25.69s     Checking `Expect predicate `existsNoRetry == 1` for object "Empty Folder" StaticText`
    t =    25.69s         Checking existence of `"Empty Folder" StaticText`
    t =    25.80s Waiting 1.0s for Sheet (First Match) to exist
    t =    26.80s     Checking `Expect predicate `existsNoRetry == 1` for object Sheet (First Match)`
    t =    26.81s         Checking existence of `Sheet (First Match)`
    t =    26.90s         Capturing element debug description
    t =    26.91s     Checking existence of `Sheet (First Match)`
    t =    26.95s Collecting debug information to assist test failure triage
    t =    26.95s     Requesting snapshot of accessibility hierarchy for app with pid 5966
    t =    27.06s Waiting 1.0s for "book-create-sheet" Other to exist
    t =    28.07s     Checking `Expect predicate `existsNoRetry == 1` for object "book-create-sheet" Other`
    t =    28.07s         Checking existence of `"book-create-sheet" Other`
    t =    28.17s         Capturing element debug description
    t =    28.18s     Checking existence of `"book-create-sheet" Other`
    t =    28.23s Collecting debug information to assist test failure triage
    t =    28.23s     Requesting snapshot of accessibility hierarchy for app with pid 5966
    t =    28.35s Waiting 1.0s for Popover (First Match) to exist
    t =    29.35s     Checking `Expect predicate `existsNoRetry == 1` for object Popover (First Match)`
    t =    29.35s         Checking existence of `Popover (First Match)`
    t =    29.44s         Capturing element debug description
    t =    29.45s     Checking existence of `Popover (First Match)`
    t =    29.49s Collecting debug information to assist test failure triage
    t =    29.49s     Requesting snapshot of accessibility hierarchy for app with pid 5966
    t =    29.61s Checking existence of `Sheet (First Match)`
    t =    29.65s Checking existence of `"book-title-field" TextField`
    t =    29.69s Waiting 1.0s for "Title" TextField to exist
    t =    30.70s     Checking `Expect predicate `existsNoRetry == 1` for object "Title" TextField`
    t =    30.70s         Checking existence of `"Title" TextField`
    t =    30.81s         Capturing element debug description
    t =    30.81s     Checking existence of `"Title" TextField`
    t =    30.86s Collecting debug information to assist test failure triage
    t =    30.87s     Requesting snapshot of accessibility hierarchy for app with pid 5966
    t =    30.98s Waiting 1.0s for "New Book" NavigationBar to exist
    t =    31.99s     Checking `Expect predicate `existsNoRetry == 1` for object "New Book" NavigationBar`
    t =    31.99s         Checking existence of `"New Book" NavigationBar`
    t =    32.09s         Capturing element debug description
    t =    32.10s     Checking existence of `"New Book" NavigationBar`
    t =    32.15s Collecting debug information to assist test failure triage
    t =    32.15s     Requesting snapshot of accessibility hierarchy for app with pid 5966
    t =    32.27s Waiting 3.0s for "empty-folder-new-book" Button to exist
    t =    33.28s     Checking `Expect predicate `existsNoRetry == 1` for object "empty-folder-new-book" Button`
    t =    33.28s         Checking existence of `"empty-folder-new-book" Button`
    t =    33.39s Waiting 5.0s for "empty-folder-new-book" Button to exist
    t =    34.40s     Checking `Expect predicate `existsNoRetry == 1` for object "empty-folder-new-book" Button`
    t =    34.41s         Checking existence of `"empty-folder-new-book" Button`
    t =    34.52s Find the "empty-folder-new-book" Button
    t =    34.61s Tap "empty-folder-new-book" Button
    t =    34.61s     Wait for com.pagebound.notes to idle
    t =    34.62s     Find the "empty-folder-new-book" Button
    t =    34.67s     Check for interrupting elements affecting "empty-folder-new-book" Button
    t =    34.72s     Synthesize event
    t =    35.02s     Wait for com.pagebound.notes to idle
    t =    35.49s Waiting 3.0s for Sheet (First Match) to exist
    t =    36.50s     Checking `Expect predicate `existsNoRetry == 1` for object Sheet (First Match)`
    t =    36.50s         Checking existence of `Sheet (First Match)`
    t =    36.65s         Capturing element debug description
    t =    37.55s     Checking `Expect predicate `existsNoRetry == 1` for object Sheet (First Match)`
    t =    37.55s         Checking existence of `Sheet (First Match)`
    t =    37.67s         Capturing element debug description
    t =    38.49s     Checking `Expect predicate `existsNoRetry == 1` for object Sheet (First Match)`
    t =    38.50s         Checking existence of `Sheet (First Match)`
    t =    38.62s         Capturing element debug description
    t =    38.62s     Checking existence of `Sheet (First Match)`
    t =    38.70s Collecting debug information to assist test failure triage
    t =    38.70s     Requesting snapshot of accessibility hierarchy for app with pid 5966
    t =    38.91s Waiting 3.0s for "book-create-sheet" Other to exist
    t =    39.91s     Checking `Expect predicate `existsNoRetry == 1` for object "book-create-sheet" Other`
    t =    39.91s         Checking existence of `"book-create-sheet" Other`
    t =    40.06s Checking existence of `Sheet (First Match)`
    t =    40.14s Checking existence of `"book-title-field" TextField`
    t =    40.23s Waiting 8.0s for "book-title-field" TextField to exist
    t =    41.23s     Checking `Expect predicate `existsNoRetry == 1` for object "book-title-field" TextField`
    t =    41.23s         Checking existence of `"book-title-field" TextField`
    t =    41.38s Checking existence of `Sheet (First Match)`
    t =    41.45s Checking existence of `"book-title-field" TextField`
    t =    41.54s Waiting 8.0s for "book-title-field" TextField to exist
    t =    42.56s     Checking `Expect predicate `existsNoRetry == 1` for object "book-title-field" TextField`
    t =    42.56s         Checking existence of `"book-title-field" TextField`
    t =    42.71s Tap "book-title-field" TextField
    t =    42.71s     Wait for com.pagebound.notes to idle
    t =    42.72s     Find the "book-title-field" TextField
    t =    42.82s     Check for interrupting elements affecting "book-title-field" TextField
    t =    42.93s     Synthesize event
    t =    43.39s     Wait for com.pagebound.notes to idle
    t =    44.15s Type 'Math' into "book-title-field" TextField
    t =    44.15s     Wait for com.pagebound.notes to idle
    t =    44.16s     Find the "book-title-field" TextField
    t =    44.32s     Check for interrupting elements affecting "book-title-field" TextField
    t =    44.44s     Synthesize event
    t =    44.75s     Wait for com.pagebound.notes to idle
    t =    44.77s Checking existence of `Sheet (First Match)`
    t =    44.90s Checking existence of `"book-create-confirm" Button`
    t =    45.02s Waiting 5.0s for "book-create-confirm" Button to exist
    t =    46.02s     Checking `Expect predicate `existsNoRetry == 1` for object "book-create-confirm" Button`
    t =    46.02s         Checking existence of `"book-create-confirm" Button`
    t =    46.19s Find the "book-create-confirm" Button
    t =    46.36s Tap "book-create-confirm" Button
    t =    46.36s     Wait for com.pagebound.notes to idle
    t =    46.36s     Find the "book-create-confirm" Button
    t =    46.48s     Check for interrupting elements affecting "book-create-confirm" Button
    t =    46.60s     Synthesize event
    t =    46.94s     Wait for com.pagebound.notes to idle
    t =    47.60s Waiting 5.0s for "book-card-Math" Button to exist
    t =    48.64s     Checking `Expect predicate `existsNoRetry == 1` for object "book-card-Math" Button`
    t =    48.64s         Checking existence of `"book-card-Math" Button`
    t =    48.75s Waiting 5.0s for "book-card-Math" Button to exist
    t =    49.77s     Checking `Expect predicate `existsNoRetry == 1` for object "book-card-Math" Button`
    t =    49.77s         Checking existence of `"book-card-Math" Button`
    t =    49.87s Find the "book-card-Math" Button
    t =    49.97s Tap "book-card-Math" Button
    t =    49.97s     Wait for com.pagebound.notes to idle
    t =    49.97s     Find the "book-card-Math" Button
    t =    50.02s     Check for interrupting elements affecting "book-card-Math" Button
    t =    50.08s     Synthesize event
    t =    50.41s     Wait for com.pagebound.notes to idle
    t =    50.49s Waiting 5.0s for "tool-pen" Button to exist
    t =    51.52s     Checking `Expect predicate `existsNoRetry == 1` for object "tool-pen" Button`
    t =    51.52s         Checking existence of `"tool-pen" Button`
    t =    51.65s Waiting 3.0s for "Math" NavigationBar to exist
    t =    52.70s     Checking `Expect predicate `existsNoRetry == 1` for object "Math" NavigationBar`
    t =    52.70s         Checking existence of `"Math" NavigationBar`
    t =    52.83s Tear Down
Test Case '-[PageBoundNotesUITests.LibraryNavigationUITests testOpenBookShowsWritingSurface]' passed (53.135 seconds).
Test Case '-[PageBoundNotesUITests.LibraryNavigationUITests testSelectFolderEnablesBookCreationFlow]' started.
    t =     0.00s Start Test at 2026-07-21 14:00:15.762
    t =     0.03s Set Up
    t =     0.04s     Open com.pagebound.notes
    t =     0.04s         Launch com.pagebound.notes
    t =     0.04s             Terminate com.pagebound.notes:5966
    t =     2.50s             Setting up automation session
    t =     4.25s             Wait for com.pagebound.notes to idle
    t =     5.65s Waiting 5.0s for "sidebar-add-menu" Button to exist
    t =     6.67s     Checking `Expect predicate `existsNoRetry == 1` for object "sidebar-add-menu" Button`
    t =     6.68s         Checking existence of `"sidebar-add-menu" Button`
    t =    10.21s Find the "sidebar-add-menu" Button
    t =    10.34s Tap "sidebar-add-menu" Button
    t =    10.34s     Wait for com.pagebound.notes to idle
    t =    10.34s     Find the "sidebar-add-menu" Button
    t =    10.87s     Check for interrupting elements affecting "sidebar-add-menu" Button
    t =    10.98s     Synthesize event
    t =    11.31s     Wait for com.pagebound.notes to idle
    t =    12.41s Waiting 3.0s for "add-menu-new-folder" Button to exist
    t =    13.41s     Checking `Expect predicate `existsNoRetry == 1` for object "add-menu-new-folder" Button`
    t =    13.42s         Checking existence of `"add-menu-new-folder" Button`
    t =    13.55s Tap "add-menu-new-folder" Button
    t =    13.55s     Wait for com.pagebound.notes to idle
    t =    13.56s     Find the "add-menu-new-folder" Button
    t =    13.65s     Check for interrupting elements affecting "add-menu-new-folder" Button
    t =    13.74s     Synthesize event
    t =    14.05s     Wait for com.pagebound.notes to idle
    t =    15.47s Waiting 3.0s for "Folder Name" TextField to exist
    t =    16.48s     Checking `Expect predicate `existsNoRetry == 1` for object "Folder Name" TextField`
    t =    16.49s         Checking existence of `"Folder Name" TextField`
    t =    16.65s Tap "Folder Name" TextField
    t =    16.65s     Wait for com.pagebound.notes to idle
    t =    16.66s     Find the "Folder Name" TextField
    t =    16.77s     Check for interrupting elements affecting "Folder Name" TextField
    t =    16.88s     Synthesize event
    t =    17.18s     Wait for com.pagebound.notes to idle
    t =    18.27s Type 'Science' into "Folder Name" TextField
    t =    18.27s     Wait for com.pagebound.notes to idle
    t =    18.28s     Find the "Folder Name" TextField
    t =    18.44s     Check for interrupting elements affecting "Folder Name" TextField
    t =    18.65s     Synthesize event
    t =    19.08s     Wait for com.pagebound.notes to idle
    t =    19.10s Tap "Create" Button
    t =    19.10s     Wait for com.pagebound.notes to idle
    t =    19.10s     Find the "Create" Button
    t =    19.28s     Check for interrupting elements affecting "Create" Button
    t =    19.41s     Synthesize event
    t =    19.85s     Wait for com.pagebound.notes to idle
    t =    20.52s Waiting 3.0s for "Folder Name" TextField to exist
    t =    21.52s     Checking `Expect predicate `existsNoRetry == 1` for object "Folder Name" TextField`
    t =    21.53s         Checking existence of `"Folder Name" TextField`
    t =    21.63s         Capturing element debug description
    t =    22.54s     Checking `Expect predicate `existsNoRetry == 1` for object "Folder Name" TextField`
    t =    22.54s         Checking existence of `"Folder Name" TextField`
    t =    22.64s         Capturing element debug description
    t =    23.52s     Checking `Expect predicate `existsNoRetry == 1` for object "Folder Name" TextField`
    t =    23.52s         Checking existence of `"Folder Name" TextField`
    t =    23.62s         Capturing element debug description
    t =    23.63s     Checking existence of `"Folder Name" TextField`
    t =    23.68s Collecting debug information to assist test failure triage
    t =    23.68s     Requesting snapshot of accessibility hierarchy for app with pid 5973
    t =    23.80s Waiting 5.0s for "Empty Folder" StaticText to exist
    t =    24.82s     Checking `Expect predicate `existsNoRetry == 1` for object "Empty Folder" StaticText`
    t =    24.83s         Checking existence of `"Empty Folder" StaticText`
    t =    24.93s Waiting 5.0s for "Empty Folder" StaticText to exist
    t =    25.95s     Checking `Expect predicate `existsNoRetry == 1` for object "Empty Folder" StaticText`
    t =    25.95s         Checking existence of `"Empty Folder" StaticText`
    t =    26.05s Waiting 1.0s for Sheet (First Match) to exist
    t =    27.05s     Checking `Expect predicate `existsNoRetry == 1` for object Sheet (First Match)`
    t =    27.05s         Checking existence of `Sheet (First Match)`
    t =    27.14s         Capturing element debug description
    t =    27.15s     Checking existence of `Sheet (First Match)`
    t =    27.20s Collecting debug information to assist test failure triage
    t =    27.20s     Requesting snapshot of accessibility hierarchy for app with pid 5973
    t =    27.31s Waiting 1.0s for "book-create-sheet" Other to exist
    t =    28.32s     Checking `Expect predicate `existsNoRetry == 1` for object "book-create-sheet" Other`
    t =    28.32s         Checking existence of `"book-create-sheet" Other`
    t =    28.42s         Capturing element debug description
    t =    28.43s     Checking existence of `"book-create-sheet" Other`
    t =    28.48s Collecting debug information to assist test failure triage
    t =    28.48s     Requesting snapshot of accessibility hierarchy for app with pid 5973
    t =    28.60s Waiting 1.0s for Popover (First Match) to exist
    t =    29.60s     Checking `Expect predicate `existsNoRetry == 1` for object Popover (First Match)`
    t =    29.60s         Checking existence of `Popover (First Match)`
    t =    29.69s         Capturing element debug description
    t =    29.70s     Checking existence of `Popover (First Match)`
    t =    29.74s Collecting debug information to assist test failure triage
    t =    29.75s     Requesting snapshot of accessibility hierarchy for app with pid 5973
    t =    29.86s Checking existence of `Sheet (First Match)`
    t =    29.90s Checking existence of `"book-title-field" TextField`
    t =    29.95s Waiting 1.0s for "Title" TextField to exist
    t =    30.95s     Checking `Expect predicate `existsNoRetry == 1` for object "Title" TextField`
    t =    30.96s         Checking existence of `"Title" TextField`
    t =    31.06s         Capturing element debug description
    t =    31.06s     Checking existence of `"Title" TextField`
    t =    31.11s Collecting debug information to assist test failure triage
    t =    31.12s     Requesting snapshot of accessibility hierarchy for app with pid 5973
    t =    31.23s Waiting 1.0s for "New Book" NavigationBar to exist
    t =    32.24s     Checking `Expect predicate `existsNoRetry == 1` for object "New Book" NavigationBar`
    t =    32.24s         Checking existence of `"New Book" NavigationBar`
    t =    32.34s         Capturing element debug description
    t =    32.34s     Checking existence of `"New Book" NavigationBar`
    t =    32.39s Collecting debug information to assist test failure triage
    t =    32.40s     Requesting snapshot of accessibility hierarchy for app with pid 5973
    t =    32.51s Waiting 3.0s for "empty-folder-new-book" Button to exist
    t =    33.51s     Checking `Expect predicate `existsNoRetry == 1` for object "empty-folder-new-book" Button`
    t =    33.51s         Checking existence of `"empty-folder-new-book" Button`
    t =    33.62s Waiting 5.0s for "empty-folder-new-book" Button to exist
    t =    34.66s     Checking `Expect predicate `existsNoRetry == 1` for object "empty-folder-new-book" Button`
    t =    34.66s         Checking existence of `"empty-folder-new-book" Button`
    t =    34.77s Find the "empty-folder-new-book" Button
    t =    34.86s Tap "empty-folder-new-book" Button
    t =    34.86s     Wait for com.pagebound.notes to idle
    t =    34.86s     Find the "empty-folder-new-book" Button
    t =    34.91s     Check for interrupting elements affecting "empty-folder-new-book" Button
    t =    34.97s     Synthesize event
    t =    35.27s     Wait for com.pagebound.notes to idle
    t =    35.75s Waiting 3.0s for Sheet (First Match) to exist
    t =    36.79s     Checking `Expect predicate `existsNoRetry == 1` for object Sheet (First Match)`
    t =    36.79s         Checking existence of `Sheet (First Match)`
    t =    36.93s         Capturing element debug description
    t =    37.76s     Checking `Expect predicate `existsNoRetry == 1` for object Sheet (First Match)`
    t =    37.76s         Checking existence of `Sheet (First Match)`
    t =    37.89s         Capturing element debug description
    t =    38.75s     Checking `Expect predicate `existsNoRetry == 1` for object Sheet (First Match)`
    t =    38.75s         Checking existence of `Sheet (First Match)`
    t =    38.88s         Capturing element debug description
    t =    38.89s     Checking existence of `Sheet (First Match)`
    t =    38.97s Collecting debug information to assist test failure triage
    t =    38.97s     Requesting snapshot of accessibility hierarchy for app with pid 5973
    t =    39.19s Waiting 3.0s for "book-create-sheet" Other to exist
    t =    40.21s     Checking `Expect predicate `existsNoRetry == 1` for object "book-create-sheet" Other`
    t =    40.21s         Checking existence of `"book-create-sheet" Other`
    t =    40.36s Checking existence of `Sheet (First Match)`
    t =    40.44s Checking existence of `"book-title-field" TextField`
    t =    40.54s Waiting 8.0s for "book-title-field" TextField to exist
    t =    41.54s     Checking `Expect predicate `existsNoRetry == 1` for object "book-title-field" TextField`
    t =    41.54s         Checking existence of `"book-title-field" TextField`
    t =    41.69s Checking existence of `Sheet (First Match)`
    t =    41.77s Checking existence of `"book-title-field" TextField`
    t =    41.86s Waiting 8.0s for "book-title-field" TextField to exist
    t =    42.88s     Checking `Expect predicate `existsNoRetry == 1` for object "book-title-field" TextField`
    t =    42.88s         Checking existence of `"book-title-field" TextField`
    t =    43.03s Tap "book-title-field" TextField
    t =    43.03s     Wait for com.pagebound.notes to idle
    t =    43.04s     Find the "book-title-field" TextField
    t =    43.14s     Check for interrupting elements affecting "book-title-field" TextField
    t =    43.24s     Synthesize event
    t =    43.57s     Wait for com.pagebound.notes to idle
    t =    44.31s Type 'Biology' into "book-title-field" TextField
    t =    44.31s     Wait for com.pagebound.notes to idle
    t =    44.32s     Find the "book-title-field" TextField
    t =    44.47s     Check for interrupting elements affecting "book-title-field" TextField
    t =    44.59s     Synthesize event
    t =    44.95s     Wait for com.pagebound.notes to idle
    t =    44.97s Checking existence of `Sheet (First Match)`
    t =    45.10s Checking existence of `"book-create-confirm" Button`
    t =    45.22s Waiting 5.0s for "book-create-confirm" Button to exist
    t =    46.25s     Checking `Expect predicate `existsNoRetry == 1` for object "book-create-confirm" Button`
    t =    46.25s         Checking existence of `"book-create-confirm" Button`
    t =    46.41s Find the "book-create-confirm" Button
    t =    46.57s Tap "book-create-confirm" Button
    t =    46.57s     Wait for com.pagebound.notes to idle
    t =    46.58s     Find the "book-create-confirm" Button
    t =    46.70s     Check for interrupting elements affecting "book-create-confirm" Button
    t =    46.82s     Synthesize event
    t =    47.16s     Wait for com.pagebound.notes to idle
    t =    47.81s Waiting 5.0s for "Biology" StaticText to exist
    t =    48.84s     Checking `Expect predicate `existsNoRetry == 1` for object "Biology" StaticText`
    t =    48.85s         Checking existence of `"Biology" StaticText`
    t =    48.96s Tear Down
Test Case '-[PageBoundNotesUITests.LibraryNavigationUITests testSelectFolderEnablesBookCreationFlow]' passed (49.234 seconds).
Test Suite 'LibraryNavigationUITests' failed at 2026-07-21 14:01:04.997.
	 Executed 3 tests, with 1 failure (0 unexpected) in 123.784 (123.869) seconds
Test Suite 'PageBoundNotesUITests.xctest' failed at 2026-07-21 14:01:05.001.
	 Executed 3 tests, with 1 failure (0 unexpected) in 123.784 (123.873) seconds
Test Suite 'All tests' failed at 2026-07-21 14:01:05.004.
	 Executed 3 tests, with 1 failure (0 unexpected) in 123.784 (123.877) seconds