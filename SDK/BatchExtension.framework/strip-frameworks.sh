#  strip-frameworks.sh
#  BatchExtension
#
#  Copyright © 2016 Batch.com. All rights reserved.

FRAMEWORK_DIRECTORY="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/BatchExtension.framework"
FRAMEWORK_BINARY_PATH="${FRAMEWORK_DIRECTORY}/BatchExtension"

individual_slices_paths=()

# Split the fat framework into one file per valid slice

for arch in $VALID_ARCHS; do
    slice_path="$FRAMEWORK_BINARY_PATH-$arch"
    lipo -extract "$arch" "$FRAMEWORK_BINARY_PATH" -o "$slice_path"
    individual_slices+=("$slice_path")
done

# Delete the fat framework and merge everything back, then clean up
rm "${FRAMEWORK_BINARY_PATH}"
lipo -create "${individual_slices[@]}" -o "${FRAMEWORK_BINARY_PATH}"
rm "${individual_slices[@]}"

# Codesign if needed
if [ "${CODE_SIGNING_REQUIRED}" == "YES" ]; then
  /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --preserve-metadata=identifier,entitlements "${FRAMEWORK_BINARY_PATH}"
fi
