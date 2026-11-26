param(
    [Parameter(Mandatory = $true)]
    [string]$RepoName,

    [switch]$Private,

    [string]$CommitMessage = "Initial commit: ZeroHook v1.0.0"
)

$ErrorActionPreference = "Stop"

# 1. Create .gitignore
@"
# Windows / PowerShell / Build artifacts
*.log
*.tmp
*.zip
bin/
obj/
out/
publish/
_build/

# ZeroHook local runtime / logs
zerohook-current.log
exclusions.json
"@ | Set-Content -Path ".gitignore" -Encoding UTF8

# 2. Create README.md if missing
if (-not (Test-Path "README.md")) {
@"
# ZeroHook

Bloat & Overlay Blocker + Real-Time Game DLL Hook Detector for Windows (PowerShell + WPF).

## Features
- Blocks or restores overlay/hook DLLs, Vulkan implicit layers, and Xbox Game Bar/DVR hooks.
- Manages vendor RGB/updater services, startup entries, shortcuts, and scheduled tasks.
- Includes a live process module/hook inspector and foreground window locker.
- Supports scheduled startup/logon execution via ``-AutoBlock``.

## Usage
Run in PowerShell (Administrator recommended for ACL/service/task changes):

``````powershell
.\ZeroHook.ps1