param(
    [Parameter(Mandatory=$true)]
    [string]$Target,

    [Parameter(Mandatory=$true)]
    [string]$SrcDir,

    [Parameter(Mandatory=$true)]
    [string]$OutputDir
)

$ErrorActionPreference = "Stop"

$SrcDir = Resolve-Path $SrcDir
$InstallStatic = Join-Path $SrcDir "install-${Target}-static"
$InstallShared = Join-Path $SrcDir "install-${Target}-shared"
$Staging = Join-Path $OutputDir "staging-$Target"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
if (Test-Path $Staging) { Remove-Item -Recurse -Force $Staging }
New-Item -ItemType Directory -Force -Path "$Staging/lib" | Out-Null
New-Item -ItemType Directory -Force -Path "$Staging/include" | Out-Null

# Copy headers
Copy-Item -Recurse -Path "$InstallStatic/include/curl" -Destination "$Staging/include/curl"

# Copy static library (.lib from static build)
$StaticLib = Get-ChildItem -Path "$InstallStatic/lib" -Filter "libcurl*.lib" -Recurse | Select-Object -First 1
if ($StaticLib) {
    Copy-Item $StaticLib.FullName -Destination "$Staging/lib/libcurl_static.lib"
} else {
    # Try alternate naming (curl uses libcurl_a.lib for static sometimes)
    $StaticLib = Get-ChildItem -Path "$InstallStatic/lib" -Filter "curl*.lib" -Recurse | Select-Object -First 1
    if ($StaticLib) {
        Copy-Item $StaticLib.FullName -Destination "$Staging/lib/libcurl_static.lib"
    } else {
        Write-Warning "No static .lib found in $InstallStatic/lib"
    }
}

# Copy shared library (.dll + import .lib from shared build)
$SharedDll = Get-ChildItem -Path "$InstallShared/bin" -Filter "libcurl*.dll" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $SharedDll) {
    $SharedDll = Get-ChildItem -Path "$InstallShared/lib" -Filter "libcurl*.dll" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
}
if ($SharedDll) {
    Copy-Item $SharedDll.FullName -Destination "$Staging/lib/libcurl.dll"
}

$ImportLib = Get-ChildItem -Path "$InstallShared/lib" -Filter "libcurl*.lib" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $ImportLib) {
    $ImportLib = Get-ChildItem -Path "$InstallShared/lib" -Filter "curl*.lib" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
}
if ($ImportLib) {
    Copy-Item $ImportLib.FullName -Destination "$Staging/lib/libcurl.lib"
}

# Copy pkg-config if available
$PkgConfig = Join-Path $InstallStatic "lib/pkgconfig/libcurl.pc"
if (Test-Path $PkgConfig) {
    New-Item -ItemType Directory -Force -Path "$Staging/lib/pkgconfig" | Out-Null
    Copy-Item $PkgConfig -Destination "$Staging/lib/pkgconfig/"
}

# Package using tar (available on Windows runners)
Write-Host "=== Packaging curl-$Target.tar.gz ==="
Push-Location $Staging
tar -czf "$OutputDir/curl-$Target.tar.gz" .
Pop-Location

Remove-Item -Recurse -Force $Staging

$ArtifactPath = Join-Path $OutputDir "curl-$Target.tar.gz"
Write-Host "=== Artifact ready: $ArtifactPath ==="
Get-Item $ArtifactPath | Format-Table Name, Length
