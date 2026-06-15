#!/usr/bin/env bash
# Builds "Envkeep.app" — a native macOS window around the `envkeep gui`
# server (Swift + WKWebView). Requires Xcode command-line tools (swiftc).
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
app="$here/Envkeep.app"
contents="$app/Contents"

command -v swiftc >/dev/null || {
  echo "error: swiftc not found. Install Xcode command-line tools: xcode-select --install" >&2
  exit 1
}

echo "Building $(basename "$app")…"
rm -rf "$app"
mkdir -p "$contents/MacOS" "$contents/Resources"

# Info.plist — regular (Dock) app; allow http to loopback for the local server.
cat > "$contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>            <string>Envkeep</string>
  <key>CFBundleDisplayName</key>     <string>Envkeep</string>
  <key>CFBundleIdentifier</key>      <string>com.envkeep.app</string>
  <key>CFBundleExecutable</key>      <string>Envkeep</string>
  <key>CFBundlePackageType</key>     <string>APPL</string>
  <key>CFBundleShortVersionString</key> <string>1.0</string>
  <key>CFBundleVersion</key>         <string>1</string>
  <key>LSMinimumSystemVersion</key>  <string>12.0</string>
  <key>NSHighResolutionCapable</key> <true/>
  <key>NSAppTransportSecurity</key>
  <dict><key>NSAllowsLocalNetworking</key><true/></dict>
</dict>
</plist>
PLIST

# Compile.
swiftc -O "$here/app/Envkeep.swift" \
  -o "$contents/MacOS/Envkeep" \
  -framework Cocoa -framework WebKit

# Optional icon: if app/icon.png exists, convert it to an .icns.
if [ -f "$here/app/icon.png" ] && command -v iconutil >/dev/null && command -v sips >/dev/null; then
  set=$(mktemp -d)/AppIcon.iconset; mkdir -p "$set"
  for s in 16 32 128 256 512; do
    sips -z $s $s        "$here/app/icon.png" --out "$set/icon_${s}x${s}.png"     >/dev/null
    sips -z $((s*2)) $((s*2)) "$here/app/icon.png" --out "$set/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns "$set" -o "$contents/Resources/AppIcon.icns"
  /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$contents/Info.plist" 2>/dev/null || true
fi

# Ad-hoc sign so the app runs without "damaged"/Gatekeeper friction locally.
codesign --force --deep --sign - "$app" 2>/dev/null || true

echo "✓ Built: $app"
echo
echo "Open it:        open \"$app\""
echo "Install to /Applications:  cp -R \"$app\" /Applications/"
