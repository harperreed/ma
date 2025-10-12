#!/bin/bash
set -e

echo "🚀 Music Assistant Player - Release Build"
echo "========================================"

# Check for required tools
command -v xcodebuild >/dev/null 2>&1 || { echo "❌ xcodebuild not found"; exit 1; }
command -v iconutil >/dev/null 2>&1 || { echo "❌ iconutil not found"; exit 1; }

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/
rm -f *.dmg

# Run tests
echo "🧪 Running tests..."
swift test

# Generate icon (if source exists)
if [ -f "Resources/icon-sources/icon-1024.png" ]; then
    echo "🎨 Generating app icon..."
    ./scripts/generate-icon.sh
fi

# Create DMG
echo "📦 Creating DMG..."
./scripts/create-dmg.sh

echo ""
echo "✅ Build complete!"
echo "📦 DMG: $(ls -1 *.dmg)"
echo ""
echo "To install:"
echo "  1. Open the DMG"
echo "  2. Drag Music Assistant Player to Applications"
echo "  3. Launch from Applications folder"
