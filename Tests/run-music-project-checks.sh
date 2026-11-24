#!/bin/sh
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
check_dir=$(mktemp -d /tmp/visusig-project-checks.XXXXXX)
trap 'rm -rf "$check_dir"' EXIT
cp -R "$repo_dir/VisuSig" "$check_dir/VisuSig"
cp -R "$repo_dir/VisuSig.xcodeproj" "$check_dir/VisuSig.xcodeproj"
cp "$repo_dir/Tests/MusicProjectChecks.swift" "$check_dir/VisuSig/VisuSigApp.swift"
python3 - "$check_dir/VisuSig.xcodeproj/project.pbxproj" "$repo_dir/../../Packages/VisualMesh" <<'PYTHON'
from pathlib import Path
import sys
project = Path(sys.argv[1])
package = Path(sys.argv[2]).resolve()
project.write_text(project.read_text().replace(
    'relativePath = "../../Packages/VisualMesh";',
    'relativePath = "' + str(package) + '";'
))
PYTHON
if ! xcodebuild -project "$check_dir/VisuSig.xcodeproj" -scheme VisuSig \
    -configuration Debug -destination 'platform=macOS,arch=arm64' \
    -derivedDataPath "$check_dir/DerivedData" build CODE_SIGNING_ALLOWED=NO \
    > "$check_dir/build.log" 2>&1; then
    cat "$check_dir/build.log"
    exit 1
fi
"$check_dir/DerivedData/Build/Products/Debug/VisuSig.app/Contents/MacOS/VisuSig"
