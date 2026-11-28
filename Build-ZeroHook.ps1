# Builds ZeroHook.exe from ZeroHook.ps1 with PS2EXE, using the same settings as the released exe:
# windowed (no console), asks for admin rights, AnyCPU (runs as 64-bit on 64-bit Windows), STA for WPF,
# and the same version info (ZeroHook / GS). The version comes from $AppVersion in ZeroHook.ps1,
# so bumping the script is enough.
#
# Run from this folder:   powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-ZeroHook.ps1
# PS2EXE is needed once:  Install-Module ps2exe -Scope CurrentUser
param(
    [string]$OutputFile = (Join-Path $PSScriptRoot "ZeroHook.exe"),
    # Hide text written to the output stream instead of showing it in message boxes
    [switch]$NoOutput,
    # Hide message boxes for unhandled errors
    [switch]$NoError
)

$ErrorActionPreference = "Stop"
$scriptFile = Join-Path $PSScriptRoot "ZeroHook.ps1"
$iconFile = Join-Path $PSScriptRoot "assets\ZeroHook.ico"

if (-not (Get-Command Invoke-ps2exe -ErrorAction SilentlyContinue)) {
    if (Get-Module -ListAvailable -Name ps2exe) {
        Import-Module ps2exe
    } else {
        throw "PS2EXE is not installed. Install it once with:  Install-Module ps2exe -Scope CurrentUser"
    }
}
foreach ($f in @($scriptFile, $iconFile)) {
    if (-not (Test-Path -LiteralPath $f)) { throw "Missing file: $f" }
}

$content = [System.IO.File]::ReadAllText($scriptFile)
if ($content -notmatch '\$AppVersion\s*=\s*"(\d+\.\d+\.\d+)"') { throw "Could not find `$AppVersion in ZeroHook.ps1" }
$version = $Matches[1]
# Optional pre-release tag ("beta1"); shown in the description and build output, not in the numeric FileVersion
$preRelease = if ($content -match '\$AppPreRelease\s*=\s*"([^"]*)"') { $Matches[1] } else { "" }
$displayVersion = if ($preRelease) { "$version $preRelease" } else { $version }

if (Get-Process -Name ([IO.Path]::GetFileNameWithoutExtension($OutputFile)) -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -ieq $OutputFile }) {
    throw "$OutputFile is running. Close ZeroHook first."
}
if (Test-Path -LiteralPath $OutputFile) {
    Copy-Item -LiteralPath $OutputFile -Destination "$OutputFile.bak" -Force
    Write-Host "Previous build kept as $(Split-Path -Leaf $OutputFile).bak"
}

$ps2exeArgs = @{
    inputFile    = $scriptFile
    outputFile   = $OutputFile
    iconFile     = $iconFile
    title        = "ZeroHook"
    description  = "ZeroHook v$displayVersion - Made by: GS | Bloat & Overlay Blocker + Real-Time Game DLL Hook Detector"
    company      = "GS"
    product      = "ZeroHook"
    copyright    = "Made by: GS"
    version      = $version
    noConsole    = $true
    requireAdmin = $true
    STA          = $true
}
if ($NoOutput) { $ps2exeArgs.noOutput = $true }
if ($NoError) { $ps2exeArgs.noError = $true }

Write-Host "Building ZeroHook $displayVersion ..."
Invoke-ps2exe @ps2exeArgs

$info = (Get-Item -LiteralPath $OutputFile).VersionInfo
$sizeKb = [math]::Round((Get-Item -LiteralPath $OutputFile).Length / 1KB)
Write-Host "Built $OutputFile ($sizeKb KB) | ZeroHook v$displayVersion | FileVersion $($info.FileVersion) | $($info.ProductName) by $($info.CompanyName)"
