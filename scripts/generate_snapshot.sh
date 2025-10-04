#!/bin/bash

WORKSPACE_DIR="homete.xcodeproj"
BUILD_SCHEME="homete"
SPM_CLONE_PATH="SourcePackages"

xcodebuild -project "${WORKSPACE_DIR}" -scheme "${BUILD_SCHEME}" -configuration Debug -clonedSourcePackagesDirPath "${SPM_CLONE_PATH}" -resolvePackageDependencies

# Snapshotの生成
set -o pipefail && xcodebuild -project "${WORKSPACE_DIR}" -configuration Debug -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16 Pro' -scheme "${BUILD_SCHEME}" -testPlan snapshotTesting -clonedSourcePackagesDirPath "${SPM_CLONE_PATH}" clean test | xcbeautify