param(
    [switch]$AutoBlock
)

# --- CONFIGURATION ---
$TaskName = "ZeroHook_AutoBlock"
$EveryoneSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-1-0")

$LauncherProcesses = @(
    "steam", "steamwebhelper", "GameOverlayUI",
    "Discord", "DiscordCanary", "DiscordPTB",
    "EADesktop", "EABackgroundService", "Origin",
    "EpicGamesLauncher", "EpicWebHelper",
    "upc", "UplayWebCore",
    "GalaxyClient",
    "Overwolf", "OverwolfBrowser",
    "obs64", "obs32", "Streamlabs OBS",
    "RTSS", "RTSSHooksLoader64",
    "RazerCortex", "Razer Synapse 3", "RazerCentralService",
    "SignalRgb", "SignalRgbLauncher",
    "OneDrive", "Dropbox",
    "CCXProcess", "AdobeIPCBroker", "Creative Cloud"
)

$SearchPaths = @(
    "${env:ProgramFiles(x86)}\Steam",
    "${env:ProgramFiles(x86)}\Steam\bin",
    "$env:ProgramFiles\Steam",
    "$env:ProgramFiles\Steam\bin",
    "$env:LOCALAPPDATA\Discord",
    "$env:LOCALAPPDATA\DiscordCanary",
    "$env:LOCALAPPDATA\DiscordPTB",
    "$env:ProgramFiles\Electronic Arts",
    "${env:ProgramFiles(x86)}\Origin",
    "${env:ProgramFiles(x86)}\Epic Games\Launcher",
    "${env:ProgramFiles(x86)}\Epic Games\Epic Online Services",
    "$env:ProgramFiles\Epic Games\Launcher",
    "$env:ProgramFiles\Epic Games\Epic Online Services",
    "${env:ProgramFiles(x86)}\Ubisoft\Ubisoft Game Launcher",
    "${env:ProgramFiles(x86)}\GOG Galaxy",
    "${env:ProgramFiles(x86)}\Overwolf",
    "$env:ProgramFiles\Overwolf",
    "$env:LOCALAPPDATA\Overwolf",
    "$env:ProgramFiles\obs-studio",
    "$env:ProgramFiles\Streamlabs OBS",
    "$env:ProgramData\obs-studio-hook",
    "${env:ProgramFiles(x86)}\RivaTuner Statistics Server",
    "$env:ProgramFiles\NVIDIA Corporation",
    "$env:ProgramData\NVIDIA Corporation",
    "$env:LOCALAPPDATA\NVIDIA Corporation",
    "$env:ProgramFiles\AMD",
    "$env:ProgramFiles\Razer",
    "${env:ProgramFiles(x86)}\Razer",
    "$env:ProgramData\Razer",
    "$env:ProgramFiles\Sony",
    "${env:ProgramFiles(x86)}\Sony"
)

$ExcludedPathRegex = "\\steamapps\\|\\Epic Games\\DirectXRedist\\|\\.egstore\\"

$TargetDLLs = @(
    "GameOverlayRenderer.dll", "GameOverlayRenderer64.dll",
    "SteamOverlayVulkanLayer.dll", "SteamOverlayVulkanLayer64.dll",
    "SteamFossilizeVulkanLayer.dll", "SteamFossilizeVulkanLayer64.dll",
    "DiscordHook.dll", "DiscordHook32.dll", "DiscordHook64.dll", "DiscordOverlay.dll",
    "IGO32.dll", "IGO64.dll",
    "EOSOVH-Win32-Shipping.dll", "EOSOVH-Win64-Shipping.dll",
    "overlay.dll", "overlay32.dll", "overlay64.dll",
    "OverlayInjector.dll", "GalaxyOverlay.dll",
    "OWClient.dll", "OWExplorer.dll", "OWUtils.dll",
    "ow-graphics-hook.dll", "ow-graphics-hook32.dll", "ow-graphics-hook64.dll",
    "ow-graphics-vulkan.dll", "ow-vulkan-overlay32.dll", "ow-vulkan-overlay64.dll",
    "ow-obs-vulkan32.dll", "ow-obs-vulkan64.dll",
    "graphics-hook32.dll", "graphics-hook64.dll",
    "obs-vulkan32.dll", "obs-vulkan64.dll",
    "RTSSHooks.dll", "RTSSHooks64.dll",
    "RTSSVkLayer32.dll", "RTSSVkLayer64.dll",
    "nvspcap.dll", "nvspcap64.dll", "amddvr64.dll",
    "k_fps.dll", "k_fps64.dll",
    "DualSenseWirelessController.dll", "PS5Controller.dll"
)

$LiveHookMap = @{
    "gameoverlayrenderer.dll"                  = "Steam"
    "gameoverlayrenderer64.dll"                = "Steam"
    "steamoverlayvulkanlayer.dll"              = "Steam"
    "steamoverlayvulkanlayer64.dll"            = "Steam"
    "steamfossilizevulkanlayer.dll"            = "Steam"
    "steamfossilizevulkanlayer64.dll"          = "Steam"

    "discordhook.dll"                          = "Discord"
    "discordhook32.dll"                        = "Discord"
    "discordhook64.dll"                        = "Discord"
    "discordoverlay.dll"                       = "Discord"

    "eosovh-win32-shipping.dll"                = "Epic"
    "eosovh-win64-shipping.dll"                = "Epic"

    "galaxyoverlay.dll"                        = "GOG"
    "overlayinjector.dll"                      = "GOG"

    "owclient.dll"                             = "Overwolf"
    "owexplorer.dll"                           = "Overwolf"
    "owutils.dll"                              = "Overwolf"
    "ow-graphics-hook.dll"                     = "Overwolf"
    "ow-graphics-hook32.dll"                   = "Overwolf"
    "ow-graphics-hook64.dll"                   = "Overwolf"
    "ow-graphics-vulkan.dll"                   = "Overwolf"
    "ow-vulkan-overlay32.dll"                  = "Overwolf"
    "ow-vulkan-overlay64.dll"                  = "Overwolf"
    "ow-obs-vulkan32.dll"                      = "Overwolf"
    "ow-obs-vulkan64.dll"                      = "Overwolf"

    "graphics-hook32.dll"                      = "OBS"
    "graphics-hook64.dll"                      = "OBS"
    "obs-vulkan32.dll"                         = "OBS"
    "obs-vulkan64.dll"                         = "OBS"

    "rtsshooks.dll"                            = "RTSS"
    "rtsshooks64.dll"                          = "RTSS"
    "rtssvklayer32.dll"                        = "RTSS"
    "rtssvklayer64.dll"                        = "RTSS"

    "nvspcap.dll"                              = "NVIDIA"
    "nvspcap64.dll"                            = "NVIDIA"
    "amddvr64.dll"                             = "AMD"

    "relimiter.addon32"                        = "ReLimiter"
    "relimiter.addon64"                        = "ReLimiter"
    "reshade32.dll"                            = "ReShade"
    "reshade64.dll"                            = "ReShade"

    "nvngx_dlss.dll"                           = "DLSSStreamline"
    "nvngx_dlssd.dll"                          = "DLSSStreamline"
    "nvngx_dlssg.dll"                          = "DLSSStreamline"
    "nvngx_dlssnr.dll"                         = "DLSSStreamline"
    "nvngx_dlssnr_real.dll"                    = "DLSSStreamline"
    "nvngx.dll_dlssnr.dll"                     = "DLSSStreamline"
    "nvngx_latewarp.dll"                       = "DLSSStreamline"
    "sl.interposer.dll"                        = "DLSSStreamline"
    "sl.common.dll"                            = "DLSSStreamline"
    "sl.dlss.dll"                              = "DLSSStreamline"
    "sl.dlss_d.dll"                            = "DLSSStreamline"
    "sl.dlss_g.dll"                            = "DLSSStreamline"
    "sl.reflex.dll"                            = "DLSSStreamline"
    "sl.pcl.dll"                               = "DLSSStreamline"
    "sl.nis.dll"                               = "DLSSStreamline"
    "sl.deepdvc.dll"                           = "DLSSStreamline"
    "sl.directsr.dll"                          = "DLSSStreamline"
    "sl.nvperf.dll"                            = "DLSSStreamline"

    "optiscaler.dll"                           = "OptiScaler"
    "amd_fidelityfx_dx12.dll"                  = "OptiScaler"
    "amd_fidelityfx_vk.dll"                    = "OptiScaler"
    "amd_fidelityfx_loader_dx12.dll"           = "OptiScaler"
    "amd_fidelityfx_loader_vk.dll"             = "OptiScaler"
    "amd_fidelityfx_upscaler_dx12.dll"         = "OptiScaler"
    "amd_fidelityfx_upscaler_vk.dll"           = "OptiScaler"
    "amd_fidelityfx_framegeneration_dx12.dll"  = "OptiScaler"
    "amd_fidelityfx_framegeneration_vk.dll"    = "OptiScaler"
    "libxess.dll"                              = "OptiScaler"
    "libxess_dx11.dll"                         = "OptiScaler"
    "libxess_fg.dll"                           = "OptiScaler"
    "libxell.dll"                              = "OptiScaler"
    "d3d12core.dll"                            = "OptiScaler"
    "fakenvapi.dll"                            = "OptiScaler"
    "dlssg_to_fsr3.dll"                        = "OptiScaler"
    "dlssg_to_fsr3_amd_is_better.dll"          = "OptiScaler"
    "dlss-enabler-headless.dll"                = "OptiScaler"
    "f5low.dll"                                = "OptiScaler"
    "params_builder.dll"                       = "OptiScaler"

    "dxgi_dxvk.dll"                            = "DXVK"
    "d3d8.dll"                                 = "ProxyHook"
    "d3d10.dll"                                = "ProxyHook"
    "d3d10core.dll"                            = "ProxyHook"
    "ddraw.dll"                                = "ProxyHook"
    "dinput.dll"                               = "ProxyHook"
    "dsound.dll"                               = "ProxyHook"
    "msacm32.dll"                              = "ProxyHook"
    "msvcp140.dll"                             = "ProxyHook"
    "msvfw32.dll"                              = "ProxyHook"
    "version.dll"                              = "ProxyHook"
    "wininet.dll"                              = "ProxyHook"
    "winhttp.dll"                              = "ProxyHook"
    "xlive.dll"                                = "ProxyHook"
    "binkw32.dll"                              = "ProxyHook"
    "binkw64.dll"                              = "ProxyHook"
    "bink2w32.dll"                             = "ProxyHook"
    "bink2w64.dll"                             = "ProxyHook"
    "vorbisfile.dll"                           = "ProxyHook"
    "xinput1_1.dll"                            = "ProxyHook"
    "xinput1_2.dll"                            = "ProxyHook"
    "xinput1_3.dll"                            = "ProxyHook"
    "xinput1_4.dll"                            = "ProxyHook"
    "xinput9_1_0.dll"                          = "ProxyHook"
    "xinputuap.dll"                            = "ProxyHook"

    "mfgunlocker.dll"                          = "MFGUnlocker"
    "rtxmfg.dll"                               = "MFGUnlocker"
    "rtx40mfgcore.dll"                         = "MFGUnlocker"

    "rtx-encore.dll"                           = "RTXEncore"
    "dxcompiler.dll"                           = "RTXEncore"
    "dxil.dll"                                 = "RTXEncore"

    "sm86_backend.dll"                         = "DLSSGMod"
    "fg_kernels.dll"                           = "DLSSGMod"
    "sr_kernels.dll"                           = "DLSSGMod"
    "xefg_kernels.dll"                         = "DLSSGMod"

    "d3dcompiler_47.dll"                       = "LumaMod"
    "bfipresentervk.dll"                       = "BFIMod"
    "bfipresentervk32.dll"                     = "BFIMod"

    "k_fps.dll"                                = "GenericOverlay"
    "k_fps64.dll"                              = "GenericOverlay"
    "overlay.dll"                              = "GenericOverlay"
    "dualsensewirelesscontroller.dll"          = "ControllerHook"
    "ps5controller.dll"                        = "ControllerHook"
}

$CollapsibleHookCategories = @(
    "ReShade",
    "ReLimiter",
    "DLSSStreamline",
    "OptiScaler",
    "DXVK",
    "ProxyHook",
    "MFGUnlocker",
    "RTXEncore",
    "DLSSGMod",
    "LumaMod",
    "BFIMod",
    "LocalProxy"
)

$LiveHookDllDescriptions = @{
    "reshade64.dll"                            = "ReShade (64-bit) — installed under a proxy/custom name or loaded by another component"
    "reshade32.dll"                            = "ReShade (32-bit) — installed under a proxy/custom name or loaded by another component"
    "dxgi.dll"                                 = "Shared proxy name (ReShade, OptiScaler, DXVK, ASI Loader, MFG Unlocker, DLSSG 2.0-3.0, or native/local library)"
    "d3d9.dll"                                 = "Shared proxy / Direct3D 9 name (ReShade, DXVK, ASI Loader, MFG Unlocker, or native/local library)"
    "d3d10.dll"                                = "Shared proxy / Direct3D 10 name (ReShade, ASI Loader, MFG Unlocker, or native/local library)"
    "d3d10core.dll"                            = "DXVK Direct3D 10 core DLL (32-bit or 64-bit, by game) or Direct3D runtime"
    "d3d11.dll"                                = "Shared proxy / Direct3D 11 name (ReShade, OptiScaler, DXVK, ASI Loader, MFG Unlocker, or native/local library)"
    "d3d12.dll"                                = "Shared proxy / Direct3D 12 name (ReShade, OptiScaler, DXVK, ASI Loader, MFG Unlocker, DLSSG 2.0-3.0, or native/local library)"
    "opengl32.dll"                             = "ReShade / OpenGL proxy or native OpenGL library"
    "dinput8.dll"                              = "Shared proxy name (ReShade, RE Framework, ASI Loader, MFG Unlocker, DLSSG 2.0-3.0, or native/local library)"
    "version.dll"                              = "Shared proxy name (ReShade, OptiScaler, ASI Loader, MFG Unlocker, DLSSG 2.0-3.0, or system/local library)"
    "winmm.dll"                                = "Shared proxy name (ReShade, OptiScaler, ASI Loader, MFG Unlocker, DLSSG 2.0-3.0, or system/local library)"
    "ddraw.dll"                                = "Shared proxy / DirectDraw name (ReShade, ASI Loader, or native/local library)"
    "xinput1_3.dll"                            = "Shared proxy / XInput 1.3 name (ReShade, ASI Loader, MFG Unlocker, or system/local library)"
    "msvcp140.dll"                             = "ReShade proxy target name or Visual C++ runtime library"
    "bink2w64.dll"                             = "Shared proxy name (ReShade, ASI Loader, MFG Unlocker, or game Bink video library)"
    "bink2w32.dll"                             = "Shared proxy name (32-bit ASI Loader or game Bink video library)"
    "binkw64.dll"                              = "Shared proxy name (64-bit ASI Loader or MFG Unlocker)"
    "binkw32.dll"                              = "Shared proxy name (32-bit ASI Loader)"
    "d3d8.dll"                                 = "DXVK (32/64-bit by game) or ASI Loader proxy name"
    "dinput.dll"                               = "32-bit ASI Loader proxy name"
    "dsound.dll"                               = "Shared proxy name (ASI Loader or MFG Unlocker)"
    "msacm32.dll"                              = "32-bit ASI Loader proxy name"
    "msvfw32.dll"                              = "32-bit ASI Loader proxy name"
    "wininet.dll"                              = "Shared proxy name (OptiScaler, ASI Loader, or MFG Unlocker)"
    "winhttp.dll"                              = "Shared proxy name (OptiScaler, ASI Loader, or MFG Unlocker)"
    "xlive.dll"                                = "32-bit ASI Loader proxy name"
    "vorbisfile.dll"                           = "32-bit ASI Loader proxy name"
    "xinput1_1.dll"                            = "Shared proxy name (ASI Loader or MFG Unlocker)"
    "xinput1_2.dll"                            = "Shared proxy name (ASI Loader or MFG Unlocker)"
    "xinput1_4.dll"                            = "Shared proxy name (ASI Loader or MFG Unlocker)"
    "xinput9_1_0.dll"                          = "Shared proxy name (ASI Loader or MFG Unlocker)"
    "xinputuap.dll"                            = "Shared proxy name (ASI Loader or MFG Unlocker)"
    "dbghelp.dll"                              = "Shared proxy name (OptiScaler or DLSSG 2.0-3.0)"
    "d3dcompiler_47.dll"                       = "HLSL shader compiler DLL shipped with some Luma mods"
    "nvngx_dlss.dll"                           = "DLSS Super Resolution (or DLSSG 2.0-3.0 dlssg_sm86\sr)"
    "nvngx_dlssd.dll"                          = "DLSS Ray Reconstruction"
    "nvngx_dlssg.dll"                          = "DLSS Frame Generation (also used in OptiScaler\streamline, DLSSG 2.0-3.0 runtime, and HSF_streamline)"
    "nvngx_dlssnr.dll"                         = "DLSS Neural Rendering (or cost scaler beside nvngx_dlssnr_real.dll / RTX Encore)"
    "nvngx_dlssnr_real.dll"                    = "Real DLSS Neural Rendering runtime kept beside the cost scaler's nvngx_dlssnr.dll"
    "nvngx.dll_dlssnr.dll"                     = "OptiScaler DLSS Neural Rendering and F5 build DLL"
    "nvngx_latewarp.dll"                       = "NVIDIA Latewarp (optional DLL for FrameWarp)"
    "sl.interposer.dll"                        = "NVIDIA Streamline interposer DLL"
    "sl.common.dll"                            = "NVIDIA Streamline common DLL"
    "sl.dlss.dll"                              = "NVIDIA Streamline DLSS module"
    "sl.dlss_d.dll"                            = "NVIDIA Streamline DLSS-D / Ray Reconstruction module"
    "sl.dlss_g.dll"                            = "NVIDIA Streamline DLSS Frame Generation module"
    "sl.reflex.dll"                            = "NVIDIA Streamline Reflex module"
    "sl.pcl.dll"                               = "NVIDIA Streamline PCL (Ping / Latency) module"
    "sl.nis.dll"                               = "NVIDIA Streamline NIS module"
    "sl.deepdvc.dll"                           = "NVIDIA Streamline DeepDVC module"
    "sl.directsr.dll"                          = "NVIDIA Streamline DirectSR module"
    "sl.nvperf.dll"                            = "NVIDIA Streamline NVPerf module"
    "optiscaler.dll"                           = "OptiScaler upscaler/frame-gen DLL (often renamed to a proxy DLL)"
    "amd_fidelityfx_dx12.dll"                  = "AMD FidelityFX DirectX 12 DLL (OptiScaler)"
    "amd_fidelityfx_vk.dll"                    = "AMD FidelityFX Vulkan DLL (OptiScaler)"
    "amd_fidelityfx_loader_dx12.dll"           = "AMD FidelityFX DirectX 12 loader DLL (OptiScaler / Batman: Arkham City DLAA mod)"
    "amd_fidelityfx_loader_vk.dll"             = "AMD FidelityFX Vulkan loader DLL (OptiScaler)"
    "amd_fidelityfx_upscaler_dx12.dll"         = "AMD FidelityFX DirectX 12 upscaler DLL (OptiScaler / Batman: Arkham City DLAA mod)"
    "amd_fidelityfx_upscaler_vk.dll"           = "AMD FidelityFX Vulkan upscaler DLL (OptiScaler)"
    "amd_fidelityfx_framegeneration_dx12.dll"  = "AMD FidelityFX DirectX 12 frame generation DLL (OptiScaler)"
    "amd_fidelityfx_framegeneration_vk.dll"    = "AMD FidelityFX Vulkan frame generation DLL (OptiScaler)"
    "libxess.dll"                              = "Intel XeSS upscaling DLL (OptiScaler / RTX Encore)"
    "libxess_dx11.dll"                         = "Intel XeSS DirectX 11 DLL (OptiScaler)"
    "libxess_fg.dll"                           = "Intel XeSS Frame Generation DLL (OptiScaler / MFG Unlocker / RTX Encore / HSF)"
    "libxell.dll"                              = "Intel XeLL low-latency DLL (OptiScaler / MFG Unlocker / RTX Encore / HSF)"
    "d3d12core.dll"                            = "OptiScaler D3D12_OptiScaler\D3D12Core.dll"
    "fakenvapi.dll"                            = "Fake NVAPI DLL (OptiScaler)"
    "dlssg_to_fsr3.dll"                        = "DLSSG-to-FSR3 frame generation bridge DLL (OptiScaler)"
    "dlssg_to_fsr3_amd_is_better.dll"          = "DLSSG-to-FSR3 variant DLL (OptiScaler)"
    "dlss-enabler-headless.dll"                = "DLSS Enabler headless DLL in the OptiScaler folder"
    "f5low.dll"                                = "OptiScaler F5 build plugin DLL"
    "params_builder.dll"                       = "OptiScaler DLSS NR build params_builder DLL"
    "dxgi_dxvk.dll"                            = "DXVK dxgi DLL when another file holds dxgi.dll (also Source engine games)"
    "mfgunlocker.dll"                          = "Universal MFG Unlocker DLL (kept as MFGUnlocker.dll when HSF loads it)"
    "rtxmfg.dll"                               = "Universal MFG Unlocker / RTXMFG DLL"
    "rtx40mfgcore.dll"                         = "Legacy MFG Unlocker core DLL (RTX40MFG)"
    "rtx-encore.dll"                           = "RTX Encore DLL"
    "dxcompiler.dll"                           = "DirectX Shader Compiler DLL used by RTX Encore / RTX Hair"
    "dxil.dll"                                 = "DirectX Intermediate Language DLL used by RTX Encore / RTX Hair"
    "sm86_backend.dll"                         = "DLSSG 2.0-3.0 SM86 backend DLL"
    "fg_kernels.dll"                           = "DLSSG 2.0-3.0 frame generation kernels DLL"
    "sr_kernels.dll"                           = "DLSSG 2.0-3.0 super resolution kernels DLL"
    "xefg_kernels.dll"                         = "DLSSG 2.0-3.0 XeFG kernels DLL"
    "bfipresentervk.dll"                       = "BFI Presenter 64-bit Vulkan layer DLL"
    "bfipresentervk32.dll"                     = "BFI Presenter 32-bit Vulkan layer DLL"
}

