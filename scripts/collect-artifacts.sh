#!/usr/bin/env bash
set -euo pipefail

TARGET=""
SRC_DIR=""
OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)     TARGET="$2"; shift 2 ;;
        --src-dir)    SRC_DIR="$2"; shift 2 ;;
        --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

if [[ -z "$TARGET" || -z "$SRC_DIR" || -z "$OUTPUT_DIR" ]]; then
    echo "Usage: collect-artifacts.sh --target <target> --src-dir <dir> --output-dir <dir>"
    exit 1
fi

SRC_DIR="$(cd "$SRC_DIR" && pwd)"
INSTALL_STATIC="$SRC_DIR/install-${TARGET}-static"
INSTALL_SHARED="$SRC_DIR/install-${TARGET}-shared"
STAGING="$OUTPUT_DIR/staging-$TARGET"

mkdir -p "$OUTPUT_DIR"
rm -rf "$STAGING"
mkdir -p "$STAGING/lib" "$STAGING/include"

# Copy headers (from either install dir — they're the same)
cp -r "$INSTALL_STATIC/include/curl" "$STAGING/include/"

# Copy static library
case "$TARGET" in
    linux-*|macos-*)
        cp "$INSTALL_STATIC/lib/libcurl.a" "$STAGING/lib/"
        ;;
esac

# Copy shared libraries
case "$TARGET" in
    linux-*)
        # Copy all .so files (libcurl.so, libcurl.so.4, libcurl.so.4.x.0)
        find "$INSTALL_SHARED/lib" -name "libcurl.so*" -exec cp -a {} "$STAGING/lib/" \;
        ;;
    macos-*)
        # Copy all .dylib files (libcurl.dylib, libcurl.4.dylib)
        find "$INSTALL_SHARED/lib" -name "libcurl*.dylib" -exec cp -a {} "$STAGING/lib/" \;
        # Fix install names to use @rpath for relocatable binaries
        for dylib in "$STAGING/lib/"*.dylib; do
            if [[ -f "$dylib" && ! -L "$dylib" ]]; then
                install_name_tool -id "@rpath/$(basename "$dylib")" "$dylib" 2>/dev/null || true
            fi
        done
        ;;
esac

# Also copy pkg-config file if available
if [[ -d "$INSTALL_STATIC/lib/pkgconfig" ]]; then
    mkdir -p "$STAGING/lib/pkgconfig"
    cp "$INSTALL_STATIC/lib/pkgconfig/libcurl.pc" "$STAGING/lib/pkgconfig/" 2>/dev/null || true
fi

# Package
echo "=== Packaging curl-$TARGET.tar.gz ==="
tar -czf "$OUTPUT_DIR/curl-$TARGET.tar.gz" -C "$STAGING" .
rm -rf "$STAGING"

echo "=== Artifact ready: $OUTPUT_DIR/curl-$TARGET.tar.gz ==="
ls -lh "$OUTPUT_DIR/curl-$TARGET.tar.gz"
