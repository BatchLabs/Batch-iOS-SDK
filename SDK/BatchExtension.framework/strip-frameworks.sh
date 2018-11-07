#  strip-frameworks.sh
#  BatchExtension
#
#  Copyright © 2016 Batch.com. All rights reserved.

FRAMEWORK_DIRECTORY="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/BatchExtension.framework"
FRAMEWORK_BINARY_PATH="${FRAMEWORK_DIRECTORY}/BatchExtension"

individual_slices_paths=()

# Split the fat framework into one file per valid slice

for arch in $VALID_ARCHS; do
    # Temporary arm64e patch, remove once a bitcode-enabled arm64e slice can be generated
    if [[ $arch == "arm64e" ]]; then
      continue
    fi

    slice_path="$FRAMEWORK_BINARY_PATH-$arch"
    lipo -extract "$arch" "$FRAMEWORK_BINARY_PATH" -o "$slice_path"
    if [ $? -eq 0 ]; then
      individual_slices+=("$slice_path")
    fi
done

# Delete the fat framework and merge everything back, then clean up
rm "${FRAMEWORK_BINARY_PATH}"
lipo -create "${individual_slices[@]}" -o "${FRAMEWORK_BINARY_PATH}"
rm "${individual_slices[@]}"

# Codesign if needed
if [ "${CODE_SIGNING_REQUIRED}" == "YES" ]; then
  /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --preserve-metadata=identifier,entitlements "${FRAMEWORK_BINARY_PATH}"
fi
