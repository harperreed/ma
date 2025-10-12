#!/bin/bash
# ABOUTME: Generates DMG background images with gradient and installation instructions
# ABOUTME: Creates both standard (600x400) and retina (1200x800) versions

set -e

OUTPUT="dmg-resources/background.png"
OUTPUT_2X="dmg-resources/background@2x.png"

echo "🎨 Generating DMG background images..."

# Create 600x400 background (standard resolution)
convert -size 600x400 \
    gradient:'#1a1a1f-#25252a' \
    -gravity center \
    -pointsize 24 \
    -fill white \
    -annotate +0+150 'Drag to Applications folder to install' \
    "$OUTPUT"

echo "✅ Created $OUTPUT"

# Create 1200x800 background (retina resolution)
convert -size 1200x800 \
    gradient:'#1a1a1f-#25252a' \
    -gravity center \
    -pointsize 48 \
    -fill white \
    -annotate +0+300 'Drag to Applications folder to install' \
    "$OUTPUT_2X"

echo "✅ Created $OUTPUT_2X"

echo "🎉 Background images generated successfully"
