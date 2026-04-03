#!/usr/bin/env bash
set -euo pipefail

TARGET=""
SRC_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)  TARGET="$2"; shift 2 ;;
        --src-dir) SRC_DIR="$2"; shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

if [[ -z "$TARGET" || -z "$SRC_DIR" ]]; then
    echo "Usage: build-curl.sh --target <target> --src-dir <dir>"
    echo "Targets: linux-x86_64, linux-aarch64, macos-x86_64, macos-aarch64"
    exit 1
fi

SRC_DIR="$(cd "$SRC_DIR" && pwd)"

# Common CMake flags
COMMON_FLAGS=(
    -DCMAKE_BUILD_TYPE=Release
    -DBUILD_CURL_EXE=OFF
    -DBUILD_TESTING=OFF
    -DCURL_DISABLE_LDAP=ON
    -DCURL_DISABLE_LDAPS=ON
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -G Ninja
)

# Target-specific flags
TARGET_FLAGS=()
case "$TARGET" in
    linux-x86_64|linux-aarch64)
        TARGET_FLAGS+=(
            -DCURL_USE_OPENSSL=ON
        )
        ;;
    macos-x86_64)
        TARGET_FLAGS+=(
            -DCURL_USE_SECTRANSP=ON
            -DCMAKE_OSX_ARCHITECTURES=x86_64
            -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0
        )
        ;;
    macos-aarch64)
        TARGET_FLAGS+=(
            -DCURL_USE_SECTRANSP=ON
            -DCMAKE_OSX_ARCHITECTURES=arm64
            -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0
        )
        ;;
    *)
        echo "Error: unsupported target '$TARGET' for this script"
        echo "Use build-curl-windows.ps1 for Windows targets"
        exit 1
        ;;
esac

# Build static library
echo "=== Building libcurl (static) for $TARGET ==="
BUILD_DIR_STATIC="$SRC_DIR/build-${TARGET}-static"
INSTALL_DIR_STATIC="$SRC_DIR/install-${TARGET}-static"
mkdir -p "$BUILD_DIR_STATIC"

cmake -S "$SRC_DIR" -B "$BUILD_DIR_STATIC" \
    "${COMMON_FLAGS[@]}" "${TARGET_FLAGS[@]}" \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR_STATIC"

cmake --build "$BUILD_DIR_STATIC" --config Release
cmake --install "$BUILD_DIR_STATIC" --config Release
echo "=== Static build complete for $TARGET ==="

# Build shared library
echo "=== Building libcurl (shared) for $TARGET ==="
BUILD_DIR_SHARED="$SRC_DIR/build-${TARGET}-shared"
INSTALL_DIR_SHARED="$SRC_DIR/install-${TARGET}-shared"
mkdir -p "$BUILD_DIR_SHARED"

cmake -S "$SRC_DIR" -B "$BUILD_DIR_SHARED" \
    "${COMMON_FLAGS[@]}" "${TARGET_FLAGS[@]}" \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR_SHARED"

cmake --build "$BUILD_DIR_SHARED" --config Release
cmake --install "$BUILD_DIR_SHARED" --config Release
echo "=== Shared build complete for $TARGET ==="