function Get-LiveHookDllDescription {
    param([string]$ModuleName)
    $name = ([string]$ModuleName).ToLowerInvariant()
    if ($LiveHookDllDescriptions.ContainsKey($name)) {
        return $LiveHookDllDescriptions[$name]
    }
    if ($name -match '^luma.*\.dll$') {
        return "Luma mod DLL (named per game by the mod)"
    }
    return ""
}

$LiveHookFeatures = [ordered]@{
    Steam = @{
        Label   = "Steam Overlay / Vulkan Layer"
        Off     = "Steam Library > right-click game > Properties > General > turn off Enable the Steam Overlay while in-game (or block via Bloat & Overlay Blocker tab)."
        Cost    = "Loses Steam overlay chat, invites, screenshots, or purchase UI."
        Restart = "Restart the game for a fresh module check."
    }
    Discord = @{
        Label   = "Discord Overlay"
        Off     = "Discord > User Settings > Game Overlay > disable for this game or toggle off Enable Overlay."
        Cost    = "Loses Discord in-game controls and notifications."
        Restart = "Restart the game if its module stays loaded."
    }
    Epic = @{
        Label   = "Epic Online Services (EOS) Overlay"
        Off     = "Block EOSOVH-Win32/64-Shipping.dll in ZeroHook's Bloat & Overlay Blocker tab."
        Cost    = "Disables Shift+F3 Epic social overlay inside EOS-integrated titles."
        Restart = "Restart the game after blocking the DLL."
    }
    EA = @{
        Label   = "EA In-Game Overlay"
        Off     = "EA app > Settings > Application > In-game overlay > Off."
        Cost    = "EA in-game invites and messages may be unavailable."
        Restart = "Restart the game to verify."
    }
    Ubisoft = @{
        Label   = "Ubisoft Connect Overlay"
        Off     = "Ubisoft Connect PC > Settings > General > disable in-game overlay."
        Cost    = "Ubisoft overlay features will be unavailable across games."
        Restart = "Restart the game to verify."
    }
    GOG = @{
        Label   = "GOG Galaxy Overlay"
        Off     = "GOG Galaxy > Settings > Game features > uncheck In-game overlay."
        Cost    = "Disables GOG Galaxy overlay, achievements popups, and chat."
        Restart = "Restart the game to verify."
    }
    Overwolf = @{
        Label   = "Overwolf Overlay / Capture Hook"
        Off     = "Open Overwolf Settings > Overlay & Hotkeys > disable overlay for this game, or exit Overwolf before playing."
        Cost    = "Disables Overwolf companion apps and recording overlays."
        Restart = "Restart the game after disabling."
    }
    OBS = @{
        Label   = "OBS / Streamlabs Game Capture"
        Off     = "In OBS Studio / Streamlabs, disable the Game Capture source targeting this game."
        Cost    = "Game Capture source will go blank during capture/streaming."
        Restart = "Close OBS normally if needed, then restart the game."
    }
    RTSS = @{
        Label   = "RivaTuner Statistics Server (RTSS)"
        Off     = "Open RTSS, select/add the game executable, and set Application detection level to None."
        Cost    = "May also stop RTSS frame limiting and on-screen display for this title."
        Restart = "Restart the game after changing detection level."
    }
    NVIDIA = @{
        Label   = "NVIDIA Capture / Overlay"
        Off     = "Press Alt+Z to disable Instant Replay, or turn off NVIDIA Overlay in NVIDIA App > Settings."
        Cost    = "Disables instant replay clips and in-game overlay tools."
        Restart = "Restart the game if needed for a fresh module snapshot."
    }
    AMD = @{
        Label   = "AMD Software In-Game Overlay / Instant Replay"
        Off     = "AMD Software: Adrenalin Edition > Settings (Gear) > Preferences > disable In-Game Overlay."
        Cost    = "Disables AMD overlay hotkey (Alt+R) and instant replay capture."
        Restart = "Restart the game to verify."
    }
    ReShade = @{
        Label   = "ReShade"
        Off     = "Open the in-game ReShade overlay and toggle Effects off using your configured key."
        Cost    = "Disables shader/color/HDR effects (DLL may remain loaded)."
        Restart = "Toggle effects back on to undo, or use the installer/mod manager to remove."
    }
    ReLimiter = @{
        Label   = "ReLimiter"
        Off     = "Open ReLimiter in ReShade and disable the frame limiter for this title."
        Cost    = "Frame cap and pacing will change; verify game/driver limiters if needed."
        Restart = "Re-enable in ReLimiter to undo."
    }
    DLSSStreamline = @{
        Label   = "DLSS / Streamline / Latewarp / Neural Rendering DLL"
        Off     = "Change upscaling, frame generation, or reflex/low-latency settings in-game or remove/restore mod DLLs in the game folder."
        Cost    = "Disables DLSS upscaling, frame generation, reflex, or neural rendering mods."
        Restart = "Restart the game after modifying game-folder files or settings."
    }
    OptiScaler = @{
        Label   = "OptiScaler / FSR / XeSS / Frame-Gen Bridge DLL"
        Off     = "Disable or remove OptiScaler / FSR / XeSS / DLSS-to-FSR3 / DLSS Enabler files from the game folder."
        Cost    = "Reverts custom upscaler or frame-generation replacement back to native rendering."
        Restart = "Restart the game after changing game-folder files."
    }
    DXVK = @{
        Label   = "DXVK Translation DLL"
        Off     = "Remove or rename the DXVK DLL in the game folder to revert to native Direct3D."
        Cost    = "Changes Direct3D-to-Vulkan translation behavior and shader/performance profile."
        Restart = "Restart the game after changing game-folder files."
    }
    ProxyHook = @{
        Label   = "Shared DLL Proxy / ASI Loader / Hook Target"
        Off     = "Inspect the module path; if it is a mod proxy (ASI Loader, ReShade, OptiScaler, MFG Unlocker), remove/disable the mod in the game folder."
        Cost    = "May be required by mods or native game/Windows components depending on the file path."
        Restart = "Restart the game after changing game-folder files."
    }
    MFGUnlocker = @{
        Label   = "Universal MFG Unlocker / RTXMFG DLL"
        Off     = "Remove or disable MFGUnlocker / RTXMFG files in the game or mod loader folder."
        Cost    = "Disables multi-frame-generation unlocker behavior."
        Restart = "Restart the game after changing files."
    }
    RTXEncore = @{
        Label   = "RTX Encore / RTX Hair / DXC Compiler DLL"
        Off     = "Remove or disable RTX Encore files in the game or plugin folder."
        Cost    = "Disables RTX Encore or RTX Hair features."
        Restart = "Restart the game after changing files."
    }
    DLSSGMod = @{
        Label   = "DLSSG 2.0-3.0 Backend / Kernel DLL"
        Off     = "Remove or disable the DLSSG mod folder/files in the game directory."
        Cost    = "Disables DLSSG frame generation replacement kernels."
        Restart = "Restart the game after changing files."
    }
    LumaMod = @{
        Label   = "Luma HDR / Shader Compiler DLL"
        Off     = "Remove or disable Luma mod files from the game folder."
        Cost    = "Disables Luma HDR / shader overrides."
        Restart = "Restart the game after changing files."
    }
    BFIMod = @{
        Label   = "BFI Presenter Vulkan Layer DLL"
        Off     = "Remove or disable BFIPresenterVK files or Vulkan layer entries."
        Cost    = "Disables Black Frame Insertion Vulkan presentation."
        Restart = "Restart the game after changing files."
    }
    GenericOverlay = @{
        Label   = "Third-Party FPS / Overlay Hook"
        Off     = "Check the DLL path shown above and disable the overlay in its parent utility or block via ZeroHook."
        Cost    = "Disables that utility's on-screen display or overlay injection."
        Restart = "Restart the game after disabling."
    }
    ControllerHook = @{
        Label   = "PlayStation / DualSense Controller Hook"
        Off     = "If unwanted, block via ZeroHook or disable controller companion software (keep allowed if using DualSense features)."
        Cost    = "Blocking may disable adaptive triggers, haptics, or controller remapping in some games."
        Restart = "Restart the game after changing."
    }
    LocalProxy = @{
        Label   = "Game-Folder Graphics / Hook Library"
        Off     = "Identify the local DLL via your game/mod manager before altering or removing it."
        Cost    = "Some games or mods depend on local graphics or input proxy DLLs."
        Restart = "Restore via original installer or mod manager if needed."
    }
    WindowsCapture = @{
        Label   = "Windows Background Capture"
        Off     = "Windows Settings > Gaming > Captures > turn off Record what happened."
        Cost    = "Disables background recording of past gameplay moments."
        Restart = "Rescan to confirm HistoricalCaptureEnabled registry state."
    }
}

$IgnoredForegroundProcesses = @(
    "pwsh", "powershell", "WindowsTerminal", "OpenConsole", "conhost", "cmd",
    "explorer", "ApplicationFrameHost", "SystemSettings", "Taskmgr",
    "steam", "steamwebhelper", "EpicGamesLauncher"
)

$VulkanKeys = @(
    "HKLM:\SOFTWARE\Khronos\Vulkan\ImplicitLayers",
    "HKLM:\SOFTWARE\WOW6432Node\Khronos\Vulkan\ImplicitLayers"
)

$BlockedLayerKeywords = @("steam", "discord", "epic", "eos", "obs", "overwolf", "rtss", "rivatuner", "razer")

$TargetServicePatterns = @(
    "MSI_*", "MSICenter*", "MysticLight*", "Mystic_Light*", "LightKeeper*", "VoiceControlService",
    "Kingston*", "FuryCtrl*", "FURYcontroller*", "FURY_controller*", "KCCService*",
    "SamsungMagician*", "Samsung Magician*",
    "ArmouryCrate*", "AsusCertService", "ASUS*", "LightingService*", "ROGLiveService*", "Aac3572MbHal*",
    "Corsair*", "iCUE*",
    "Gigabyte*", "GBT_*", "RGBFusion*", "SelLed*",
    "ASRock*", "AsrPolychrome*",
    "NZXT*", "CAMHelper*",
    "LGHUB*", "logi_lamparray*",
    "Razer*",
    "SteelSeries*",
    "OpenRGB*", "SignalRgb*",
    "OneDrive", "Dropbox",
    "Adobe*Update*", "Adobe*Updater*", "ARMservice"
)

$StartupUtilityKeywords = @(
    "msi center", "msicenter", "mystic light", "mysticlight", "mystic_light", "dragon center", "lightkeeper",
    "kingston", "fury ctrl", "furyctrl", "furycontroller",
    "samsung magician", "samsungmagician",
    "armoury crate", "armourycrate", "aura", "asus", "rog live",
    "corsair", "icue",
    "gigabyte", "gcc", "rgb fusion", "rgbfusion", "easytune",
    "asrock", "polychrome",
    "nzxt", "cam",
    "lghub", "logitech g hub",
    "razer", "synapse", "cortex",
    "steelseries",
    "openrgb", "signalrgb",
    "onedrive", "dropbox", "adobe", "creative cloud"
)

$StartupLocations = @(
    @{ Run = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"; Approved = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" },
    @{ Run = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"; Approved = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" },
    @{ Run = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"; Approved = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32" }
)

$StartupFolderPaths = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
)
$StartupBackupDir = "$env:ProgramData\ZeroHook_StartupBackup"
$LocalInstallDir  = "$env:ProgramData\ZeroHook"
$LocalScriptPath  = Join-Path $LocalInstallDir "ZeroHook.ps1"
$ExclusionsFile   = Join-Path $StartupBackupDir "exclusions.json"
$LogDir           = Join-Path $env:LOCALAPPDATA "ZeroHook\Logs"
$DiagLogFile      = Join-Path $LogDir "zerohook-current.log"
$MaxLogLines      = 1500
$Script:DiagWriteCount = 0

function Hide-Username {
    param([string]$Text)
    if ($env:USERPROFILE) {
        return $Text -ireplace [regex]::Escape($env:USERPROFILE), "C:\Users\%USERNAME%"
    }
    return $Text
}

function Format-DiagnosticLine {
    param([string]$Text)
    $clean = Hide-Username ([string]$Text)
    return ($clean -replace "`r?`n", " | ")
}

function Trim-DiagnosticLogFile {
    try {
        if (Test-Path -LiteralPath $DiagLogFile) {
            $lines = @(Get-Content -LiteralPath $DiagLogFile -Encoding UTF8 -ErrorAction SilentlyContinue)
            if ($lines.Count -gt $MaxLogLines) {
                $lines | Select-Object -Last $MaxLogLines | Set-Content -LiteralPath $DiagLogFile -Encoding UTF8 -Force
            }
        }
    } catch {}
}

function Write-DiagnosticLog {
    param(
        [string]$Level = "INFO",
        [string]$Source = "APP",
        [string]$Message = "",
        [switch]$ForceTrim
    )
    try {
        if (-not (Test-Path -LiteralPath $LogDir)) {
            New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
        }
        $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $safeMsg = Format-DiagnosticLine -Text $Message
        $entry = "[$ts] [$Level] [$Source] $safeMsg"

        Add-Content -LiteralPath $DiagLogFile -Value $entry -Encoding UTF8 -ErrorAction SilentlyContinue

        $Script:DiagWriteCount++
        if ($ForceTrim -or (($Script:DiagWriteCount % 50) -eq 0)) {
            Trim-DiagnosticLogFile
        }
    } catch {}
}

function Copy-BugReportToClipboard {
    param(
        [string]$FallbackTitle = "ZeroHook Diagnostic Log"
    )
    Trim-DiagnosticLogFile
    $cv = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue
    $osInfo = if ($cv -and $cv.ProductName) {
        if ($cv.DisplayVersion) { "$($cv.ProductName) ($($cv.DisplayVersion))" } else { $cv.ProductName }
    } else {
        [System.Environment]::OSVersion.VersionString
    }
    $psVer  = $PSVersionTable.PSVersion.ToString()
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $exePath = try { Hide-Username ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) } catch { "Unknown" }

    $recentLines = if (Test-Path -LiteralPath $DiagLogFile) {
        @(Get-Content -LiteralPath $DiagLogFile -Encoding UTF8 -ErrorAction SilentlyContinue | Select-Object -Last 400)
    } else {
        @()
    }

    if ($recentLines.Count -eq 0 -and $LogBox) {
        $uiText = (New-Object System.Windows.Documents.TextRange($LogBox.Document.ContentStart, $LogBox.Document.ContentEnd)).Text
        $recentLines = @($uiText -split "`r?`n" | Where-Object { $_.Trim() -ne "" } | ForEach-Object { Format-DiagnosticLine $_ })
    }

    $report = @(
        "=== ZeroHook Bug Report ==="
        "App: ZeroHook (Made by: GS | Build: v.1.0.0)"
        "Section: $FallbackTitle"
        "Timestamp (UTC): $((Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'))Z"
        "OS: $osInfo"
        "PowerShell: $psVer | Admin: $isAdmin"
        "Executable: $exePath"
        "--- Recent Log ---"
        ($recentLines -join "`r`n")
        "=== End Report ==="
    ) -join "`r`n"

    [System.Windows.Clipboard]::SetText($report)
    Write-DiagnosticLog -Level "INFO" -Source "CLIPBOARD" -Message "Copied bug report ($($recentLines.Count) log lines) to clipboard." -ForceTrim
}

function Get-SavedExclusions {
    if (Test-Path $ExclusionsFile) {
        try {
            $Raw = Get-Content -Path $ExclusionsFile -Raw -ErrorAction Stop | ConvertFrom-Json
            if ($null -ne $Raw) { return @($Raw) }
        } catch {}
    }
    return @()
}

function Save-Exclusions {
    param([string[]]$Ids)
    try {
        if (-not (Test-Path $StartupBackupDir)) {
            New-Item -Path $StartupBackupDir -ItemType Directory -Force | Out-Null
        }
        if (-not $Ids -or $Ids.Count -eq 0) {
            if (Test-Path $ExclusionsFile) { Remove-Item -Path $ExclusionsFile -Force -ErrorAction SilentlyContinue }
        } else {
            $Ids | ConvertTo-Json | Set-Content -Path $ExclusionsFile -Encoding UTF8 -Force
        }
    } catch {
        Write-DiagnosticLog -Level "ERROR" -Source "EXCLUSIONS" -Message "Failed saving exclusions: $($_.Exception.Message)"
    }
}

function Get-AppGroupName {
    param([string]$Text)
    $s = ([string]$Text).ToLower()
    if ($s -match "steam|steaminput|fossilize") { return "STEAM" }
    if ($s -match "discord") { return "DISCORD" }
    if ($s -match "epic|eosovh|\\eos\\") { return "EPIC / EOS" }
    if ($s -match "electronic arts|\bea\b|\\ea\\|eadesktop|eabackgroundservice|origin|igo32\.dll|igo64\.dll") { return "EA / ORIGIN" }
    if ($s -match "ubisoft|uplay|upc") { return "UBISOFT" }
    if ($s -match "gog|galaxy") { return "GOG GALAXY" }
    if ($s -match "overwolf|ow[a-z0-9_-]*\.dll") { return "OVERWOLF" }
    if ($s -match "obs|streamlabs|graphics-hook") { return "OBS / STREAMLABS" }
    if ($s -match "rtss|rivatuner") { return "RTSS / RIVATUNER" }
    if ($s -match "nvidia|nvspcap") { return "NVIDIA" }
    if ($s -match "\\amd\\|amddvr") { return "AMD" }
    if ($s -match "razer|synapse|cortex") { return "RAZER" }
    if ($s -match "sony|dualsense|ps5controller") { return "SONY / DUALSENSE" }
    if ($s -match "msi|msicenter|mystic|dragon center|lightkeeper|voicecontrolservice") { return "MSI" }
    if ($s -match "asus|armoury|aura|rog live|asuscert|lightingservice|aac3572") { return "ASUS" }
    if ($s -match "corsair|icue") { return "CORSAIR" }
    if ($s -match "gigabyte|gbt_|rgbfusion|easytune|selled") { return "GIGABYTE" }
    if ($s -match "asrock|polychrome") { return "ASROCK" }
    if ($s -match "nzxt|camhelper|\bcam\b") { return "NZXT" }
    if ($s -match "lghub|logitech|lamparray") { return "LOGITECH" }
    if ($s -match "kingston|fury|kccservice") { return "KINGSTON" }
    if ($s -match "samsung|magician") { return "SAMSUNG" }
    if ($s -match "steelseries") { return "STEELSERIES" }
    if ($s -match "openrgb|signalrgb") { return "OPENRGB / SIGNALRGB" }
    if ($s -match "onedrive") { return "ONEDRIVE" }
    if ($s -match "dropbox") { return "DROPBOX" }
    if ($s -match "adobe|acrobat|elements|creative cloud|ccxprocess|adobeipcbroker|armservice") { return "ADOBE" }
    if ($s -match "k_fps") { return "FPS / OVERLAY HOOKS" }
    if ($s -match "xbox|gamedvr|gamebar") { return "XBOX / GAME BAR" }
    return "OTHER"
}

function Test-IsEveryoneDenyRule {
    param($Rule)
    if ($Rule.AccessControlType -ne "Deny") { return $false }
    try {
        $Sid = $Rule.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier])
        return ($Sid.Value -eq "S-1-1-0")
    } catch { return $false }
}

function Get-RunningLaunchers {
    $Running = @()
    foreach ($ProcName in $LauncherProcesses) {
        $Procs = Get-Process -Name $ProcName -ErrorAction SilentlyContinue
        if ($Procs) { $Running += $Procs }
    }
    return $Running
}

function Get-OverlayDLLs {
    $Found = @()
    foreach ($BasePath in $SearchPaths) {
        if (Test-Path $BasePath) {
            if ($BasePath -like "*\Steam") {
                $Found += Get-ChildItem -Path $BasePath -File -ErrorAction SilentlyContinue |
                    Where-Object { $TargetDLLs -contains $_.Name }
            } else {
                $Found += Get-ChildItem -Path $BasePath -Recurse -File -ErrorAction SilentlyContinue |
                    Where-Object { ($TargetDLLs -contains $_.Name) -and ($_.FullName -notmatch $ExcludedPathRegex) }
            }
        }
    }
    $Found = @($Found | Sort-Object FullName -Unique)
    $Results = @()
    foreach ($F in $Found) {
        $IsBlocked = $false
        $Acl = Get-Acl -Path $F.FullName -ErrorAction SilentlyContinue
        if ($Acl) {
            foreach ($R in $Acl.Access) {
                if (Test-IsEveryoneDenyRule $R) { $IsBlocked = $true; break }
            }
        }
        $Results += [PSCustomObject]@{ Name = $F.Name; FullName = $F.FullName; IsBlocked = $IsBlocked }
    }
    return $Results
}

