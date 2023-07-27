#!/bin/bash

if [ `uname -s` == Linux ]; then
    CLANGFORMAT=`which clang-format`
else
    CLANGFORMAT=`xcrun -find clang-format`
fi

if [ ! -x "${CLANGFORMAT}" ]; then
    echo "clang-format is missing. On a mac, please install it using homebrew: brew install clang-format"
    exit 1
fi

EXPECTED_CLANGFORMAT_VERSION=`cat ../../.clang-format-version`
CLANGFORMAT_VERSION=`${CLANGFORMAT} --version`

if echo $CLANGFORMAT_VERSION | grep -q -v "${EXPECTED_CLANGFORMAT_VERSION}"; then
    echo "clang-format version mismatch. expected ${EXPECTED_CLANGFORMAT_VERSION}, got ${CLANGFORMAT_VERSION}"
fi

set -e
SDK_FOLDER="../../sdk"

# Format Objective-C code
find "${SDK_FOLDER}/Batch" "${SDK_FOLDER}/batchTests" -type f -name "*.[mh]" -not \( -path "${SDK_FOLDER}/Batch/Versions.h" \) -print0 | xargs -0 ${CLANGFORMAT} --dry-run --Werror -i

# Format Swift code
swift run -c release swiftformat --lint "${SDK_FOLDER}/Batch" "${SDK_FOLDER}/batchTests"
