# ZeroHook

**ZeroHook** is a Windows desktop utility built with PowerShell and WPF designed to detect, block, and manage third-party overlays, injected DLL hooks, Vulkan implicit layers, and background vendor bloat—without needing to keep an app running in the background.

---

## Quick Launch

Open **PowerShell as Administrator** and run:

```powershell
irm "https://raw.githubusercontent.com/GS-ZeroHook/ZeroHook/main/ZeroHook.ps1" | iex
```

*(Prefer a standalone `.exe`? Download `ZeroHook.exe` from the **Releases** page on the right.)*

---

## Why ZeroHook Exists

### Overlays Hook Into Games Even When "Disabled"
Turning off the in-game overlay toggle inside launchers like **Steam** or **Discord** usually only hides the visual UI—it **does not** stop their overlay DLLs (`GameOverlayRenderer64.dll`, `DiscordHook64.dll`, etc.) from injecting into your game process, hooking graphics APIs (DirectX / Vulkan), and adding frame-time variance or input latency.

ZeroHook blocks those hook libraries at the OS/permission level so they cannot load into your games in the first place.

### Set It Once & Forget It (Zero Background Overhead)
* **No Resident Background App:** ZeroHook does not sit in your system tray eating CPU or RAM while you play.
* **Survives Launcher & Client Updates:** When clients like Steam update and replace or re-register their overlay files, ZeroHook automatically re-applies your configured blocks at Windows startup via its built-in `-AutoBlock` task—so your protections stay active without manual upkeep.

---

## Core Features

### 1. Overlay & Hook Blocker
* **DLL & Overlay Blocking:** Blocks overlay and hook DLLs (Steam, Discord, GeForce Experience/NVIDIA App, AMD Radeon, RTSS/MSI Afterburner, Overwolf, and vendor utilities) using reversible file/ACL permissions so they cannot inject into games—even when disabled in client settings.
* **Vulkan Implicit Layers:** Detects and disables intrusive Vulkan implicit layers in the Windows Registry while preserving clean restoration paths.
* **Xbox Game Bar & Game DVR:** Disables Windows Game Bar and background capture/DVR hooks that can cause stuttering or input lag (Windows Game Mode is never modified).
* **One-Click Restore:** Every change is non-destructive and can be reverted individually or all at once.

### 2. Vendor Bloat & Background Process Control
* **Services Management:** Safely disables or restores non-essential vendor RGB, peripheral, and updater background services.
* **Startup Entries & Shortcuts:** Audits and disables auto-starting registry `Run` entries and Startup folder shortcuts without uninstalling your software.
* **Scheduled Tasks:** Disables recurring background telemetry and updater tasks in Windows Task Scheduler.

### 3. Real-Time Game DLL Hook & Module Inspector
* **Loaded Module Scanning:** Inspects running processes and lists loaded DLLs, highlighting known overlays, third-party hooks, unsigned modules, and external injections.
* **On-Demand Scanning:** Runs only when you trigger a scan—no background polling.
* **Exclusions Support (`exclusions.json`):** Whitelist trusted DLLs or processes you intentionally run.

### 4. Foreground Window Locker
* **Focus Protection:** Prevents background popups, updaters, or notifications from stealing focus or minimizing full-screen/borderless games.

---

## Requirements & Permissions

* **OS:** Windows 10 or Windows 11
* **Privileges:** **Run as Administrator** is required to modify system services, scheduled tasks, registry keys, and file/ACL permissions.

---

## Local / Offline Usage

If you downloaded `ZeroHook.exe` or cloned this repository locally:

```powershell
# Launch the WPF interface (run PowerShell as Administrator)
.\ZeroHook.ps1

# Re-apply saved blocks silently (used automatically at Windows startup)
.\ZeroHook.ps1 -AutoBlock
```

---

## Safety & Transparency
* **Non-Destructive:** Blocks execution/loading permissions and startup triggers rather than deleting third-party files.
* **Local Logging:** Records actions locally in `zerohook-current.log` for easy troubleshooting.
* **Fully Auditable:** Everything runs directly from the single `ZeroHook.ps1` script in this repository.