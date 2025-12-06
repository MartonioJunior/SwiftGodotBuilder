#!/bin/bash

# Build the project
swift build -c debug

# Check if build succeeded
if [ $? -ne 0 ]; then
  echo "Build failed, not starting Godot"
  exit 1
fi

# Copy dylibs
bash -lc 'cfg='debug'; src=.build/$cfg; dest=GodotProject/bin; mkdir -p "$dest"; cp -f "$src"/*.dylib "$dest" 2>/dev/null || true'

bash -c 'rm -f ../*.{d,dia,swiftdeps,swiftmodule}'

# Codesign all dylibs
codesign --force --deep --sign - GodotProject/bin/*.dylib 2>/dev/null

# Start Godot - unless "norun" argument is given
if [ "$1" == "norun" ]; then
  exit 0
fi

godot --path GodotProject/ --disable-crash-handler

