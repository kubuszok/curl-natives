# curl-natives

Pre-built libcurl binaries for [Scala Native](https://scala-native.org/), targeting 6 platform/architecture combinations.

Windows builds use **MSVC** (not MinGW), which is required by Scala Native.

## Platforms

| Target | Architecture | TLS Backend | Static | Shared |
|--------|-------------|-------------|--------|--------|
| Linux | x86_64 | OpenSSL | `.a` | `.so` |
| Linux | aarch64 | OpenSSL | `.a` | `.so` |
| macOS | x86_64 | SecureTransport | `.a` | `.dylib` |
| macOS | aarch64 | SecureTransport | `.a` | `.dylib` |
| Windows | x86_64 | Schannel | `.lib` | `.dll` |
| Windows | aarch64 | Schannel | `.lib` | `.dll` |

## Artifact structure

Each `curl-{target}.tar.gz` contains:

```
lib/
  libcurl.a              # static (Unix)
  libcurl_static.lib     # static (Windows)
  libcurl.so*            # shared (Linux)
  libcurl*.dylib         # shared (macOS)
  libcurl.dll            # shared (Windows)
  libcurl.lib            # import lib (Windows)
include/
  curl/
    curl.h
    curlver.h
    easy.h
    multi.h
    ...
```

## Building

### Manual trigger

Go to **Actions** → **Build libcurl** → **Run workflow** and specify the curl version (e.g., `8.19.0`).

### Tag-based release

Push a tag to create a GitHub Release with all 6 artifacts:

```bash
git tag curl-8.19.0
git push origin curl-8.19.0
```

## Usage

Download the appropriate artifact from the [Releases](../../releases) page and extract it into your Scala Native project's native library path.