function Get-VulkanLayersList {
    $Layers = @()
    foreach ($Key in $VulkanKeys) {
        if (Test-Path $Key) {
            $Properties = Get-ItemProperty -Path $Key
            $Properties.PSObject.Properties | ForEach-Object {
                $Name = $_.Name
                $Val = $_.Value
                if ($Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider")) {
                    foreach ($Keyword in $BlockedLayerKeywords) {
                        if ($Name -match $Keyword) {
                            $Layers += [PSCustomObject]@{ Key = $Key; Name = $Name; IsDisabled = ($Val -eq 1) }
                            break
                        }
                    }
                }
            }
        }
    }
    return $Layers
}

function Get-GameBarStatus {
    $AppCapture = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -ErrorAction SilentlyContinue).AppCaptureEnabled
    $GameDVR = (Get-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -ErrorAction SilentlyContinue).GameDVR_Enabled
    return ($AppCapture -eq 0 -and $GameDVR -eq 0)
}

function Get-UtilityServices {
    param($AllServices = $null)
    if ($null -eq $AllServices) { $AllServices = Get-Service -ErrorAction SilentlyContinue }
    $Matched = @()
    foreach ($Svc in $AllServices) {
        if ($Svc.Name -match "LEDKeeper2_Host" -or $Svc.DisplayName -match "LEDKeeper2_Host") { continue }
        foreach ($Pattern in $TargetServicePatterns) {
            if ($Svc.Name -like $Pattern -or $Svc.DisplayName -like $Pattern) {
                $Matched += $Svc
                break
            }
        }
    }
    return ($Matched | Sort-Object Name -Unique)
}

function Get-UtilityStartupItems {
    $Items = @()
    foreach ($Loc in $StartupLocations) {
        if (Test-Path $Loc.Run) {
            $Props = Get-ItemProperty -Path $Loc.Run
            foreach ($Prop in $Props.PSObject.Properties) {
                if ($Prop.Name -in @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider")) { continue }
                $EntryName = $Prop.Name
                $EntryCmd = [string]$Prop.Value
                if ($EntryName -match "LEDKeeper2_Host" -or $EntryCmd -match "LEDKeeper2_Host") { continue }
                foreach ($Kw in $StartupUtilityKeywords) {
                    if ($EntryName.ToLower().Contains($Kw) -or $EntryCmd.ToLower().Contains($Kw)) {
                        $IsDisabled = $false
                        if (Test-Path $Loc.Approved) {
                            $AppVal = (Get-ItemProperty -Path $Loc.Approved -Name $EntryName -ErrorAction SilentlyContinue).$EntryName
                            if ($AppVal -is [byte[]] -and $AppVal.Length -ge 1 -and (($AppVal[0] -band 1) -eq 1)) { $IsDisabled = $true }
                        }
                        $Items += [PSCustomObject]@{
                            Name = $EntryName; Command = $EntryCmd; RunPath = $Loc.Run; ApprovedPath = $Loc.Approved; IsDisabled = $IsDisabled
                        }
                        break
                    }
                }
            }
        }
    }
    return $Items
}

function Get-UtilityStartupShortcuts {
    $Found = @()
    foreach ($Dir in $StartupFolderPaths) {
        if (Test-Path $Dir) {
            $Files = Get-ChildItem -Path $Dir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "desktop.ini" }
            foreach ($File in $Files) {
                if ($File.Name -match "LEDKeeper2_Host") { continue }
                foreach ($Kw in $StartupUtilityKeywords) {
                    if ($File.Name.ToLower().Contains($Kw)) {
                        $Found += [PSCustomObject]@{ Name = $File.Name; FullPath = $File.FullName; OrigFolder = $Dir; IsDisabled = $false }
                        break
                    }
                }
            }
        }
    }
    foreach ($Sub in @("User", "Common")) {
        $BDir = Join-Path $StartupBackupDir $Sub
        if (Test-Path $BDir) {
            $OrigDir = if ($Sub -eq "User") { $StartupFolderPaths[0] } else { $StartupFolderPaths[1] }
            $Files = Get-ChildItem -Path $BDir -File -ErrorAction SilentlyContinue
            foreach ($File in $Files) {
                $Found += [PSCustomObject]@{ Name = $File.Name; FullPath = $File.FullName; OrigFolder = $OrigDir; IsDisabled = $true }
            }
        }
    }
    return $Found
}

function Get-UtilityScheduledTasks {
    param($AllTasks = $null)
    if ($null -eq $AllTasks) { $AllTasks = Get-ScheduledTask -ErrorAction SilentlyContinue }
    $Matched = @()
    foreach ($Task in $AllTasks) {
        if ($Task.TaskName -eq $TaskName) { continue }
        if ($Task.TaskPath -like "\Microsoft\Windows\*") { continue }
        if ($Task.TaskName -match "LEDKeeper2_Host") { continue }
        $FullString = "$($Task.TaskPath)$($Task.TaskName)".ToLower()
        foreach ($Kw in $StartupUtilityKeywords) {
            if ($FullString.Contains($Kw)) { $Matched += $Task; break }
        }
    }
    return $Matched
}

function Ensure-ForegroundWin32 {
    if (-not ("ZeroHook.Win32Foreground" -as [type])) {
        Add-Type -ErrorAction Stop -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
namespace ZeroHook {
    public static class Win32Foreground {
        [DllImport("user32.dll")] private static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out int lpdwProcessId);
        public static int GetForegroundPid() {
            int pid = 0;
            IntPtr hwnd = GetForegroundWindow();
            if (hwnd == IntPtr.Zero) return 0;
            uint tid = GetWindowThreadProcessId(hwnd, out pid);
            return tid != 0 ? pid : 0;
        }
    }
}
"@
    }
}

function Get-LiveHookFeatureKey {
    param([string]$ModuleName, [string]$ModulePath, [string]$GamePath)
    $name = ([string]$ModuleName).ToLowerInvariant()
    if ($LiveHookMap.ContainsKey($name)) { return $LiveHookMap[$name] }
    if ($name -match '^luma.*\.dll$') { return "LumaMod" }
    if ($name -in @("igo32.dll", "igo64.dll") -and $ModulePath -match '(?i)[\\/](Electronic Arts|EA Desktop|Origin)[\\/]') { return "EA" }
    if ($name -in @("overlay32.dll", "overlay64.dll") -and $ModulePath -match '(?i)[\\/]Ubisoft Game Launcher[\\/]') { return "Ubisoft" }
    if ($name -in @("dxgi.dll", "d3d9.dll", "d3d11.dll", "d3d12.dll", "opengl32.dll", "dinput8.dll", "winmm.dll") -and
        $GamePath -and $ModulePath -and ([IO.Path]::GetDirectoryName($ModulePath) -ieq [IO.Path]::GetDirectoryName($GamePath))) {
        try {
            $ver = [Diagnostics.FileVersionInfo]::GetVersionInfo($ModulePath)
            if ($ver.ProductName -match '(?i)\bReShade\b' -or $ver.OriginalFilename -match '(?i)^ReShade') { return "ReShade" }
        } catch {}
        return "LocalProxy"
    }
    return $null
}

function Get-ProcessHookSnapshot {
    param([int]$TargetPid, $ExpectedStartUtc = $null, [string]$GamePath = "")
    $byFeature = @{}
    $allModules = [System.Collections.Generic.List[object]]::new()
    $state = "PASS"
    $message = ""
    $proc = $null

    try {
        $proc = Get-Process -Id $TargetPid -ErrorAction Stop
        if ($null -ne $ExpectedStartUtc) {
            $actualStart = $proc.StartTime.ToUniversalTime()
            if ([Math]::Abs(($actualStart - $ExpectedStartUtc).TotalSeconds) -gt 2) {
                throw "Process start time changed (PID reused or process restarted)."
            }
        }
        $modules = $proc.Modules
        if ($null -eq $modules -or $modules.Count -eq 0) {
            throw "Windows returned an empty or inaccessible module list."
        }
        foreach ($m in $modules) {
            $modName = [string]$m.ModuleName
            $modPath = [string]$m.FileName
            $item = [PSCustomObject]@{
                Name        = $modName
                Path        = $modPath
                Description = (Get-LiveHookDllDescription -ModuleName $modName)
                Key         = "$modName|$modPath"
            }
            [void]$allModules.Add($item)
            $feat = Get-LiveHookFeatureKey -ModuleName $item.Name -ModulePath $item.Path -GamePath $GamePath
            if ($feat) {
                if (-not $byFeature.ContainsKey($feat)) { $byFeature[$feat] = [System.Collections.Generic.List[object]]::new() }
                [void]$byFeature[$feat].Add($item)
            }
        }
        $proc.Refresh()
        if ($proc.HasExited) { throw "Target process exited during module scan." }
    } catch {
        $state = "INCONCLUSIVE"
        $message = $_.Exception.GetBaseException().Message
        $byFeature.Clear()
    } finally {
        if ($proc) { $proc.Dispose() }
    }

    $findings = @()
    foreach ($k in $LiveHookFeatures.Keys) {
        if ($byFeature.ContainsKey($k)) {
            $findings += [PSCustomObject]@{ Id = $k; Label = $LiveHookFeatures[$k].Label; Modules = $byFeature[$k].ToArray(); Scope = "Loaded in process" }
        }
    }

    $historicalCapture = "Unknown"
    try {
        $val = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "HistoricalCaptureEnabled" -ErrorAction Stop
        if ($null -ne $val.HistoricalCaptureEnabled) {
            if ([int]$val.HistoricalCaptureEnabled -eq 1) {
                $historicalCapture = "Enabled"
                $findings += [PSCustomObject]@{ Id = "WindowsCapture"; Label = $LiveHookFeatures["WindowsCapture"].Label; Modules = @(); Scope = "HistoricalCaptureEnabled = 1" }
            } else { $historicalCapture = "Off" }
        }
    } catch {}

    return [PSCustomObject]@{
        State = $state; Message = $message; Findings = $findings; TotalModuleCount = $allModules.Count; HistoricalCapture = $historicalCapture
    }
}

