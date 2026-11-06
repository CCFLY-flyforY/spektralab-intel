#!/bin/bash
# build-intel.sh -- build SpektraLab for Intel (x86_64) macOS with Command Line Tools only.
#
#   ./build-intel.sh --app "/tmp/SpektraLab-x86.app" --out ./build
#
# --app  the .app copied out of the official arm64 DMG. It is used as the
#        bundle skeleton (Assets.car, default.metallib, film/paper configs,
#        DI LUTs, icns), so actool and metal -- which ship only with Xcode --
#        are never needed. Only Contents/MacOS/SpektraLab is replaced.
set -euo pipefail

APP=""
OUT="./build"
while [ $# -gt 0 ]; do
  case "$1" in
    --app) APP="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    *) echo "usage: $0 --app <SpektraLab.app> [--out DIR]" >&2; exit 2 ;;
  esac
done
[ -d "$APP" ] || { echo "error: --app must point at the .app from the official DMG" >&2; exit 2; }

ROOT=$(cd "$(dirname "$0")" && pwd)
UI="$ROOT/modern_UI/Spektrafilm"
ENG="$ROOT/engine"
OBJ="$ROOT/build-obj"
OUTBIN="$ROOT/build"
mkdir -p "$OBJ" "$OUTBIN"
SDK=$(xcrun --show-sdk-path)

echo "== engine (C++20, x86_64)"
for f in "$ENG"/src/core/*.cpp "$ENG"/src/gpu/*.cpp "$ENG"/src/pipeline/*.cpp; do
  o="$OBJ/$(basename "${f%.cpp}").o"
  clang++ -std=c++20 -O2 -I"$ENG/include" -I"$ENG/src" -I"$ENG/src/core" \
          -I"$ENG/third_party/metal-cpp" -target x86_64-apple-macos15.0 -c "$f" -o "$o"
done
ar rcs "$OBJ/libspektrafilm_engine.a" "$OBJ"/*.o

echo "== app (Swift 6)"
cd "$UI"
FILES=$(find Spektrafilm -name "*.swift" | tr "\n" " ")
swiftc -parse-as-library -O -sdk "$SDK" -target x86_64-apple-macos15.0 -swift-version 6 \
      -import-objc-header Spektrafilm/Service/Spektrafilm-Bridging-Header.h \
      -I "$ENG/include" -o "$OUTBIN/SpektraLab-x86_64" $FILES \
      "$OBJ/libspektrafilm_engine.a" -lc++ \
      -framework Metal -framework MetalKit -framework Accelerate -framework CoreText \
      -framework CoreGraphics -framework QuartzCore -framework CoreImage \
      -framework ImageIO -framework UniformTypeIdentifiers -framework AppKit -framework SwiftUI

echo "== bundle"
OUT_APP="$OUT/SpektraLab.app"
rm -rf "$OUT_APP"
cp -R "$APP" "$OUT_APP"
cp "$OUTBIN/SpektraLab-x86_64" "$OUT_APP/Contents/MacOS/SpektraLab"
rm -rf "$OUT_APP/Contents/_CodeSignature"
codesign --force --deep --sign - "$OUT_APP"
lipo -archs "$OUT_APP/Contents/MacOS/SpektraLab"
echo "built: $OUT_APP"
