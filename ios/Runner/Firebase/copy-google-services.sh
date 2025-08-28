#!/bin/bash

# Create a symbolic link to the GoogleService-Info.plist file
ln -sf "${SRCROOT}/Runner/Firebase/GoogleService-Info.plist" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"

echo "GoogleService-Info.plist copied successfully."