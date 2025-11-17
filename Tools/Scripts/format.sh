#!/bin/bash
set -euo pipefail

# Simple logging helpers
log() { echo "[format] $*"; }
section() { echo; echo "==> $*"; }

# Resolve repository root from this script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SDK_FOLDER="${REPO_ROOT}/sdk"

section "Environment"
log "Repo root: ${REPO_ROOT}"
log "SDK folder: ${SDK_FOLDER}"

# Locate clang-format
if [ "$(uname -s)" = Linux ]; then
    CLANGFORMAT="$(command -v clang-format || true)"
else
    CLANGFORMAT="$(xcrun -find clang-format)"
fi

if [ -z "${CLANGFORMAT}" ] || [ ! -x "${CLANGFORMAT}" ]; then
    echo "clang-format is missing. On a Mac, install via: brew install clang-format" >&2
    exit 1
fi

EXPECTED_CLANGFORMAT_VERSION="$(cat "${REPO_ROOT}/.clang-format-version")"
CLANGFORMAT_VERSION="$(${CLANGFORMAT} --version 2>/dev/null || echo unknown)"

section "Objective-C formatting (clang-format)"
log "Expected version: ${EXPECTED_CLANGFORMAT_VERSION}"
log "Actual version:   ${CLANGFORMAT_VERSION}"
if echo "${CLANGFORMAT_VERSION}" | grep -q -v "${EXPECTED_CLANGFORMAT_VERSION}"; then
    log "Warning: clang-format version mismatch"
fi

OC_FILE_COUNT=$(find "${SDK_FOLDER}/Batch" "${SDK_FOLDER}/batchTests" -type f -name "*.[mh]" -not \( -path "${SDK_FOLDER}/Batch/Supporting Files/Versions.h" \) | wc -l | awk '{print $1}')
log "Formatting ${OC_FILE_COUNT} Objective-C files"
find "${SDK_FOLDER}/Batch" "${SDK_FOLDER}/batchTests" -type f -name "*.[mh]" -not \( -path "${SDK_FOLDER}/Batch/Supporting Files/Versions.h" \) -print0 | xargs -0 "${CLANGFORMAT}" -i
log "Objective-C formatting done"

# Locate swift-format from Swift toolchain first
if [ "$(uname -s)" = "Darwin" ]; then
    SWIFT_FORMAT_BIN="$(xcrun -find swift-format 2>/dev/null || true)"
else
    SWIFT_FORMAT_BIN="$(command -v swift-format || true)"
fi

if [ -z "${SWIFT_FORMAT_BIN}" ]; then
    # Fallback to PATH in case it's directly available
    if command -v swift-format >/dev/null 2>&1; then
        SWIFT_FORMAT_BIN="swift-format"
    fi
fi

if [ -z "${SWIFT_FORMAT_BIN}" ]; then
    echo "swift-format not found. Use a Swift toolchain that bundles it (xcrun -find swift-format), or: brew install swift-format" >&2
    echo "Alternatively, run: make format" >&2
    exit 1
fi

SWIFT_FORMAT_VERSION="$(${SWIFT_FORMAT_BIN} --version 2>/dev/null || echo unknown)"

section "Swift formatting (swift-format)"
log "swift-format: ${SWIFT_FORMAT_VERSION}"
SWIFT_FILE_COUNT=$(find "${SDK_FOLDER}" -type f -name "*.swift" | wc -l | awk '{print $1}')
log "Formatting ${SWIFT_FILE_COUNT} Swift files"
"${SWIFT_FORMAT_BIN}" --recursive --parallel --in-place "${SDK_FOLDER}"
log "Swift formatting done"

section "Summary"
log "Formatted ${OC_FILE_COUNT} Objective-C files and ${SWIFT_FILE_COUNT} Swift files"