if ($AutoBlock) {
    Write-DiagnosticLog -Level "INFO" -Source "AUTOBLOCK" -Message "Starting scheduled AutoBlock run."
    $ExcludedIds = Get-SavedExclusions
    $errCount = 0

    foreach ($File in (Get-OverlayDLLs)) {
        if ($ExcludedIds -contains "DLL|$($File.FullName)") { continue }
        try {
            $Acl = Get-Acl -Path $File.FullName
            $Rule = New-Object System.Security.AccessControl.FileSystemAccessRule($EveryoneSID, "ReadAndExecute", "Deny")
            $Acl.SetAccessRule($Rule)
            Set-Acl -Path $File.FullName -AclObject $Acl
        } catch {
            $errCount++
            Write-DiagnosticLog -Level "ERROR" -Source "AUTOBLOCK" -Message "DLL block failed ($($File.FullName)): $($_.Exception.Message)"
        }
    }
    foreach ($Layer in (Get-VulkanLayersList)) {
        if ($ExcludedIds -contains "VULKAN|$($Layer.Key)|$($Layer.Name)") { continue }
        try {
            Set-ItemProperty -Path $Layer.Key -Name $Layer.Name -Value 1 -Type DWord
        } catch {
            $errCount++
            Write-DiagnosticLog -Level "ERROR" -Source "AUTOBLOCK" -Message "Vulkan layer disable failed ($($Layer.Name)): $($_.Exception.Message)"
        }
    }
    if ($ExcludedIds -notcontains "GAMEBAR|XBOX") {
        try {
            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord
            New-Item -Path "HKCU:\System\GameConfigStore" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord
            Remove-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -ErrorAction SilentlyContinue
        } catch {
            $errCount++
            Write-DiagnosticLog -Level "ERROR" -Source "AUTOBLOCK" -Message "GameBar disable failed: $($_.Exception.Message)"
        }
    }
    foreach ($Svc in (Get-UtilityServices)) {
        if ($ExcludedIds -contains "SVC|$($Svc.Name)") { continue }
        try {
            if ($Svc.StartType -ne "Manual" -and $Svc.StartType -ne "Disabled") { Set-Service -Name $Svc.Name -StartupType Manual -ErrorAction Stop }
            if ($Svc.Status -eq "Running") { Stop-Service -Name $Svc.Name -Force -ErrorAction SilentlyContinue }
        } catch {
            $errCount++
            Write-DiagnosticLog -Level "ERROR" -Source "AUTOBLOCK" -Message "Service disable failed ($($Svc.Name)): $($_.Exception.Message)"
        }
    }
    $DisabledBytes = [byte[]](0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    foreach ($Item in (Get-UtilityStartupItems)) {
        if ($ExcludedIds -contains "RUN|$($Item.RunPath)|$($Item.Name)") { continue }
        try {
            if (-not (Test-Path $Item.ApprovedPath)) { New-Item -Path $Item.ApprovedPath -Force | Out-Null }
            Set-ItemProperty -Path $Item.ApprovedPath -Name $Item.Name -Value $DisabledBytes -Type Binary -ErrorAction Stop
        } catch {
            $errCount++
            Write-DiagnosticLog -Level "ERROR" -Source "AUTOBLOCK" -Message "Startup item disable failed ($($Item.Name)): $($_.Exception.Message)"
        }
    }
    foreach ($Sc in (Get-UtilityStartupShortcuts | Where-Object { -not $_.IsDisabled })) {
        if ($ExcludedIds -contains "SHORTCUT|$($Sc.OrigFolder)|$($Sc.Name)") { continue }
        try {
            $Sub = if ($Sc.OrigFolder -eq $StartupFolderPaths[0]) { "User" } else { "Common" }
            $DestDir = Join-Path $StartupBackupDir $Sub
            if (-not (Test-Path $DestDir)) { New-Item -Path $DestDir -ItemType Directory -Force | Out-Null }
            Move-Item -Path $Sc.FullPath -Destination (Join-Path $DestDir $Sc.Name) -Force -ErrorAction Stop
        } catch {
            $errCount++
            Write-DiagnosticLog -Level "ERROR" -Source "AUTOBLOCK" -Message "Shortcut move failed ($($Sc.Name)): $($_.Exception.Message)"
        }
    }
    foreach ($Task in (Get-UtilityScheduledTasks)) {
        if ($ExcludedIds -contains "TASK|$($Task.TaskPath)$($Task.TaskName)") { continue }
        try {
            if ($Task.State -ne "Disabled") { Disable-ScheduledTask -TaskName $Task.TaskName -TaskPath $Task.TaskPath -ErrorAction Stop | Out-Null }
        } catch {
            $errCount++
            Write-DiagnosticLog -Level "ERROR" -Source "AUTOBLOCK" -Message "Task disable failed ($($Task.TaskName)): $($_.Exception.Message)"
        }
    }

    Write-DiagnosticLog -Level "INFO" -Source "AUTOBLOCK" -Message "Completed scheduled AutoBlock run (Errors: $errCount)." -ForceTrim
    return
}

# --- WPF GUI SETUP & LOGO LOADING ---
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

Write-DiagnosticLog -Level "INFO" -Source "APP" -Message "ZeroHook GUI started (Build: v.1.0.0)."

function Get-ZeroHookLogo {
    param([string]$ExplicitPath = "")
    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
        $candidates += $ExplicitPath
    }
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
    $exeDir = ""
    try {
        $mainMod = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        if ($mainMod) { $exeDir = [System.IO.Path]::GetDirectoryName($mainMod) }
    } catch {}

    foreach ($dir in @($scriptDir, $exeDir, $LocalInstallDir, (Get-Location).Path)) {
        if ($dir) {
            $candidates += (Join-Path $dir "icon-preview.png")
            $candidates += (Join-Path $dir "zerohook-logo.png")
            $candidates += (Join-Path $dir "logo.png")
        }
    }

    foreach ($p in ($candidates | Select-Object -Unique)) {
        if ($p -and (Test-Path -LiteralPath $p)) {
            try {
                $bytes = [System.IO.File]::ReadAllBytes($p)
                $ms = New-Object System.IO.MemoryStream(,$bytes)
                $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                $bmp.BeginInit()
                $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                $bmp.StreamSource = $ms
                $bmp.EndInit()
                $bmp.Freeze()
                return $bmp
            } catch {}
        }
    }

    try {
        $Size = 64
        $Dv = New-Object System.Windows.Media.DrawingVisual
        $Dc = $Dv.RenderOpen()
        $BgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#18181B")
        $BorderPen = New-Object System.Windows.Media.Pen(([System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")), 4)
        $Dc.DrawRoundedRectangle($BgBrush, $BorderPen, (New-Object System.Windows.Rect(2, 2, 60, 60)), 14, 14)
        $Tf = New-Object System.Windows.Media.Typeface((New-Object System.Windows.Media.FontFamily("Segoe UI")), [System.Windows.FontStyles]::Normal, [System.Windows.FontWeights]::Bold, [System.Windows.FontStretches]::Normal)
        $Ft = New-Object System.Windows.Media.FormattedText("ZH", [System.Globalization.CultureInfo]::InvariantCulture, [System.Windows.FlowDirection]::LeftToRight, $Tf, 22, ([System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")))
        $Dc.DrawText($Ft, (New-Object System.Windows.Point(([Math]::Max(4, ((64 - $Ft.Width) / 2.0))), ([Math]::Max(4, ((64 - $Ft.Height) / 2.0) - 1)))))
        $Dc.Close()
        $Rtb = New-Object System.Windows.Media.Imaging.RenderTargetBitmap($Size, $Size, 96, 96, [System.Windows.Media.PixelFormats]::Pbgra32)
        $Rtb.Render($Dv)
        $Rtb.Freeze()
        return $Rtb
    } catch {
        return $null
    }
}

$ZeroHookLogo = Get-ZeroHookLogo

[xml]$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ZeroHook"
        Height="1014" Width="1401" MinHeight="640" MinWidth="920"
        WindowStartupLocation="CenterScreen"
        Background="#161618" Foreground="#E4E4E7"
        FontFamily="Segoe UI">

    <Window.Resources>
        <Style x:Key="CardButton" TargetType="Button">
            <Setter Property="Background" Value="#202024"/>
            <Setter Property="BorderBrush" Value="#2E2E34"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="8,4"/>
            <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
            <Setter Property="VerticalContentAlignment" Value="Stretch"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="5" Padding="{TemplateBinding Padding}">
                            <ContentPresenter/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#27272C"/>
                                <Setter TargetName="border" Property="BorderBrush" Value="#4A4A55"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#1C1C20"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ActionButton" TargetType="Button">
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Height" Value="28"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="5">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Opacity" Value="0.88"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Opacity" Value="0.75"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="14">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <Grid Grid.Row="0" Margin="0,0,0,8">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                <Image x:Name="ImgHeaderLogo" Width="28" Height="28" Margin="0,0,10,0" VerticalAlignment="Center"
                       RenderOptions.BitmapScalingMode="HighQuality"/>
                <TextBlock Text="ZeroHook" FontSize="18" FontWeight="Bold" Foreground="#FFFFFF" VerticalAlignment="Center"/>
                <TextBlock Text="Made by: GS  |  Build: v.1.0.0"
                           FontSize="11" Foreground="#71717A" Margin="10,2,0,0" VerticalAlignment="Center"/>
                <TextBlock Text="- Bloat &amp; Overlay Blocker + Real-Time Game DLL Hook Detector"
                           FontSize="11.5" Foreground="#A1A1AA" Margin="10,1,0,0" VerticalAlignment="Center"/>
            </StackPanel>
            <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                <Button x:Name="BtnCopyBugReport" Content="Copy Log for Dev"
                        Background="#202024" Foreground="#4ADE80" FontWeight="SemiBold" FontSize="11.5"
                        Padding="10,3" Height="25" Margin="0,0,6,0" VerticalAlignment="Center" Cursor="Hand">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border x:Name="b" Background="{TemplateBinding Background}" BorderBrush="#3F3F46" BorderThickness="1" CornerRadius="5" Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="b" Property="Background" Value="#27272C"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
                <Button x:Name="BtnAboutInfo" Content="What It Blocks / Info"
                        Background="#202024" Foreground="#38BDF8" FontWeight="SemiBold" FontSize="11.5"
                        Padding="10,3" Height="25" Margin="0,0,6,0" VerticalAlignment="Center" Cursor="Hand">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border x:Name="b" Background="{TemplateBinding Background}" BorderBrush="#3F3F46" BorderThickness="1" CornerRadius="5" Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="b" Property="Background" Value="#27272C"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
                <Button x:Name="BtnRefresh" Content="Refresh Status"
                        Background="#27272A" Foreground="#E4E4E7" FontWeight="SemiBold" FontSize="11.5"
                        Padding="10,3" Height="25" VerticalAlignment="Center" Cursor="Hand">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border x:Name="b" Background="{TemplateBinding Background}" BorderBrush="#3F3F46" BorderThickness="1" CornerRadius="5" Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="b" Property="Background" Value="#323238"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
            </StackPanel>
        </Grid>

        <TabControl x:Name="MainTabs" Grid.Row="1" Background="#161618" BorderBrush="#2E2E34" BorderThickness="1" Padding="8">
            <TabControl.Resources>
                <Style TargetType="TabItem">
                    <Setter Property="Foreground" Value="#A1A1AA"/>
                    <Setter Property="FontWeight" Value="SemiBold"/>
                    <Setter Property="FontSize" Value="12"/>
                    <Setter Property="Padding" Value="14,6"/>
                    <Setter Property="Background" Value="#202024"/>
                    <Setter Property="Template">
                        <Setter.Value>
                            <ControlTemplate TargetType="TabItem">
                                <Border x:Name="bd" Background="{TemplateBinding Background}" BorderBrush="#2E2E34" BorderThickness="1" CornerRadius="5,5,0,0" Margin="0,0,4,0" Padding="{TemplateBinding Padding}" Cursor="Hand">
                                    <ContentPresenter ContentSource="Header" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Border>
                                <ControlTemplate.Triggers>
                                    <Trigger Property="IsSelected" Value="True">
                                        <Setter TargetName="bd" Property="Background" Value="#27272E"/>
                                        <Setter Property="Foreground" Value="#FFFFFF"/>
                                    </Trigger>
                                    <Trigger Property="IsMouseOver" Value="True">
                                        <Setter TargetName="bd" Property="Background" Value="#24242B"/>
                                    </Trigger>
                                </ControlTemplate.Triggers>
                            </ControlTemplate>
                        </Setter.Value>
                    </Setter>
                </Style>
            </TabControl.Resources>

            <TabItem Header="Bloat &amp; Overlay Blocker">
                <Grid Margin="4,8,4,4">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <Grid Grid.Row="0" Margin="0,0,0,6">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="5"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="8"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="8"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>

                        <Button x:Name="CardTask" Grid.Row="0" Grid.Column="0" Style="{StaticResource CardButton}">
                            <StackPanel>
                                <TextBlock Text="STARTUP AUTO-BLOCK" FontSize="9.5" FontWeight="SemiBold" Foreground="#A1A1AA"/>
                                <TextBlock x:Name="TxtCardTaskStatus" Text="SCANNING..." FontSize="12.5" FontWeight="Bold" Foreground="#E4E4E7" Margin="0,1,0,0"/>
                                <TextBlock Text="Task Scheduler (60s delay)" FontSize="10" Foreground="#71717A"/>
                            </StackPanel>
                        </Button>

                        <Button x:Name="CardDlls" Grid.Row="0" Grid.Column="2" Style="{StaticResource CardButton}">
                            <StackPanel>
                                <TextBlock Text="OVERLAY &amp; HOOK DLLS" FontSize="9.5" FontWeight="SemiBold" Foreground="#A1A1AA"/>
                                <TextBlock x:Name="TxtCardDllStatus" Text="SCANNING..." FontSize="12.5" FontWeight="Bold" Foreground="#E4E4E7" Margin="0,1,0,0"/>
                                <TextBlock Text="Steam, Discord, EA, Epic, OBS..." FontSize="10" Foreground="#71717A"/>
                            </StackPanel>
                        </Button>

                        <Button x:Name="CardVulkan" Grid.Row="0" Grid.Column="4" Style="{StaticResource CardButton}">
                            <StackPanel>
                                <TextBlock Text="VULKAN &amp; XBOX GAME BAR" FontSize="9.5" FontWeight="SemiBold" Foreground="#A1A1AA"/>
                                <TextBlock x:Name="TxtCardVulkanStatus" Text="SCANNING..." FontSize="12.5" FontWeight="Bold" Foreground="#E4E4E7" Margin="0,1,0,0"/>
                                <TextBlock Text="Implicit Layers &amp; Game DVR" FontSize="10" Foreground="#71717A"/>
                            </StackPanel>
                        </Button>

                        <Button x:Name="CardServices" Grid.Row="2" Grid.Column="0" Style="{StaticResource CardButton}">
                            <StackPanel>
                                <TextBlock Text="RGB &amp; UTILITY SERVICES" FontSize="9.5" FontWeight="SemiBold" Foreground="#A1A1AA"/>
                                <TextBlock x:Name="TxtCardSvcStatus" Text="SCANNING..." FontSize="12.5" FontWeight="Bold" Foreground="#E4E4E7" Margin="0,1,0,0"/>
                                <TextBlock Text="MSI, ASUS, Corsair, Razer, SignalRGB..." FontSize="10" Foreground="#71717A"/>
                            </StackPanel>
                        </Button>

                        <Button x:Name="CardStartup" Grid.Row="2" Grid.Column="2" Style="{StaticResource CardButton}">
                            <StackPanel>
                                <TextBlock Text="STARTUP APPS &amp; TASKS" FontSize="9.5" FontWeight="SemiBold" Foreground="#A1A1AA"/>
                                <TextBlock x:Name="TxtCardStartupStatus" Text="SCANNING..." FontSize="12.5" FontWeight="Bold" Foreground="#E4E4E7" Margin="0,1,0,0"/>
                                <TextBlock Text="Run Keys, Shortcuts &amp; Tasks" FontSize="10" Foreground="#71717A"/>
                            </StackPanel>
                        </Button>

                        <Button x:Name="CardLaunchers" Grid.Row="2" Grid.Column="4" Style="{StaticResource CardButton}">
                            <StackPanel>
                                <TextBlock Text="BACKGROUND LAUNCHERS" FontSize="9.5" FontWeight="SemiBold" Foreground="#A1A1AA"/>
                                <TextBlock x:Name="TxtCardLauncherStatus" Text="SCANNING..." FontSize="12.5" FontWeight="Bold" Foreground="#E4E4E7" Margin="0,1,0,0"/>
                                <TextBlock Text="Running overlay/RGB/cloud processes" FontSize="10" Foreground="#71717A"/>
                            </StackPanel>
                        </Button>
                    </Grid>

                    <Grid Grid.Row="1" Margin="0,0,0,8">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="5"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="8"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="8"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>

                        <Button x:Name="BtnBlockAll" Grid.Row="0" Grid.Column="0" Style="{StaticResource ActionButton}"
                                Background="#22A055" Content="Block Everything (Respects Exclusions)"/>
                        <Button x:Name="BtnCustomBlock" Grid.Row="0" Grid.Column="2" Style="{StaticResource ActionButton}"
                                Background="#D97706" Content="Custom Block / Select Items..."/>
                        <Button x:Name="BtnRestoreAll" Grid.Row="0" Grid.Column="4" Style="{StaticResource ActionButton}"
                                Background="#DC2626" Content="Restore Everything (Default Auto-Start)"/>

                        <Button x:Name="BtnBlockOverlaysOnly" Grid.Row="2" Grid.Column="0" Style="{StaticResource ActionButton}"
                                Background="#2563EB" Content="Block Overlay Hooks Only"/>
                        <Button x:Name="BtnToggleTask" Grid.Row="2" Grid.Column="2" Style="{StaticResource ActionButton}"
                                Background="#3F3F46" Content="Toggle Auto-Run at Startup (Task Scheduler)"/>
                        <Button x:Name="BtnQuickFilter" Grid.Row="2" Grid.Column="4" Style="{StaticResource ActionButton}"
                                Background="#52525B" Content="Reset Log &amp; Filters"/>
                    </Grid>

                    <Border Grid.Row="2" Background="#121214" BorderBrush="#2E2E34" BorderThickness="1" CornerRadius="8" Padding="12">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <Grid Grid.Row="0" Margin="0,0,0,8">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <TextBlock x:Name="TxtLogHeader" Grid.Column="0" Text="ACTIVITY &amp; SCAN LOG - ALL APPS &amp; ITEMS"
                                           FontSize="11.5" FontWeight="Bold" Foreground="#A1A1AA" VerticalAlignment="Center"/>
                                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                                    <TextBlock Text="App Filter:" FontSize="11.5" Foreground="#A1A1AA" VerticalAlignment="Center" Margin="0,0,6,0"/>
                                    <ComboBox x:Name="CmbAppFilter" Width="190" Height="24" FontSize="11.5"
                                              Background="#202024" Foreground="#111113" VerticalAlignment="Center"/>
                                </StackPanel>
                            </Grid>
                            <RichTextBox x:Name="LogBox" Grid.Row="1"
                                         Background="#0C0C0E" Foreground="#D4D4D8"
                                         BorderBrush="#27272A" BorderThickness="1"
                                         FontFamily="Consolas" FontSize="12.5"
                                         IsReadOnly="True" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto"
                                         Padding="8">
                                <RichTextBox.Resources>
                                    <Style TargetType="{x:Type Paragraph}">
                                        <Setter Property="Margin" Value="0,1,0,1"/>
                                    </Style>
                                </RichTextBox.Resources>
                            </RichTextBox>
                        </Grid>
                    </Border>
                </Grid>
            </TabItem>

            <TabItem Header="Live DLL Hooks">
                <Grid Margin="4,8,4,4">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <Border Grid.Row="0" Background="#1A1A1E" BorderBrush="#2E2E34" BorderThickness="1" CornerRadius="6" Padding="10" Margin="0,0,0,8">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="8"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>

                            <Grid Grid.Row="0">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>

                                <TextBlock Grid.Column="0" Text="Target Process:" FontSize="12" FontWeight="SemiBold" Foreground="#E4E4E7" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                <ComboBox x:Name="CmbHookProcess" Grid.Column="1" Height="26" FontSize="11.5"
                                          Background="#202024" Foreground="#111113" VerticalAlignment="Center"/>
                                <Button x:Name="BtnReloadProcs" Grid.Column="2" Content="Reload Processes"
                                        Background="#27272A" Foreground="#E4E4E7" FontWeight="SemiBold" FontSize="11.5"
                                        Padding="10,3" Height="26" Margin="8,0,0,0" BorderBrush="#3F3F46" BorderThickness="1" Cursor="Hand"/>
                                <Button x:Name="BtnLockForeground" Grid.Column="3" Content="Lock Foreground (3s)"
                                        Background="#2563EB" Foreground="#FFFFFF" FontWeight="SemiBold" FontSize="11.5"
                                        Padding="12,3" Height="26" Margin="8,0,0,0" BorderThickness="0" Cursor="Hand"/>
                            </Grid>

                            <Grid Grid.Row="2">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>

                                <Button x:Name="BtnToggleLiveMonitor" Grid.Column="0" Content="Start Real-Time Watch"
                                        Background="#22A055" Foreground="#FFFFFF" FontWeight="SemiBold" FontSize="11.5"
                                        Padding="12,3" Height="26" BorderThickness="0" Cursor="Hand"/>
                                <Button x:Name="BtnScanNowHooks" Grid.Column="1" Content="Scan Snapshot Now"
                                        Background="#3F3F46" Foreground="#FFFFFF" FontWeight="SemiBold" FontSize="11.5"
                                        Padding="12,3" Height="26" Margin="8,0,0,0" BorderThickness="0" Cursor="Hand"/>
                                <Button x:Name="BtnClearHookLog" Grid.Column="2" Content="Clear Hook Log"
                                        Background="#27272A" Foreground="#E4E4E7" FontWeight="SemiBold" FontSize="11.5"
                                        Padding="10,3" Height="26" Margin="8,0,0,0" BorderBrush="#3F3F46" BorderThickness="1" Cursor="Hand"/>

                                <StackPanel Grid.Column="3" Orientation="Horizontal" VerticalAlignment="Center" Margin="14,0,0,0">
                                    <TextBlock Text="Interval:" FontSize="11.5" Foreground="#A1A1AA" VerticalAlignment="Center" Margin="0,0,6,0"/>
                                    <ComboBox x:Name="CmbPollInterval" Width="85" Height="24" FontSize="11.5"
                                              Background="#202024" Foreground="#111113" VerticalAlignment="Center"/>
                                </StackPanel>

                                <TextBlock x:Name="TxtLiveHookStatus" Grid.Column="4" Text="IDLE - Select a game process or lock onto foreground window"
                                           FontSize="11.5" FontWeight="SemiBold" Foreground="#38BDF8" VerticalAlignment="Center" TextAlignment="Right"/>
                            </Grid>
                        </Grid>
                    </Border>

                    <Grid Grid.Row="1" Margin="0,0,0,8">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="8"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="8"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>

                        <Border Grid.Column="0" Background="#202024" BorderBrush="#2E2E34" BorderThickness="1" CornerRadius="5" Padding="10,6">
                            <StackPanel>
                                <TextBlock Text="ACTIVE HOOK GROUPS" FontSize="9.5" FontWeight="SemiBold" Foreground="#A1A1AA"/>
                                <TextBlock x:Name="TxtHookGroupCount" Text="0 GROUPS" FontSize="13" FontWeight="Bold" Foreground="#E4E4E7"/>
                            </StackPanel>
                        </Border>

                        <Border Grid.Column="2" Background="#202024" BorderBrush="#2E2E34" BorderThickness="1" CornerRadius="5" Padding="10,6">
                            <StackPanel>
                                <TextBlock Text="LOADED MODULES IN PROCESS" FontSize="9.5" FontWeight="SemiBold" Foreground="#A1A1AA"/>
                                <TextBlock x:Name="TxtHookModuleTotal" Text="0 MODULES" FontSize="13" FontWeight="Bold" Foreground="#E4E4E7"/>
                            </StackPanel>
                        </Border>

                        <Border Grid.Column="4" Background="#202024" BorderBrush="#2E2E34" BorderThickness="1" CornerRadius="5" Padding="10,6">
                            <StackPanel>
                                <TextBlock Text="WINDOWS HISTORICAL CAPTURE" FontSize="9.5" FontWeight="SemiBold" Foreground="#A1A1AA"/>
                                <TextBlock x:Name="TxtHookCaptureState" Text="UNKNOWN" FontSize="13" FontWeight="Bold" Foreground="#E4E4E7"/>
                            </StackPanel>
                        </Border>
                    </Grid>

                    <Border Grid.Row="2" Background="#121214" BorderBrush="#2E2E34" BorderThickness="1" CornerRadius="8" Padding="12">
                        <RichTextBox x:Name="HookLogBox"
                                     Background="#0C0C0E" Foreground="#D4D4D8"
                                     BorderBrush="#27272A" BorderThickness="1"
                                     FontFamily="Consolas" FontSize="12"
                                     IsReadOnly="True" IsDocumentEnabled="True"
                                     VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto"
                                     Padding="8">
                            <RichTextBox.Resources>
                                <Style TargetType="{x:Type Paragraph}">
                                    <Setter Property="Margin" Value="0,1,0,1"/>
                                </Style>
                            </RichTextBox.Resources>
                        </RichTextBox>
                    </Border>
                </Grid>
            </TabItem>
        </TabControl>
    </Grid>
</Window>
"@

try {
    $Reader = (New-Object System.Xml.XmlNodeReader $Xaml)
    $Window = [Windows.Markup.XamlReader]::Load($Reader)
    if ($ZeroHookLogo) {
        $Window.Icon = $ZeroHookLogo
    }
} catch {
    Write-DiagnosticLog -Level "ERROR" -Source "XAML" -Message "Failed to load GUI XAML: $($_.Exception.Message)" -ForceTrim
    [System.Windows.MessageBox]::Show("Failed to load GUI XAML:`n$($_.Exception.Message)", "ZeroHook Error") | Out-Null
    return
}

$ImgHeaderLogo        = $Window.FindName("ImgHeaderLogo")
$BtnCopyBugReport     = $Window.FindName("BtnCopyBugReport")
$BtnAboutInfo         = $Window.FindName("BtnAboutInfo")
$BtnRefresh           = $Window.FindName("BtnRefresh")
$CardTask             = $Window.FindName("CardTask")
$CardDlls             = $Window.FindName("CardDlls")
$CardVulkan           = $Window.FindName("CardVulkan")
$CardServices         = $Window.FindName("CardServices")
$CardStartup          = $Window.FindName("CardStartup")
$CardLaunchers        = $Window.FindName("CardLaunchers")

$TxtCardTaskStatus    = $Window.FindName("TxtCardTaskStatus")
$TxtCardDllStatus     = $Window.FindName("TxtCardDllStatus")
$TxtCardVulkanStatus  = $Window.FindName("TxtCardVulkanStatus")
$TxtCardSvcStatus     = $Window.FindName("TxtCardSvcStatus")
$TxtCardStartupStatus = $Window.FindName("TxtCardStartupStatus")
$TxtCardLauncherStatus= $Window.FindName("TxtCardLauncherStatus")

$BtnBlockAll          = $Window.FindName("BtnBlockAll")
$BtnCustomBlock       = $Window.FindName("BtnCustomBlock")
$BtnRestoreAll        = $Window.FindName("BtnRestoreAll")
$BtnBlockOverlaysOnly = $Window.FindName("BtnBlockOverlaysOnly")
$BtnToggleTask        = $Window.FindName("BtnToggleTask")
$BtnQuickFilter       = $Window.FindName("BtnQuickFilter")
$TxtLogHeader         = $Window.FindName("TxtLogHeader")
$CmbAppFilter         = $Window.FindName("CmbAppFilter")
$LogBox               = $Window.FindName("LogBox")

$CmbHookProcess       = $Window.FindName("CmbHookProcess")
$BtnReloadProcs       = $Window.FindName("BtnReloadProcs")
$BtnLockForeground    = $Window.FindName("BtnLockForeground")
$BtnToggleLiveMonitor = $Window.FindName("BtnToggleLiveMonitor")
$BtnScanNowHooks      = $Window.FindName("BtnScanNowHooks")
$BtnClearHookLog      = $Window.FindName("BtnClearHookLog")
$CmbPollInterval      = $Window.FindName("CmbPollInterval")
$TxtLiveHookStatus    = $Window.FindName("TxtLiveHookStatus")
$TxtHookGroupCount    = $Window.FindName("TxtHookGroupCount")
$TxtHookModuleTotal   = $Window.FindName("TxtHookModuleTotal")
$TxtHookCaptureState  = $Window.FindName("TxtHookCaptureState")
$HookLogBox           = $Window.FindName("HookLogBox")

if ($ZeroHookLogo -and $ImgHeaderLogo) {
    $ImgHeaderLogo.Source = $ZeroHookLogo
}

$AppFilterOptions = @(
    "ALL APPS",
    "STEAM",
    "DISCORD",
    "EPIC / EOS",
    "EA / ORIGIN",
    "UBISOFT",
    "GOG GALAXY",
    "OVERWOLF",
    "OBS / STREAMLABS",
    "RTSS / RIVATUNER",
    "NVIDIA",
    "AMD",
    "RAZER",
    "SONY / DUALSENSE",
    "MSI",
    "ASUS",
    "CORSAIR",
    "GIGABYTE",
    "ASROCK",
    "NZXT",
    "LOGITECH",
    "KINGSTON",
    "SAMSUNG",
    "STEELSERIES",
    "OPENRGB / SIGNALRGB",
    "ONEDRIVE",
    "DROPBOX",
    "ADOBE",
    "XBOX / GAME BAR",
    "OTHER"
)
foreach ($Opt in $AppFilterOptions) {
    [void]$CmbAppFilter.Items.Add($Opt)
}
$CmbAppFilter.SelectedIndex = 0

foreach ($Secs in @(1, 2, 3, 5)) {
    [void]$CmbPollInterval.Items.Add("${Secs}s")
}
$CmbPollInterval.SelectedIndex = 3

$BrushGreen  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
$BrushRed    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
$BrushYellow = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FACC15")
$BrushCyan   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
$BrushGray   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
$BrushMuted  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#71717A")

$Script:CurrentCategoryFilter = "ALL"
$Script:SuppressFilterEvent = $false
$Script:SuppressHookProcessSelection = $false
$Script:ScanData = @{}

$Script:LiveHookTarget = $null
$Script:LastHookSnapshot = $null
$Script:LastHookTargetInfo = $null
$Script:SeenModuleKeys = New-Object 'System.Collections.Generic.HashSet[string]'
$Script:CollapsedHookCategories = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($cat in $CollapsibleHookCategories) {
    [void]$Script:CollapsedHookCategories.Add($cat)
}
$Script:PendingHookDetections = @{}

function Test-IsCollapsibleCategory {
    param([string]$CategoryId)
    return ($CollapsibleHookCategories -contains $CategoryId)
}

function Test-IsCategoryMinimized {
    param([string]$CategoryId)
    if (-not (Test-IsCollapsibleCategory -CategoryId $CategoryId)) { return $false }
    return $Script:CollapsedHookCategories.Contains($CategoryId)
}

function Invoke-ToggleHookCategory {
    param([string]$CategoryId)
    if ([string]::IsNullOrWhiteSpace($CategoryId)) { return }
    if (-not (Test-IsCollapsibleCategory -CategoryId $CategoryId)) { return }

    if ($Script:CollapsedHookCategories.Contains($CategoryId)) {
        [void]$Script:CollapsedHookCategories.Remove($CategoryId)
    } else {
        [void]$Script:CollapsedHookCategories.Add($CategoryId)
    }

    Render-HookLogFromState -ForceSnapshot:($null -ne $Script:LastHookSnapshot)
}

function New-CategoryToggleLink {
    param([string]$CategoryId)
    $isMin = Test-IsCategoryMinimized -CategoryId $CategoryId
    $symbol = if ($isMin) { "[+]" } else { "[-]" }

    $link = New-Object System.Windows.Documents.Hyperlink
    $link.Tag = $CategoryId
    $link.IsEnabled = $true
    $link.TextDecorations = $null
    $link.Foreground = $BrushCyan
    $link.FontWeight = "Bold"
    $link.Cursor = [System.Windows.Input.Cursors]::Hand

    $run = New-Object System.Windows.Documents.Run("$symbol ")
    $run.FontWeight = "Bold"
    $run.Foreground = $BrushCyan
    [void]$link.Inlines.Add($run)

    $link.Add_Click({
        param($sender, $e)
        $e.Handled = $true
        $cid = [string]$sender.Tag
        Invoke-ToggleHookCategory -CategoryId $cid
    })

    $link.Add_MouseLeftButtonDown({
        param($sender, $e)
        $e.Handled = $true
        $cid = [string]$sender.Tag
        Invoke-ToggleHookCategory -CategoryId $cid
    })

    return $link
}

function Save-LocalScriptCopy {
    if (-not (Test-Path -LiteralPath $LocalInstallDir)) {
        New-Item -Path $LocalInstallDir -ItemType Directory -Force | Out-Null
    }
    $scriptText = $null
    if ($PSCommandPath -and (Test-Path -LiteralPath $PSCommandPath)) {
        $scriptText = Get-Content -LiteralPath $PSCommandPath -Raw -Encoding UTF8
    } elseif ($MyInvocation.ScriptName -and (Test-Path -LiteralPath $MyInvocation.ScriptName)) {
        $scriptText = Get-Content -LiteralPath $MyInvocation.ScriptName -Raw -Encoding UTF8
    } elseif ($MyInvocation.MyCommand -and $MyInvocation.MyCommand.ScriptBlock) {
        $scriptText = $MyInvocation.MyCommand.ScriptBlock.ToString()
    }
    if ([string]::IsNullOrWhiteSpace($scriptText)) {
        throw "Could not capture ZeroHook script source to save locally."
    }
    Set-Content -LiteralPath $LocalScriptPath -Value $scriptText -Encoding UTF8 -Force
    return $LocalScriptPath
}

function Limit-LogBlocks {
    param(
        [System.Windows.Controls.RichTextBox]$Box,
        [int]$MaxBlocks = 500
    )
    if (-not $Box -or -not $Box.Document) { return }
    while ($Box.Document.Blocks.Count -gt $MaxBlocks) {
        $Box.Document.Blocks.Remove($Box.Document.Blocks.FirstBlock)
    }
}

function Clear-Log {
    param([string]$HeaderTitle = "ACTIVITY & SCAN LOG")
    $TxtLogHeader.Text = $HeaderTitle
    $LogBox.Document.Blocks.Clear()
    Write-DiagnosticLog -Level "INFO" -Source "UI" -Message "--- $HeaderTitle ---"
}

function Add-Log {
    param(
        [string]$Badge = "",
        [string]$Message = "",
        [string]$BadgeColor = "Gray",
        [string]$MsgColor = "Gray",
        [switch]$NoScroll
    )
    if ($Badge -ne "" -or $Message -ne "") {
        $lvl = if ($Badge -match "FAIL|ERROR") { "ERROR" } elseif ($Badge -match "WARN|IMPORTANT") { "WARN" } else { "INFO" }
        Write-DiagnosticLog -Level $lvl -Source "BLOCKER" -Message "$Badge$Message".Trim()
    }
    $Para = New-Object System.Windows.Documents.Paragraph
    if ($Badge -ne "") {
        $RunBadge = New-Object System.Windows.Documents.Run($Badge)
        $RunBadge.FontWeight = "Bold"
        switch ($BadgeColor) {
            "Green"  { $RunBadge.Foreground = $BrushGreen }
            "Red"    { $RunBadge.Foreground = $BrushRed }
            "Yellow" { $RunBadge.Foreground = $BrushYellow }
            "Cyan"   { $RunBadge.Foreground = $BrushCyan }
            "Muted"  { $RunBadge.Foreground = $BrushMuted }
            default  { $RunBadge.Foreground = $BrushGray }
        }
        $Para.Inlines.Add($RunBadge)
    }
    if ($Message -ne "") {
        $RunMsg = New-Object System.Windows.Documents.Run($Message)
        switch ($MsgColor) {
            "Green"  { $RunMsg.Foreground = $BrushGreen }
            "Red"    { $RunMsg.Foreground = $BrushRed }
            "Yellow" { $RunMsg.Foreground = $BrushYellow }
            "Cyan"   { $RunMsg.Foreground = $BrushCyan }
            "Muted"  { $RunMsg.Foreground = $BrushMuted }
            default  { $RunMsg.Foreground = $BrushGray }
        }
        $Para.Inlines.Add($RunMsg)
    }
    $LogBox.Document.Blocks.Add($Para)
    Limit-LogBlocks -Box $LogBox -MaxBlocks 500
    if (-not $NoScroll) { $LogBox.ScrollToEnd() }
}

function Add-HookLog {
    param(
        [string]$Badge = "",
        [string]$Message = "",
        [string]$BadgeColor = "Gray",
        [string]$MsgColor = "Gray",
        [string]$ToggleCategoryId = "",
        [switch]$NoScroll
    )
    if ($Badge -ne "" -or $Message -ne "") {
        $lvl = if ($Badge -match "FAIL|ERROR|INCONCLUSIVE|EXITED") { "WARN" } else { "INFO" }
        Write-DiagnosticLog -Level $lvl -Source "LIVEHOOK" -Message "$Badge$Message".Trim()
    }
    $Para = New-Object System.Windows.Documents.Paragraph
    if (-not [string]::IsNullOrWhiteSpace($ToggleCategoryId) -and (Test-IsCollapsibleCategory -CategoryId $ToggleCategoryId)) {
        $toggleLink = New-CategoryToggleLink -CategoryId $ToggleCategoryId
        $Para.Inlines.Add($toggleLink)
    }
    if ($Badge -ne "") {
        $RunBadge = New-Object System.Windows.Documents.Run($Badge)
        $RunBadge.FontWeight = "Bold"
        switch ($BadgeColor) {
            "Green"  { $RunBadge.Foreground = $BrushGreen }
            "Red"    { $RunBadge.Foreground = $BrushRed }
            "Yellow" { $RunBadge.Foreground = $BrushYellow }
            "Cyan"   { $RunBadge.Foreground = $BrushCyan }
            "Muted"  { $RunBadge.Foreground = $BrushMuted }
            default  { $RunBadge.Foreground = $BrushGray }
        }
        $Para.Inlines.Add($RunBadge)
    }
    if ($Message -ne "") {
        $RunMsg = New-Object System.Windows.Documents.Run($Message)
        switch ($MsgColor) {
            "Green"  { $RunMsg.Foreground = $BrushGreen }
            "Red"    { $RunMsg.Foreground = $BrushRed }
            "Yellow" { $RunMsg.Foreground = $BrushYellow }
            "Cyan"   { $RunMsg.Foreground = $BrushCyan }
            "Muted"  { $RunMsg.Foreground = $BrushMuted }
            default  { $RunMsg.Foreground = $BrushGray }
        }
        $Para.Inlines.Add($RunMsg)
    }
    $HookLogBox.Document.Blocks.Add($Para)
    Limit-LogBlocks -Box $HookLogBox -MaxBlocks 500
    if (-not $NoScroll) { $HookLogBox.ScrollToEnd() }
}

function Add-SteamClientTipToLog {
    param([switch]$NoScroll)
    Add-Log -Badge "`n[STEAM CLIENT TIP] " -Message "For extra optimization, consider disabling these in your Steam client too (Settings > Interface > Advanced - requires a Steam restart):" -BadgeColor "Cyan" -MsgColor "Gray" -NoScroll:$NoScroll
    Add-Log -Badge "  - " -Message "Enable smooth scrolling in web views" -BadgeColor "Cyan" -MsgColor "Gray" -NoScroll:$NoScroll
    Add-Log -Badge "  - " -Message "Enable GPU accelerated rendering in web views" -BadgeColor "Cyan" -MsgColor "Gray" -NoScroll:$NoScroll
    Add-Log -Badge "  - " -Message "Enable hardware video decoding, if supported" -BadgeColor "Cyan" -MsgColor "Gray" -NoScroll:$NoScroll
    Add-Log -Badge "  - " -Message "Note: Steam re-enables its Vulkan layers on every launch. Keep Steam auto-startup enabled and use the Auto-Run task scheduler so they are disabled automatically 60s after Windows Startup & Logon." -BadgeColor "Yellow" -MsgColor "Yellow" -NoScroll:$NoScroll
}

function Refresh-HookProcessList {
    param([switch]$SelectFirstSilently)

    $Script:SuppressHookProcessSelection = $true
    try {
        $CmbHookProcess.Items.Clear()
        $procs = Get-Process -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Id -ne $PID -and
                $_.MainWindowHandle -ne 0 -and
                ($_.ProcessName -notin $IgnoredForegroundProcesses)
            } |
            Sort-Object ProcessName, Id

        foreach ($p in $procs) {
            $title = if ($p.MainWindowTitle) { " - $($p.MainWindowTitle)" } else { "" }
            $item = New-Object System.Windows.Controls.ComboBoxItem
            $item.Content = "$($p.ProcessName) (PID $($p.Id))$title"
            $item.Tag = [PSCustomObject]@{
                Id   = [int]$p.Id
                Name = [string]$p.ProcessName
                Path = $(try { [string]$p.Path } catch { "" })
            }
            [void]$CmbHookProcess.Items.Add($item)
        }

        if ($CmbHookProcess.Items.Count -gt 0 -and $null -eq $CmbHookProcess.SelectedItem) {
            $CmbHookProcess.SelectedIndex = 0
        }
    } finally {
        $Script:SuppressHookProcessSelection = $false
    }
}

function Get-SelectedHookTarget {
    if ($CmbHookProcess.SelectedItem -and $CmbHookProcess.SelectedItem.Tag) {
        $sel = $CmbHookProcess.SelectedItem.Tag
        try {
            $p = Get-Process -Id $sel.Id -ErrorAction Stop
            $startedUtc = try { $p.StartTime.ToUniversalTime() } catch { $null }
            $path = try { [string]$p.Path } catch { $sel.Path }
            $p.Dispose()
            return [PSCustomObject]@{
                Id = [int]$sel.Id; Name = [string]$p.ProcessName; Path = [string]$path; StartedUtc = $startedUtc
            }
        } catch { return $null }
    }
    return $null
}

function Render-HookLogFromState {
    param([switch]$ForceSnapshot)
    $snap = $Script:LastHookSnapshot
    $target = $Script:LastHookTargetInfo
    if (-not $snap -or -not $target) { return }

    $HookLogBox.Document.Blocks.Clear()
    $Script:PendingHookDetections.Clear()

    if ($ForceSnapshot) {
        Add-HookLog -Badge "`n=== SNAPSHOT: $($target.Name) (PID $($target.Id)) ===" -BadgeColor "Cyan" -NoScroll
        if ($target.Path) { Add-HookLog -Message "  Path: $(Hide-Username $target.Path)" -MsgColor "Muted" -NoScroll }
        if ($snap.Findings.Count -eq 0) {
            Add-HookLog -Badge "  [CLEAN] " -Message "No matched overlay/hook modules detected in loaded modules." -BadgeColor "Green" -NoScroll
        } else {
            foreach ($f in $snap.Findings) {
                $isCollapsible = Test-IsCollapsibleCategory -CategoryId $f.Id
                $isMin = Test-IsCategoryMinimized -CategoryId $f.Id
                if ($isCollapsible -and $isMin) {
                    Add-HookLog -Badge "  [$($f.Id)] $($f.Label) " -Message "($($f.Modules.Count) module(s) — minimized)" -BadgeColor "Yellow" -MsgColor "Muted" -ToggleCategoryId $f.Id -NoScroll
                } else {
                    if ($isCollapsible) {
                        Add-HookLog -Badge "  [$($f.Id)] $($f.Label) " -Message "($($f.Scope))" -BadgeColor "Yellow" -MsgColor "Muted" -ToggleCategoryId $f.Id -NoScroll
                    } else {
                        Add-HookLog -Badge "  [$($f.Id)] $($f.Label) " -Message "($($f.Scope))" -BadgeColor "Yellow" -MsgColor "Muted" -ToggleCategoryId $f.Id -NoScroll
                    }
                    foreach ($m in $f.Modules) {
                        $descSuffix = if (-not [string]::IsNullOrWhiteSpace($m.Description)) { " — $($m.Description)" } else { "" }
                        Add-HookLog -Message "     - $(Hide-Username $m.Path)$descSuffix" -MsgColor "Gray" -NoScroll
                    }
                    if ($LiveHookFeatures.Contains($f.Id)) {
                        Add-HookLog -Badge "     How to disable: " -Message $LiveHookFeatures[$f.Id].Off -BadgeColor "Cyan" -MsgColor "Gray" -NoScroll
                    }
                }
            }
        }
        $HookLogBox.ScrollToEnd()
    }
}

function Invoke-HookMonitorStep {
    param([switch]$ForceLogSnapshot)

    $target = $Script:LiveHookTarget
    if (-not $target) {
        $target = Get-SelectedHookTarget
        if ($target) { $Script:LiveHookTarget = $target }
    }

    if (-not $target) {
        $TxtLiveHookStatus.Text = "NO VALID TARGET - Pick a process or lock onto foreground window"
        $TxtLiveHookStatus.Foreground = $BrushYellow
        return
    }

    $currentProc = $null
    try {
        $currentProc = Get-Process -Id $target.Id -ErrorAction Stop
        if ($null -ne $target.StartedUtc) {
            $nowUtc = $currentProc.StartTime.ToUniversalTime()
            if ([Math]::Abs(($nowUtc - $target.StartedUtc).TotalSeconds) -gt 2) {
                throw "PID restarted."
            }
        }
    } catch {
        $TxtLiveHookStatus.Text = "TARGET EXITED: $($target.Name) (PID $($target.Id))"
        $TxtLiveHookStatus.Foreground = $BrushRed
        Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [EXITED] " -Message "$($target.Name) (PID $($target.Id)) is no longer running." -BadgeColor "Red"
        $Script:LiveHookTarget = $null
        $Script:LastHookSnapshot = $null
        $Script:LastHookTargetInfo = $null
        $Script:SeenModuleKeys.Clear()
        $Script:PendingHookDetections.Clear()
        return
    } finally {
        if ($currentProc) { $currentProc.Dispose() }
    }

    $snap = Get-ProcessHookSnapshot -TargetPid $target.Id -ExpectedStartUtc $target.StartedUtc -GamePath $target.Path
    $Script:LastHookSnapshot = $snap
    $Script:LastHookTargetInfo = $target

    $TxtHookGroupCount.Text = "$($snap.Findings.Count) GROUPS"
    $TxtHookGroupCount.Foreground = if ($snap.Findings.Count -gt 0) { $BrushYellow } else { $BrushGreen }

    $TxtHookModuleTotal.Text = "$($snap.TotalModuleCount) MODULES"
    $TxtHookModuleTotal.Foreground = $BrushCyan

    $TxtHookCaptureState.Text = $snap.HistoricalCapture.ToUpper()
    $TxtHookCaptureState.Foreground = if ($snap.HistoricalCapture -eq "Enabled") { $BrushYellow } elseif ($snap.HistoricalCapture -eq "Off") { $BrushGreen } else { $BrushGray }

    if ($snap.State -eq "INCONCLUSIVE") {
        $TxtLiveHookStatus.Text = "INCONCLUSIVE: $($target.Name) (PID $($target.Id))"
        $TxtLiveHookStatus.Foreground = $BrushRed
        if ($ForceLogSnapshot) {
            Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [INCONCLUSIVE] " -Message "Module list unavailable for $($target.Name) (PID $($target.Id)): $($snap.Message)" -BadgeColor "Red"
        }
        return
    }

    $TxtLiveHookStatus.Text = "MONITORING: $($target.Name) (PID $($target.Id)) | $($snap.Findings.Count) hook group(s)"
    $TxtLiveHookStatus.Foreground = $BrushGreen

    $currentHookKeys = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($f in $snap.Findings) {
        $isCollapsible = Test-IsCollapsibleCategory -CategoryId $f.Id
        $isMin = Test-IsCategoryMinimized -CategoryId $f.Id
        $newModsInGroup = [System.Collections.Generic.List[object]]::new()

        foreach ($m in $f.Modules) {
            [void]$currentHookKeys.Add($m.Key)
            if (-not $Script:SeenModuleKeys.Contains($m.Key)) {
                [void]$Script:SeenModuleKeys.Add($m.Key)
                [void]$newModsInGroup.Add($m)
            }
        }

        if ($newModsInGroup.Count -gt 0) {
            if ($isCollapsible -and $isMin) {
                if (-not $Script:PendingHookDetections.ContainsKey($f.Id)) {
                    $Script:PendingHookDetections[$f.Id] = [System.Collections.Generic.List[object]]::new()
                }
                foreach ($nm in $newModsInGroup) { [void]$Script:PendingHookDetections[$f.Id].Add($nm) }
                $totalQueued = $Script:PendingHookDetections[$f.Id].Count
                Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [HOOK DETECTED][$($f.Id)] " -Message "$totalQueued module(s) detected (minimized — click [+] to expand)" -BadgeColor "Yellow" -MsgColor "Muted" -ToggleCategoryId $f.Id -NoScroll
            } else {
                foreach ($nm in $newModsInGroup) {
                    Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [HOOK DETECTED][$($f.Id)] " -Message "$($nm.Name) -> $(Hide-Username $nm.Path)" -BadgeColor "Yellow" -MsgColor "Gray" -ToggleCategoryId $f.Id -NoScroll
                    if (-not [string]::IsNullOrWhiteSpace($nm.Description)) {
                        Add-HookLog -Badge "   Desc: " -Message $nm.Description -BadgeColor "Green" -MsgColor "Gray" -NoScroll
                    }
                }
                if ($LiveHookFeatures.Contains($f.Id)) {
                    Add-HookLog -Badge "   Off switch: " -Message $LiveHookFeatures[$f.Id].Off -BadgeColor "Cyan" -MsgColor "Muted" -NoScroll
                }
            }
        }
    }

    $removedKeys = @()
    foreach ($prevKey in $Script:SeenModuleKeys) {
        if (-not $currentHookKeys.Contains($prevKey)) { $removedKeys += $prevKey }
    }
    foreach ($rk in $removedKeys) {
        [void]$Script:SeenModuleKeys.Remove($rk)
        Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [HOOK UNLOADED] " -Message $rk -BadgeColor "Cyan" -MsgColor "Muted" -NoScroll
    }

    if ($ForceLogSnapshot) {
        Render-HookLogFromState -ForceSnapshot
    }
}

$HookTimer = New-Object System.Windows.Threading.DispatcherTimer
$HookTimer.Interval = [TimeSpan]::FromSeconds(5)
$HookTimer.Add_Tick({ Invoke-HookMonitorStep })

function Show-AboutInfoWindow {
    [xml]$InfoXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="What ZeroHook Does &amp; Blocks - ZeroHook"
        Height="760" Width="1020" MinHeight="520" MinWidth="740"
        WindowStartupLocation="CenterOwner"
        Background="#161618" Foreground="#E4E4E7"
        FontFamily="Segoe UI">
    <Grid Margin="14">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,10">
            <TextBlock Text="WHAT THIS APP DOES &amp; TARGETS" FontSize="15" FontWeight="Bold" Foreground="#FFFFFF"/>
            <TextBlock Text="Exact breakdown of actions performed on your system and the DLLs, Vulkan layers, services, cloud/updater apps, and startup entries matched."
                       FontSize="11.5" Foreground="#A1A1AA" Margin="0,2,0,0"/>
        </StackPanel>
        <Border Grid.Row="1" Background="#0C0C0E" BorderBrush="#2E2E34" BorderThickness="1" CornerRadius="6" Padding="10">
            <RichTextBox x:Name="InfoBox" Background="Transparent" Foreground="#D4D4D8" BorderThickness="0"
                         FontFamily="Consolas" FontSize="12" IsReadOnly="True"
                         VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto">
                <RichTextBox.Resources>
                    <Style TargetType="{x:Type Paragraph}">
                        <Setter Property="Margin" Value="0,1,0,1"/>
                    </Style>
                </RichTextBox.Resources>
            </RichTextBox>
        </Border>
        <Button x:Name="BtnCloseInfo" Grid.Row="2" Content="Close" HorizontalAlignment="Right"
                Background="#3F3F46" Foreground="#FFFFFF" FontWeight="SemiBold"
                Margin="0,10,0,0" Padding="16,5" Height="30" BorderThickness="0" Cursor="Hand"/>
    </Grid>
</Window>
"@
    $IReader = (New-Object System.Xml.XmlNodeReader $InfoXaml)
    $InfoWin = [Windows.Markup.XamlReader]::Load($IReader)
    $InfoWin.Owner = $Window
    if ($ZeroHookLogo) { $InfoWin.Icon = $ZeroHookLogo }
    $InfoBox = $InfoWin.FindName("InfoBox")
    $BtnCloseInfo = $InfoWin.FindName("BtnCloseInfo")

    $AddInfoLine = {
        param([string]$Lead, [string]$Body, [string]$LeadColor = "Cyan", [string]$BodyColor = "Gray")
        $P = New-Object System.Windows.Documents.Paragraph
        if ($Lead -ne "") {
            $RL = New-Object System.Windows.Documents.Run($Lead)
            $RL.FontWeight = "Bold"
            switch ($LeadColor) {
                "Green"  { $RL.Foreground = $BrushGreen }
                "Yellow" { $RL.Foreground = $BrushYellow }
                "Cyan"   { $RL.Foreground = $BrushCyan }
                "Muted"  { $RL.Foreground = $BrushMuted }
                default  { $RL.Foreground = $BrushGray }
            }
            $P.Inlines.Add($RL)
        }
        if ($Body -ne "") {
            $RB = New-Object System.Windows.Documents.Run($Body)
            switch ($BodyColor) {
                "Green"  { $RB.Foreground = $BrushGreen }
                "Yellow" { $RB.Foreground = $BrushYellow }
                "Cyan"   { $RB.Foreground = $BrushCyan }
                "Muted"  { $RB.Foreground = $BrushMuted }
                default  { $RB.Foreground = $BrushGray }
            }
            $P.Inlines.Add($RB)
        }
        [void]$InfoBox.Document.Blocks.Add($P)
    }

    & $AddInfoLine -Lead "1. HOW BLOCKING & RESTORING WORKS" -LeadColor "Yellow"
    & $AddInfoLine -Lead "   - Overlay & Hook DLLs: " -Body "Adds or removes an NTFS Deny (ReadAndExecute) rule for Everyone (S-1-1-0) on matched DLLs without deleting files." -LeadColor "Cyan"
    & $AddInfoLine -Lead "   - Vulkan Implicit Layers: " -Body "Sets registry DWORD values under Khronos Vulkan ImplicitLayers to 1 (disabled) or 0 (enabled)." -LeadColor "Cyan"
    & $AddInfoLine -Lead "   - Xbox Game Bar / DVR: " -Body "Toggles AppCaptureEnabled and GameDVR_Enabled in HKCU GameDVR and GameConfigStore (Windows Game Mode is never modified)." -LeadColor "Cyan"
    & $AddInfoLine -Lead "   - RGB & Utility Services: " -Body "Switches matched vendor and updater services to Manual (or restores Automatic) and stops running instances when blocking." -LeadColor "Cyan"
    & $AddInfoLine -Lead "   - Startup Apps, Cloud Sync & Tasks: " -Body "Updates StartupApproved binary flags for Run entries, moves startup shortcuts to ProgramData backup (and back on restore), and disables/enables matching non-Microsoft scheduled tasks." -LeadColor "Cyan"
    & $AddInfoLine -Lead "   - Keep-Safe Presets & Exclusions: " -Body "Custom Block includes quick 'Keep Safe' presets (Keep RGB Control, Keep Controller / Gamepad Support). Unchecked items save to exclusions.json and are respected by Block Everything and -AutoBlock." -LeadColor "Cyan"
    & $AddInfoLine -Lead "   - Diagnostic Logs & Bug Reports: " -Body "Saves masked session logs to %LOCALAPPDATA%\ZeroHook\Logs\zerohook-current.log (max 1,500 lines). Click 'Copy Log for Dev' in the header to copy a bug report for GS." -LeadColor "Cyan"

    & $AddInfoLine -Lead "`n2. TARGETED OVERLAY & HOOK DLLS ($($TargetDLLs.Count))" -LeadColor "Yellow"
    & $AddInfoLine -Lead "   - DLLs: " -Body ($TargetDLLs -join ", ") -LeadColor "Green"

    & $AddInfoLine -Lead "`n3. VULKAN LAYER KEYWORDS & XBOX HOOKS" -LeadColor "Yellow"
    & $AddInfoLine -Lead "   - Keywords: " -Body ($BlockedLayerKeywords -join ", ") -LeadColor "Green"
    & $AddInfoLine -Lead "   - Keys: " -Body ($VulkanKeys -join " | ") -LeadColor "Cyan"

    & $AddInfoLine -Lead "`n4. RGB, UPDATER & UTILITY SERVICE PATTERNS ($($TargetServicePatterns.Count))" -LeadColor "Yellow"
    & $AddInfoLine -Lead "   - Patterns: " -Body ($TargetServicePatterns -join ", ") -LeadColor "Green"
    & $AddInfoLine -Lead "   - Note: " -Body "LEDKeeper2_Host is explicitly skipped." -LeadColor "Cyan"

    & $AddInfoLine -Lead "`n5. STARTUP, CLOUD SYNC & VENDOR KEYWORDS ($($StartupUtilityKeywords.Count))" -LeadColor "Yellow"
    & $AddInfoLine -Lead "   - Keywords: " -Body ($StartupUtilityKeywords -join ", ") -LeadColor "Green"
    & $AddInfoLine -Lead "   - Monitored Processes: " -Body ($LauncherProcesses -join ", ") -LeadColor "Cyan"

    $FormattedSearchPaths = ($SearchPaths | ForEach-Object { Hide-Username $_ }) -join "; "
    & $AddInfoLine -Lead "`n6. SCAN PATHS & EXCLUDED SUBFOLDERS" -LeadColor "Yellow"
    & $AddInfoLine -Lead "   - Search Paths: " -Body $FormattedSearchPaths -LeadColor "Cyan"
    & $AddInfoLine -Lead "   - Excluded Regex: " -Body $ExcludedPathRegex -LeadColor "Cyan"

    & $AddInfoLine -Lead "`n7. EXTRA STEAM CLIENT OPTIMIZATION" -LeadColor "Yellow"
    & $AddInfoLine -Lead "   For extra optimization, consider disabling these in your Steam client too (Settings > Interface > Advanced - requires a Steam restart):" -LeadColor "Cyan"
    & $AddInfoLine -Lead "     * " -Body "Enable smooth scrolling in web views" -LeadColor "Green" -BodyColor "Green"
    & $AddInfoLine -Lead "     * " -Body "Enable GPU accelerated rendering in web views" -LeadColor "Green" -BodyColor "Green"
    & $AddInfoLine -Lead "     * " -Body "Enable hardware video decoding, if supported" -LeadColor "Green" -BodyColor "Green"
    & $AddInfoLine -Lead "     * Note: " -Body "Steam re-enables its Vulkan layers on every launch. Keep Steam auto-startup enabled and use the Auto-Run task scheduler so they are disabled automatically 60s after Windows Startup & Logon." -BadgeColor "Yellow" -BodyColor "Yellow"

    $BtnCloseInfo.Add_Click({ $InfoWin.Close() })
    $InfoWin.ShowDialog() | Out-Null
}

function Show-CustomBlockDialog {
    $ExcludedIds = @(Get-SavedExclusions)
    $AllServices = @(Get-Service -ErrorAction SilentlyContinue)
    $AllTasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue)
    $Dlls = @(Get-OverlayDLLs)
    $VulkanLayers = @(Get-VulkanLayersList)
    $GameBarOff = Get-GameBarStatus
    $Services = @(Get-UtilityServices -AllServices $AllServices)
    $StartupItems = @(Get-UtilityStartupItems)
    $Shortcuts = @(Get-UtilityStartupShortcuts)
    $VendorTasks = @(Get-UtilityScheduledTasks -AllTasks $AllTasks)

    $Candidates = [System.Collections.Generic.List[object]]::new()

    foreach ($File in $Dlls) {
        $id = "DLL|$($File.FullName)"
        [void]$Candidates.Add([PSCustomObject]@{
            Id          = $id
            Kind        = "DLL"
            App         = (Get-AppGroupName "$($File.Name) $($File.FullName)")
            DetailText  = "[Overlay DLL] $($File.Name)  ($(Hide-Username $File.FullName))"
            IsExcluded  = ($ExcludedIds -contains $id)
            IsBlocked   = [bool]$File.IsBlocked
        })
    }
    foreach ($Layer in $VulkanLayers) {
        $id = "VULKAN|$($Layer.Key)|$($Layer.Name)"
        [void]$Candidates.Add([PSCustomObject]@{
            Id          = $id
            Kind        = "VULKAN"
            App         = (Get-AppGroupName $Layer.Name)
            DetailText  = "[Vulkan Layer] $(Hide-Username $Layer.Name)"
            IsExcluded  = ($ExcludedIds -contains $id)
            IsBlocked   = [bool]$Layer.IsDisabled
        })
    }
    $gbId = "GAMEBAR|XBOX"
    [void]$Candidates.Add([PSCustomObject]@{
        Id          = $gbId
        Kind        = "GAMEBAR"
        App         = "XBOX / GAME BAR"
        DetailText  = "[Game Bar] Xbox Game Bar / Game DVR Background Hooks"
        IsExcluded  = ($ExcludedIds -contains $gbId)
        IsBlocked   = [bool]$GameBarOff
    })
    foreach ($Svc in $Services) {
        $id = "SVC|$($Svc.Name)"
        $off = ($Svc.StartType -eq "Manual" -or $Svc.StartType -eq "Disabled")
        [void]$Candidates.Add([PSCustomObject]@{
            Id          = $id
            Kind        = "SVC"
            App         = (Get-AppGroupName "$($Svc.Name) $($Svc.DisplayName)")
            DetailText  = "[Service] $($Svc.DisplayName) ($($Svc.Name)) [Start: $($Svc.StartType)]"
            IsExcluded  = ($ExcludedIds -contains $id)
            IsBlocked   = $off
        })
    }
    foreach ($Item in $StartupItems) {
        $id = "RUN|$($Item.RunPath)|$($Item.Name)"
        [void]$Candidates.Add([PSCustomObject]@{
            Id          = $id
            Kind        = "RUN"
            App         = (Get-AppGroupName "$($Item.Name) $($Item.Command)")
            DetailText  = "[Startup Run] $($Item.Name)  ($(Hide-Username $Item.RunPath))"
            IsExcluded  = ($ExcludedIds -contains $id)
            IsBlocked   = [bool]$Item.IsDisabled
        })
    }
    foreach ($Sc in $Shortcuts) {
        $id = "SHORTCUT|$($Sc.OrigFolder)|$($Sc.Name)"
        [void]$Candidates.Add([PSCustomObject]@{
            Id          = $id
            Kind        = "SHORTCUT"
            App         = (Get-AppGroupName "$($Sc.Name) $($Sc.FullPath)")
            DetailText  = "[Startup Shortcut] $($Sc.Name) ($(Hide-Username $Sc.OrigFolder))"
            IsExcluded  = ($ExcludedIds -contains $id)
            IsBlocked   = [bool]$Sc.IsDisabled
        })
    }
    foreach ($Task in $VendorTasks) {
        $id = "TASK|$($Task.TaskPath)$($Task.TaskName)"
        $off = ($Task.State -eq "Disabled")
        [void]$Candidates.Add([PSCustomObject]@{
            Id          = $id
            Kind        = "TASK"
            App         = (Get-AppGroupName "$($Task.TaskPath)$($Task.TaskName)")
            DetailText  = "[Scheduled Task] $($Task.TaskPath)$($Task.TaskName) [$($Task.State)]"
            IsExcluded  = ($ExcludedIds -contains $id)
            IsBlocked   = $off
        })
    }

    [xml]$PickXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Select Items to Block / Disable - ZeroHook"
        Height="740" Width="1040" MinHeight="500" MinWidth="720"
        WindowStartupLocation="CenterOwner"
        Background="#161618" Foreground="#E4E4E7"
        FontFamily="Segoe UI">
    <Grid Margin="14">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,8">
            <TextBlock Text="SELECT ITEMS TO BLOCK OR DISABLE" FontSize="15" FontWeight="Bold" Foreground="#FFFFFF"/>
            <TextBlock Text="Checked items will be blocked/disabled. Uncheck anything you want to keep active (saved for Auto-Block too)."
                       FontSize="11.5" Foreground="#A1A1AA" Margin="0,2,0,0"/>
        </StackPanel>

        <Grid Grid.Row="1" Margin="0,0,0,6">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBox x:Name="TxtFilterBox" Grid.Column="0" Height="28" FontSize="12" Padding="8,4"
                     Background="#202024" Foreground="#FFFFFF" BorderBrush="#3F3F46" BorderThickness="1"
                     VerticalContentAlignment="Center"/>
            <Button x:Name="BtnCheckVisible" Grid.Column="1" Content="Check All Visible"
                    Background="#27272A" Foreground="#E4E4E7" FontWeight="SemiBold" FontSize="11.5"
                    Padding="12,4" Height="28" Margin="8,0,0,0" BorderBrush="#3F3F46" BorderThickness="1" Cursor="Hand"/>
            <Button x:Name="BtnUncheckVisible" Grid.Column="2" Content="Uncheck All Visible"
                    Background="#27272A" Foreground="#E4E4E7" FontWeight="SemiBold" FontSize="11.5"
                    Padding="12,4" Height="28" Margin="6,0,0,0" BorderBrush="#3F3F46" BorderThickness="1" Cursor="Hand"/>
        </Grid>

        <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,0,0,8" VerticalAlignment="Center">
            <TextBlock Text="Keep Safe Presets:" FontSize="11.5" Foreground="#A1A1AA" VerticalAlignment="Center" Margin="0,0,8,0"/>
            <Button x:Name="BtnKeepRgb" Content="Keep RGB Control"
                    Background="#1E293B" Foreground="#60A5FA" FontWeight="SemiBold" FontSize="11.5"
                    Padding="10,4" Height="26" Margin="0,0,6,0" BorderBrush="#2563EB" BorderThickness="1" Cursor="Hand"/>
            <Button x:Name="BtnKeepController" Content="Keep Controller / Gamepad Support"
                    Background="#1E293B" Foreground="#60A5FA" FontWeight="SemiBold" FontSize="11.5"
                    Padding="10,4" Height="26" BorderBrush="#2563EB" BorderThickness="1" Cursor="Hand"/>
        </StackPanel>

        <Border Grid.Row="3" Background="#0C0C0E" BorderBrush="#2E2E34" BorderThickness="1" CornerRadius="6" Padding="10">
            <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto">
                <StackPanel x:Name="ItemsPanel"/>
            </ScrollViewer>
        </Border>

        <Grid Grid.Row="4" Margin="0,10,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock x:Name="TxtPickCount" Grid.Column="0" Text="" Foreground="#A1A1AA" FontSize="12" VerticalAlignment="Center"/>
            <Button x:Name="BtnApplySelected" Grid.Column="1" Content="Apply Selected Blocks"
                    Background="#22A055" Foreground="#FFFFFF" FontWeight="SemiBold" FontSize="12"
                    Padding="14,6" Height="32" Margin="0,0,8,0" BorderThickness="0" Cursor="Hand"/>
            <Button x:Name="BtnCancelPick" Grid.Column="2" Content="Cancel"
                    Background="#27272A" Foreground="#E4E4E7" FontWeight="SemiBold" FontSize="12"
                    Padding="14,6" Height="32" BorderBrush="#3F3F46" BorderThickness="1" Cursor="Hand"/>
        </Grid>
    </Grid>
</Window>
"@

    $PReader = (New-Object System.Xml.XmlNodeReader $PickXaml)
    $PickWin = [Windows.Markup.XamlReader]::Load($PReader)
    $PickWin.Owner = $Window
    if ($ZeroHookLogo) { $PickWin.Icon = $ZeroHookLogo }

    $TxtFilterBox     = $PickWin.FindName("TxtFilterBox")
    $BtnCheckVisible  = $PickWin.FindName("BtnCheckVisible")
    $BtnUncheckVisible= $PickWin.FindName("BtnUncheckVisible")
    $BtnKeepRgb       = $PickWin.FindName("BtnKeepRgb")
    $BtnKeepController= $PickWin.FindName("BtnKeepController")
    $ItemsPanel       = $PickWin.FindName("ItemsPanel")
    $TxtPickCount     = $PickWin.FindName("TxtPickCount")
    $BtnApplySelected = $PickWin.FindName("BtnApplySelected")
    $BtnCancelPick    = $PickWin.FindName("BtnCancelPick")

    $Entries = [System.Collections.Generic.List[object]]::new()
    $GroupHeaders = [System.Collections.Generic.List[object]]::new()
    $Script:SyncingGroupToggle = $false

    $SyncGroupToggleState = {
        param($gh)
        if ($Script:SyncingGroupToggle -or -not $gh.GroupToggle) { return }
        $Script:SyncingGroupToggle = $true
        try {
            $allChecked = $true
            foreach ($entry in $gh.Entries) {
                if (-not $entry.CheckBox.IsChecked) { $allChecked = $false; break }
            }
            $gh.GroupToggle.IsChecked = $allChecked
        } finally {
            $Script:SyncingGroupToggle = $false
        }
    }

    $UpdateCount = {
        $checked = @($Entries | Where-Object { $_.CheckBox.IsChecked }).Count
        $TxtPickCount.Text = "$checked of $($Entries.Count) items marked for blocking/disabling"
        foreach ($gh in $GroupHeaders) {
            & $SyncGroupToggleState $gh
        }
    }

    $ApplySearchFilter = {
        $q = ([string]$TxtFilterBox.Text).Trim().ToLower()
        foreach ($entry in $Entries) {
            $match = ([string]::IsNullOrEmpty($q)) -or $entry.SearchText.Contains($q)
            $entry.CheckBox.Visibility = if ($match) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
        }
        foreach ($gh in $GroupHeaders) {
            $anyVisible = $false
            foreach ($entry in $gh.Entries) {
                if ($entry.CheckBox.Visibility -eq [System.Windows.Visibility]::Visible) { $anyVisible = $true; break }
            }
            $gh.HeaderRow.Visibility = if ($anyVisible) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
        }
    }

    $Grouped = @($Candidates | Group-Object App | Sort-Object Name)
    foreach ($grp in $Grouped) {
        $hdrRow = New-Object System.Windows.Controls.StackPanel
        $hdrRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $hdrRow.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $hdrRow.Margin = New-Object System.Windows.Thickness(2, 10, 2, 3)

        $groupCb = New-Object System.Windows.Controls.CheckBox
        $groupCb.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $groupCb.Margin = New-Object System.Windows.Thickness(0, 0, 6, 0)

        $hdr = New-Object System.Windows.Controls.TextBlock
        $hdr.Text = "=== $($grp.Name) ==="
        $hdr.Foreground = $BrushCyan
        $hdr.FontWeight = "Bold"
        $hdr.FontFamily = New-Object System.Windows.Media.FontFamily("Consolas")
        $hdr.FontSize = 12
        $hdr.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

        [void]$hdrRow.Children.Add($groupCb)
        [void]$hdrRow.Children.Add($hdr)
        [void]$ItemsPanel.Children.Add($hdrRow)

        $grpEntries = [System.Collections.Generic.List[object]]::new()
        foreach ($c in $grp.Group) {
            $cb = New-Object System.Windows.Controls.CheckBox
            $statePrefix = if ($c.IsBlocked) { "[CURRENTLY BLOCKED] " } else { "[ACTIVE] " }
            $cb.Content = "$statePrefix$($c.DetailText)"
            $cb.Tag = $c
            $cb.IsChecked = (-not $c.IsExcluded)
            $cb.Foreground = if ($c.IsBlocked) { $BrushGreen } else { $BrushRed }
            $cb.Margin = New-Object System.Windows.Thickness(18, 2, 2, 2)
            $cb.FontFamily = New-Object System.Windows.Media.FontFamily("Consolas")
            $cb.FontSize = 11.5
            $cb.Add_Checked($UpdateCount)
            $cb.Add_Unchecked($UpdateCount)
            [void]$ItemsPanel.Children.Add($cb)

            $rec = [PSCustomObject]@{
                CheckBox   = $cb
                Candidate  = $c
                SearchText = "$($grp.Name) $($c.DetailText) $statePrefix".ToLower()
            }
            [void]$Entries.Add($rec)
            [void]$grpEntries.Add($rec)
        }

        $ghObj = [PSCustomObject]@{
            HeaderRow   = $hdrRow
            GroupToggle = $groupCb
            Entries     = $grpEntries
        }
        $groupCb.Tag = $ghObj
        $groupCb.Add_Checked({
            param($sender, $e)
            if ($Script:SyncingGroupToggle) { return }
            $gh = $sender.Tag
            foreach ($entry in $gh.Entries) {
                if ($entry.CheckBox.Visibility -eq [System.Windows.Visibility]::Visible) {
                    $entry.CheckBox.IsChecked = $true
                }
            }
            & $UpdateCount
        })
        $groupCb.Add_Unchecked({
            param($sender, $e)
            if ($Script:SyncingGroupToggle) { return }
            $gh = $sender.Tag
            foreach ($entry in $gh.Entries) {
                if ($entry.CheckBox.Visibility -eq [System.Windows.Visibility]::Visible) {
                    $entry.CheckBox.IsChecked = $false
                }
            }
            & $UpdateCount
        })

        [void]$GroupHeaders.Add($ghObj)
    }
    & $UpdateCount

    $RgbApps = @("MSI", "ASUS", "CORSAIR", "GIGABYTE", "ASROCK", "NZXT", "LOGITECH", "KINGSTON", "STEELSERIES", "OPENRGB / SIGNALRGB", "RAZER")
    $ControllerApps = @("SONY / DUALSENSE")

    $TxtFilterBox.Add_TextChanged($ApplySearchFilter)

    $BtnCheckVisible.Add_Click({
        foreach ($entry in $Entries) {
            if ($entry.CheckBox.Visibility -eq [System.Windows.Visibility]::Visible) {
                $entry.CheckBox.IsChecked = $true
            }
        }
        & $UpdateCount
    })

    $BtnUncheckVisible.Add_Click({
        foreach ($entry in $Entries) {
            if ($entry.CheckBox.Visibility -eq [System.Windows.Visibility]::Visible) {
                $entry.CheckBox.IsChecked = $false
            }
        }
        & $UpdateCount
    })

    $BtnKeepRgb.Add_Click({
        foreach ($entry in $Entries) {
            if ($entry.Candidate.App -in $RgbApps) {
                $entry.CheckBox.IsChecked = $false
            }
        }
        & $UpdateCount
    })

    $BtnKeepController.Add_Click({
        foreach ($entry in $Entries) {
            if ($entry.Candidate.App -in $ControllerApps) {
                $entry.CheckBox.IsChecked = $false
            }
        }
        & $UpdateCount
    })

    $Applied = $false
    $BtnApplySelected.Add_Click({ $Applied = $true; $PickWin.Close() })
    $BtnCancelPick.Add_Click({ $Applied = $false; $PickWin.Close() })

    $PickWin.ShowDialog() | Out-Null
    if (-not $Applied) { return }

    $NewExclusions = @()
    $CheckedIds = @()
    foreach ($entry in $Entries) {
        $id = $entry.Candidate.Id
        if ($entry.CheckBox.IsChecked) { $CheckedIds += $id }
        else { $NewExclusions += $id }
    }
    Save-Exclusions -Ids $NewExclusions

    Clear-Log "ACTIVITY LOG - BLOCKING SELECTED ITEMS (HOOKS + RGB/BLOAT)"
    $DisabledBytes = [byte[]](0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)

    foreach ($File in $Dlls) {
        if ($CheckedIds -notcontains "DLL|$($File.FullName)") { continue }
        $appTag = Get-AppGroupName "$($File.Name) $($File.FullName)"
        try {
            $Acl = Get-Acl -Path $File.FullName
            $Rule = New-Object System.Security.AccessControl.FileSystemAccessRule($EveryoneSID, "ReadAndExecute", "Deny")
            $Acl.SetAccessRule($Rule)
            Set-Acl -Path $File.FullName -AclObject $Acl
            Add-Log -Badge "[BLOCKED][$appTag] " -Message (Hide-Username $File.FullName) -BadgeColor "Green" -NoScroll
        } catch {
            Add-Log -Badge "[FAILED][$appTag] " -Message "$(Hide-Username $File.FullName) - $($_.Exception.Message)" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    foreach ($Layer in $VulkanLayers) {
        if ($CheckedIds -notcontains "VULKAN|$($Layer.Key)|$($Layer.Name)") { continue }
        $appTag = Get-AppGroupName $Layer.Name
        try {
            Set-ItemProperty -Path $Layer.Key -Name $Layer.Name -Value 1 -Type DWord
            Add-Log -Badge "[DISABLED VULKAN][$appTag] " -Message (Hide-Username $Layer.Name) -BadgeColor "Green" -NoScroll
        } catch {
            Add-Log -Badge "[FAILED VULKAN][$appTag] " -Message "$(Hide-Username $Layer.Name) - $($_.Exception.Message)" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    if ($CheckedIds -contains "GAMEBAR|XBOX") {
        try {
            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord
            New-Item -Path "HKCU:\System\GameConfigStore" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord
            Add-Log -Badge "[DISABLED][XBOX / GAME BAR] " -Message "Xbox Game Bar & Game DVR Registry Hooks" -BadgeColor "Green" -NoScroll
        } catch {
            Add-Log -Badge "[FAILED][XBOX / GAME BAR] " -Message $_.Exception.Message -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    foreach ($Svc in $Services) {
        if ($CheckedIds -notcontains "SVC|$($Svc.Name)") { continue }
        $appTag = Get-AppGroupName "$($Svc.Name) $($Svc.DisplayName)"
        try {
            if ($Svc.StartType -ne "Manual" -and $Svc.StartType -ne "Disabled") { Set-Service -Name $Svc.Name -StartupType Manual -ErrorAction Stop }
            if ($Svc.Status -eq "Running") { Stop-Service -Name $Svc.Name -Force -ErrorAction SilentlyContinue }
            Add-Log -Badge "[MANUAL & STOPPED][$appTag] " -Message "$($Svc.DisplayName) ($($Svc.Name))" -BadgeColor "Green" -NoScroll
        } catch {
            Add-Log -Badge "[FAILED SERVICE][$appTag] " -Message "$($Svc.Name) - $($_.Exception.Message)" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    foreach ($Item in $StartupItems) {
        if ($CheckedIds -notcontains "RUN|$($Item.RunPath)|$($Item.Name)") { continue }
        $appTag = Get-AppGroupName "$($Item.Name) $($Item.Command)"
        try {
            if (-not (Test-Path $Item.ApprovedPath)) { New-Item -Path $Item.ApprovedPath -Force | Out-Null }
            Set-ItemProperty -Path $Item.ApprovedPath -Name $Item.Name -Value $DisabledBytes -Type Binary -ErrorAction Stop
            Add-Log -Badge "[DISABLED STARTUP][$appTag] " -Message $Item.Name -BadgeColor "Green" -NoScroll
        } catch {
            Add-Log -Badge "[FAILED STARTUP][$appTag] " -Message "$($Item.Name) - $($_.Exception.Message)" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    foreach ($Sc in ($Shortcuts | Where-Object { -not $_.IsDisabled })) {
        if ($CheckedIds -notcontains "SHORTCUT|$($Sc.OrigFolder)|$($Sc.Name)") { continue }
        $appTag = Get-AppGroupName "$($Sc.Name) $($Sc.FullPath)"
        try {
            $Sub = if ($Sc.OrigFolder -eq $StartupFolderPaths[0]) { "User" } else { "Common" }
            $DestDir = Join-Path $StartupBackupDir $Sub
            if (-not (Test-Path $DestDir)) { New-Item -Path $DestDir -ItemType Directory -Force | Out-Null }
            Move-Item -Path $Sc.FullPath -Destination (Join-Path $DestDir $Sc.Name) -Force -ErrorAction Stop
            Add-Log -Badge "[DISABLED SHORTCUT][$appTag] " -Message $Sc.Name -BadgeColor "Green" -NoScroll
        } catch {
            Add-Log -Badge "[FAILED SHORTCUT][$appTag] " -Message "$($Sc.Name) - $($_.Exception.Message)" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    foreach ($Task in $VendorTasks) {
        if ($CheckedIds -notcontains "TASK|$($Task.TaskPath)$($Task.TaskName)") { continue }
        $appTag = Get-AppGroupName "$($Task.TaskPath)$($Task.TaskName)"
        try {
            if ($Task.State -ne "Disabled") { Disable-ScheduledTask -TaskName $Task.TaskName -TaskPath $Task.TaskPath -ErrorAction Stop | Out-Null }
            Add-Log -Badge "[DISABLED TASK][$appTag] " -Message "  $($Task.TaskPath)$($Task.TaskName)" -BadgeColor "Green" -NoScroll
        } catch {
            Add-Log -Badge "[FAILED TASK][$appTag] " -Message "$($Task.TaskName) - $($_.Exception.Message)" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }

    Add-Log -Badge "`n=== BLOCK COMPLETE ===" -BadgeColor "Cyan"
    Update-Dashboard -Filter "NONE"
}

function Render-PerAppSummary {
    param([string]$AppFilter = "ALL APPS", [string]$CategoryFilter = "ALL")
    $D = $Script:ScanData
    if (-not $D -or $D.Count -eq 0) { return }
    $Entries = @()

    if ($CategoryFilter -in @("ALL", "DLLS")) {
        foreach ($File in $D.Dlls) {
            $IsBlocked = [bool]$File.IsBlocked
            $Entries += [PSCustomObject]@{
                App = (Get-AppGroupName "$($File.Name) $($File.FullName)"); IsBlocked = $IsBlocked
                StatusText = if ($IsBlocked) { "BLOCKED" } else { "ACTIVE" }; Detail = (Hide-Username $File.FullName)
            }
        }
    }
    if ($CategoryFilter -in @("ALL", "VULKAN")) {
        foreach ($Layer in $D.VulkanLayers) {
            $Entries += [PSCustomObject]@{
                App = (Get-AppGroupName $Layer.Name); IsBlocked = [bool]$Layer.IsDisabled
                StatusText = if ($Layer.IsDisabled) { "BLOCKED/OFF" } else { "ENABLED" }; Detail = (Hide-Username $Layer.Name)
            }
        }
        $Entries += [PSCustomObject]@{
            App = "XBOX / GAME BAR"; IsBlocked = [bool]$D.GameBarOff
            StatusText = if ($D.GameBarOff) { "BLOCKED/OFF" } else { "ENABLED" }; Detail = "Xbox Game Bar / Game DVR Background Hooks"
        }
    }
    if ($CategoryFilter -in @("ALL", "SERVICES")) {
        foreach ($Svc in $D.Services) {
            $Off = ($Svc.StartType -eq "Manual" -or $Svc.StartType -eq "Disabled")
            $Entries += [PSCustomObject]@{
                App = (Get-AppGroupName "$($Svc.Name) $($Svc.DisplayName)"); IsBlocked = $Off
                StatusText = if ($Off) { "BLOCKED/MANUAL" } else { "AUTO/RUNNING" }
                Detail = "$($Svc.DisplayName) ($($Svc.Name)) [Start: $($Svc.StartType), State: $($Svc.Status)]"
            }
        }
    }
    if ($CategoryFilter -in @("ALL", "STARTUP")) {
        foreach ($Item in $D.StartupItems) {
            $Entries += [PSCustomObject]@{
                App = (Get-AppGroupName "$($Item.Name) $($Item.Command)"); IsBlocked = [bool]$Item.IsDisabled
                StatusText = if ($Item.IsDisabled) { "BLOCKED/OFF" } else { "ENABLED" }; Detail = "[Run] $($Item.Name)"
            }
        }
        foreach ($Sc in $D.Shortcuts) {
            $Entries += [PSCustomObject]@{
                App = (Get-AppGroupName "$($Sc.Name) $($Sc.FullPath)"); IsBlocked = [bool]$Sc.IsDisabled
                StatusText = if ($Sc.IsDisabled) { "BLOCKED/OFF" } else { "ENABLED" }; Detail = "[Shortcut] $($Sc.Name)"
            }
        }
        foreach ($Task in $D.VendorTasks) {
            $Off = ($Task.State -eq "Disabled")
            $Entries += [PSCustomObject]@{
                App = (Get-AppGroupName "$($Task.TaskPath)$($Task.TaskName)"); IsBlocked = $Off
                StatusText = if ($Off) { "BLOCKED/OFF" } else { "ENABLED" }; Detail = "[Task] $($Task.TaskPath)$($Task.TaskName)"
            }
        }
    }
    if ($CategoryFilter -in @("ALL", "LAUNCHERS")) {
        foreach ($G in ($D.RunningProcs | Group-Object ProcessName)) {
            $Entries += [PSCustomObject]@{
                App = (Get-AppGroupName $G.Name); IsBlocked = $false
                StatusText = "RUNNING ($($G.Count))"; Detail = "$($G.Name).exe"
            }
        }
    }
    if ($AppFilter -ne "ALL APPS") { $Entries = @($Entries | Where-Object { $_.App -eq $AppFilter }) }

    Add-Log -Badge "`n=== PER-APP BREAKDOWN ($AppFilter) ===" -BadgeColor "Cyan" -NoScroll
    if ($Entries.Count -eq 0) {
        Add-Log -Message "  No matching items found for '$AppFilter' in this view." -MsgColor "Muted" -NoScroll
        if ($AppFilter -eq "STEAM") { Add-SteamClientTipToLog -NoScroll }
        return
    }
    foreach ($Grp in ($Entries | Group-Object App | Sort-Object Name)) {
        $Items = @($Grp.Group)
        $BlockedCount = @($Items | Where-Object { $_.IsBlocked }).Count
        $TotalCount = $Items.Count
        $AppColor = if ($BlockedCount -eq $TotalCount) { "Green" } elseif ($BlockedCount -gt 0) { "Yellow" } else { "Red" }
        Add-Log -Badge "`n$($Grp.Name): " -Message "$BlockedCount / $TotalCount" -BadgeColor $AppColor -MsgColor "Cyan" -NoScroll
        foreach ($It in $Items) {
            Add-Log -Badge "  [$($It.StatusText.PadRight(14))] " -Message "$($It.Detail)" -BadgeColor $(if ($It.IsBlocked) { "Green" } else { "Red" }) -NoScroll
        }
    }
}

function Render-FilteredLog {
    param([string]$Filter = $Script:CurrentCategoryFilter)
    if ($Filter -eq "NONE") { return }
    $Script:CurrentCategoryFilter = $Filter
    $AppFilter = if ($CmbAppFilter.SelectedItem) { [string]$CmbAppFilter.SelectedItem } else { "ALL APPS" }
    $D = $Script:ScanData
    if (-not $D -or $D.Count -eq 0) { return }

    Clear-Log "$Filter - FILTER: $AppFilter"
    if ($AppFilter -ne "ALL APPS") {
        Render-PerAppSummary -AppFilter $AppFilter -CategoryFilter $Filter
        if ($AppFilter -eq "STEAM") { Add-SteamClientTipToLog -NoScroll }
        Add-Log -Badge "`n=== SCAN COMPLETE ===" -BadgeColor "Cyan"
        return
    }

    if ($Filter -in @("ALL", "TASK")) {
        Add-Log -Badge "[0/5] Startup Auto-Block Task:" -BadgeColor "Yellow" -NoScroll
        if ($D.Task) { Add-Log -Badge "  [ENABLED]  " -Message "Scheduled Task '$TaskName' is active (60s delay)" -BadgeColor "Green" -NoScroll }
        else { Add-Log -Badge "  [DISABLED] " -Message "No startup Scheduled Task configured" -BadgeColor "Muted" -NoScroll }
    }
    if ($Filter -in @("ALL", "DLLS")) {
        Add-Log -Badge "`n[1/5] Overlay & Hook DLL Files:" -BadgeColor "Yellow" -NoScroll
        foreach ($File in $D.Dlls) {
            $AppTag = Get-AppGroupName "$($File.Name) $($File.FullName)"
            Add-Log -Badge "  [$(if ($File.IsBlocked) { 'BLOCKED' } else { 'ACTIVE ' })][$AppTag] " -Message (Hide-Username $File.FullName) -BadgeColor $(if ($File.IsBlocked) { 'Green' } else { 'Red' }) -NoScroll
        }
    }
    if ($Filter -in @("ALL", "VULKAN")) {
        Add-Log -Badge "`n[2/5] Vulkan Implicit Layers & Xbox Game Bar:" -BadgeColor "Yellow" -NoScroll
        foreach ($Layer in $D.VulkanLayers) {
            $AppTag = Get-AppGroupName $Layer.Name
            Add-Log -Badge "  [$(if ($Layer.IsDisabled) { 'DISABLED' } else { 'ENABLED ' }) VULKAN][$AppTag] " -Message (Hide-Username $Layer.Name) -BadgeColor $(if ($Layer.IsDisabled) { 'Green' } else { 'Red' }) -NoScroll
        }
        Add-Log -Badge "  [$(if ($D.GameBarOff) { 'DISABLED' } else { 'ENABLED ' })][XBOX / GAME BAR] " -Message "Xbox Game Bar / Game DVR Background Hooks" -BadgeColor $(if ($D.GameBarOff) { 'Green' } else { 'Red' }) -NoScroll
    }
    if ($Filter -in @("ALL", "SERVICES")) {
        Add-Log -Badge "`n[3/5] RGB, Updater & Utility Services:" -BadgeColor "Yellow" -NoScroll
        foreach ($Svc in $D.Services) {
            $Off = ($Svc.StartType -eq "Manual" -or $Svc.StartType -eq "Disabled")
            $AppTag = Get-AppGroupName "$($Svc.Name) $($Svc.DisplayName)"
            Add-Log -Badge "  [$(if ($Off) { 'MANUAL/OFF' } else { 'AUTO/ON   ' })][$AppTag] " -Message "$($Svc.DisplayName) ($($Svc.Name)) - Start: $($Svc.StartType) | State: $($Svc.Status)" -BadgeColor $(if ($Off) { 'Green' } else { 'Red' }) -NoScroll
        }
    }
    if ($Filter -in @("ALL", "STARTUP")) {
        Add-Log -Badge "`n[4/5] Utility Startup Apps, Shortcuts & Vendor Scheduled Tasks:" -BadgeColor "Yellow" -NoScroll
        foreach ($Item in $D.StartupItems) {
            $AppTag = Get-AppGroupName "$($Item.Name) $($Item.Command)"
            Add-Log -Badge "  [$(if ($Item.IsDisabled) { 'DISABLED' } else { 'ENABLED ' }) STARTUP][$AppTag] " -Message "$($Item.Name) ($($Item.RunPath))" -BadgeColor $(if ($Item.IsDisabled) { 'Green' } else { 'Red' }) -NoScroll
        }
        foreach ($Sc in $D.Shortcuts) {
            $AppTag = Get-AppGroupName "$($Sc.Name) $($Sc.FullPath)"
            Add-Log -Badge "  [$(if ($Sc.IsDisabled) { 'DISABLED' } else { 'ENABLED ' }) SHORTCUT][$AppTag] " -Message "$($Sc.Name) ($(Hide-Username $Sc.OrigFolder))" -BadgeColor $(if ($Sc.IsDisabled) { 'Green' } else { 'Red' }) -NoScroll
        }
        foreach ($Task in $D.VendorTasks) {
            $Off = ($Task.State -eq "Disabled")
            $AppTag = Get-AppGroupName "$($Task.TaskPath)$($Task.TaskName)"
            Add-Log -Badge "  [$(if ($Off) { 'DISABLED' } else { 'ENABLED ' }) TASK][$AppTag] " -Message "$($Task.TaskPath)$($Task.TaskName)" -BadgeColor $(if ($Off) { 'Green' } else { 'Red' }) -NoScroll
        }
    }
    if ($Filter -in @("ALL", "LAUNCHERS")) {
        Add-Log -Badge "`n[5/5] Background Launcher & Overlay Processes:" -BadgeColor "Yellow" -NoScroll
        if ($D.RunningProcs.Count -eq 0) {
            Add-Log -Badge "  [CLEAN] " -Message "No background launchers or overlay processes are running." -BadgeColor "Green" -NoScroll
        } else {
            foreach ($G in ($D.RunningProcs | Group-Object ProcessName)) {
                $AppTag = Get-AppGroupName $G.Name
                Add-Log -Badge "  [RUNNING][$AppTag] " -Message "$($G.Name).exe (Instances: $($G.Count))" -BadgeColor "Red" -NoScroll
            }
        }
    }
    if ($Filter -eq "ALL") {
        Render-PerAppSummary -AppFilter "ALL APPS" -CategoryFilter "ALL"
        Add-SteamClientTipToLog -NoScroll
    }
    Add-Log -Badge "`n=== SCAN COMPLETE ===" -BadgeColor "Cyan"
}

function Update-Dashboard {
    param([string]$Filter = $Script:CurrentCategoryFilter)
    $AllServices = @(Get-Service -ErrorAction SilentlyContinue)
    $AllTasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue)
    $ExistingTask = $AllTasks | Where-Object { $_.TaskName -eq $TaskName } | Select-Object -First 1
    $Dlls = @(Get-OverlayDLLs)
    $VulkanLayers = @(Get-VulkanLayersList)
    $GameBarOff = Get-GameBarStatus
    $Services = @(Get-UtilityServices -AllServices $AllServices)
    $StartupItems = @(Get-UtilityStartupItems)
    $Shortcuts = @(Get-UtilityStartupShortcuts)
    $VendorTasks = @(Get-UtilityScheduledTasks -AllTasks $AllTasks)
    $RunningProcs = @(Get-RunningLaunchers)

    $Script:ScanData = @{
        Task = $ExistingTask; Dlls = $Dlls; VulkanLayers = $VulkanLayers; GameBarOff = $GameBarOff
        Services = $Services; StartupItems = $StartupItems; Shortcuts = $Shortcuts; VendorTasks = $VendorTasks; RunningProcs = $RunningProcs
    }

    $TxtCardTaskStatus.Text = if ($ExistingTask) { "ENABLED" } else { "DISABLED" }
    $TxtCardTaskStatus.Foreground = if ($ExistingTask) { $BrushGreen } else { $BrushGray }

    $BlockedDllCount = @($Dlls | Where-Object { $_.IsBlocked }).Count
    $TxtCardDllStatus.Text = if ($Dlls.Count -eq 0) { "NONE FOUND" } else { "$BlockedDllCount/$($Dlls.Count) BLOCKED" }
    $TxtCardDllStatus.Foreground = if ($Dlls.Count -eq 0) { $BrushGray } elseif ($BlockedDllCount -eq $Dlls.Count) { $BrushGreen } else { $BrushRed }

    $DisabledVulkanCount = @($VulkanLayers | Where-Object { $_.IsDisabled }).Count
    $TxtCardVulkanStatus.Text = if ($GameBarOff -and ($DisabledVulkanCount -eq $VulkanLayers.Count)) { "ALL DISABLED" } else { "$DisabledVulkanCount/$($VulkanLayers.Count) VULKAN OFF" }
    $TxtCardVulkanStatus.Foreground = if ($GameBarOff -and ($DisabledVulkanCount -eq $VulkanLayers.Count)) { $BrushGreen } else { $BrushYellow }

    $ManualSvcCount = @($Services | Where-Object { $_.StartType -eq "Manual" -or $_.StartType -eq "Disabled" }).Count
    $TxtCardSvcStatus.Text = if ($Services.Count -eq 0) { "NONE FOUND" } else { "$ManualSvcCount/$($Services.Count) MANUAL" }
    $TxtCardSvcStatus.Foreground = if ($Services.Count -eq 0) { $BrushGray } elseif ($ManualSvcCount -eq $Services.Count) { $BrushGreen } else { $BrushRed }

    $TotalStartup = $StartupItems.Count + $Shortcuts.Count + $VendorTasks.Count
    $DisabledStartup = @($StartupItems | Where-Object { $_.IsDisabled }).Count +
                       @($Shortcuts | Where-Object { $_.IsDisabled }).Count +
                       @($VendorTasks | Where-Object { $_.State -eq "Disabled" }).Count
    $TxtCardStartupStatus.Text = if ($TotalStartup -eq 0) { "NONE FOUND" } else { "$DisabledStartup/$TotalStartup OFF" }
    $TxtCardStartupStatus.Foreground = if ($TotalStartup -eq 0) { $BrushGray } elseif ($DisabledStartup -eq $TotalStartup) { $BrushGreen } else { $BrushRed }

    $TxtCardLauncherStatus.Text = if ($RunningProcs.Count -eq 0) { "NONE RUNNING" } else { "$(@($RunningProcs.ProcessName | Select-Object -Unique).Count) APPS RUNNING" }
    $TxtCardLauncherStatus.Foreground = if ($RunningProcs.Count -eq 0) { $BrushGreen } else { $BrushYellow }

    Render-FilteredLog -Filter $Filter
}

function Prompt-CloseLaunchers {
    $Running = Get-RunningLaunchers
    if ($Running.Count -gt 0) {
        $Res = [System.Windows.MessageBox]::Show(
            "Background launchers, RGB apps, or cloud/updater processes are running. Close them first?",
            "ZeroHook",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Question
        )
        if ($Res -eq [System.Windows.MessageBoxResult]::Yes) {
            foreach ($ProcName in $LauncherProcesses) {
                Get-Process -Name $ProcName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            }
            Start-Sleep -Seconds 2
        }
    }
}

function Invoke-BlockHooksGUI {
    $ExcludedIds = Get-SavedExclusions
    foreach ($File in (Get-OverlayDLLs)) {
        if ($ExcludedIds -contains "DLL|$($File.FullName)") { continue }
        $appTag = Get-AppGroupName "$($File.Name) $($File.FullName)"
        try {
            $Acl = Get-Acl -Path $File.FullName
            $Rule = New-Object System.Security.AccessControl.FileSystemAccessRule($EveryoneSID, "ReadAndExecute", "Deny")
            $Acl.SetAccessRule($Rule)
            Set-Acl -Path $File.FullName -AclObject $Acl
            Add-Log -Badge "[BLOCKED][$appTag] " -Message (Hide-Username $File.FullName) -BadgeColor "Green" -NoScroll
        } catch {
            Add-Log -Badge "[FAILED][$appTag] " -Message "$(Hide-Username $File.FullName) - $($_.Exception.Message)" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    foreach ($Layer in (Get-VulkanLayersList)) {
        if ($ExcludedIds -contains "VULKAN|$($Layer.Key)|$($Layer.Name)") { continue }
        $appTag = Get-AppGroupName $Layer.Name
        try {
            Set-ItemProperty -Path $Layer.Key -Name $Layer.Name -Value 1 -Type DWord
            Add-Log -Badge "[DISABLED VULKAN][$appTag] " -Message (Hide-Username $Layer.Name) -BadgeColor "Green" -NoScroll
        } catch {
            Add-Log -Badge "[FAILED VULKAN][$appTag] " -Message "$(Hide-Username $Layer.Name) - $($_.Exception.Message)" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    if ($ExcludedIds -notcontains "GAMEBAR|XBOX") {
        try {
            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord
            New-Item -Path "HKCU:\System\GameConfigStore" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord
            Add-Log -Badge "[DISABLED][XBOX / GAME BAR] " -Message "Xbox Game Bar & Game DVR Registry Hooks" -BadgeColor "Green" -NoScroll
        } catch {
            Add-Log -Badge "[FAILED][XBOX / GAME BAR] " -Message $_.Exception.Message -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
}

function Invoke-RestoreHooksGUI {
    foreach ($File in (Get-OverlayDLLs)) {
        $appTag = Get-AppGroupName "$($File.Name) $($File.FullName)"
        try {
            $Acl = Get-Acl -Path $File.FullName
            $Removed = $false
            foreach ($Rule in @($Acl.Access)) {
                if (Test-IsEveryoneDenyRule $Rule) { $Acl.RemoveAccessRule($Rule) | Out-Null; $Removed = $true }
            }
            if ($Removed) {
                Set-Acl -Path $File.FullName -AclObject $Acl
                Add-Log -Badge "[RESTORED][$appTag] " -Message (Hide-Username $File.FullName) -BadgeColor "Green" -NoScroll
            }
        } catch {
            Add-Log -Badge "[FAILED RESTORE][$appTag] " -Message "$(Hide-Username $File.FullName) - $($_.Exception.Message)" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    foreach ($Layer in (Get-VulkanLayersList)) {
        try {
            Set-ItemProperty -Path $Layer.Key -Name $Layer.Name -Value 0 -Type DWord
        } catch {
            Add-Log -Badge "[FAILED RESTORE VULKAN] " -Message "$(Hide-Username $Layer.Name) - $($_.Exception.Message)" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    } catch {
        Add-Log -Badge "[FAILED RESTORE GAMEBAR] " -Message $_.Exception.Message -BadgeColor "Red" -MsgColor "Red" -NoScroll
    }
}

function Invoke-BlockUtilitiesGUI {
    $ExcludedIds = Get-SavedExclusions
    foreach ($Svc in (Get-UtilityServices)) {
        if ($ExcludedIds -contains "SVC|$($Svc.Name)") { continue }
        $appTag = Get-AppGroupName "$($Svc.Name) $($Svc.DisplayName)"
        try {
            if ($Svc.StartType -ne "Manual" -and $Svc.StartType -ne "Disabled") { Set-Service -Name $Svc.Name -StartupType Manual -ErrorAction Stop }
            if ($Svc.Status -eq "Running") { Stop-Service -Name $Svc.Name -Force -ErrorAction SilentlyContinue }
            Add-Log -Badge "[MANUAL & STOPPED][$appTag] " -Message "$($Svc.DisplayName) ($($Svc.Name))" -BadgeColor "Green" -NoScroll
        } catch {
            Add-Log -Badge "[FAILED SERVICE][$appTag] " -Message "$($Svc.Name) - $($_.Exception.Message)" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    $DisabledBytes = [byte[]](0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    foreach ($Item in (Get-UtilityStartupItems)) {
        if ($ExcludedIds -contains "RUN|$($Item.RunPath)|$($Item.Name)") { continue }
        $appTag = Get-AppGroupName "$($Item.Name) $($Item.Command)"
        try {
            if (-not (Test-Path $Item.ApprovedPath)) { New-Item -Path $Item.ApprovedPath -Force | Out-Null }
            Set-ItemProperty -Path $Item.ApprovedPath -Name $Item.Name -Value $DisabledBytes -Type Binary -ErrorAction Stop
            Add-Log -Badge "[DISABLED STARTUP][$appTag] " -Message $Item.Name -BadgeColor "Green" -NoScroll
        } catch {
            Add-Log -Badge "[FAILED STARTUP][$appTag] " -Message "$($Item.Name) - $($_.Exception.Message)" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    foreach ($Sc in (Get-UtilityStartupShortcuts | Where-Object { -not $_.IsDisabled })) {
        if ($ExcludedIds -contains "SHORTCUT|$($Sc.OrigFolder)|$($Sc.Name)") { continue }
        $appTag = Get-AppGroupName "$($Sc.Name) $($Sc.FullPath)"
        try {
            $Sub = if ($Sc.OrigFolder -eq $StartupFolderPaths[0]) { "User" } else { "Common" }
            $DestDir = Join-Path $StartupBackupDir $Sub
            if (-not (Test-Path $DestDir)) { New-Item -Path $DestDir -ItemType Directory -Force | Out-Null }
            Move-Item -Path $Sc.FullPath -Destination (Join-Path $DestDir $Sc.Name) -Force -ErrorAction Stop
            Add-Log -Badge "[DISABLED SHORTCUT][$appTag] " -Message $Sc.Name -BadgeColor "Green" -NoScroll
        } catch {
            Add-Log -Badge "[FAILED SHORTCUT][$appTag] " -Message "$($Sc.Name) - $($_.Exception.Message)" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    foreach ($Task in (Get-UtilityScheduledTasks)) {
        if ($ExcludedIds -contains "TASK|$($Task.TaskPath)$($Task.TaskName)") { continue }
        $appTag = Get-AppGroupName "$($Task.TaskPath)$($Task.TaskName)"
        try {
            if ($Task.State -ne "Disabled") { Disable-ScheduledTask -TaskName $Task.TaskName -TaskPath $Task.TaskPath -ErrorAction Stop | Out-Null }
            Add-Log -Badge "[DISABLED TASK][$appTag] " -Message "  $($Task.TaskPath)$($Task.TaskName)" -BadgeColor "Green" -NoScroll
        } catch {
            Add-Log -Badge "[FAILED TASK][$appTag] " -Message "$($Task.TaskName) - $($_.Exception.Message)" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
}

function Invoke-RestoreUtilitiesGUI {
    foreach ($Svc in (Get-UtilityServices)) {
        try {
            Set-Service -Name $Svc.Name -StartupType Automatic -ErrorAction Stop
            Start-Service -Name $Svc.Name -ErrorAction SilentlyContinue
        } catch {
            Add-Log -Badge "[FAILED RESTORE SERVICE] " -Message "$($Svc.Name) - $($_.Exception.Message)" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    $EnabledBytes = [byte[]](0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    foreach ($Item in (Get-UtilityStartupItems)) {
        try {
            if (Test-Path $Item.ApprovedPath) { Set-ItemProperty -Path $Item.ApprovedPath -Name $Item.Name -Value $EnabledBytes -Type Binary -ErrorAction Stop }
        } catch {
            Add-Log -Badge "[FAILED RESTORE STARTUP] " -Message "$($Item.Name) - $($_.Exception.Message)" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    foreach ($Sc in (Get-UtilityStartupShortcuts | Where-Object { $_.IsDisabled })) {
        try {
            if (-not (Test-Path $Sc.OrigFolder)) { New-Item -Path $Sc.OrigFolder -ItemType Directory -Force | Out-Null }
            Move-Item -Path $Sc.FullPath -Destination (Join-Path $Sc.OrigFolder $Sc.Name) -Force -ErrorAction Stop
        } catch {
            Add-Log -Badge "[FAILED RESTORE SHORTCUT] " -Message "$($Sc.Name) - $($_.Exception.Message)" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    foreach ($Task in (Get-UtilityScheduledTasks)) {
        try {
            Enable-ScheduledTask -TaskName $Task.TaskName -TaskPath $Task.TaskPath -ErrorAction Stop | Out-Null
        } catch {
            Add-Log -Badge "[FAILED RESTORE TASK] " -Message "$($Task.TaskName) - $($_.Exception.Message)" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
}

$CmbAppFilter.Add_SelectionChanged({
    if (-not $Script:SuppressFilterEvent -and $Script:ScanData.Count -gt 0) {
        Render-FilteredLog -Filter $Script:CurrentCategoryFilter
    }
})

$BtnCopyBugReport.Add_Click({
    try {
        Copy-BugReportToClipboard -FallbackTitle $TxtLogHeader.Text
        $BtnCopyBugReport.Content = "Copied!"
        Add-Log -Badge "[$(Get-Date -Format 'HH:mm:ss')] [BUG REPORT COPIED] " -Message "Diagnostic info and recent logs copied to clipboard. Paste it in your message/issue to GS." -BadgeColor "Green" -MsgColor "Gray"
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 350
        $BtnCopyBugReport.Content = "Copy Log for Dev"
    } catch {
        Write-DiagnosticLog -Level "ERROR" -Source "CLIPBOARD" -Message "Failed to copy bug report: $($_.Exception.Message)" -ForceTrim
        [System.Windows.MessageBox]::Show("Could not copy log to clipboard:`n$($_.Exception.Message)", "ZeroHook") | Out-Null
    }
})

$BtnAboutInfo.Add_Click({ Show-AboutInfoWindow })
$BtnRefresh.Add_Click({ Update-Dashboard -Filter "ALL" })
$BtnQuickFilter.Add_Click({
    $Script:SuppressFilterEvent = $true
    $CmbAppFilter.SelectedIndex = 0
    $Script:SuppressFilterEvent = $false
    Render-FilteredLog -Filter "ALL"
})

$CardTask.Add_Click({ Render-FilteredLog -Filter "TASK" })
$CardDlls.Add_Click({ Render-FilteredLog -Filter "DLLS" })
$CardVulkan.Add_Click({ Render-FilteredLog -Filter "VULKAN" })
$CardServices.Add_Click({ Render-FilteredLog -Filter "SERVICES" })
$CardStartup.Add_Click({ Render-FilteredLog -Filter "STARTUP" })
$CardLaunchers.Add_Click({ Render-FilteredLog -Filter "LAUNCHERS" })

$BtnBlockAll.Add_Click({
    Clear-Log "ACTIVITY LOG - BLOCKING EVERYTHING (HOOKS + RGB/BLOAT)"
    Prompt-CloseLaunchers
    Invoke-BlockHooksGUI
    Invoke-BlockUtilitiesGUI
    Add-Log -Badge "`n=== BLOCK COMPLETE ===" -BadgeColor "Cyan"
    Update-Dashboard -Filter "NONE"
})

$BtnCustomBlock.Add_Click({ Show-CustomBlockDialog })

$BtnRestoreAll.Add_Click({
    Clear-Log "ACTIVITY LOG - RESTORING EVERYTHING"
    Prompt-CloseLaunchers
    Invoke-RestoreHooksGUI
    Invoke-RestoreUtilitiesGUI
    Add-Log -Badge "`n=== RESTORE COMPLETE ===" -BadgeColor "Cyan"
    Update-Dashboard -Filter "NONE"
})

$BtnBlockOverlaysOnly.Add_Click({
    Clear-Log "ACTIVITY LOG - BLOCKING OVERLAY HOOKS ONLY"
    Prompt-CloseLaunchers
    Invoke-BlockHooksGUI
    Add-Log -Badge "`n=== OVERLAY HOOK BLOCK COMPLETE ===" -BadgeColor "Cyan"
    Update-Dashboard -Filter "NONE"
})

$BtnToggleTask.Add_Click({
    $ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($ExistingTask) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Add-Log -Badge "[$(Get-Date -Format 'HH:mm:ss')] [TASK REMOVED] " -Message "Scheduled Task '$TaskName' disabled and removed from Task Scheduler." -BadgeColor "Yellow" -MsgColor "Gray"
        Update-Dashboard -Filter "NONE"
    } else {
        try {
            $ExePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
            $IsHostShell = (-not $ExePath) -or ($ExePath -match '(?i)\\(powershell|pwsh)\.exe$')

            if ($IsHostShell) {
                $SavedScript = Save-LocalScriptCopy
                $PsExe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
                $Action = New-ScheduledTaskAction -Execute $PsExe -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$SavedScript`" -AutoBlock"
                $TargetDesc = $SavedScript
            } else {
                $Action = New-ScheduledTaskAction -Execute $ExePath -Argument "-AutoBlock"
                $TargetDesc = $ExePath
            }

            $TriggerStartup = New-ScheduledTaskTrigger -AtStartup; $TriggerStartup.Delay = "PT60S"
            $TriggerLogon = New-ScheduledTaskTrigger -AtLogOn; $TriggerLogon.Delay = "PT60S"
            $Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
            $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden
            Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger @($TriggerStartup, $TriggerLogon) -Principal $Principal -Settings $Settings -Force | Out-Null
            Add-Log -Badge "[$(Get-Date -Format 'HH:mm:ss')] [TASK ENABLED] " -Message "Scheduled Task '$TaskName' registered (60s delay at startup/logon) pointing to: $(Hide-Username $TargetDesc)" -BadgeColor "Green" -MsgColor "Gray" -NoScroll
            if (-not $IsHostShell) {
                Add-Log -Badge "  [IMPORTANT] " -Message "Keep ZeroHook in its current folder/location—moving or renaming the executable will break the Scheduled Task until re-enabled." -BadgeColor "Yellow" -MsgColor "Yellow"
            } else {
                Add-Log -Badge "  [SAVED LOCALLY] " -Message "Saved a local copy to $(Hide-Username $SavedScript) so Auto-Block runs reliably at startup without internet." -BadgeColor "Cyan" -MsgColor "Gray"
            }
            Update-Dashboard -Filter "NONE"
        } catch {
            Add-Log -Badge "[$(Get-Date -Format 'HH:mm:ss')] [FAILED] " -Message $_.Exception.Message -BadgeColor "Red" -MsgColor "Red"
        }
    }
})

$BtnReloadProcs.Add_Click({ Refresh-HookProcessList })
$CmbHookProcess.Add_SelectionChanged({
    if ($Script:SuppressHookProcessSelection) { return }
    $Script:SeenModuleKeys.Clear()
    $Script:PendingHookDetections.Clear()
    $Script:LastHookSnapshot = $null
    $Script:LastHookTargetInfo = $null
    $Script:LiveHookTarget = Get-SelectedHookTarget
    if ($Script:LiveHookTarget) { Invoke-HookMonitorStep -ForceLogSnapshot }
})
$CmbPollInterval.Add_SelectionChanged({
    if ($CmbPollInterval.SelectedItem) {
        $sec = [int]([string]$CmbPollInterval.SelectedItem -replace "s$", "")
        if ($sec -ge 1) { $HookTimer.Interval = [TimeSpan]::FromSeconds($sec) }
    }
})

$BtnLockForeground.Add_Click({
    Ensure-ForegroundWin32
    $TxtLiveHookStatus.Text = "SWITCH TO GAME WINDOW NOW... Locking in 3s"
    $TxtLiveHookStatus.Foreground = $BrushYellow
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Seconds 3

    $fgPid = [ZeroHook.Win32Foreground]::GetForegroundPid()
    if ($fgPid -le 0) { return }
    try {
        $p = Get-Process -Id $fgPid -ErrorAction Stop
        if ($p.Id -eq $PID -or ($p.ProcessName -in $IgnoredForegroundProcesses)) { $p.Dispose(); return }
        $Script:LiveHookTarget = [PSCustomObject]@{
            Id = [int]$p.Id; Name = [string]$p.ProcessName
            Path = $(try { [string]$p.Path } catch { "" })
            StartedUtc = $(try { $p.StartTime.ToUniversalTime() } catch { $null })
        }
        $p.Dispose()
        $Script:SeenModuleKeys.Clear()
        $Script:PendingHookDetections.Clear()
        $Script:LastHookSnapshot = $null
        $Script:LastHookTargetInfo = $null
        Refresh-HookProcessList -SelectFirstSilently
        for ($i = 0; $i -lt $CmbHookProcess.Items.Count; $i++) {
            if ($CmbHookProcess.Items[$i].Tag.Id -eq $fgPid) { $CmbHookProcess.SelectedIndex = $i; break }
        }
        Invoke-HookMonitorStep -ForceLogSnapshot
    } catch {
        Write-DiagnosticLog -Level "ERROR" -Source "LIVEHOOK" -Message "Foreground lock failed: $($_.Exception.Message)"
    }
})

$BtnToggleLiveMonitor.Add_Click({
    if ($HookTimer.IsEnabled) {
        $HookTimer.Stop()
        $BtnToggleLiveMonitor.Content = "Start Real-Time Watch"
        $BtnToggleLiveMonitor.Background = $BrushGreen
        Write-DiagnosticLog -Level "INFO" -Source "LIVEHOOK" -Message "Real-time watch stopped."
    } else {
        $Script:LiveHookTarget = Get-SelectedHookTarget
        if (-not $Script:LiveHookTarget) { return }
        $Script:SeenModuleKeys.Clear()
        $Script:PendingHookDetections.Clear()
        $Script:LastHookSnapshot = $null
        $Script:LastHookTargetInfo = $null
        $HookTimer.Start()
        $BtnToggleLiveMonitor.Content = "Stop Real-Time Watch"
        $BtnToggleLiveMonitor.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#DC2626")
        Write-DiagnosticLog -Level "INFO" -Source "LIVEHOOK" -Message "Real-time watch started for $($Script:LiveHookTarget.Name) (PID $($Script:LiveHookTarget.Id))."
        Invoke-HookMonitorStep -ForceLogSnapshot
    }
})

$BtnScanNowHooks.Add_Click({
    $Script:LiveHookTarget = Get-SelectedHookTarget
    Invoke-HookMonitorStep -ForceLogSnapshot
})

$BtnClearHookLog.Add_Click({ $HookLogBox.Document.Blocks.Clear() })

$Window.Add_ContentRendered({
    [System.Windows.Forms.Application]::DoEvents()
    Refresh-HookProcessList -SelectFirstSilently
    Update-Dashboard -Filter "ALL"
})

$Window.Add_Closed({
    if ($HookTimer.IsEnabled) { $HookTimer.Stop() }
    Write-DiagnosticLog -Level "INFO" -Source "APP" -Message "ZeroHook GUI closed." -ForceTrim
})

$Window.ShowDialog() | Out-Null