export default `#!/bin/bash
set -e

# Build the Swift library
swift build

mkdir -p GodotProject/bin

# Copy built libraries to Godot project
cp .build/debug/*.{dylib,so,dll} GodotProject/bin/ 2>/dev/null || true`
