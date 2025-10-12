#!/bin/bash
# ABOUTME: Generates AppIcon.icns from a source image
# ABOUTME: Uses sips to create all required icon sizes and iconutil to convert to .icns format

SOURCE_IMAGE="Resources/icon-sources/icon-1024.png"
ICONSET="Resources/icon-sources/AppIcon.iconset"
OUTPUT="Resources/AppIcon.icns"

# Create iconset directory
mkdir -p "$ICONSET"

# Generate all required sizes
sips -z 16 16     "$SOURCE_IMAGE" --out "$ICONSET/icon_16x16.png"
sips -z 32 32     "$SOURCE_IMAGE" --out "$ICONSET/icon_16x16@2x.png"
sips -z 32 32     "$SOURCE_IMAGE" --out "$ICONSET/icon_32x32.png"
sips -z 64 64     "$SOURCE_IMAGE" --out "$ICONSET/icon_32x32@2x.png"
sips -z 128 128   "$SOURCE_IMAGE" --out "$ICONSET/icon_128x128.png"
sips -z 256 256   "$SOURCE_IMAGE" --out "$ICONSET/icon_128x128@2x.png"
sips -z 256 256   "$SOURCE_IMAGE" --out "$ICONSET/icon_256x256.png"
sips -z 512 512   "$SOURCE_IMAGE" --out "$ICONSET/icon_256x256@2x.png"
sips -z 512 512   "$SOURCE_IMAGE" --out "$ICONSET/icon_512x512.png"
sips -z 1024 1024 "$SOURCE_IMAGE" --out "$ICONSET/icon_512x512@2x.png"

# Convert to icns
iconutil -c icns "$ICONSET" -o "$OUTPUT"

echo "Icon generated at $OUTPUT"
