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

echo "Build successful! AWV is now in your Applications folder."

