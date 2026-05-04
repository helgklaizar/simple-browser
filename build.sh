#!/bin/zsh
set -e

echo "Building AWV with modular architecture..."

# Find all Swift files
SWIFT_FILES=(Sources/**/*.swift)

# Compile
swiftc -parse-as-library $SWIFT_FILES -o AWV.app/Contents/MacOS/AWV

# Sign
codesign --force --deep --sign - AWV.app

# Copy to Applications
echo "Deploying to /Applications..."
cp -R AWV.app /Applications/

# Package for OTA Updates (Sparkle / GitHub Releases)
echo "Packaging for OTA updates..."
mkdir -p releases
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" AWV.app/Contents/Info.plist 2>/dev/null || echo "1.0.0")
zip -q -r "releases/AWV-v${VERSION}.zip" AWV.app
echo "Created releases/AWV-v${VERSION}.zip"

echo "Build successful! AWV is now in your Applications folder and packaged for release."
