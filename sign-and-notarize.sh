#!/bin/bash
set -e

function version_from_git() {
  local git_root
  git_root=$(git rev-parse --show-toplevel)

  local version="unknown"

  if tag=$(cd "$git_root" && git tag --points-at HEAD | head -n 1); then
    if [[ -n "$tag" ]]; then
      version="$tag"
      echo "$version"
      return
    fi
  fi

  if timestamp=$(cd "$git_root" && git log -1 --format=%cd --date=format:%Y%m%d); then
    if [[ -n "$timestamp" ]]; then
      version="$timestamp"
      echo "$version"
      return
    fi
  fi

  echo "$version"
}

echo "Building SwiftGodotBuilderCLI..."
swift build --quiet -c release --product swiftgodotbuilder

echo "Signing SwiftGodotBuilderCLI..."
binary=".build/release/swiftgodotbuilder"
codesign --timestamp --options runtime --force --sign "Developer ID Application: John Susek (WX2UGCD2SK)" "$binary" || true

echo "Zipping signed SwiftGodotBuilderCLI..."
filename="swiftgodotbuilder-macos-$(version_from_git).zip"
rm -f "$filename"
zip -j "$filename" "$binary"
echo "Created $filename"

echo "Notarizing $filename..."

xcrun notarytool submit "$filename" \
      --keychain-profile "SGB" \
      --wait \
      >/dev/null

echo "Done! $filename is ready for distribution."
