param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("windows-x86_64", "windows-aarch64")]
    [string]$Target,

    [Parameter(Mandatory=$true)]
    [string]$SrcDir
)

$ErrorActionPreference = "Stop"

$SrcDir = Resolve-Path $SrcDir

# Map target to Visual Studio architecture
switch ($Target) {
    "windows-x86_64"  { $Arch = "x64" }
    "windows-aarch64" { $Arch = "ARM64" }
}

# Common CMake flags — uses Visual Studio generator to ensure MSVC (not MinGW)
$CommonFlags = @(
    "-G", "Visual Studio 17 2022",
    "-A", $Arch,
    "-DBUILD_CURL_EXE=OFF",
    "-DBUILD_TESTING=OFF",
    "-DCURL_USE_SCHANNEL=ON",
    "-DCURL_DISABLE_LDAP=ON",
    "-DCURL_DISABLE_LDAPS=ON",
    "-DCURL_USE_LIBPSL=OFF"
)

# Build static library
Write-Host "=== Building libcurl (static) for $Target ==="
$BuildDirStatic = Join-Path $SrcDir "build-${Target}-static"
$InstallDirStatic = Join-Path $SrcDir "install-${Target}-static"
New-Item -ItemType Directory -Force -Path $BuildDirStatic | Out-Null

cmake -S $SrcDir -B $BuildDirStatic @CommonFlags `
    "-DBUILD_SHARED_LIBS=OFF" `
    "-DCMAKE_INSTALL_PREFIX=$InstallDirStatic"
if ($LASTEXITCODE -ne 0) { throw "CMake configure (static) failed" }

cmake --build $BuildDirStatic --config Release
if ($LASTEXITCODE -ne 0) { throw "CMake build (static) failed" }

cmake --install $BuildDirStatic --config Release
if ($LASTEXITCODE -ne 0) { throw "CMake install (static) failed" }

Write-Host "=== Static build complete for $Target ==="

# Build shared library
Write-Host "=== Building libcurl (shared) for $Target ==="
$BuildDirShared = Join-Path $SrcDir "build-${Target}-shared"
$InstallDirShared = Join-Path $SrcDir "install-${Target}-shared"
New-Item -ItemType Directory -Force -Path $BuildDirShared | Out-Null

cmake -S $SrcDir -B $BuildDirShared @CommonFlags `
    "-DBUILD_SHARED_LIBS=ON" `
    "-DCMAKE_INSTALL_PREFIX=$InstallDirShared"
if ($LASTEXITCODE -ne 0) { throw "CMake configure (shared) failed" }

cmake --build $BuildDirShared --config Release
if ($LASTEXITCODE -ne 0) { throw "CMake build (shared) failed" }

cmake --install $BuildDirShared --config Release
if ($LASTEXITCODE -ne 0) { throw "CMake install (shared) failed" }

Write-Host "=== Shared build complete for $Target ==="
