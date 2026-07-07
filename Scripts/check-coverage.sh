#!/usr/bin/env bash
set -euo pipefail

# Checks code coverage for the PageBoundNotes target after running unit tests.
# Usage: ./Scripts/check-coverage.sh [minimum_percent]
# Default minimum: 60 (testable layers — Models, Persistence, Services, ViewModels)
# SwiftUI view bodies are excluded from the gate; they are covered by UI tests.

MIN_COVERAGE="${1:-60}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="${DERIVED_DATA:-$PROJECT_DIR/build/DerivedData}"
RESULT_BUNDLE="$DERIVED_DATA/TestResults.xcresult"
SCHEME="PageBoundNotes"
DESTINATION="${DESTINATION:-platform=iOS Simulator,id=093011D7-838F-4E78-B427-112C7E6961FD}"

echo "Running tests with coverage enabled..."
rm -rf "$RESULT_BUNDLE"
xcodebuild test \
  -project "$PROJECT_DIR/PageBoundNotes.xcodeproj" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA" \
  -enableCodeCoverage YES \
  -resultBundlePath "$RESULT_BUNDLE" \
  -only-testing:PageBoundNotesTests \
  CODE_SIGNING_ALLOWED=NO

echo "Computing coverage for PageBoundNotes target..."
read -r OVERALL_COVERAGE TESTABLE_COVERAGE < <(xcrun xccov view --report --json "$RESULT_BUNDLE" \
  | python3 -c "
import json, sys

def is_swiftui_view(name: str) -> bool:
    markers = ('View.swift', 'Sheet.swift', 'CardView.swift', 'Surface.swift',
               'BackgroundView.swift', 'PaletteView.swift', 'Modifier.swift')
    return any(marker in name for marker in markers)

data = json.load(sys.stdin)
for target in data.get('targets', []):
    if target.get('name') != 'PageBoundNotes.app':
        continue
    overall = target.get('lineCoverage', 0) * 100
    executable = covered = 0
    for file_info in target.get('files', []):
        name = file_info.get('name', '')
        if is_swiftui_view(name):
            continue
        lines = file_info.get('executableLines', 0)
        line_cov = file_info.get('lineCoverage', 0)
        executable += lines
        covered += int(lines * line_cov)
    testable = (covered / executable * 100) if executable else 0.0
    print(f'{overall:.1f} {testable:.1f}')
    break
else:
    print('0.0 0.0')
")

echo "Overall line coverage: ${OVERALL_COVERAGE}%"
echo "Testable layer coverage (excludes SwiftUI views): ${TESTABLE_COVERAGE}%"
REQUIRED="$MIN_COVERAGE"

if python3 -c "import sys; sys.exit(0 if float('${TESTABLE_COVERAGE}') >= float('${REQUIRED}') else 1)"; then
  echo "Testable layer coverage meets minimum threshold of ${REQUIRED}%."
else
  echo "Testable layer coverage ${TESTABLE_COVERAGE}% is below minimum threshold of ${REQUIRED}%." >&2
  exit 1
fi
