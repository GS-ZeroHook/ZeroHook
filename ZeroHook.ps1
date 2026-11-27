param(
    [switch]$AutoBlock,
    [switch]$DebugLog
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

$BaseSearchPaths = @(
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
    "$env:SystemRoot\System32",
    "$env:ProgramFiles\AMD",
    "$env:ProgramFiles\Razer",
    "${env:ProgramFiles(x86)}\Razer",
    "$env:ProgramData\Razer",
    "$env:ProgramFiles\Sony",
    "${env:ProgramFiles(x86)}\Sony"
)

$SearchPaths = @($BaseSearchPaths)
$ExcludedPathRegex = "\\steamapps\\|\\Epic Games\\DirectXRedist\\|\\.egstore\\|(^|[\\/])WindowsApps([\\/]|$)"

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

$OverlayHookCategories = @(
    "Steam",
    "Discord",
    "Epic",
    "EA",
    "Ubisoft",
    "GOG",
    "Overwolf",
    "OBS",
    "RTSS",
    "NVIDIA",
    "AMD",
    "GenericOverlay",
    "ControllerHook"
)

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
    "bink2w64.dll"                              = "Shared proxy name (ReShade, ASI Loader, MFG Unlocker, or game Bink video library)"
    "bink2w32.dll"                              = "Shared proxy name (32-bit ASI Loader or game Bink video library)"
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
    if ([string]::IsNullOrWhiteSpace($ModuleName)) { return "" }
    $name = $ModuleName.ToLowerInvariant()
    if ($LiveHookDllDescriptions.ContainsKey($name)) {
        return $LiveHookDllDescriptions[$name]
    }
    if ($name -match '^luma.*\.dll$') {
        return "Luma mod DLL (named per game by the mod)"
    }
    return ""
}

function Get-LiveHookFindingColor {
    param([string]$CategoryId)
    if ($OverlayHookCategories -contains $CategoryId) {
        return "Red"
    }
    return "Yellow"
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
$StartupBackupDir       = "$env:ProgramData\ZeroHook_StartupBackup"
$LocalInstallDir        = "$env:ProgramData\ZeroHook"
$LocalScriptPath        = Join-Path $LocalInstallDir "ZeroHook.ps1"
$UserConfigDir          = Join-Path $env:LOCALAPPDATA "ZeroHook"
$ExclusionsFile         = Join-Path $UserConfigDir "exclusions.json"
$RoamingExclusionsFile  = Join-Path $env:APPDATA "ZeroHook\exclusions.json"
$LegacyExclusionsFile   = Join-Path $StartupBackupDir "exclusions.json"
$LogDir                 = Join-Path $env:LOCALAPPDATA "ZeroHook\Logs"
$DiagLogFile            = Join-Path $LogDir "zerohook-current.log"
$MaxLogLines            = 2500
$Script:SessionId       = ([guid]::NewGuid().ToString("N").Substring(0, 8))
$Script:DiagWriteCount  = 0
$Script:ExclusionsLoggedOnce = $false
$Script:DetectedStoreGames = @()
$Script:StoreScanCompleted = $false
$Script:StorePrefixEntries = @()
$Script:StorePathCache = @{}

function Hide-Username {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return "" }
    $out = $Text
    if ($env:USERPROFILE) {
        $out = $out -ireplace [regex]::Escape($env:USERPROFILE), "C:\Users\%USERNAME%"
    }
    if ($env:USERNAME) {
        $out = $out -ireplace ("(?i)(\\Users\\)" + [regex]::Escape($env:USERNAME) + "(\\|$)"), "`$1%USERNAME%`$2"
    }
    return $out
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
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
        [string]$Level = "INFO",
        [string]$Source = "APP",
        [string]$Message = "",
        [switch]$ForceTrim
    )
    if ($Level -eq "DEBUG" -and -not $DebugLog) { return }
    try {
        $logFolder = if ($LogDir) { $LogDir } else { Join-Path $env:LOCALAPPDATA "ZeroHook\Logs" }
        $logPath = if ($DiagLogFile) { $DiagLogFile } else { Join-Path $logFolder "zerohook-current.log" }
        if (-not (Test-Path -LiteralPath $logFolder)) {
            New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
        }
        $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $safeMsg = Format-DiagnosticLine -Text $Message
        $entry = "[$ts] [$Script:SessionId] [$Level] [$Source] $safeMsg"

        Add-Content -LiteralPath $logPath -Value $entry -Encoding UTF8 -ErrorAction SilentlyContinue

        $Script:DiagWriteCount++
        if ($ForceTrim -or (($Script:DiagWriteCount % 50) -eq 0)) {
            Trim-DiagnosticLogFile
        }
    } catch {}
}

function Format-ErrorRecordDetail {
    param(
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        [string]$Context = "",
        [string]$Target = ""
    )
    if (-not $ErrorRecord) { return "Unknown error" }
    $baseEx = $ErrorRecord.Exception.GetBaseException()
    $exType = if ($baseEx) { $baseEx.GetType().FullName } else { $ErrorRecord.Exception.GetType().FullName }
    $exMsg  = if ($baseEx -and $baseEx.Message) { $baseEx.Message } else { [string]$ErrorRecord }

    $parts = [System.Collections.Generic.List[string]]::new()
    if (-not [string]::IsNullOrWhiteSpace($Context)) { [void]$parts.Add("op=$Context") }
    if (-not [string]::IsNullOrWhiteSpace($Target))  { [void]$parts.Add("target=$(Hide-Username $Target)") }
    [void]$parts.Add("err=$exMsg")
    [void]$parts.Add("type=$exType")

    $inv = $ErrorRecord.InvocationInfo
    if ($inv -and $inv.ScriptLineNumber -gt 0) {
        $loc = "line=$($inv.ScriptLineNumber),col=$($inv.OffsetInLine)"
        if ($inv.MyCommand -and $inv.MyCommand.Name) { $loc += ",fn=$($inv.MyCommand.Name)" }
        [void]$parts.Add($loc)
    }

    return ($parts -join " | ")
}

function Write-DiagnosticError {
    param(
        [string]$Source = "APP",
        [string]$Context = "",
        [string]$Target = "",
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        [switch]$ForceTrim
    )
    $detail = Format-ErrorRecordDetail -ErrorRecord $ErrorRecord -Context $Context -Target $Target
    Write-DiagnosticLog -Level "ERROR" -Source $Source -Message $detail -ForceTrim:$ForceTrim
    return $detail
}

function Get-EnvironmentSummary {
    $cv = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue
    $osInfo = if ($cv -and $cv.ProductName) {
        $verStr = if ($cv.DisplayVersion) { "$($cv.DisplayVersion)" } else { "" }
        $bldStr = if ($cv.CurrentBuild) { "build $($cv.CurrentBuild).$($cv.UBR)" } else { "" }
        $meta = (@($verStr, $bldStr) | Where-Object { $_ -ne "" }) -join ", "
        if ($meta) { "$($cv.ProductName) ($meta)" } else { [string]$cv.ProductName }
    } else {
        [System.Environment]::OSVersion.VersionString
    }

    $psVer = "$($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))"
    $isAdmin = try {
        ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { $false }

    $proc = $null
    $exePath = "Unknown"
    $wsMb = "N/A"
    try {
        $proc = [System.Diagnostics.Process]::GetCurrentProcess()
        if ($proc.MainModule -and $proc.MainModule.FileName) {
            $exePath = Hide-Username $proc.MainModule.FileName
        }
        $wsMb = "{0:N1} MB" -f ($proc.WorkingSet64 / 1MB)
    } catch {}
    finally {
        if ($proc) { $proc.Dispose() }
    }

    $mode = if ($AutoBlock) { "-AutoBlock" } else { "GUI" }
    if ($DebugLog) { $mode += " + -DebugLog" }

    return [PSCustomObject]@{
        OsInfo       = $osInfo
        PsVer        = $psVer
        IsAdmin      = $isAdmin
        ExePath      = $exePath
        WorkingSet   = $wsMb
        Mode         = $mode
        ScriptPath   = if ($PSCommandPath) { Hide-Username $PSCommandPath } else { "Inline/Hosted" }
        Arch         = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    }
}

Write-DiagnosticLog -Level "INFO" -Source "SESSION" -Message "Session started | SessionId=$Script:SessionId | PID=$PID | Mode=$(if ($AutoBlock) { '-AutoBlock' } else { 'GUI' }) | DebugLog=$([bool]$DebugLog)" -ForceTrim
$initEnv = Get-EnvironmentSummary
Write-DiagnosticLog -Level "INFO" -Source "ENV" -Message "OS=$($initEnv.OsInfo) ($($initEnv.Arch)) | PS=$($initEnv.PsVer) | Admin=$($initEnv.IsAdmin) | Exe=$($initEnv.ExePath) | Script=$($initEnv.ScriptPath)" -ForceTrim

# --- STORE DETECTION HELPERS ---
function Normalize-StorePath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return "" }
    $p = $Path.Trim().Trim('"') -replace '/', '\'
    if ($p -match '^\\\\\?\\') { $p = $p.Substring(4) }
    while ($p.Length -gt 3 -and $p.EndsWith('\')) {
        $p = $p.Substring(0, $p.Length - 1)
    }
    return $p
}

function Ensure-StoreNativeWin32 {
    if (-not ("ZeroHook.StoreNative" -as [type])) {
        Add-Type -ErrorAction Stop -TypeDefinition @"
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;

namespace ZeroHook {
    public static class StoreNative {
        public const uint GENERIC_READ = 0x80000000;
        public const uint FILE_SHARE_READ = 0x00000001;
        public const uint FILE_SHARE_WRITE = 0x00000002;
        public const uint FILE_SHARE_DELETE = 0x00000004;
        public const uint OPEN_EXISTING = 3;
        public const uint FILE_FLAG_BACKUP_SEMANTICS = 0x02000000;
        public const uint FILE_FLAG_OPEN_REPARSE_POINT = 0x00200000;

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern SafeFileHandle CreateFileW(
            string lpFileName,
            uint dwDesiredAccess,
            uint dwShareMode,
            IntPtr lpSecurityAttributes,
            uint dwCreationDisposition,
            uint dwFlagsAndAttributes,
            IntPtr hTemplateFile
        );

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern uint GetFinalPathNameByHandleW(
            SafeFileHandle hFile,
            StringBuilder lpszFilePath,
            uint cchFilePath,
            uint dwFlags
        );

        public static string ResolveFinalPath(string path) {
            if (string.IsNullOrWhiteSpace(path)) return path;
            try {
                using (SafeFileHandle h = CreateFileW(
                    path,
                    GENERIC_READ,
                    FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                    IntPtr.Zero,
                    OPEN_EXISTING,
                    FILE_FLAG_BACKUP_SEMANTICS,
                    IntPtr.Zero)) {
                    if (h.IsInvalid) return path;
                    StringBuilder sb = new StringBuilder(1024);
                    uint len = GetFinalPathNameByHandleW(h, sb, (uint)sb.Capacity, 0);
                    if (len == 0) return path;
                    if (len >= sb.Capacity) {
                        sb.EnsureCapacity((int)len + 2);
                        len = GetFinalPathNameByHandleW(h, sb, (uint)sb.Capacity, 0);
                        if (len == 0) return path;
                    }
                    string resolved = sb.ToString();
                    if (resolved.StartsWith(@"\\?\")) {
                        resolved = resolved.Substring(4);
                    }
                    return string.IsNullOrWhiteSpace(resolved) ? path : resolved;
                }
            } catch {
                return path;
            }
        }
    }
}
"@
    }
}

function Resolve-JunctionTargetPath {
    param([string]$Path)
    $clean = Normalize-StorePath $Path
    if ([string]::IsNullOrWhiteSpace($clean)) { return "" }
    try {
        Ensure-StoreNativeWin32
        $resolved = Normalize-StorePath ([ZeroHook.StoreNative]::ResolveFinalPath($clean))
        if (-not [string]::IsNullOrWhiteSpace($resolved)) {
            return $resolved
        }
    } catch {}
    return $clean
}

function Get-RegistryStringValue {
    param(
        [string]$Path,
        [string[]]$Names
    )
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        $props = Get-ItemProperty -LiteralPath $Path -ErrorAction Stop
        foreach ($n in $Names) {
            $val = $props.$n
            if ($null -ne $val -and -not [string]::IsNullOrWhiteSpace([string]$val)) {
                return [string]$val
            }
        }
    } catch {}
    return $null
}

function Parse-VdfKeyValues {
    param([string]$Content)
    $result = @{}
    if ([string]::IsNullOrWhiteSpace($Content)) { return $result }
    $lines = $Content -split "`r?`n"
    foreach ($line in $lines) {
        $m = [regex]::Match($line.Trim(), '^"([^"]+)"\s+"([^"]*)"')
        if ($m.Success) {
            $k = $m.Groups[1].Value.ToLowerInvariant()
            if (-not $result.ContainsKey($k)) {
                $result[$k] = $m.Groups[2].Value
            }
        }
    }
    return $result
}

function Get-VdfLibraryPaths {
    param([string]$VdfFilePath)
    $paths = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path -LiteralPath $VdfFilePath)) { return @() }
    try {
        $lines = Get-Content -LiteralPath $VdfFilePath -Encoding UTF8 -ErrorAction Stop
        foreach ($line in $lines) {
            $m = [regex]::Match($line.Trim(), '^"path"\s+"([^"]+)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if ($m.Success) {
                $p = Normalize-StorePath $m.Groups[1].Value
                if (-not [string]::IsNullOrWhiteSpace($p) -and -not $paths.Contains($p)) {
                    [void]$paths.Add($p)
                }
            }
        }
    } catch {}
    return $paths.ToArray()
}

function Get-SteamAppNameFromAppInfo {
    param(
        [string]$SteamRoot,
        [string]$AppId
    )
    if ([string]::IsNullOrWhiteSpace($SteamRoot) -or [string]::IsNullOrWhiteSpace($AppId)) { return $null }
    $appInfoPath = Join-Path $SteamRoot "appcache\appinfo.vdf"
    if (-not (Test-Path -LiteralPath $appInfoPath)) { return $null }
    try {
        $bytes = [System.IO.File]::ReadAllBytes($appInfoPath)
        $enc = [System.Text.Encoding]::UTF8
        $idBytes = [System.BitConverter]::GetBytes([UInt32]$AppId)
        $pos = 0
        while ($pos -lt ($bytes.Length - 4)) {
            if ($bytes[$pos] -eq $idBytes[0] -and $bytes[$pos+1] -eq $idBytes[1] -and $bytes[$pos+2] -eq $idBytes[2] -and $bytes[$pos+3] -eq $idBytes[3]) {
                $windowStart = [Math]::Max(0, $pos - 64)
                $windowLen = [Math]::Min($bytes.Length - $windowStart, 8192)
                $winText = $enc.GetString($bytes, $windowStart, $windowLen)
                $m = [regex]::Match($winText, 'name\x00([^\x00\r\n]{2,120})\x00')
                if ($m.Success) {
                    $candidate = $m.Groups[1].Value.Trim()
                    if ($candidate -and $candidate -notmatch '^appid_\d+$') {
                        return $candidate
                    }
                }
            }
            $pos++
        }
    } catch {}
    return $null
}

function Get-SteamGames {
    $games = [System.Collections.Generic.List[object]]::new()
    $steamPath = Get-RegistryStringValue -Path "HKLM:\SOFTWARE\Valve\Steam" -Names @("SteamPath", "InstallPath")
    if (-not $steamPath) {
        $steamPath = Get-RegistryStringValue -Path "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -Names @("SteamPath", "InstallPath")
    }
    if (-not $steamPath) { return @() }
    $steamRoot = Normalize-StorePath $steamPath
    if (-not (Test-Path -LiteralPath $steamRoot)) { return @() }

    $libraries = [System.Collections.Generic.List[string]]::new()
    [void]$libraries.Add($steamRoot)
    $libVdf = Join-Path $steamRoot "steamapps\libraryfolders.vdf"
    foreach ($lib in (Get-VdfLibraryPaths -VdfFilePath $libVdf)) {
        if (-not $libraries.Contains($lib)) {
            [void]$libraries.Add($lib)
        }
    }

    foreach ($lib in $libraries) {
        $steamAppsDir = Join-Path $lib "steamapps"
        if (-not (Test-Path -LiteralPath $steamAppsDir)) { continue }
        $manifests = Get-ChildItem -Path $steamAppsDir -Filter "appmanifest_*.acf" -File -ErrorAction SilentlyContinue
        foreach ($mf in $manifests) {
            try {
                $raw = Get-Content -LiteralPath $mf.FullName -Raw -Encoding UTF8 -ErrorAction Stop
                $kv = Parse-VdfKeyValues -Content $raw
                $installDir = if ($kv.ContainsKey("installdir")) { $kv["installdir"] } else { "" }
                if ([string]::IsNullOrWhiteSpace($installDir)) { continue }
                $gamePath = Normalize-StorePath (Join-Path $steamAppsDir "common\$installDir")
                $appId = if ($kv.ContainsKey("appid")) { $kv["appid"] } elseif ($mf.BaseName -match 'appmanifest_(\d+)') { $matches[1] } else { "" }
                $name = if ($kv.ContainsKey("name")) { $kv["name"] } else { $installDir }
                if ($name -match '^appid_\d+$') {
                    $resolvedName = Get-SteamAppNameFromAppInfo -SteamRoot $steamRoot -AppId $appId
                    if ($resolvedName) { $name = $resolvedName }
                }
                [void]$games.Add([PSCustomObject]@{
                    Store       = "Steam"
                    Name        = $name
                    InstallPath = $gamePath
                    LaunchUri   = if ($appId) { "steam://rungameid/$appId" } else { "" }
                    Id          = $appId
                })
            } catch {}
        }
    }
    return $games.ToArray()
}

function Get-EpicGames {
    $games = [System.Collections.Generic.List[object]]::new()

    $manifestDir = Join-Path $env:ProgramData "Epic\EpicGamesLauncher\Data\Manifests"
    if (Test-Path -LiteralPath $manifestDir) {
        $items = Get-ChildItem -Path $manifestDir -Filter "*.item" -File -ErrorAction SilentlyContinue
        foreach ($it in $items) {
            try {
                $json = Get-Content -LiteralPath $it.FullName -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json
                $loc = Normalize-StorePath ([string]$json.InstallLocation)
                if ([string]::IsNullOrWhiteSpace($loc)) { continue }
                $ns = [string]$json.CatalogNamespace
                $catId = [string]$json.CatalogItemId
                $appName = [string]$json.AppName
                $uri = if ($ns -and $catId -and $appName) {
                    "com.epicgames.launcher://apps/${ns}%3A${catId}%3A${appName}?action=launch&silent=true"
                } else { "" }
                $title = if ($json.DisplayName) { [string]$json.DisplayName } else { Split-Path -Leaf $loc }
                [void]$games.Add([PSCustomObject]@{
                    Store       = "Epic"
                    Name        = $title
                    InstallPath = $loc
                    LaunchUri   = $uri
                    Id          = $appName
                })
            } catch {}
        }
    }

    $eglv2Jsonl = Join-Path $env:LOCALAPPDATA "com.epicgames.eglv2\installations.jsonl"
    if (Test-Path -LiteralPath $eglv2Jsonl) {
        $catalogCachePath = Join-Path $env:LOCALAPPDATA "com.epicgames.eglv2\cache\prod\catalog-cache.json"
        $catalogItems = $null
        if (Test-Path -LiteralPath $catalogCachePath) {
            try {
                $catObj = Get-Content -LiteralPath $catalogCachePath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json
                if ($catObj -and $catObj.items) { $catalogItems = $catObj.items }
            } catch {}
        }

        try {
            $lines = @(Get-Content -LiteralPath $eglv2Jsonl -Encoding UTF8 -ErrorAction Stop)
            $latestByInstallId = @{}
            for ($i = 1; $i -lt $lines.Count; $i++) {
                $line = $lines[$i].Trim()
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                try {
                    $ev = $line | ConvertFrom-Json
                    if ($ev.installationId) {
                        $latestByInstallId[[string]$ev.installationId] = $ev
                    }
                } catch {}
            }

            foreach ($kvp in $latestByInstallId.GetEnumerator()) {
                $ev = $kvp.Value
                if (-not [bool]$ev.complete) { continue }
                $loc = Normalize-StorePath ([string]$ev.installLocation)
                if ([string]::IsNullOrWhiteSpace($loc)) { continue }

                $artifactId = [string]$ev.artifactId
                $itemId = [string]$ev.itemId
                $name = ""

                if ($artifactId) {
                    $uninstKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\EpicGames-$artifactId"
                    $name = Get-RegistryStringValue -Path $uninstKey -Names @("DisplayName")
                }

                if ([string]::IsNullOrWhiteSpace($name) -and $catalogItems -and $itemId) {
                    $entry = $catalogItems.PSObject.Properties[$itemId].Value
                    if ($entry -and $entry.item) {
                        $mainGameId = if ($entry.item.mainGameItem -and $entry.item.mainGameItem.id) { [string]$entry.item.mainGameItem.id } else { "" }
                        if ($mainGameId) {
                            $parentEntry = $catalogItems.PSObject.Properties[$mainGameId].Value
                            if ($parentEntry -and $parentEntry.item -and $parentEntry.item.title) {
                                $name = [string]$parentEntry.item.title
                            }
                        }
                        if ([string]::IsNullOrWhiteSpace($name) -and $entry.item.title) {
                            $name = [string]$entry.item.title
                        }
                    }
                }

                if ([string]::IsNullOrWhiteSpace($name)) {
                    $name = Split-Path -Leaf $loc
                }

                [void]$games.Add([PSCustomObject]@{
                    Store       = "Epic"
                    Name        = $name
                    InstallPath = $loc
                    LaunchUri   = ""
                    Id          = if ($artifactId) { $artifactId } else { $itemId }
                })
            }
        } catch {}
    }

    return $games.ToArray()
}

function Get-GogGames {
    $games = [System.Collections.Generic.List[object]]::new()
    $regRoots = @(
        "HKLM:\SOFTWARE\GOG.com\Games",
        "HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games"
    )
    foreach ($root in $regRoots) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        $subKeys = Get-ChildItem -Path $root -ErrorAction SilentlyContinue
        foreach ($sk in $subKeys) {
            $pathVal = Get-RegistryStringValue -Path $sk.PSPath -Names @("PATH", "path")
            $loc = Normalize-StorePath $pathVal
            if ([string]::IsNullOrWhiteSpace($loc)) { continue }
            $nameVal = Get-RegistryStringValue -Path $sk.PSPath -Names @("GAMENAME", "GameName")
            if ([string]::IsNullOrWhiteSpace($nameVal)) { $nameVal = Split-Path -Leaf $loc }
            [void]$games.Add([PSCustomObject]@{
                Store       = "GOG"
                Name        = $nameVal
                InstallPath = $loc
                LaunchUri   = ""
                Id          = $sk.PSChildName
            })
        }
    }
    return $games.ToArray()
}

function Get-EaGames {
    $games = [System.Collections.Generic.List[object]]::new()

    $eaContentDir = Join-Path $env:ProgramData "EA\content"
    if (Test-Path -LiteralPath $eaContentDir) {
        $xmls = Get-ChildItem -Path $eaContentDir -Filter "installerdata.xml" -Recurse -File -ErrorAction SilentlyContinue
        foreach ($xf in $xmls) {
            try {
                [xml]$doc = Get-Content -LiteralPath $xf.FullName -Raw -ErrorAction Stop
                $gameName = [string]$doc.SelectSingleNode("//gameName").'#text'
                $installPath = Normalize-StorePath ([string]$doc.SelectSingleNode("//defaultInstallPath").'#text')
                if (-not [string]::IsNullOrWhiteSpace($installPath)) {
                    [void]$games.Add([PSCustomObject]@{
                        Store       = "EA"
                        Name        = if ($gameName) { $gameName } else { Split-Path -Leaf $installPath }
                        InstallPath = $installPath
                        LaunchUri   = ""
                        Id          = $xf.Directory.Parent.Name
                    })
                }
            } catch {}
        }
    }

    $originRoot = "HKLM:\SOFTWARE\Wow6432Node\Origin Games"
    if (Test-Path -LiteralPath $originRoot) {
        foreach ($sk in (Get-ChildItem -Path $originRoot -ErrorAction SilentlyContinue)) {
            $loc = Normalize-StorePath (Get-RegistryStringValue -Path $sk.PSPath -Names @("InstallDir", "Install Dir"))
            if (-not [string]::IsNullOrWhiteSpace($loc)) {
                $disp = Get-RegistryStringValue -Path $sk.PSPath -Names @("DisplayName")
                [void]$games.Add([PSCustomObject]@{
                    Store       = "EA"
                    Name        = if ($disp) { $disp } else { Split-Path -Leaf $loc }
                    InstallPath = $loc
                    LaunchUri   = ""
                    Id          = $sk.PSChildName
                })
            }
        }
    }

    $studioNames = @("EA Games", "Electronic Arts", "BioWare", "DICE", "Respawn", "Criterion Games", "Ghost Games", "PopCap")
    $regPrefixes = @("HKLM:\SOFTWARE", "HKLM:\SOFTWARE\Wow6432Node")
    foreach ($pref in $regPrefixes) {
        foreach ($st in $studioNames) {
            $stPath = Join-Path $pref $st
            if (-not (Test-Path -LiteralPath $stPath)) { continue }
            $directLoc = Normalize-StorePath (Get-RegistryStringValue -Path $stPath -Names @("Install Dir", "InstallDir", "Install Directory"))
            if (-not [string]::IsNullOrWhiteSpace($directLoc)) {
                [void]$games.Add([PSCustomObject]@{
                    Store       = "EA"
                    Name        = Split-Path -Leaf $directLoc
                    InstallPath = $directLoc
                    LaunchUri   = ""
                    Id          = $st
                })
            }
            foreach ($sub in (Get-ChildItem -Path $stPath -Recurse -ErrorAction SilentlyContinue)) {
                $subLoc = Normalize-StorePath (Get-RegistryStringValue -Path $sub.PSPath -Names @("Install Dir", "InstallDir", "Install Directory"))
                if (-not [string]::IsNullOrWhiteSpace($subLoc)) {
                    $subName = Get-RegistryStringValue -Path $sub.PSPath -Names @("DisplayName")
                    if ([string]::IsNullOrWhiteSpace($subName)) { $subName = Split-Path -Leaf $subLoc }
                    [void]$games.Add([PSCustomObject]@{
                        Store       = "EA"
                        Name        = $subName
                        InstallPath = $subLoc
                        LaunchUri   = ""
                        Id          = $sub.PSChildName
                    })
                }
            }
        }
    }

    $eaFolders = @("${env:ProgramFiles}\EA Games", "${env:ProgramFiles(x86)}\EA Games") | Select-Object -Unique
    foreach ($ef in $eaFolders) {
        if (-not (Test-Path -LiteralPath $ef)) { continue }
        foreach ($dir in (Get-ChildItem -Path $ef -Directory -ErrorAction SilentlyContinue)) {
            $topExe = Get-ChildItem -Path $dir.FullName -Filter "*.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($topExe) {
                $loc = Normalize-StorePath $dir.FullName
                [void]$games.Add([PSCustomObject]@{
                    Store       = "EA"
                    Name        = $dir.Name
                    InstallPath = $loc
                    LaunchUri   = ""
                    Id          = $dir.Name
                })
            }
        }
    }

    $eaAppData = Join-Path $env:LOCALAPPDATA "Electronic Arts\EA Desktop"
    if (Test-Path -LiteralPath $eaAppData) {
        $cfgFiles = Get-ChildItem -Path $eaAppData -Include "*.ini", "*.json" -Recurse -File -ErrorAction SilentlyContinue
        foreach ($cf in $cfgFiles) {
            try {
                $txt = Get-Content -LiteralPath $cf.FullName -Raw -ErrorAction Stop
                $matches = [regex]::Matches($txt, '[A-Za-z]:[\\/][^\r\n"\'']+')
                foreach ($m in $matches) {
                    $cand = Normalize-StorePath $m.Value
                    if ($cand -and (Test-Path -LiteralPath $cand)) {
                        $xmlCand = Join-Path $cand "__Installer\installerdata.xml"
                        if (Test-Path -LiteralPath $xmlCand) {
                            [xml]$doc = Get-Content -LiteralPath $xmlCand -Raw -ErrorAction Stop
                            $gName = [string]$doc.SelectSingleNode("//gameName").'#text'
                            $gPath = Normalize-StorePath ([string]$doc.SelectSingleNode("//defaultInstallPath").'#text')
                            if ([string]::IsNullOrWhiteSpace($gPath)) { $gPath = $cand }
                            [void]$games.Add([PSCustomObject]@{
                                Store       = "EA"
                                Name        = if ($gName) { $gName } else { Split-Path -Leaf $gPath }
                                InstallPath = $gPath
                                LaunchUri   = ""
                                Id          = Split-Path -Leaf $gPath
                            })
                        }
                    }
                }
            } catch {}
        }
    }

    return $games.ToArray()
}

function Get-UbisoftGames {
    $games = [System.Collections.Generic.List[object]]::new()

    $ubiRegPaths = @(
        "HKLM:\SOFTWARE\Ubisoft\Launcher\Installs",
        "HKLM:\SOFTWARE\WOW6432Node\Ubisoft\Launcher\Installs"
    )
    foreach ($rp in $ubiRegPaths) {
        if (-not (Test-Path -LiteralPath $rp)) { continue }
        foreach ($sk in (Get-ChildItem -Path $rp -ErrorAction SilentlyContinue)) {
            $loc = Normalize-StorePath (Get-RegistryStringValue -Path $sk.PSPath -Names @("InstallDir"))
            if (-not [string]::IsNullOrWhiteSpace($loc)) {
                $folderName = Split-Path -Leaf $loc
                [void]$games.Add([PSCustomObject]@{
                    Store       = "Ubisoft"
                    Name        = $folderName
                    InstallPath = $loc
                    LaunchUri   = if ($sk.PSChildName -match '^\d+$') { "uplay://launch/$($sk.PSChildName)/0" } else { "" }
                    Id          = $sk.PSChildName
                })
            }
        }
    }

    $settingsYml = Join-Path $env:LOCALAPPDATA "Ubisoft Game Launcher\settings.yml"
    if (Test-Path -LiteralPath $settingsYml) {
        try {
            $lines = Get-Content -LiteralPath $settingsYml -Encoding UTF8 -ErrorAction Stop
            foreach ($line in $lines) {
                if ($line -match '^\s*game_installation_path\s*:\s*(.+)$') {
                    $rootDir = Normalize-StorePath $matches[1]
                    if ($rootDir -and (Test-Path -LiteralPath $rootDir)) {
                        foreach ($sub in (Get-ChildItem -Path $rootDir -Directory -ErrorAction SilentlyContinue)) {
                            $loc = Normalize-StorePath $sub.FullName
                            [void]$games.Add([PSCustomObject]@{
                                Store       = "Ubisoft"
                                Name        = $sub.Name
                                InstallPath = $loc
                                LaunchUri   = ""
                                Id          = $sub.Name
                            })
                        }
                    }
                }
            }
        } catch {}
    }

    $ubiDefaults = @(
        "${env:ProgramFiles(x86)}\Ubisoft\Ubisoft Game Launcher\games",
        "${env:ProgramFiles}\Ubisoft\Ubisoft Game Launcher\games"
    ) | Select-Object -Unique
    foreach ($ud in $ubiDefaults) {
        if (-not (Test-Path -LiteralPath $ud)) { continue }
        foreach ($sub in (Get-ChildItem -Path $ud -Directory -ErrorAction SilentlyContinue)) {
            $loc = Normalize-StorePath $sub.FullName
            [void]$games.Add([PSCustomObject]@{
                Store       = "Ubisoft"
                Name        = $sub.Name
                InstallPath = $loc
                LaunchUri   = ""
                Id          = $sub.Name
            })
        }
    }

    return $games.ToArray()
}

function Get-BattleNetGames {
    $games = [System.Collections.Generic.List[object]]::new()
    $targetPublishers = @("Blizzard Entertainment", "Activision", "Activision Blizzard")

    $uninstRoots = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    foreach ($ur in $uninstRoots) {
        if (-not (Test-Path -LiteralPath $ur)) { continue }
        foreach ($sk in (Get-ChildItem -Path $ur -ErrorAction SilentlyContinue)) {
            $pub = Get-RegistryStringValue -Path $sk.PSPath -Names @("Publisher")
            if (-not $pub -or ($pub -notin $targetPublishers)) { continue }
            $disp = Get-RegistryStringValue -Path $sk.PSPath -Names @("DisplayName")
            if ($disp -and ($disp -match '(?i)Battle\.net') -and ($disp -notmatch '(?i)\bgame\b')) { continue }
            $loc = Normalize-StorePath (Get-RegistryStringValue -Path $sk.PSPath -Names @("InstallLocation"))
            if (-not [string]::IsNullOrWhiteSpace($loc)) {
                [void]$games.Add([PSCustomObject]@{
                    Store       = "Battle.net"
                    Name        = if ($disp) { $disp } else { Split-Path -Leaf $loc }
                    InstallPath = $loc
                    LaunchUri   = ""
                    Id          = $sk.PSChildName
                })
            }
        }
    }

    $bnetCfg = Join-Path $env:APPDATA "Battle.net\Battle.net.config"
    if (Test-Path -LiteralPath $bnetCfg) {
        try {
            $cfgObj = Get-Content -LiteralPath $bnetCfg -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json
            $defPath = $null
            if ($cfgObj.Client -and $cfgObj.Client.Install -and $cfgObj.Client.Install.DefaultInstallPath) {
                $defPath = Normalize-StorePath ([string]$cfgObj.Client.Install.DefaultInstallPath)
            }
            if ($defPath -and (Test-Path -LiteralPath $defPath)) {
                foreach ($sub in (Get-ChildItem -Path $defPath -Directory -ErrorAction SilentlyContinue)) {
                    $hasExe = Get-ChildItem -Path $sub.FullName -Filter "*.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($hasExe) {
                        [void]$games.Add([PSCustomObject]@{
                            Store       = "Battle.net"
                            Name        = $sub.Name
                            InstallPath = (Normalize-StorePath $sub.FullName)
                            LaunchUri   = ""
                            Id          = $sub.Name
                        })
                    }
                }
            }
        } catch {}
    }

    $bnetDefaults = @(
        "${env:ProgramFiles(x86)}\Battle.net",
        "${env:ProgramFiles}\Battle.net",
        "${env:ProgramFiles(x86)}\Blizzard Entertainment",
        "${env:ProgramFiles}\Blizzard Entertainment"
    ) | Select-Object -Unique
    foreach ($bd in $bnetDefaults) {
        if (-not (Test-Path -LiteralPath $bd)) { continue }
        foreach ($sub in (Get-ChildItem -Path $bd -Directory -ErrorAction SilentlyContinue)) {
            if ($sub.Name -match '^(Battle\.net|Blizzard Battle\.net)$') { continue }
            $hasExe = Get-ChildItem -Path $sub.FullName -Filter "*.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($hasExe) {
                [void]$games.Add([PSCustomObject]@{
                    Store       = "Battle.net"
                    Name        = $sub.Name
                    InstallPath = (Normalize-StorePath $sub.FullName)
                    LaunchUri   = ""
                    Id          = $sub.Name
                })
            }
        }
    }

    return $games.ToArray()
}

function Get-RockstarGames {
    $games = [System.Collections.Generic.List[object]]::new()

    $uninstRoots = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    foreach ($ur in $uninstRoots) {
        if (-not (Test-Path -LiteralPath $ur)) { continue }
        foreach ($sk in (Get-ChildItem -Path $ur -ErrorAction SilentlyContinue)) {
            $pub = Get-RegistryStringValue -Path $sk.PSPath -Names @("Publisher")
            if (-not $pub -or ($pub -notmatch '(?i)Rockstar')) { continue }
            $disp = Get-RegistryStringValue -Path $sk.PSPath -Names @("DisplayName")
            if ($disp -and ($disp -match '(?i)Launcher') -and ($disp -match '(?i)Rockstar') -and ($disp -notmatch '(?i)Grand')) { continue }
            $loc = Normalize-StorePath (Get-RegistryStringValue -Path $sk.PSPath -Names @("InstallLocation"))
            if (-not [string]::IsNullOrWhiteSpace($loc)) {
                [void]$games.Add([PSCustomObject]@{
                    Store       = "Rockstar"
                    Name        = if ($disp) { $disp } else { Split-Path -Leaf $loc }
                    InstallPath = $loc
                    LaunchUri   = ""
                    Id          = $sk.PSChildName
                })
            }
        }
    }

    $rstarRegPaths = @(
        "HKLM:\SOFTWARE\Rockstar Games\Launcher",
        "HKLM:\SOFTWARE\WOW6432Node\Rockstar Games\Launcher",
        "HKLM:\SOFTWARE\Rockstar Games\Rockstar Games Launcher",
        "HKLM:\SOFTWARE\WOW6432Node\Rockstar Games\Rockstar Games Launcher"
    )
    foreach ($rr in $rstarRegPaths) {
        $launcherFolder = Normalize-StorePath (Get-RegistryStringValue -Path $rr -Names @("InstallFolder", "InstallDir"))
        if ($launcherFolder) {
            $titlesDat = Join-Path $launcherFolder "titles.dat"
            if (Test-Path -LiteralPath $titlesDat) {
                try {
                    $raw = Get-Content -LiteralPath $titlesDat -Raw -Encoding UTF8 -ErrorAction Stop
                    $pathMatches = [regex]::Matches($raw, '"InstallFolder"\s*:\s*"([^"]+)"')
                    foreach ($pm in $pathMatches) {
                        $tLoc = Normalize-StorePath $pm.Groups[1].Value
                        if (-not [string]::IsNullOrWhiteSpace($tLoc)) {
                            [void]$games.Add([PSCustomObject]@{
                                Store       = "Rockstar"
                                Name        = Split-Path -Leaf $tLoc
                                InstallPath = $tLoc
                                LaunchUri   = ""
                                Id          = Split-Path -Leaf $tLoc
                            })
                        }
                    }
                } catch {}
            }
        }
    }

    $rstarDefaults = @("${env:ProgramFiles}\Rockstar Games", "${env:ProgramFiles(x86)}\Rockstar Games") | Select-Object -Unique
    foreach ($rd in $rstarDefaults) {
        if (-not (Test-Path -LiteralPath $rd)) { continue }
        foreach ($sub in (Get-ChildItem -Path $rd -Directory -ErrorAction SilentlyContinue)) {
            if ($sub.Name -match '(?i)^Rockstar Games Launcher$') { continue }
            [void]$games.Add([PSCustomObject]@{
                Store       = "Rockstar"
                Name        = $sub.Name
                InstallPath = (Normalize-StorePath $sub.FullName)
                LaunchUri   = ""
                Id          = $sub.Name
            })
        }
    }

    return $games.ToArray()
}

function Get-XboxGames {
    $games = [System.Collections.Generic.List[object]]::new()

    $registeredFullNames = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $repoRoot = "HKLM:\SOFTWARE\Microsoft\GamingServices\PackageRepository\Root"
    if (Test-Path -LiteralPath $repoRoot) {
        try {
            $props = Get-ItemProperty -LiteralPath $repoRoot -ErrorAction SilentlyContinue
            if ($props) {
                foreach ($p in $props.PSObject.Properties) {
                    if ($p.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider")) {
                        [void]$registeredFullNames.Add([string]$p.Name)
                    }
                }
            }
            foreach ($sk in (Get-ChildItem -Path $repoRoot -Recurse -ErrorAction SilentlyContinue)) {
                $pkgFull = Get-RegistryStringValue -Path $sk.PSPath -Names @("PackageFullName")
                if ($pkgFull) { [void]$registeredFullNames.Add($pkgFull) }
                if ($sk.PSChildName -match '_') { [void]$registeredFullNames.Add($sk.PSChildName) }
            }
        } catch {}
    }

    try {
        $null = [Windows.Management.Deployment.PackageManager, Windows.Management.Deployment, ContentType = WindowsRuntime]
        $pm = New-Object Windows.Management.Deployment.PackageManager
        $pkgs = $pm.FindPackagesForUser("")

        foreach ($pkg in $pkgs) {
            try {
                if ($pkg.IsFramework -or $pkg.IsResourcePackage -or $pkg.IsBundle) { continue }
                $sigKind = [string]$pkg.SignatureKind
                if ($sigKind -and ($sigKind -notmatch 'Store')) { continue }

                $fullName = [string]$pkg.Id.FullName
                $rawPath = ""
                try { $rawPath = Normalize-StorePath ([string]$pkg.InstalledLocation.Path) } catch {}
                if ([string]::IsNullOrWhiteSpace($rawPath)) { continue }

                $resolvedPath = Resolve-JunctionTargetPath -Path $rawPath
                $finalPath = if ($resolvedPath -and ($resolvedPath -notmatch '(?i)[\\/]WindowsApps([\\/]|$)')) {
                    $resolvedPath
                } else {
                    $rawPath
                }

                $hasGameConfig = $false
                if ($finalPath -and ($finalPath -notmatch '(?i)[\\/]WindowsApps([\\/]|$)') -and (Test-Path -LiteralPath $finalPath)) {
                    $hasGameConfig = Test-Path -LiteralPath (Join-Path $finalPath "MicrosoftGame.config") -ErrorAction SilentlyContinue
                }

                if (-not ($registeredFullNames.Contains($fullName) -or $hasGameConfig)) { continue }

                $dispName = [string]$pkg.DisplayName
                if ([string]::IsNullOrWhiteSpace($dispName)) { $dispName = [string]$pkg.Id.Name }

                $aumid = ""
                try {
                    $appListEntries = $pkg.GetAppListEntries()
                    if ($appListEntries -and $appListEntries.Count -gt 0) {
                        $aumid = [string]$appListEntries[0].AppUserModelId
                    }
                } catch {}

                [void]$games.Add([PSCustomObject]@{
                    Store       = "Xbox"
                    Name        = $dispName
                    InstallPath = $finalPath
                    LaunchUri   = if ($aumid) { "shell:AppsFolder\$aumid" } else { "" }
                    Id          = $fullName
                })
            } catch {}
        }
    } catch {
        [void](Write-DiagnosticError -Source "STORE" -Context "Xbox PackageManager scan" -Target "Windows.Management.Deployment.PackageManager" -ErrorRecord $_)
    }

    return $games.ToArray()
}

function Rebuild-StorePathIndex {
    $Script:StorePathCache = @{}
    $entries = [System.Collections.Generic.List[object]]::new()
    foreach ($g in $Script:DetectedStoreGames) {
        if ($g -and -not [string]::IsNullOrWhiteSpace($g.InstallPath)) {
            $norm = Normalize-StorePath $g.InstallPath
            if (-not [string]::IsNullOrWhiteSpace($norm)) {
                [void]$entries.Add([PSCustomObject]@{
                    Store  = [string]$g.Store
                    Exact  = $norm
                    Prefix = ($norm.TrimEnd('\') + '\')
                    Length = $norm.Length
                })
            }
        }
    }
    $Script:StorePrefixEntries = @($entries | Sort-Object Length -Descending)
}

function Get-InstalledStoreGames {
    param([switch]$Refresh)
    if (-not $Refresh -and $Script:StoreScanCompleted) {
        return $Script:DetectedStoreGames
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $allRaw = [System.Collections.Generic.List[object]]::new()
    $steamExtraPaths = [System.Collections.Generic.List[string]]::new()

    $steamPath = Get-RegistryStringValue -Path "HKLM:\SOFTWARE\Valve\Steam" -Names @("SteamPath", "InstallPath")
    if (-not $steamPath) {
        $steamPath = Get-RegistryStringValue -Path "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -Names @("SteamPath", "InstallPath")
    }
    if ($steamPath) {
        $steamRoot = Normalize-StorePath $steamPath
        if ($steamRoot -and (Test-Path -LiteralPath $steamRoot)) {
            [void]$steamExtraPaths.Add($steamRoot)
            $steamBin = Join-Path $steamRoot "bin"
            if (Test-Path -LiteralPath $steamBin) { [void]$steamExtraPaths.Add($steamBin) }
            $libVdf = Join-Path $steamRoot "steamapps\libraryfolders.vdf"
            foreach ($lib in (Get-VdfLibraryPaths -VdfFilePath $libVdf)) {
                [void]$steamExtraPaths.Add($lib)
                $libBin = Join-Path $lib "bin"
                if (Test-Path -LiteralPath $libBin) { [void]$steamExtraPaths.Add($libBin) }
            }
        }
    }

    $detectors = @(
        @{ Name = "Steam";      Fn = { Get-SteamGames } },
        @{ Name = "Epic";       Fn = { Get-EpicGames } },
        @{ Name = "GOG";        Fn = { Get-GogGames } },
        @{ Name = "EA";         Fn = { Get-EaGames } },
        @{ Name = "Ubisoft";    Fn = { Get-UbisoftGames } },
        @{ Name = "Battle.net"; Fn = { Get-BattleNetGames } },
        @{ Name = "Rockstar";   Fn = { Get-RockstarGames } },
        @{ Name = "Xbox";       Fn = { Get-XboxGames } }
    )
    $perStoreCounts = @()

    foreach ($det in $detectors) {
        try {
            $res = @(& $det.Fn)
            $perStoreCounts += "$($det.Name)=$($res.Count)"
            if ($res) {
                foreach ($item in $res) {
                    if ($item -and -not [string]::IsNullOrWhiteSpace($item.InstallPath)) {
                        $item.InstallPath = Normalize-StorePath $item.InstallPath
                        [void]$allRaw.Add($item)
                    }
                }
            }
        } catch {
            $perStoreCounts += "$($det.Name)=ERR"
            [void](Write-DiagnosticError -Source "STORE" -Context "Store detector ($($det.Name))" -Target $det.Name -ErrorRecord $_)
        }
    }

    $seenPaths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $deduped = [System.Collections.Generic.List[object]]::new()
    foreach ($g in $allRaw) {
        $key = "$($g.Store)|$($g.InstallPath)"
        if ($seenPaths.Add($key)) {
            [void]$deduped.Add($g)
        }
    }

    $Script:DetectedStoreGames = @($deduped | Sort-Object Store, Name, InstallPath)
    Rebuild-StorePathIndex

    $extraPaths = [System.Collections.Generic.List[string]]::new()
    foreach ($p in $BaseSearchPaths) {
        $normP = Normalize-StorePath $p
        if (-not [string]::IsNullOrWhiteSpace($normP) -and -not $extraPaths.Contains($normP)) {
            [void]$extraPaths.Add($normP)
        }
    }
    foreach ($sp in $steamExtraPaths) {
        $normSp = Normalize-StorePath $sp
        if (-not [string]::IsNullOrWhiteSpace($normSp) -and -not $extraPaths.Contains($normSp)) {
            [void]$extraPaths.Add($normSp)
        }
    }
    $Script:SearchPaths = $extraPaths.ToArray()
    $script:SearchPaths = $Script:SearchPaths
    $Script:StoreScanCompleted = $true
    $sw.Stop()

    Write-DiagnosticLog -Level "DEBUG" -Source "STORE" -Message "Store scan finished in $($sw.ElapsedMilliseconds)ms | TotalDeduped=$($Script:DetectedStoreGames.Count) | SearchPaths=$($Script:SearchPaths.Count) | Breakdown: $($perStoreCounts -join ', ')"

    return $Script:DetectedStoreGames
}

function Get-StoreForPath {
    param([string]$FilePath)
    $normFile = Normalize-StorePath $FilePath
    if ([string]::IsNullOrWhiteSpace($normFile)) { return $null }
    if ($Script:StorePathCache.ContainsKey($normFile)) {
        return $Script:StorePathCache[$normFile]
    }
    if (-not $Script:StoreScanCompleted) {
        $null = Get-InstalledStoreGames
    }
    $matchedStore = $null
    foreach ($entry in $Script:StorePrefixEntries) {
        if ($normFile.StartsWith($entry.Prefix, [System.StringComparison]::OrdinalIgnoreCase) -or
            $normFile.Equals($entry.Exact, [System.StringComparison]::OrdinalIgnoreCase)) {
            $matchedStore = $entry.Store
            break
        }
    }
    $Script:StorePathCache[$normFile] = $matchedStore
    return $matchedStore
}

function Get-AppGroupName {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return "OTHER" }
    $s = $Text.ToLowerInvariant()
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

function Get-ExclusionsDiagnosticSummary {
    param([string[]]$ExcludedIds = $null)
    $ids = if ($null -ne $ExcludedIds) { @($ExcludedIds) } else { @(Get-SavedExclusions) }
    if ($ids.Count -eq 0) {
        return [PSCustomObject]@{
            Count   = 0
            Summary = "None (0)"
            IdsText = "None"
        }
    }

    $sanitizedIds = @($ids | ForEach-Object { Hide-Username ([string]$_) })
    $byApp = @($sanitizedIds | ForEach-Object {
        [PSCustomObject]@{
            App = (Get-AppGroupName $_)
            Id  = $_
        }
    } | Group-Object App | Sort-Object Name)

    $catParts = @($byApp | ForEach-Object {
        $sampleIds = @($_.Group | Select-Object -First 4 -ExpandProperty Id)
        $extra = $_.Group.Count - $sampleIds.Count
        $idListStr = ($sampleIds -join "; ")
        if ($extra -gt 0) { $idListStr += " (+$extra more)" }
        "$($_.Name) [$($_.Count): $idListStr]"
    })

    return [PSCustomObject]@{
        Count   = $ids.Count
        Summary = "$($ids.Count) -> " + ($catParts -join " | ")
        IdsText = ($sanitizedIds -join " ; ")
    }
}

function Log-ExclusionsOnce {
    param([string[]]$ExcludedIds = $null)
    if ($Script:ExclusionsLoggedOnce) { return }
    $Script:ExclusionsLoggedOnce = $true
    $exInfo = Get-ExclusionsDiagnosticSummary -ExcludedIds $ExcludedIds
    Write-DiagnosticLog -Level "INFO" -Source "EXCLUSIONS" -Message "One-time exclusions snapshot: $($exInfo.Summary)" -ForceTrim
}

function Copy-BugReportToClipboard {
    param(
        [string]$FallbackTitle = "ZeroHook Diagnostic Log"
    )
    Trim-DiagnosticLogFile
    $envInfo = Get-EnvironmentSummary

    $exclList = try { @(Get-SavedExclusions) } catch { @() }
    $exclInfo = Get-ExclusionsDiagnosticSummary -ExcludedIds $exclList
    $exclCount = $exclInfo.Count
    $taskState = try {
        $t = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($t) { "$($t.State)" } else { "NotRegistered" }
    } catch { "QueryFailed" }

    $storeSummary = if ($Script:DetectedStoreGames -and $Script:DetectedStoreGames.Count -gt 0) {
        $grpParts = @($Script:DetectedStoreGames | Group-Object Store | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Count)" })
        "$($Script:DetectedStoreGames.Count) ($($grpParts -join ', '))"
    } else {
        "0"
    }

    $liveTargetInfo = if ($Script:LiveHookTarget) {
        "$($Script:LiveHookTarget.Name) (PID $($Script:LiveHookTarget.Id))"
    } elseif ($Script:LastHookTargetInfo) {
        "Last: $($Script:LastHookTargetInfo.Name) (PID $($Script:LastHookTargetInfo.Id))"
    } else {
        "None"
    }
    $appFilterVal = if ($CmbAppFilter -and $CmbAppFilter.SelectedItem) { [string]$CmbAppFilter.SelectedItem } else { "N/A" }
    $pollVal = if ($CmbPollInterval -and $CmbPollInterval.SelectedItem) { [string]$CmbPollInterval.SelectedItem } else { "N/A" }
    $watchEnabled = if ($HookTimer) { [bool]$HookTimer.IsEnabled } else { $false }

    $recentLines = if (Test-Path -LiteralPath $DiagLogFile) {
        @(Get-Content -LiteralPath $DiagLogFile -Encoding UTF8 -ErrorAction SilentlyContinue | Select-Object -Last 600)
    } else {
        @()
    }

    if ($recentLines.Count -eq 0 -and $LogBox) {
        $uiText = (New-Object System.Windows.Documents.TextRange($LogBox.Document.ContentStart, $LogBox.Document.ContentEnd)).Text
        $recentLines = @($uiText -split "`r?`n" | Where-Object { $_.Trim() -ne "" } | ForEach-Object { Format-DiagnosticLine $_ })
    }

    $report = @(
        "=== ZeroHook Bug Report ==="
        "App: ZeroHook (Made by: GS | Build: v.1.0.2)"
        "SessionId: $Script:SessionId | RunMode: $($envInfo.Mode)"
        "Section: $FallbackTitle"
        "Timestamp (UTC): $((Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'))Z"
        "OS: $($envInfo.OsInfo) ($($envInfo.Arch))"
        "PowerShell: $($envInfo.PsVer) | Admin: $($envInfo.IsAdmin) | WorkingSet: $($envInfo.WorkingSet)"
        "Executable: $($envInfo.ExePath)"
        "Script: $($envInfo.ScriptPath)"
        "ExclusionsSummary: $($exclInfo.Summary)"
        "ExclusionsIDs: $($exclInfo.IdsText)"
        "State: Task=$taskState | Exclusions=$exclCount | StoreGames=$storeSummary | CategoryFilter=$Script:CurrentCategoryFilter | AppFilter=$appFilterVal | LiveTarget=$liveTargetInfo | WatchActive=$watchEnabled | Poll=$pollVal"
        "--- Recent Log ($($recentLines.Count) lines) ---"
        ($recentLines -join "`r`n")
        "=== End Report ==="
    ) -join "`r`n"

    [System.Windows.Clipboard]::SetText($report)
    Write-DiagnosticLog -Level "INFO" -Source "CLIPBOARD" -Message "Copied bug report (lines=$($recentLines.Count), section='$FallbackTitle', exclusions=$exclCount, task=$taskState)." -ForceTrim
}

function Get-HostRuntimeInfo {
    $exePath = ""
    try {
        $exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    } catch {}

    $isHostShell = [string]::IsNullOrWhiteSpace($exePath) -or ($exePath -match '(?i)\\(powershell|pwsh)\.exe$')
    $sourceScriptPath = $null

    if ($PSCommandPath -and (Test-Path -LiteralPath $PSCommandPath)) {
        $sourceScriptPath = $PSCommandPath
    } elseif ($MyInvocation.ScriptName -and (Test-Path -LiteralPath $MyInvocation.ScriptName)) {
        $sourceScriptPath = $MyInvocation.ScriptName
    }

    return [PSCustomObject]@{
        ExePath          = $exePath
        IsPortableExe    = (-not $isHostShell)
        SourceScriptPath = $sourceScriptPath
    }
}

function Invoke-RelaunchDebugMode {
    try {
        Write-DiagnosticLog -Level "INFO" -Source "APP" -Message "Relaunching ZeroHook in Debug Mode (-DebugLog)..." -ForceTrim
        $hostInfo = Get-HostRuntimeInfo

        if ($hostInfo.IsPortableExe) {
            $argList = @("-DebugLog")
            if ($AutoBlock) { $argList += "-AutoBlock" }
            Start-Process -FilePath $hostInfo.ExePath -ArgumentList $argList | Out-Null
        } else {
            $scriptFile = if ($hostInfo.SourceScriptPath) {
                $hostInfo.SourceScriptPath
            } elseif (Test-Path -LiteralPath $LocalScriptPath) {
                $LocalScriptPath
            } else {
                Save-LocalScriptCopy
            }
            $hostExe = if ($hostInfo.ExePath) { $hostInfo.ExePath } else { Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe" }
            $argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$scriptFile`"", "-DebugLog")
            if ($AutoBlock) { $argList += "-AutoBlock" }
            Start-Process -FilePath $hostExe -ArgumentList $argList | Out-Null
        }

        if ($Window) {
            $Window.Close()
        }
    } catch {
        $errCtx = Write-DiagnosticError -Source "APP" -Context "Relaunch in Debug Mode" -Target "ZeroHook" -ErrorRecord $_ -ForceTrim
        [System.Windows.MessageBox]::Show("Could not relaunch in Debug Mode:`n$errCtx", "ZeroHook Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
}

function Get-SavedExclusions {
    $targetDir = if ($UserConfigDir) { $UserConfigDir } else { Join-Path $env:LOCALAPPDATA "ZeroHook" }
    $targetPath = if ($ExclusionsFile) { $ExclusionsFile } else { Join-Path $targetDir "exclusions.json" }

    if (-not (Test-Path -LiteralPath $targetPath)) {
        foreach ($srcPath in @($RoamingExclusionsFile, $LegacyExclusionsFile)) {
            if ($srcPath -and ($srcPath -ne $targetPath) -and (Test-Path -LiteralPath $srcPath)) {
                try {
                    if (-not (Test-Path -LiteralPath $targetDir)) {
                        [System.IO.Directory]::CreateDirectory($targetDir) | Out-Null
                    }
                    Copy-Item -LiteralPath $srcPath -Destination $targetPath -Force -ErrorAction Stop
                    Write-DiagnosticLog -Level "INFO" -Source "EXCLUSIONS" -Message "Migrated legacy exclusions from $(Hide-Username $srcPath) to $(Hide-Username $targetPath)." -ForceTrim
                    break
                } catch {
                    [void](Write-DiagnosticError -Source "EXCLUSIONS" -Context "Migrate legacy exclusions" -Target $srcPath -ErrorRecord $_)
                }
            }
        }
    }

    if (Test-Path -LiteralPath $targetPath) {
        try {
            $rawText = [System.IO.File]::ReadAllText($targetPath, (New-Object System.Text.UTF8Encoding($false)))
            if (-not [string]::IsNullOrWhiteSpace($rawText)) {
                $parsed = ConvertFrom-Json -InputObject $rawText
                if ($null -ne $parsed) {
                    $ids = @($parsed | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
                    Write-DiagnosticLog -Level "DEBUG" -Source "EXCLUSIONS" -Message "Loaded $($ids.Count) exclusion(s) from $(Hide-Username $targetPath)."
                    Log-ExclusionsOnce -ExcludedIds $ids
                    return $ids
                }
            }
        } catch {
            [void](Write-DiagnosticError -Source "EXCLUSIONS" -Context "Read exclusions.json" -Target $targetPath -ErrorRecord $_ -ForceTrim)
        }
    }
    Log-ExclusionsOnce -ExcludedIds @()
    return @()
}

function Save-Exclusions {
    param([string[]]$Ids)
    $targetDir = if ($UserConfigDir) { $UserConfigDir } else { Join-Path $env:LOCALAPPDATA "ZeroHook" }
    $targetFile = if ($ExclusionsFile) { $ExclusionsFile } else { Join-Path $targetDir "exclusions.json" }

    try {
        if (-not (Test-Path -LiteralPath $targetDir)) {
            [System.IO.Directory]::CreateDirectory($targetDir) | Out-Null
        }

        $cleanIds = @(
            $Ids |
                ForEach-Object { [string]$_ } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                Select-Object -Unique
        )

        if ($cleanIds.Count -eq 0) {
            $json = "[]"
        } else {
            $json = ConvertTo-Json -InputObject @($cleanIds) -Compress
            if (-not $json.StartsWith("[")) {
                $json = "[$json]"
            }
        }

        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($targetFile, $json, $utf8NoBom)
        $exSummary = Get-ExclusionsDiagnosticSummary -ExcludedIds $cleanIds
        Write-DiagnosticLog -Level "INFO" -Source "EXCLUSIONS" -Message "Saved $($cleanIds.Count) exclusion(s) to $(Hide-Username $targetFile) | $($exSummary.Summary)." -ForceTrim
    } catch {
        [void](Write-DiagnosticError -Source "EXCLUSIONS" -Context "Save exclusions.json" -Target $targetFile -ErrorRecord $_ -ForceTrim)
        try {
            [System.Windows.MessageBox]::Show(
                "Could not save exclusions to:`n$targetFile`n`n$($_.Exception.Message)",
                "ZeroHook Error",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error
            ) | Out-Null
        } catch {}
    }
}

function Test-ItemExcluded {
    param(
        [string]$Id,
        [string[]]$ExcludedIds
    )
    if ([string]::IsNullOrWhiteSpace($Id) -or -not $ExcludedIds) { return $false }
    return ($ExcludedIds -contains $Id)
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
    if (-not $Script:StoreScanCompleted) {
        $null = Get-InstalledStoreGames
    }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $Found = [System.Collections.Generic.List[object]]::new()
    $seenFull = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $sys32Path = Normalize-StorePath "$env:SystemRoot\System32"
    $sysWow64Path = Normalize-StorePath "$env:SystemRoot\SysWOW64"
    $targetNameSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($td in $TargetDLLs) { [void]$targetNameSet.Add($td) }

    $addFile = {
        param($fileObj)
        if ($fileObj -and $seenFull.Add($fileObj.FullName)) {
            [void]$Found.Add($fileObj)
        }
    }

    foreach ($BasePath in $Script:SearchPaths) {
        $normBase = Normalize-StorePath $BasePath
        if (-not $normBase -or ($normBase -match '(?i)[\\/]WindowsApps([\\/]|$)')) { continue }
        if (-not (Test-Path -LiteralPath $normBase)) { continue }

        if ($normBase -ieq $sys32Path) {
            $nv64 = Join-Path $normBase "nvspcap64.dll"
            if (Test-Path -LiteralPath $nv64) {
                & $addFile (Get-Item -LiteralPath $nv64 -ErrorAction SilentlyContinue)
            }
            if (Test-Path -LiteralPath $sysWow64Path) {
                $nv32 = Join-Path $sysWow64Path "nvspcap.dll"
                if (Test-Path -LiteralPath $nv32) {
                    & $addFile (Get-Item -LiteralPath $nv32 -ErrorAction SilentlyContinue)
                }
            }
        } elseif ((Split-Path -Leaf $normBase) -ieq "Steam" -or $normBase -like "*\Steam") {
            foreach ($f in (Get-ChildItem -LiteralPath $normBase -File -ErrorAction SilentlyContinue)) {
                if ($targetNameSet.Contains($f.Name)) { & $addFile $f }
            }
            $steamBin = Join-Path $normBase "bin"
            if (Test-Path -LiteralPath $steamBin) {
                foreach ($f in (Get-ChildItem -Path $steamBin -Recurse -File -ErrorAction SilentlyContinue)) {
                    if ($targetNameSet.Contains($f.Name) -and ($f.FullName -notmatch $ExcludedPathRegex)) {
                        & $addFile $f
                    }
                }
            }
        } else {
            foreach ($f in (Get-ChildItem -Path $normBase -Recurse -File -ErrorAction SilentlyContinue)) {
                if ($targetNameSet.Contains($f.Name) -and ($f.FullName -notmatch $ExcludedPathRegex)) {
                    & $addFile $f
                }
            }
        }
    }

    $Results = [System.Collections.Generic.List[object]]::new()
    foreach ($F in $Found) {
        $IsBlocked = $false
        try {
            $Acl = Get-Acl -Path $F.FullName -ErrorAction Stop
            if ($Acl) {
                foreach ($R in $Acl.Access) {
                    if (Test-IsEveryoneDenyRule $R) { $IsBlocked = $true; break }
                }
            }
        } catch {
            [void](Write-DiagnosticError -Source "SCAN" -Context "Read DLL ACL" -Target $F.FullName -ErrorRecord $_)
        }
        $storeName = Get-StoreForPath -FilePath $F.FullName
        [void]$Results.Add([PSCustomObject]@{ Name = $F.Name; FullName = $F.FullName; IsBlocked = $IsBlocked; Store = $storeName })
    }
    $sw.Stop()
    Write-DiagnosticLog -Level "DEBUG" -Source "SCAN" -Message "Get-OverlayDLLs completed in $($sw.ElapsedMilliseconds)ms | Found=$($Results.Count)"
    return $Results.ToArray()
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
                            $Layers += [PSCustomObject]@{
                                Key        = $Key
                                Name       = $Name
                                App        = (Get-AppGroupName $Name)
                                IsDisabled = ($Val -eq 1)
                            }
                            break
                        }
                    }
                }
            }
        }
    }
    return @($Layers | Sort-Object App, Name)
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
                $EntryName = [string]$Prop.Name
                $EntryCmd = [string]$Prop.Value
                if ($EntryName -match "LEDKeeper2_Host" -or $EntryCmd -match "LEDKeeper2_Host") { continue }
                $nameLower = if ($EntryName) { $EntryName.ToLowerInvariant() } else { "" }
                $cmdLower = if ($EntryCmd) { $EntryCmd.ToLowerInvariant() } else { "" }
                foreach ($Kw in $StartupUtilityKeywords) {
                    if ($nameLower.Contains($Kw) -or $cmdLower.Contains($Kw)) {
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
                $fNameLower = if ($File.Name) { $File.Name.ToLowerInvariant() } else { "" }
                foreach ($Kw in $StartupUtilityKeywords) {
                    if ($fNameLower.Contains($Kw)) {
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
        $FullString = "$($Task.TaskPath)$($Task.TaskName)".ToLowerInvariant()
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
    if ([string]::IsNullOrWhiteSpace($ModuleName)) { return $null }
    $name = $ModuleName.ToLowerInvariant()
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
    if (-not $Script:StoreScanCompleted) {
        $null = Get-InstalledStoreGames
    }
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
                throw "Process start time changed (PID reused or process restarted; expected=$($ExpectedStartUtc.ToString('o')), actual=$($actualStart.ToString('o')))."
            }
        }
        $modules = $proc.Modules
        if ($null -eq $modules -or $modules.Count -eq 0) {
            throw "Windows returned an empty or inaccessible module list."
        }
        foreach ($m in $modules) {
            $modName = [string]$m.ModuleName
            $modPath = [string]$m.FileName
            $storeTag = Get-StoreForPath -FilePath $modPath
            $baseDesc = Get-LiveHookDllDescription -ModuleName $modName
            $fullDesc = if ($storeTag -and $baseDesc) { "[$storeTag] $baseDesc" } elseif ($storeTag) { "[$storeTag] Store game directory module" } else { $baseDesc }
            $item = [PSCustomObject]@{
                Name        = $modName
                Path        = $modPath
                Description = $fullDesc
                Store       = $storeTag
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
        if ($proc.HasExited) { throw "Target process exited during module scan (ExitCode=$($proc.ExitCode))." }
    } catch {
        $state = "INCONCLUSIVE"
        $message = $_.Exception.GetBaseException().Message
        $byFeature.Clear()
        [void](Write-DiagnosticError -Source "LIVEHOOK" -Context "Get-ProcessHookSnapshot" -Target "PID=$TargetPid;Path=$GamePath" -ErrorRecord $_)
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

    Write-DiagnosticLog -Level "DEBUG" -Source "LIVEHOOK" -Message "Snapshot PID=$TargetPid | State=$state | Modules=$($allModules.Count) | HookGroups=$($findings.Count) | Capture=$historicalCapture"

    return [PSCustomObject]@{
        State = $state; Message = $message; Findings = $findings; TotalModuleCount = $allModules.Count; HistoricalCapture = $historicalCapture
    }
}

# Pre-populate store game paths & log one-time exclusions at startup
$null = Get-InstalledStoreGames -Refresh
$null = Get-SavedExclusions

if ($AutoBlock) {
    $abSw = [System.Diagnostics.Stopwatch]::StartNew()
    Write-DiagnosticLog -Level "INFO" -Source "AUTOBLOCK" -Message "Starting scheduled AutoBlock run (respecting exclusions)." -ForceTrim
    $ExcludedIds = @(Get-SavedExclusions)
    $errCount = 0
    $skippedCount = 0
    $blockedCount = 0

    foreach ($File in (Get-OverlayDLLs)) {
        if (Test-ItemExcluded -Id "DLL|$($File.FullName)" -ExcludedIds $ExcludedIds) { $skippedCount++; continue }
        try {
            $Acl = Get-Acl -Path $File.FullName
            $Rule = New-Object System.Security.AccessControl.FileSystemAccessRule($EveryoneSID, "ReadAndExecute", "Deny")
            $Acl.SetAccessRule($Rule)
            Set-Acl -Path $File.FullName -AclObject $Acl
            $blockedCount++
        } catch {
            $errCount++
            [void](Write-DiagnosticError -Source "AUTOBLOCK" -Context "Block overlay DLL" -Target $File.FullName -ErrorRecord $_)
        }
    }
    foreach ($Layer in (Get-VulkanLayersList)) {
        if (Test-ItemExcluded -Id "VULKAN|$($Layer.Key)|$($Layer.Name)" -ExcludedIds $ExcludedIds) { $skippedCount++; continue }
        try {
            Set-ItemProperty -Path $Layer.Key -Name $Layer.Name -Value 1 -Type DWord
            $blockedCount++
        } catch {
            $errCount++
            [void](Write-DiagnosticError -Source "AUTOBLOCK" -Context "Disable Vulkan layer" -Target "$($Layer.Key)\$($Layer.Name)" -ErrorRecord $_)
        }
    }
    if (-not (Test-ItemExcluded -Id "GAMEBAR|XBOX" -ExcludedIds $ExcludedIds)) {
        try {
            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord
            New-Item -Path "HKCU:\System\GameConfigStore" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord
            Remove-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -ErrorAction SilentlyContinue
            $blockedCount++
        } catch {
            $errCount++
            [void](Write-DiagnosticError -Source "AUTOBLOCK" -Context "Disable Xbox Game Bar/DVR" -Target "HKCU GameDVR/GameConfigStore" -ErrorRecord $_)
        }
    } else {
        $skippedCount++
    }
    foreach ($Svc in (Get-UtilityServices)) {
        if (Test-ItemExcluded -Id "SVC|$($Svc.Name)" -ExcludedIds $ExcludedIds) { $skippedCount++; continue }
        try {
            if ($Svc.StartType -ne "Manual" -and $Svc.StartType -ne "Disabled") { Set-Service -Name $Svc.Name -StartupType Manual -ErrorAction Stop }
            if ($Svc.Status -eq "Running") { Stop-Service -Name $Svc.Name -Force -ErrorAction SilentlyContinue }
            $blockedCount++
        } catch {
            $errCount++
            [void](Write-DiagnosticError -Source "AUTOBLOCK" -Context "Set service Manual/stop" -Target $Svc.Name -ErrorRecord $_)
        }
    }
    $DisabledBytes = [byte[]](0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    foreach ($Item in (Get-UtilityStartupItems)) {
        if (Test-ItemExcluded -Id "RUN|$($Item.RunPath)|$($Item.Name)" -ExcludedIds $ExcludedIds) { $skippedCount++; continue }
        try {
            if (-not (Test-Path $Item.ApprovedPath)) { New-Item -Path $Item.ApprovedPath -Force | Out-Null }
            Set-ItemProperty -Path $Item.ApprovedPath -Name $Item.Name -Value $DisabledBytes -Type Binary -ErrorAction Stop
            $blockedCount++
        } catch {
            $errCount++
            [void](Write-DiagnosticError -Source "AUTOBLOCK" -Context "Disable startup Run entry" -Target "$($Item.RunPath)\$($Item.Name)" -ErrorRecord $_)
        }
    }
    foreach ($Sc in (Get-UtilityStartupShortcuts | Where-Object { -not $_.IsDisabled })) {
        if (Test-ItemExcluded -Id "SHORTCUT|$($Sc.OrigFolder)|$($Sc.Name)" -ExcludedIds $ExcludedIds) { $skippedCount++; continue }
        try {
            $Sub = if ($Sc.OrigFolder -eq $StartupFolderPaths[0]) { "User" } else { "Common" }
            $DestDir = Join-Path $StartupBackupDir $Sub
            if (-not (Test-Path $DestDir)) { New-Item -Path $DestDir -ItemType Directory -Force | Out-Null }
            Move-Item -Path $Sc.FullPath -Destination (Join-Path $DestDir $Sc.Name) -Force -ErrorAction Stop
            $blockedCount++
        } catch {
            $errCount++
            [void](Write-DiagnosticError -Source "AUTOBLOCK" -Context "Move startup shortcut" -Target $Sc.FullPath -ErrorRecord $_)
        }
    }
    foreach ($Task in (Get-UtilityScheduledTasks)) {
        if (Test-ItemExcluded -Id "TASK|$($Task.TaskPath)$($Task.TaskName)" -ExcludedIds $ExcludedIds) { $skippedCount++; continue }
        try {
            if ($Task.State -ne "Disabled") { Disable-ScheduledTask -TaskName $Task.TaskName -TaskPath $Task.TaskPath -ErrorAction Stop | Out-Null }
            $blockedCount++
        } catch {
            $errCount++
            [void](Write-DiagnosticError -Source "AUTOBLOCK" -Context "Disable scheduled task" -Target "$($Task.TaskPath)$($Task.TaskName)" -ErrorRecord $_)
        }
    }

    $abSw.Stop()
    Write-DiagnosticLog -Level "INFO" -Source "AUTOBLOCK" -Message "Completed scheduled AutoBlock run in $($abSw.ElapsedMilliseconds)ms (Applied: $blockedCount, Excluded skipped: $skippedCount, Errors: $errCount)." -ForceTrim
    return
}

# --- WPF GUI SETUP & LOGO LOADING ---
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

Write-DiagnosticLog -Level "INFO" -Source "APP" -Message "ZeroHook GUI started (Build: v.1.0.2)."

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
                        <Border x:Name="border" Background="#202024"
                                BorderBrush="#2E2E34"
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
            <Setter Property="Background" Value="#27272A"/>
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
                <TextBlock Text="Made by: GS  |  Build: v.1.0.2"
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
                            <Border x:Name="b" Background="#202024" BorderBrush="#3F3F46" BorderThickness="1" CornerRadius="5" Padding="{TemplateBinding Padding}">
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
                <Button x:Name="BtnDebugMode" Content="Debug Mode"
                        Background="#202024" Foreground="#FACC15" FontWeight="SemiBold" FontSize="11.5"
                        Padding="10,3" Height="25" Margin="0,0,6,0" VerticalAlignment="Center" Cursor="Hand"
                        ToolTip="Relaunch ZeroHook with -DebugLog enabled">
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
                            <Border x:Name="b" Background="#202024" BorderBrush="#3F3F46" BorderThickness="1" CornerRadius="5" Padding="{TemplateBinding Padding}">
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
                            <Border x:Name="b" Background="#27272A" BorderBrush="#3F3F46" BorderThickness="1" CornerRadius="5" Padding="{TemplateBinding Padding}">
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
                                <Border x:Name="bd" Background="#202024" BorderBrush="#2E2E34" BorderThickness="1" CornerRadius="5,5,0,0" Margin="0,0,4,0" Padding="{TemplateBinding Padding}" Cursor="Hand">
                                    <ContentPresenter ContentSource="Header" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Border>
                                <ControlTemplate.Triggers>
                                    <Trigger Property="IsSelected" Value="True">
                                        <Setter TargetName="bd" Property="Background" Value="#27272E"/>
                                        <Setter TargetName="bd" Property="TextElement.Foreground" Value="#FFFFFF"/>
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
                                Background="#D97706" Content="Exclusions List..."/>
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
    $innerErr = if ($_.Exception.InnerException) { $_.Exception.InnerException.Message } else { "" }
    $fullErr = if ($innerErr) { "$($_.Exception.Message)`n$innerErr" } else { $_.Exception.Message }
    [void](Write-DiagnosticError -Source "XAML" -Context "Load main GUI XAML" -Target "MainWindow" -ErrorRecord $_ -ForceTrim)
    [System.Windows.MessageBox]::Show("Failed to load GUI XAML:`n$fullErr", "ZeroHook Error") | Out-Null
    return
}

$ImgHeaderLogo        = $Window.FindName("ImgHeaderLogo")
$BtnCopyBugReport     = $Window.FindName("BtnCopyBugReport")
$BtnDebugMode         = $Window.FindName("BtnDebugMode")
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

if ($BtnDebugMode) {
    if ($DebugLog) {
        $BtnDebugMode.Content = "Debug Active (Relaunch)"
        $BtnDebugMode.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2A2410")
    } else {
        $BtnDebugMode.Content = "Debug Mode"
        $BtnDebugMode.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#202024")
    }
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
    $link.FontWeight = [System.Windows.FontWeights]::Bold
    $link.Cursor = [System.Windows.Input.Cursors]::Hand

    $run = New-Object System.Windows.Documents.Run("$symbol ")
    $run.FontWeight = [System.Windows.FontWeights]::Bold
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
    $hostInfo = Get-HostRuntimeInfo
    if ($hostInfo.IsPortableExe) {
        throw "Portable executable detected; no script copy is saved to ProgramData."
    }

    if (-not (Test-Path -LiteralPath $LocalInstallDir)) {
        New-Item -Path $LocalInstallDir -ItemType Directory -Force | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $scriptText = $null
    $sourceUsed = "none"

    if ($hostInfo.SourceScriptPath) {
        $scriptText = [System.IO.File]::ReadAllText($hostInfo.SourceScriptPath, $utf8NoBom)
        $sourceUsed = "ScriptFile"
    } elseif ($MyInvocation.MyCommand -and $MyInvocation.MyCommand.ScriptBlock) {
        $scriptText = $MyInvocation.MyCommand.ScriptBlock.ToString()
        $sourceUsed = "ScriptBlock"
    }

    if ([string]::IsNullOrWhiteSpace($scriptText) -or $scriptText.Length -lt 1000 -or ($scriptText -notmatch 'ZeroHook_AutoBlock')) {
        throw "Captured script source looks incomplete/empty (source=$sourceUsed, len=$(if ($scriptText) { $scriptText.Length } else { 0 })). Run ZeroHook from a .ps1 file to create the scheduled task."
    }

    [System.IO.File]::WriteAllText($LocalScriptPath, $scriptText, $utf8NoBom)
    Write-DiagnosticLog -Level "INFO" -Source "TASK" -Message "Saved local script copy to $(Hide-Username $LocalScriptPath) via $sourceUsed (chars=$($scriptText.Length))."
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
    Write-DiagnosticLog -Level "DEBUG" -Source "UI" -Message "Cleared Blocker log -> '$HeaderTitle'"
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
        $RunBadge.FontWeight = [System.Windows.FontWeights]::Bold
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
        [string]$DiagMessage = "",
        [switch]$SkipDiagLog,
        [switch]$NoScroll
    )
    if (-not $SkipDiagLog -and ($Badge -ne "" -or $Message -ne "" -or $DiagMessage -ne "")) {
        $lvl = if ($Badge -match "FAIL|ERROR|INCONCLUSIVE|EXITED") { "WARN" } else { "INFO" }
        $logText = if (-not [string]::IsNullOrWhiteSpace($DiagMessage)) { $DiagMessage } else { "$Badge$Message".Trim() }
        Write-DiagnosticLog -Level $lvl -Source "LIVEHOOK" -Message $logText
    }
    $Para = New-Object System.Windows.Documents.Paragraph
    if (-not [string]::IsNullOrWhiteSpace($ToggleCategoryId) -and (Test-IsCollapsibleCategory -CategoryId $ToggleCategoryId)) {
        $toggleLink = New-CategoryToggleLink -CategoryId $ToggleCategoryId
        $Para.Inlines.Add($toggleLink)
    }
    if ($Badge -ne "") {
        $RunBadge = New-Object System.Windows.Documents.Run($Badge)
        $RunBadge.FontWeight = [System.Windows.FontWeights]::Bold
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

function Get-MissingCoreOverlayLabels {
    param($Snapshot)
    $detectedIds = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    if ($Snapshot -and $Snapshot.Findings) {
        foreach ($f in $Snapshot.Findings) {
            if ($f -and -not [string]::IsNullOrWhiteSpace([string]$f.Id)) {
                [void]$detectedIds.Add([string]$f.Id)
            }
        }
    }

    $coreOverlays = @(
        @{ Id = "Steam";   Name = "Steam" },
        @{ Id = "Discord"; Name = "Discord" },
        @{ Id = "NVIDIA";  Name = "NVIDIA" }
    )
    $missing = [System.Collections.Generic.List[string]]::new()
    foreach ($ov in $coreOverlays) {
        if (-not $detectedIds.Contains($ov.Id)) {
            [void]$missing.Add($ov.Name)
        }
    }
    return $missing.ToArray()
}

function Write-MissingCoreOverlaysHookLog {
    param(
        $Snapshot,
        [string]$Prefix = "  ",
        [string]$Timestamp = "",
        [switch]$NoScroll
    )
    if (-not $Snapshot -or $Snapshot.State -eq "INCONCLUSIVE") { return }
    $missing = @(Get-MissingCoreOverlayLabels -Snapshot $Snapshot)
    if ($missing.Count -gt 0) {
        $joined = ($missing -join ", ")
        $tsPart = if (-not [string]::IsNullOrWhiteSpace($Timestamp)) { "[$Timestamp] " } else { "" }
        Add-HookLog -Badge "${Prefix}${tsPart}[NOT DETECTED] " `
            -Message "$joined .dll overlay(s) not detected in process." `
            -BadgeColor "Green" -MsgColor "Green" -SkipDiagLog -NoScroll:$NoScroll
    }
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
        Write-DiagnosticLog -Level "DEBUG" -Source "LIVEHOOK" -Message "Refreshed target process list -> $($CmbHookProcess.Items.Count) candidate window process(es)."
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
            $pName = [string]$p.ProcessName
            $p.Dispose()
            return [PSCustomObject]@{
                Id = [int]$sel.Id; Name = $pName; Path = [string]$path; StartedUtc = $startedUtc
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
        Add-HookLog -Badge "`n=== SNAPSHOT: $($target.Name) (PID $($target.Id)) ===" -BadgeColor "Cyan" -SkipDiagLog -NoScroll
        if ($target.Path) { Add-HookLog -Message "  Path: $(Hide-Username $target.Path)" -MsgColor "Muted" -SkipDiagLog -NoScroll }
        Write-MissingCoreOverlaysHookLog -Snapshot $snap -Prefix "  " -NoScroll
        if ($snap.Findings.Count -eq 0) {
            Add-HookLog -Badge "  [CLEAN] " -Message "No matched overlay/hook modules detected in loaded modules." -BadgeColor "Green" -SkipDiagLog -NoScroll
        } else {
            foreach ($f in $snap.Findings) {
                $findingColor = Get-LiveHookFindingColor -CategoryId $f.Id
                $isCollapsible = Test-IsCollapsibleCategory -CategoryId $f.Id
                $isMin = Test-IsCategoryMinimized -CategoryId $f.Id
                if ($isCollapsible -and $isMin) {
                    $modDetails = @($f.Modules | ForEach-Object {
                        $d = if (-not [string]::IsNullOrWhiteSpace($_.Description)) { " ($($_.Description))" } else { "" }
                        "$($_.Name) -> $(Hide-Username $_.Path)$d"
                    }) -join " | "
                    Add-HookLog -Badge "  [$($f.Id)] $($f.Label) " -Message "($($f.Modules.Count) module(s) — minimized)" `
                        -BadgeColor $findingColor -MsgColor "Muted" -ToggleCategoryId $f.Id `
                        -DiagMessage "[$($f.Id)] $($f.Label) ($($f.Modules.Count) module(s) — minimized in UI): $modDetails" -NoScroll
                } else {
                    Add-HookLog -Badge "  [$($f.Id)] $($f.Label) " -Message "($($f.Scope))" -BadgeColor $findingColor -MsgColor "Muted" -ToggleCategoryId $f.Id -SkipDiagLog -NoScroll
                    foreach ($m in $f.Modules) {
                        $descSuffix = if (-not [string]::IsNullOrWhiteSpace($m.Description)) { " — $($m.Description)" } else { "" }
                        Add-HookLog -Message "     - $(Hide-Username $m.Path)$descSuffix" -MsgColor "Gray" -SkipDiagLog -NoScroll
                    }
                    if ($LiveHookFeatures.Contains($f.Id)) {
                        Add-HookLog -Badge "     How to disable: " -Message $LiveHookFeatures[$f.Id].Off -BadgeColor "Cyan" -MsgColor "Gray" -SkipDiagLog -NoScroll
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
        Write-DiagnosticLog -Level "DEBUG" -Source "LIVEHOOK" -Message "Monitor step skipped: no valid target process."
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
        Write-DiagnosticLog -Level "INFO" -Source "LIVEHOOK" -Message "Target exited: $($target.Name) (PID $($target.Id))."
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

    if (-not $ForceLogSnapshot) {
        Write-MissingCoreOverlaysHookLog -Snapshot $snap -Prefix "" -Timestamp (Get-Date -Format 'HH:mm:ss') -NoScroll
    }

    $currentHookKeys = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($f in $snap.Findings) {
        $findingColor = Get-LiveHookFindingColor -CategoryId $f.Id
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
            foreach ($nm in $newModsInGroup) {
                $descPart = if (-not [string]::IsNullOrWhiteSpace($nm.Description)) { " | Desc: $($nm.Description)" } else { "" }
                $minTag = if ($isCollapsible -and $isMin) { " [UI-MINIMIZED]" } else { "" }
                Write-DiagnosticLog -Level "INFO" -Source "LIVEHOOK" -Message "[HOOK DETECTED][$($f.Id)]$minTag $($nm.Name) -> $(Hide-Username $nm.Path)$descPart"
            }

            if ($isCollapsible -and $isMin) {
                if (-not $Script:PendingHookDetections.ContainsKey($f.Id)) {
                    $Script:PendingHookDetections[$f.Id] = [System.Collections.Generic.List[object]]::new()
                }
                foreach ($nm in $newModsInGroup) { [void]$Script:PendingHookDetections[$f.Id].Add($nm) }
                $totalQueued = $Script:PendingHookDetections[$f.Id].Count
                Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [HOOK DETECTED][$($f.Id)] " -Message "$totalQueued module(s) detected (minimized — click [+] to expand)" -BadgeColor $findingColor -MsgColor "Muted" -ToggleCategoryId $f.Id -SkipDiagLog -NoScroll
            } else {
                foreach ($nm in $newModsInGroup) {
                    Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [HOOK DETECTED][$($f.Id)] " -Message "$($nm.Name) -> $(Hide-Username $nm.Path)" -BadgeColor $findingColor -MsgColor "Gray" -ToggleCategoryId $f.Id -SkipDiagLog -NoScroll
                    if (-not [string]::IsNullOrWhiteSpace($nm.Description)) {
                        Add-HookLog -Badge "   Desc: " -Message $nm.Description -BadgeColor "Green" -MsgColor "Gray" -SkipDiagLog -NoScroll
                    }
                }
                if ($LiveHookFeatures.Contains($f.Id)) {
                    Add-HookLog -Badge "   Off switch: " -Message $LiveHookFeatures[$f.Id].Off -BadgeColor "Cyan" -MsgColor "Muted" -SkipDiagLog -NoScroll
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
        Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [HOOK UNLOADED] " -Message (Hide-Username $rk) -BadgeColor "Cyan" -MsgColor "Muted" -NoScroll
    }

    if ($ForceLogSnapshot) {
        Render-HookLogFromState -ForceSnapshot
    } else {
        $HookLogBox.ScrollToEnd()
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
            $RL.FontWeight = [System.Windows.FontWeights]::Bold
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
    & $AddInfoLine -Lead "   - Exclusions List: " -Body "Checked items in Exclusions List are saved to %LOCALAPPDATA%\ZeroHook\exclusions.json (kept allowed/unblocked) and respected by Block Everything, Block Overlay Hooks Only, and -AutoBlock." -LeadColor "Cyan"
    & $AddInfoLine -Lead "   - Diagnostic Logs & Bug Reports: " -Body "Saves masked session logs to %LOCALAPPDATA%\ZeroHook\Logs\zerohook-current.log (max 2,500 lines; optional -DebugLog). Click 'Copy Log for Dev' in the header to copy a bug report for GS." -LeadColor "Cyan"

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

function Restore-SingleExcludedItem {
    param($Candidate)
    $EnabledBytes = [byte[]](0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    switch ($Candidate.Kind) {
        "DLL" {
            $f = $Candidate.RawObject
            if ($f -and $f.IsBlocked) {
                $Acl = Get-Acl -Path $f.FullName
                $Removed = $false
                foreach ($Rule in @($Acl.Access)) {
                    if (Test-IsEveryoneDenyRule $Rule) { $Acl.RemoveAccessRule($Rule) | Out-Null; $Removed = $true }
                }
                if ($Removed) {
                    Set-Acl -Path $f.FullName -AclObject $Acl
                    Add-Log -Badge "[UNEXCLUDED / ALLOWED][$($Candidate.App)] " -Message (Hide-Username $f.FullName) -BadgeColor "Cyan" -NoScroll
                }
            }
        }
        "VULKAN" {
            $l = $Candidate.RawObject
            if ($l -and $l.IsDisabled) {
                Set-ItemProperty -Path $l.Key -Name $l.Name -Value 0 -Type DWord
                Add-Log -Badge "[UNEXCLUDED / ENABLED VULKAN][$($Candidate.App)] " -Message (Hide-Username $l.Name) -BadgeColor "Cyan" -NoScroll
            }
        }
        "GAMEBAR" {
            if ($Candidate.IsBlocked) {
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                Add-Log -Badge "[UNEXCLUDED / ENABLED][XBOX / GAME BAR] " -Message "Xbox Game Bar & Game DVR Registry Hooks" -BadgeColor "Cyan" -NoScroll
            }
        }
        "SVC" {
            $s = $Candidate.RawObject
            if ($s -and ($s.StartType -eq "Manual" -or $s.StartType -eq "Disabled")) {
                Set-Service -Name $s.Name -StartupType Automatic -ErrorAction Stop
                Start-Service -Name $s.Name -ErrorAction SilentlyContinue
                Add-Log -Badge "[UNEXCLUDED / AUTO][$($Candidate.App)] " -Message "$($s.DisplayName) ($($s.Name))" -BadgeColor "Cyan" -NoScroll
            }
        }
        "RUN" {
            $r = $Candidate.RawObject
            if ($r -and $r.IsDisabled -and (Test-Path $r.ApprovedPath)) {
                Set-ItemProperty -Path $r.ApprovedPath -Name $r.Name -Value $EnabledBytes -Type Binary -ErrorAction Stop
                Add-Log -Badge "[UNEXCLUDED / ENABLED STARTUP][$($Candidate.App)] " -Message $r.Name -BadgeColor "Cyan" -NoScroll
            }
        }
        "SHORTCUT" {
            $sc = $Candidate.RawObject
            if ($sc -and $sc.IsDisabled) {
                if (-not (Test-Path $sc.OrigFolder)) { New-Item -Path $sc.OrigFolder -ItemType Directory -Force | Out-Null }
                Move-Item -Path $sc.FullPath -Destination (Join-Path $sc.OrigFolder $sc.Name) -Force -ErrorAction Stop
                Add-Log -Badge "[UNEXCLUDED / RESTORED SHORTCUT][$($Candidate.App)] " -Message $sc.Name -BadgeColor "Cyan" -NoScroll
            }
        }
        "TASK" {
            $t = $Candidate.RawObject
            if ($t -and $t.State -eq "Disabled") {
                Enable-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction Stop | Out-Null
                Add-Log -Badge "[UNEXCLUDED / ENABLED TASK][$($Candidate.App)] " -Message "$($t.TaskPath)$($t.TaskName)" -BadgeColor "Cyan" -NoScroll
            }
        }
    }
}

function Show-ExclusionsDialog {
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
            IsExcluded  = (Test-ItemExcluded -Id $id -ExcludedIds $ExcludedIds)
            IsBlocked   = [bool]$File.IsBlocked
            RawObject   = $File
        })
    }
    foreach ($Layer in $VulkanLayers) {
        $id = "VULKAN|$($Layer.Key)|$($Layer.Name)"
        [void]$Candidates.Add([PSCustomObject]@{
            Id          = $id
            Kind        = "VULKAN"
            App         = (Get-AppGroupName $Layer.Name)
            DetailText  = "[Vulkan Layer] $(Hide-Username $Layer.Name)"
            IsExcluded  = (Test-ItemExcluded -Id $id -ExcludedIds $ExcludedIds)
            IsBlocked   = [bool]$Layer.IsDisabled
            RawObject   = $Layer
        })
    }
    $gbId = "GAMEBAR|XBOX"
    [void]$Candidates.Add([PSCustomObject]@{
        Id          = $gbId
        Kind        = "GAMEBAR"
        App         = "XBOX / GAME BAR"
        DetailText  = "[Game Bar] Xbox Game Bar / Game DVR Background Hooks"
        IsExcluded  = (Test-ItemExcluded -Id $gbId -ExcludedIds $ExcludedIds)
        IsBlocked   = [bool]$GameBarOff
        RawObject   = $null
    })
    foreach ($Svc in $Services) {
        $id = "SVC|$($Svc.Name)"
        $off = ($Svc.StartType -eq "Manual" -or $Svc.StartType -eq "Disabled")
        [void]$Candidates.Add([PSCustomObject]@{
            Id          = $id
            Kind        = "SVC"
            App         = (Get-AppGroupName "$($Svc.Name) $($Svc.DisplayName)")
            DetailText  = "[Service] $($Svc.DisplayName) ($($Svc.Name)) [Start: $($Svc.StartType)]"
            IsExcluded  = (Test-ItemExcluded -Id $id -ExcludedIds $ExcludedIds)
            IsBlocked   = $off
            RawObject   = $Svc
        })
    }
    foreach ($Item in $StartupItems) {
        $id = "RUN|$($Item.RunPath)|$($Item.Name)"
        [void]$Candidates.Add([PSCustomObject]@{
            Id          = $id
            Kind        = "RUN"
            App         = (Get-AppGroupName "$($Item.Name) $($Item.Command)")
            DetailText  = "[Startup Run] $($Item.Name)  ($(Hide-Username $Item.RunPath))"
            IsExcluded  = (Test-ItemExcluded -Id $id -ExcludedIds $ExcludedIds)
            IsBlocked   = [bool]$Item.IsDisabled
            RawObject   = $Item
        })
    }
    foreach ($Sc in $Shortcuts) {
        $id = "SHORTCUT|$($Sc.OrigFolder)|$($Sc.Name)"
        [void]$Candidates.Add([PSCustomObject]@{
            Id          = $id
            Kind        = "SHORTCUT"
            App         = (Get-AppGroupName "$($Sc.Name) $($Sc.FullPath)")
            DetailText  = "[Startup Shortcut] $($Sc.Name) ($(Hide-Username $Sc.OrigFolder))"
            IsExcluded  = (Test-ItemExcluded -Id $id -ExcludedIds $ExcludedIds)
            IsBlocked   = [bool]$Sc.IsDisabled
            RawObject   = $Sc
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
            IsExcluded  = (Test-ItemExcluded -Id $id -ExcludedIds $ExcludedIds)
            IsBlocked   = $off
            RawObject   = $Task
        })
    }

    [xml]$PickXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Exclusions List (Do Not Block) - ZeroHook"
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
            <TextBlock Text="EXCLUSIONS LIST — ITEMS YOU DO NOT WANT TO BLOCK" FontSize="15" FontWeight="Bold" Foreground="#FFFFFF"/>
            <TextBlock Text="CHECKED items are EXCLUDED (kept active/allowed and skipped by Block Everything, Block Overlay Hooks Only, and Auto-Block). Unchecked items remain eligible to block."
                       FontSize="11.5" Foreground="#A1A1AA" Margin="0,2,0,0" TextWrapping="Wrap"/>
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
            <Button x:Name="BtnCheckVisible" Grid.Column="1" Content="Exclude All Visible"
                    Background="#27272A" Foreground="#E4E4E7" FontWeight="SemiBold" FontSize="11.5"
                    Padding="12,4" Height="28" Margin="8,0,0,0" BorderBrush="#3F3F46" BorderThickness="1" Cursor="Hand"/>
            <Button x:Name="BtnUncheckVisible" Grid.Column="2" Content="Clear Exclusions Visible"
                    Background="#27272A" Foreground="#E4E4E7" FontWeight="SemiBold" FontSize="11.5"
                    Padding="12,4" Height="28" Margin="6,0,0,0" BorderBrush="#3F3F46" BorderThickness="1" Cursor="Hand"/>
        </Grid>

        <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,0,0,8" VerticalAlignment="Center">
            <TextBlock Text="Quick Exclude Presets:" FontSize="11.5" Foreground="#A1A1AA" VerticalAlignment="Center" Margin="0,0,8,0"/>
            <Button x:Name="BtnKeepRgb" Content="Exclude RGB Control"
                    Background="#1E293B" Foreground="#60A5FA" FontWeight="SemiBold" FontSize="11.5"
                    Padding="10,4" Height="26" Margin="0,0,6,0" BorderBrush="#2563EB" BorderThickness="1" Cursor="Hand"/>
            <Button x:Name="BtnKeepController" Content="Exclude Controller / Gamepad"
                    Background="#1E293B" Foreground="#60A5FA" FontWeight="SemiBold" FontSize="11.5"
                    Padding="10,4" Height="26" Margin="0,0,6,0" BorderBrush="#2563EB" BorderThickness="1" Cursor="Hand"/>
        </StackPanel>

        <Border Grid.Row="3" Background="#0C0C0E" BorderBrush="#2E2E34" BorderThickness="1" CornerRadius="6" Padding="10">
            <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                <StackPanel x:Name="ItemsPanel" HorizontalAlignment="Stretch"/>
            </ScrollViewer>
        </Border>

        <Grid Grid.Row="4" Margin="0,10,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock x:Name="TxtPickCount" Grid.Column="0" Text="" Foreground="#A1A1AA" FontSize="12" VerticalAlignment="Center"/>
            <Button x:Name="BtnApplySelected" Grid.Column="1" Content="Save Exclusions"
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

    $GetExclusionEntryColor = {
        param($entry)
        if ($entry.CheckBox.IsChecked) { return $BrushGreen }
        if ($entry.Candidate.IsBlocked) { return $BrushYellow }
        return $BrushRed
    }

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
        foreach ($entry in $Entries) {
            $entry.CheckBox.Foreground = & $GetExclusionEntryColor $entry
        }
        $excludedCount = @($Entries | Where-Object { $_.CheckBox.IsChecked }).Count
        $eligibleCount = $Entries.Count - $excludedCount
        $TxtPickCount.Text = "$excludedCount excluded (kept safe)  |  $eligibleCount eligible to block  (of $($Entries.Count) total)"
        foreach ($gh in $GroupHeaders) {
            & $SyncGroupToggleState $gh
        }
    }

    $ApplySearchFilter = {
        $q = ([string]$TxtFilterBox.Text).Trim().ToLowerInvariant()
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
        $hdr.FontWeight = [System.Windows.FontWeights]::Bold
        $hdr.FontFamily = New-Object System.Windows.Media.FontFamily("Consolas")
        $hdr.FontSize = 12
        $hdr.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $hdr.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

        [void]$hdrRow.Children.Add($groupCb)
        [void]$hdrRow.Children.Add($hdr)
        [void]$ItemsPanel.Children.Add($hdrRow)

        $grpEntries = [System.Collections.Generic.List[object]]::new()
        foreach ($c in $grp.Group) {
            $cb = New-Object System.Windows.Controls.CheckBox
            $statePrefix = if ($c.IsBlocked) { "[CURRENTLY BLOCKED] " } else { "[ACTIVE] " }
            $cbContentTb = New-Object System.Windows.Controls.TextBlock
            $cbContentTb.Text = "$statePrefix$($c.DetailText)"
            $cbContentTb.TextWrapping = [System.Windows.TextWrapping]::Wrap
            $cb.Content = $cbContentTb
            $cb.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
            $cb.Tag = $c
            $cb.IsChecked = [bool]$c.IsExcluded
            $cb.Foreground = if ($c.IsExcluded) { $BrushGreen } elseif ($c.IsBlocked) { $BrushYellow } else { $BrushRed }
            $cb.Margin = New-Object System.Windows.Thickness(18, 2, 8, 2)
            $cb.FontFamily = New-Object System.Windows.Media.FontFamily("Consolas")
            $cb.FontSize = 11.5
            $cb.Add_Checked($UpdateCount)
            $cb.Add_Unchecked($UpdateCount)
            [void]$ItemsPanel.Children.Add($cb)

            $rec = [PSCustomObject]@{
                CheckBox   = $cb
                Candidate  = $c
                SearchText = "$($grp.Name) $($c.DetailText) $statePrefix".ToLowerInvariant()
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
                $entry.CheckBox.IsChecked = $true
            }
        }
        & $UpdateCount
    })

    $BtnKeepController.Add_Click({
        foreach ($entry in $Entries) {
            if ($entry.Candidate.App -in $ControllerApps) {
                $entry.CheckBox.IsChecked = $true
            }
        }
        & $UpdateCount
    })

    $Applied = $false
    $BtnApplySelected.Add_Click({
        $Applied = $true
        $selectedIds = @($Entries | Where-Object { $_.CheckBox.IsChecked } | ForEach-Object { [string]$_.Candidate.Id })
        Save-Exclusions -Ids $selectedIds
        $PickWin.Close()
    })
    $BtnCancelPick.Add_Click({ $Applied = $false; $PickWin.Close() })

    $PickWin.ShowDialog() | Out-Null
    if (-not $Applied) {
        Write-DiagnosticLog -Level "DEBUG" -Source "EXCLUSIONS" -Message "Exclusions dialog cancelled without changes."
        return
    }

    $NewExclusions = @(Get-SavedExclusions)
    $NewlyExcludedCandidates = @()
    foreach ($entry in $Entries) {
        $c = $entry.Candidate
        if ($entry.CheckBox.IsChecked -and (-not $c.IsExcluded)) {
            $NewlyExcludedCandidates += $c
        }
    }

    Clear-Log "ACTIVITY LOG - SAVING EXCLUSIONS LIST"
    Add-Log -Badge "[EXCLUSIONS SAVED] " -Message "$($NewExclusions.Count) item(s) marked as excluded (saved to %LOCALAPPDATA%\ZeroHook\exclusions.json)." -BadgeColor "Green" -NoScroll

    foreach ($nc in $NewlyExcludedCandidates) {
        try {
            Restore-SingleExcludedItem -Candidate $nc
        } catch {
            $errCtx = Write-DiagnosticError -Source "EXCLUSIONS" -Context "Restore newly excluded item ($($nc.Kind))" -Target $nc.DetailText -ErrorRecord $_
            Add-Log -Badge "[FAILED UNEXCLUDE][$($nc.App)] " -Message "$($nc.DetailText) - $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }

    Add-Log -Badge "`n=== EXCLUSIONS UPDATED ===" -BadgeColor "Cyan"
    Update-Dashboard -Filter "NONE"
}

function Render-PerAppSummary {
    param([string]$AppFilter = "ALL APPS", [string]$CategoryFilter = "ALL", [switch]$ShowSteamTip)
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
        if ($ShowSteamTip -and $AppFilter -eq "STEAM") { Add-SteamClientTipToLog -NoScroll }
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
    param([string]$Filter = $Script:CurrentCategoryFilter, [switch]$ShowSteamTip)
    if ($Filter -eq "NONE") { return }
    $Script:CurrentCategoryFilter = $Filter
    $AppFilter = if ($CmbAppFilter.SelectedItem) { [string]$CmbAppFilter.SelectedItem } else { "ALL APPS" }
    $D = $Script:ScanData
    if (-not $D -or $D.Count -eq 0) { return }

    Write-DiagnosticLog -Level "DEBUG" -Source "UI" -Message "Render-FilteredLog -> Category=$Filter | AppFilter=$AppFilter"

    Clear-Log "$Filter - FILTER: $AppFilter"
    if ($AppFilter -ne "ALL APPS") {
        $showTipForApp = [bool]($ShowSteamTip -and ($AppFilter -eq "STEAM"))
        Render-PerAppSummary -AppFilter $AppFilter -CategoryFilter $Filter -ShowSteamTip:$showTipForApp
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
        if ($ShowSteamTip) {
            Add-SteamClientTipToLog -NoScroll
        }
    }
    Add-Log -Badge "`n=== SCAN COMPLETE ===" -BadgeColor "Cyan"
}

function Update-Dashboard {
    param([string]$Filter = $Script:CurrentCategoryFilter, [switch]$ShowSteamTip)
    $scanSw = [System.Diagnostics.Stopwatch]::StartNew()
    $ExcludedIds = @(Get-SavedExclusions)
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

    $exclDllCount = @($Dlls | Where-Object { Test-ItemExcluded -Id "DLL|$($_.FullName)" -ExcludedIds $ExcludedIds }).Count
    $exclVulkanCount = @($VulkanLayers | Where-Object { Test-ItemExcluded -Id "VULKAN|$($_.Key)|$($_.Name)" -ExcludedIds $ExcludedIds }).Count + $(if (Test-ItemExcluded -Id "GAMEBAR|XBOX" -ExcludedIds $ExcludedIds) { 1 } else { 0 })
    $exclSvcCount = @($Services | Where-Object { Test-ItemExcluded -Id "SVC|$($_.Name)" -ExcludedIds $ExcludedIds }).Count
    $exclStartupCount = @($StartupItems | Where-Object { Test-ItemExcluded -Id "RUN|$($_.RunPath)|$($_.Name)" -ExcludedIds $ExcludedIds }).Count +
                        @($Shortcuts | Where-Object { Test-ItemExcluded -Id "SHORTCUT|$($_.OrigFolder)|$($_.Name)" -ExcludedIds $ExcludedIds }).Count +
                        @($VendorTasks | Where-Object { Test-ItemExcluded -Id "TASK|$($_.TaskPath)$($_.TaskName)" -ExcludedIds $ExcludedIds }).Count

    $taskBase = if ($ExistingTask) { "ENABLED" } else { "DISABLED" }
    $TxtCardTaskStatus.Text = if ($ExcludedIds.Count -gt 0) { "$taskBase ($($ExcludedIds.Count) excluded)" } else { $taskBase }
    $TxtCardTaskStatus.Foreground = if ($ExistingTask) { $BrushGreen } else { $BrushGray }

    $BlockedDllCount = @($Dlls | Where-Object { $_.IsBlocked }).Count
    $dllBase = if ($Dlls.Count -eq 0) { "NONE FOUND" } else { "$BlockedDllCount/$($Dlls.Count) BLOCKED" }
    $TxtCardDllStatus.Text = if ($exclDllCount -gt 0) { "$dllBase ($exclDllCount excluded)" } else { $dllBase }
    $TxtCardDllStatus.Foreground = if ($Dlls.Count -eq 0) { $BrushGray } elseif ($BlockedDllCount -eq $Dlls.Count) { $BrushGreen } else { $BrushRed }

    $DisabledVulkanCount = @($VulkanLayers | Where-Object { $_.IsDisabled }).Count
    $vulkanBase = if ($GameBarOff -and ($DisabledVulkanCount -eq $VulkanLayers.Count)) { "ALL DISABLED" } else { "$DisabledVulkanCount/$($VulkanLayers.Count) VULKAN OFF" }
    $TxtCardVulkanStatus.Text = if ($exclVulkanCount -gt 0) { "$vulkanBase ($exclVulkanCount excluded)" } else { $vulkanBase }
    $TxtCardVulkanStatus.Foreground = if ($GameBarOff -and ($DisabledVulkanCount -eq $VulkanLayers.Count)) { $BrushGreen } else { $BrushYellow }

    $ManualSvcCount = @($Services | Where-Object { $_.StartType -eq "Manual" -or $_.StartType -eq "Disabled" }).Count
    $svcBase = if ($Services.Count -eq 0) { "NONE FOUND" } else { "$ManualSvcCount/$($Services.Count) MANUAL" }
    $TxtCardSvcStatus.Text = if ($exclSvcCount -gt 0) { "$svcBase ($exclSvcCount excluded)" } else { $svcBase }
    $TxtCardSvcStatus.Foreground = if ($Services.Count -eq 0) { $BrushGray } elseif ($ManualSvcCount -eq $Services.Count) { $BrushGreen } else { $BrushRed }

    $TotalStartup = $StartupItems.Count + $Shortcuts.Count + $VendorTasks.Count
    $DisabledStartup = @($StartupItems | Where-Object { $_.IsDisabled }).Count +
                       @($Shortcuts | Where-Object { $_.IsDisabled }).Count +
                       @($VendorTasks | Where-Object { $_.State -eq "Disabled" }).Count
    $startupBase = if ($TotalStartup -eq 0) { "NONE FOUND" } else { "$DisabledStartup/$TotalStartup OFF" }
    $TxtCardStartupStatus.Text = if ($exclStartupCount -gt 0) { "$startupBase ($exclStartupCount excluded)" } else { $startupBase }
    $TxtCardStartupStatus.Foreground = if ($TotalStartup -eq 0) { $BrushGray } elseif ($DisabledStartup -eq $TotalStartup) { $BrushGreen } else { $BrushRed }

    $TxtCardLauncherStatus.Text = if ($RunningProcs.Count -eq 0) { "NONE RUNNING" } else { "$(@($RunningProcs.ProcessName | Select-Object -Unique).Count) APPS RUNNING" }
    $TxtCardLauncherStatus.Foreground = if ($RunningProcs.Count -eq 0) { $BrushGreen } else { $BrushYellow }

    $scanSw.Stop()
    Write-DiagnosticLog -Level "DEBUG" -Source "SCAN" -Message "Update-Dashboard scanned in $($scanSw.ElapsedMilliseconds)ms | Task=$([bool]$ExistingTask) | DLLs=$BlockedDllCount/$($Dlls.Count) | Vulkan=$DisabledVulkanCount/$($VulkanLayers.Count) | GameBarOff=$GameBarOff | Svcs=$ManualSvcCount/$($Services.Count) | Startup=$DisabledStartup/$TotalStartup | RunningProcs=$($RunningProcs.Count)"

    Render-FilteredLog -Filter $Filter -ShowSteamTip:$ShowSteamTip
}

function Prompt-CloseLaunchers {
    $Running = Get-RunningLaunchers
    if ($Running.Count -gt 0) {
        $procNames = @($Running.ProcessName | Select-Object -Unique) -join ", "
        Write-DiagnosticLog -Level "INFO" -Source "BLOCKER" -Message "Prompting to close running launcher/utility processes ($($Running.Count) instances: $procNames)."
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
            Write-DiagnosticLog -Level "INFO" -Source "BLOCKER" -Message "User chose to stop running launcher/utility processes."
            [System.Windows.Forms.Application]::DoEvents()
        } else {
            Write-DiagnosticLog -Level "INFO" -Source "BLOCKER" -Message "User chose not to stop running launcher/utility processes."
        }
    }
}

function Invoke-BlockHooksGUI {
    param(
        $DllList = $null,
        $VulkanList = $null
    )
    $ExcludedIds = @(Get-SavedExclusions)
    $targetDlls = if ($null -ne $DllList) { $DllList } else { Get-OverlayDLLs }
    $targetVulkan = if ($null -ne $VulkanList) { $VulkanList } else { Get-VulkanLayersList }

    foreach ($File in $targetDlls) {
        $id = "DLL|$($File.FullName)"
        $appTag = Get-AppGroupName "$($File.Name) $($File.FullName)"
        if (Test-ItemExcluded -Id $id -ExcludedIds $ExcludedIds) {
            Add-Log -Badge "[EXCLUDED / KEPT][$appTag] " -Message (Hide-Username $File.FullName) -BadgeColor "Cyan" -NoScroll
            continue
        }
        try {
            $Acl = Get-Acl -Path $File.FullName
            $Rule = New-Object System.Security.AccessControl.FileSystemAccessRule($EveryoneSID, "ReadAndExecute", "Deny")
            $Acl.SetAccessRule($Rule)
            Set-Acl -Path $File.FullName -AclObject $Acl
            Add-Log -Badge "[BLOCKED][$appTag] " -Message (Hide-Username $File.FullName) -BadgeColor "Green" -NoScroll
        } catch {
            $errCtx = Write-DiagnosticError -Source "BLOCKER" -Context "Block overlay DLL" -Target $File.FullName -ErrorRecord $_
            Add-Log -Badge "[FAILED][$appTag] " -Message "$(Hide-Username $File.FullName) - $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    foreach ($Layer in $targetVulkan) {
        $id = "VULKAN|$($Layer.Key)|$($Layer.Name)"
        $appTag = Get-AppGroupName $Layer.Name
        if (Test-ItemExcluded -Id $id -ExcludedIds $ExcludedIds) {
            Add-Log -Badge "[EXCLUDED / KEPT VULKAN][$appTag] " -Message (Hide-Username $Layer.Name) -BadgeColor "Cyan" -NoScroll
            continue
        }
        try {
            Set-ItemProperty -Path $Layer.Key -Name $Layer.Name -Value 1 -Type DWord
            Add-Log -Badge "[DISABLED VULKAN][$appTag] " -Message (Hide-Username $Layer.Name) -BadgeColor "Green" -NoScroll
        } catch {
            $errCtx = Write-DiagnosticError -Source "BLOCKER" -Context "Disable Vulkan layer" -Target "$($Layer.Key)\$($Layer.Name)" -ErrorRecord $_
            Add-Log -Badge "[FAILED VULKAN][$appTag] " -Message "$(Hide-Username $Layer.Name) - $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    if (-not (Test-ItemExcluded -Id "GAMEBAR|XBOX" -ExcludedIds $ExcludedIds)) {
        try {
            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord
            New-Item -Path "HKCU:\System\GameConfigStore" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord
            Add-Log -Badge "[DISABLED][XBOX / GAME BAR] " -Message "Xbox Game Bar & Game DVR Registry Hooks" -BadgeColor "Green" -NoScroll
        } catch {
            $errCtx = Write-DiagnosticError -Source "BLOCKER" -Context "Disable Xbox Game Bar/DVR" -Target "HKCU GameDVR/GameConfigStore" -ErrorRecord $_
            Add-Log -Badge "[FAILED][XBOX / GAME BAR] " -Message $errCtx -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    } else {
        Add-Log -Badge "[EXCLUDED / KEPT][XBOX / GAME BAR] " -Message "Xbox Game Bar & Game DVR Registry Hooks" -BadgeColor "Cyan" -NoScroll
    }
}

function Invoke-RestoreHooksGUI {
    param(
        $DllList = $null,
        $VulkanList = $null
    )
    $targetDlls = if ($null -ne $DllList) { $DllList } else { Get-OverlayDLLs }
    $targetVulkan = if ($null -ne $VulkanList) { $VulkanList } else { Get-VulkanLayersList }

    foreach ($File in $targetDlls) {
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
            $errCtx = Write-DiagnosticError -Source "BLOCKER" -Context "Restore overlay DLL ACL" -Target $File.FullName -ErrorRecord $_
            Add-Log -Badge "[FAILED RESTORE][$appTag] " -Message "$(Hide-Username $File.FullName) - $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    foreach ($Layer in $targetVulkan) {
        try {
            Set-ItemProperty -Path $Layer.Key -Name $Layer.Name -Value 0 -Type DWord
        } catch {
            $errCtx = Write-DiagnosticError -Source "BLOCKER" -Context "Restore Vulkan layer" -Target "$($Layer.Key)\$($Layer.Name)" -ErrorRecord $_
            Add-Log -Badge "[FAILED RESTORE VULKAN] " -Message "$(Hide-Username $Layer.Name) - $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    } catch {
        $errCtx = Write-DiagnosticError -Source "BLOCKER" -Context "Restore Xbox Game Bar/DVR" -Target "HKCU GameDVR/GameConfigStore" -ErrorRecord $_
        Add-Log -Badge "[FAILED RESTORE GAMEBAR] " -Message $errCtx -BadgeColor "Red" -MsgColor "Red" -NoScroll
    }
}

function Invoke-BlockUtilitiesGUI {
    param(
        $ServiceList = $null,
        $StartupList = $null,
        $ShortcutList = $null,
        $TaskList = $null
    )
    $ExcludedIds = @(Get-SavedExclusions)
    $targetServices = if ($null -ne $ServiceList) { $ServiceList } else { Get-UtilityServices }
    $targetStartup = if ($null -ne $StartupList) { $StartupList } else { Get-UtilityStartupItems }
    $targetShortcuts = if ($null -ne $ShortcutList) { $ShortcutList } else { Get-UtilityStartupShortcuts }
    $targetTasks = if ($null -ne $TaskList) { $TaskList } else { Get-UtilityScheduledTasks }

    foreach ($Svc in $targetServices) {
        $id = "SVC|$($Svc.Name)"
        $appTag = Get-AppGroupName "$($Svc.Name) $($Svc.DisplayName)"
        if (Test-ItemExcluded -Id $id -ExcludedIds $ExcludedIds) {
            Add-Log -Badge "[EXCLUDED / KEPT SERVICE][$appTag] " -Message "$($Svc.DisplayName) ($($Svc.Name))" -BadgeColor "Cyan" -NoScroll
            continue
        }
        try {
            if ($Svc.StartType -ne "Manual" -and $Svc.StartType -ne "Disabled") { Set-Service -Name $Svc.Name -StartupType Manual -ErrorAction Stop }
            if ($Svc.Status -eq "Running") { Stop-Service -Name $Svc.Name -Force -ErrorAction SilentlyContinue }
            Add-Log -Badge "[MANUAL & STOPPED][$appTag] " -Message "$($Svc.DisplayName) ($($Svc.Name))" -BadgeColor "Green" -NoScroll
        } catch {
            $errCtx = Write-DiagnosticError -Source "BLOCKER" -Context "Set service Manual/stop" -Target $Svc.Name -ErrorRecord $_
            Add-Log -Badge "[FAILED SERVICE][$appTag] " -Message "$($Svc.Name) - $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    $DisabledBytes = [byte[]](0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    foreach ($Item in $targetStartup) {
        $id = "RUN|$($Item.RunPath)|$($Item.Name)"
        $appTag = Get-AppGroupName "$($Item.Name) $($Item.Command)"
        if (Test-ItemExcluded -Id $id -ExcludedIds $ExcludedIds) {
            Add-Log -Badge "[EXCLUDED / KEPT STARTUP][$appTag] " -Message $Item.Name -BadgeColor "Cyan" -NoScroll
            continue
        }
        try {
            if (-not (Test-Path $Item.ApprovedPath)) { New-Item -Path $Item.ApprovedPath -Force | Out-Null }
            Set-ItemProperty -Path $Item.ApprovedPath -Name $Item.Name -Value $DisabledBytes -Type Binary -ErrorAction Stop
            Add-Log -Badge "[DISABLED STARTUP][$appTag] " -Message $Item.Name -BadgeColor "Green" -NoScroll
        } catch {
            $errCtx = Write-DiagnosticError -Source "BLOCKER" -Context "Disable startup Run entry" -Target "$($Item.RunPath)\$($Item.Name)" -ErrorRecord $_
            Add-Log -Badge "[FAILED STARTUP][$appTag] " -Message "$($Item.Name) - $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    foreach ($Sc in ($targetShortcuts | Where-Object { -not $_.IsDisabled })) {
        $id = "SHORTCUT|$($Sc.OrigFolder)|$($Sc.Name)"
        $appTag = Get-AppGroupName "$($Sc.Name) $($Sc.FullPath)"
        if (Test-ItemExcluded -Id $id -ExcludedIds $ExcludedIds) {
            Add-Log -Badge "[EXCLUDED / KEPT SHORTCUT][$appTag] " -Message $Sc.Name -BadgeColor "Cyan" -NoScroll
            continue
        }
        try {
            $Sub = if ($Sc.OrigFolder -eq $StartupFolderPaths[0]) { "User" } else { "Common" }
            $DestDir = Join-Path $StartupBackupDir $Sub
            if (-not (Test-Path $DestDir)) { New-Item -Path $DestDir -ItemType Directory -Force | Out-Null }
            Move-Item -Path $Sc.FullPath -Destination (Join-Path $DestDir $Sc.Name) -Force -ErrorAction Stop
            Add-Log -Badge "[DISABLED SHORTCUT][$appTag] " -Message $Sc.Name -BadgeColor "Green" -NoScroll
        } catch {
            $errCtx = Write-DiagnosticError -Source "BLOCKER" -Context "Move startup shortcut" -Target $Sc.FullPath -ErrorRecord $_
            Add-Log -Badge "[FAILED SHORTCUT][$appTag] " -Message "$($Sc.Name) - $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    foreach ($Task in $targetTasks) {
        $id = "TASK|$($Task.TaskPath)$($Task.TaskName)"
        $appTag = Get-AppGroupName "$($Task.TaskPath)$($Task.TaskName)"
        if (Test-ItemExcluded -Id $id -ExcludedIds $ExcludedIds) {
            Add-Log -Badge "[EXCLUDED / KEPT TASK][$appTag] " -Message "$($Task.TaskPath)$($Task.TaskName)" -BadgeColor "Cyan" -NoScroll
            continue
        }
        try {
            if ($Task.State -ne "Disabled") { Disable-ScheduledTask -TaskName $Task.TaskName -TaskPath $Task.TaskPath -ErrorAction Stop | Out-Null }
            Add-Log -Badge "[DISABLED TASK][$appTag] " -Message "  $($Task.TaskPath)$($Task.TaskName)" -BadgeColor "Green" -NoScroll
        } catch {
            $errCtx = Write-DiagnosticError -Source "BLOCKER" -Context "Disable scheduled task" -Target "$($Task.TaskPath)$($Task.TaskName)" -ErrorRecord $_
            Add-Log -Badge "[FAILED TASK][$appTag] " -Message "$($Task.TaskName) - $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
}

function Invoke-RestoreUtilitiesGUI {
    param(
        $ServiceList = $null,
        $StartupList = $null,
        $ShortcutList = $null,
        $TaskList = $null
    )
    $targetServices = if ($null -ne $ServiceList) { $ServiceList } else { Get-UtilityServices }
    $targetStartup = if ($null -ne $StartupList) { $StartupList } else { Get-UtilityStartupItems }
    $targetShortcuts = if ($null -ne $ShortcutList) { $ShortcutList } else { Get-UtilityStartupShortcuts }
    $targetTasks = if ($null -ne $TaskList) { $TaskList } else { Get-UtilityScheduledTasks }

    foreach ($Svc in $targetServices) {
        try {
            Set-Service -Name $Svc.Name -StartupType Automatic -ErrorAction Stop
            Start-Service -Name $Svc.Name -ErrorAction SilentlyContinue
        } catch {
            $errCtx = Write-DiagnosticError -Source "BLOCKER" -Context "Restore service Automatic" -Target $Svc.Name -ErrorRecord $_
            Add-Log -Badge "[FAILED RESTORE SERVICE] " -Message "$($Svc.Name) - $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    $EnabledBytes = [byte[]](0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    foreach ($Item in $targetStartup) {
        try {
            if (Test-Path $Item.ApprovedPath) { Set-ItemProperty -Path $Item.ApprovedPath -Name $Item.Name -Value $EnabledBytes -Type Binary -ErrorAction Stop }
        } catch {
            $errCtx = Write-DiagnosticError -Source "BLOCKER" -Context "Restore startup Run entry" -Target "$($Item.RunPath)\$($Item.Name)" -ErrorRecord $_
            Add-Log -Badge "[FAILED RESTORE STARTUP] " -Message "$($Item.Name) - $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    foreach ($Sc in ($targetShortcuts | Where-Object { $_.IsDisabled })) {
        try {
            if (-not (Test-Path $Sc.OrigFolder)) { New-Item -Path $Sc.OrigFolder -ItemType Directory -Force | Out-Null }
            Move-Item -Path $Sc.FullPath -Destination (Join-Path $Sc.OrigFolder $Sc.Name) -Force -ErrorAction Stop
        } catch {
            $errCtx = Write-DiagnosticError -Source "BLOCKER" -Context "Restore startup shortcut" -Target $Sc.FullPath -ErrorRecord $_
            Add-Log -Badge "[FAILED RESTORE SHORTCUT] " -Message "$($Sc.Name) - $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
    foreach ($Task in $targetTasks) {
        try {
            if ($Task.State -eq "Disabled") { Enable-ScheduledTask -TaskName $Task.TaskName -TaskPath $Task.TaskPath -ErrorAction Stop | Out-Null }
        } catch {
            $errCtx = Write-DiagnosticError -Source "BLOCKER" -Context "Restore scheduled task" -Target "$($Task.TaskPath)$($Task.TaskName)" -ErrorRecord $_
            Add-Log -Badge "[FAILED RESTORE TASK] " -Message "$($Task.TaskName) - $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoScroll
        }
    }
}

$BtnCopyBugReport.Add_Click({
    try {
        $secName = if ($MainTabs.SelectedIndex -eq 1) { "Live DLL Hooks" } else { "Bloat & Overlay Blocker" }
        Copy-BugReportToClipboard -FallbackTitle $secName
        $origText = $BtnCopyBugReport.Content
        $BtnCopyBugReport.Content = "Copied!"
        Start-Sleep -Milliseconds 350
        $BtnCopyBugReport.Content = $origText
        if ($MainTabs.SelectedIndex -eq 1) {
            Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [BUG REPORT COPIED] " -Message "Copied sanitized diagnostic report + recent log to clipboard for GS." -BadgeColor "Green"
        } else {
            Add-Log -Badge "[BUG REPORT COPIED] " -Message "Copied sanitized diagnostic report + recent log to clipboard for GS." -BadgeColor "Green"
        }
    } catch {
        $errCtx = Write-DiagnosticError -Source "CLIPBOARD" -Context "Copy bug report to clipboard" -Target "Clipboard" -ErrorRecord $_
        [System.Windows.MessageBox]::Show("Could not copy bug report:`n$errCtx", "ZeroHook Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})

$BtnDebugMode.Add_Click({
    Invoke-RelaunchDebugMode
})

$BtnAboutInfo.Add_Click({ Show-AboutInfoWindow })
$BtnRefresh.Add_Click({
    if ($MainTabs.SelectedIndex -eq 1) {
        Refresh-HookProcessList
        Invoke-HookMonitorStep -ForceLogSnapshot
    } else {
        Update-Dashboard -Filter $Script:CurrentCategoryFilter
    }
})

$CardTask.Add_Click({
    $Script:SuppressFilterEvent = $true; $CmbAppFilter.SelectedIndex = 0; $Script:SuppressFilterEvent = $false
    Update-Dashboard -Filter "TASK"
})
$CardDlls.Add_Click({
    $Script:SuppressFilterEvent = $true; $CmbAppFilter.SelectedIndex = 0; $Script:SuppressFilterEvent = $false
    Update-Dashboard -Filter "DLLS"
})
$CardVulkan.Add_Click({
    $Script:SuppressFilterEvent = $true; $CmbAppFilter.SelectedIndex = 0; $Script:SuppressFilterEvent = $false
    Update-Dashboard -Filter "VULKAN"
})
$CardServices.Add_Click({
    $Script:SuppressFilterEvent = $true; $CmbAppFilter.SelectedIndex = 0; $Script:SuppressFilterEvent = $false
    Update-Dashboard -Filter "SERVICES"
})
$CardStartup.Add_Click({
    $Script:SuppressFilterEvent = $true; $CmbAppFilter.SelectedIndex = 0; $Script:SuppressFilterEvent = $false
    Update-Dashboard -Filter "STARTUP"
})
$CardLaunchers.Add_Click({
    $Script:SuppressFilterEvent = $true; $CmbAppFilter.SelectedIndex = 0; $Script:SuppressFilterEvent = $false
    Update-Dashboard -Filter "LAUNCHERS"
})

$CmbAppFilter.Add_SelectionChanged({
    if ($Script:SuppressFilterEvent) { return }
    $selectedApp = if ($CmbAppFilter.SelectedItem) { [string]$CmbAppFilter.SelectedItem } else { "ALL APPS" }
    Write-DiagnosticLog -Level "DEBUG" -Source "UI" -Message "App filter changed to '$selectedApp'."
    if ($Script:ScanData.Count -eq 0) { Update-Dashboard -Filter $Script:CurrentCategoryFilter }
    else { Render-FilteredLog -Filter $Script:CurrentCategoryFilter }
})

$BtnBlockAll.Add_Click({
    Write-DiagnosticLog -Level "INFO" -Source "BLOCKER" -Message "Action clicked: Block Everything (respecting exclusions)."
    Prompt-CloseLaunchers
    Clear-Log "ACTIVITY LOG - BLOCKING EVERYTHING (RESPECTING EXCLUSIONS)"
    $exclCount = @(Get-SavedExclusions).Count
    Add-Log -Badge "[EXCLUSIONS ACTIVE] " -Message "$exclCount excluded item(s) will be kept allowed/unblocked." -BadgeColor "Cyan" -NoScroll
    Invoke-BlockHooksGUI
    Invoke-BlockUtilitiesGUI
    Add-Log -Badge "`n=== BLOCK COMPLETE ===" -BadgeColor "Green"
    Update-Dashboard -Filter "NONE"
})

$BtnCustomBlock.Add_Click({
    Write-DiagnosticLog -Level "INFO" -Source "EXCLUSIONS" -Message "Action clicked: Exclusions List."
    Show-ExclusionsDialog
})

$BtnRestoreAll.Add_Click({
    Write-DiagnosticLog -Level "INFO" -Source "BLOCKER" -Message "Action clicked: Restore Everything (Default Auto-Start)."
    Clear-Log "ACTIVITY LOG - RESTORING EVERYTHING"
    Invoke-RestoreHooksGUI
    Invoke-RestoreUtilitiesGUI
    Add-Log -Badge "`n=== RESTORE COMPLETE ===" -BadgeColor "Green"
    Update-Dashboard -Filter "NONE"
})

$BtnBlockOverlaysOnly.Add_Click({
    Write-DiagnosticLog -Level "INFO" -Source "BLOCKER" -Message "Action clicked: Block Overlay Hooks Only (respecting exclusions)."
    Prompt-CloseLaunchers
    Clear-Log "ACTIVITY LOG - BLOCKING OVERLAY HOOKS ONLY (RESPECTING EXCLUSIONS)"
    $exclCount = @(Get-SavedExclusions).Count
    Add-Log -Badge "[EXCLUSIONS ACTIVE] " -Message "$exclCount excluded item(s) will be kept allowed/unblocked." -BadgeColor "Cyan" -NoScroll
    Invoke-BlockHooksGUI
    Add-Log -Badge "`n=== OVERLAY BLOCK COMPLETE ===" -BadgeColor "Green"
    Update-Dashboard -Filter "NONE"
})

$BtnToggleTask.Add_Click({
    Write-DiagnosticLog -Level "INFO" -Source "TASK" -Message "Action clicked: Toggle Auto-Run at Startup (Task Scheduler)."
    $Existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($Existing) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-DiagnosticLog -Level "INFO" -Source "TASK" -Message "Removed scheduled task '$TaskName'."
        Update-Dashboard -Filter "TASK"
        Add-Log -Badge "`n[TASK REMOVED] " -Message "Scheduled task '$TaskName' deleted." -BadgeColor "Yellow"
    } else {
        $hostInfo = Get-HostRuntimeInfo
        if ($hostInfo.IsPortableExe) {
            $exeArg = "-AutoBlock"
            if ($DebugLog) { $exeArg += " -DebugLog" }
            $Action = New-ScheduledTaskAction -Execute $hostInfo.ExePath -Argument $exeArg
        } else {
            try {
                $TargetScript = Save-LocalScriptCopy
            } catch {
                $errCtx = Write-DiagnosticError -Source "TASK" -Context "Save local script copy for task" -Target $LocalScriptPath -ErrorRecord $_
                Add-Log -Badge "[FAILED] " -Message "Could not save script copy: $errCtx" -BadgeColor "Red" -MsgColor "Red"
                return
            }
            $psArg = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$TargetScript`" -AutoBlock"
            if ($DebugLog) { $psArg += " -DebugLog" }
            $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $psArg
        }
        $Trigger = New-ScheduledTaskTrigger -AtLogOn
        $Trigger.Delay = "PT60S"
        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -RunLevel Highest -Force | Out-Null
        Write-DiagnosticLog -Level "INFO" -Source "TASK" -Message "Registered scheduled task '$TaskName' (AtLogOn, 60s delay)."
        Update-Dashboard -Filter "TASK" -ShowSteamTip
        Add-Log -Badge "`n[TASK ENABLED] " -Message "Scheduled task '$TaskName' will run 60s after logon." -BadgeColor "Green"
    }
})

$BtnQuickFilter.Add_Click({
    Write-DiagnosticLog -Level "INFO" -Source "UI" -Message "Action clicked: Reset Log & Filters."
    $Script:SuppressFilterEvent = $true
    $CmbAppFilter.SelectedIndex = 0
    $Script:SuppressFilterEvent = $false
    Update-Dashboard -Filter "ALL"
})

$BtnReloadProcs.Add_Click({
    Refresh-HookProcessList
    Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [PROCESSES RELOADED] " -Message "Found $($CmbHookProcess.Items.Count) window process(es)." -BadgeColor "Cyan"
})

$CmbHookProcess.Add_SelectionChanged({
    if ($Script:SuppressHookProcessSelection) { return }
    $selTarget = Get-SelectedHookTarget
    if ($selTarget) {
        $Script:LiveHookTarget = $selTarget
        $Script:SeenModuleKeys.Clear()
        $Script:PendingHookDetections.Clear()
        $TxtLiveHookStatus.Text = "SELECTED: $($selTarget.Name) (PID $($selTarget.Id))"
        $TxtLiveHookStatus.Foreground = $BrushCyan
        Write-DiagnosticLog -Level "INFO" -Source "LIVEHOOK" -Message "Selected target process: $($selTarget.Name) (PID $($selTarget.Id))."
    }
})

$BtnLockForeground.Add_Click({
    try {
        Ensure-ForegroundWin32
    } catch {
        $errCtx = Write-DiagnosticError -Source "LIVEHOOK" -Context "Compile Win32 foreground helper" -Target "ZeroHook.Win32Foreground" -ErrorRecord $_
        Add-HookLog -Badge "[ERROR] " -Message "Could not initialize foreground helper: $errCtx" -BadgeColor "Red" -MsgColor "Red"
        return
    }
    $BtnLockForeground.IsEnabled = $false
    $TxtLiveHookStatus.Text = "LOCKING IN 3s - Switch to your game window now..."
    $TxtLiveHookStatus.Foreground = $BrushYellow
    Write-DiagnosticLog -Level "INFO" -Source "LIVEHOOK" -Message "Lock Foreground (3s) started."

    for ($i = 3; $i -ge 1; $i--) {
        $TxtLiveHookStatus.Text = "LOCKING IN ${i}s - Switch to your game window now..."
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Seconds 1
    }

    $fgPid = [ZeroHook.Win32Foreground]::GetForegroundPid()
    $BtnLockForeground.IsEnabled = $true

    if ($fgPid -le 0 -or $fgPid -eq $PID) {
        $TxtLiveHookStatus.Text = "LOCK FAILED - Foreground window is ZeroHook or invalid"
        $TxtLiveHookStatus.Foreground = $BrushRed
        Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [LOCK FAILED] " -Message "No external foreground window captured (PID=$fgPid)." -BadgeColor "Red"
        return
    }

    try {
        $p = Get-Process -Id $fgPid -ErrorAction Stop
        $startedUtc = try { $p.StartTime.ToUniversalTime() } catch { $null }
        $path = try { [string]$p.Path } catch { "" }
        $pName = [string]$p.ProcessName
        $p.Dispose()

        if ($pName -in $IgnoredForegroundProcesses) {
            $TxtLiveHookStatus.Text = "LOCK SKIPPED - Ignored system/shell process ($pName)"
            $TxtLiveHookStatus.Foreground = $BrushYellow
            Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [LOCK SKIPPED] " -Message "Foreground process '$pName' (PID $fgPid) is in ignored list." -BadgeColor "Yellow"
            return
        }

        $Script:LiveHookTarget = [PSCustomObject]@{ Id = [int]$fgPid; Name = $pName; Path = [string]$path; StartedUtc = $startedUtc }
        $Script:SeenModuleKeys.Clear()
        $Script:PendingHookDetections.Clear()
        Refresh-HookProcessList

        for ($idx = 0; $idx -lt $CmbHookProcess.Items.Count; $idx++) {
            $itemTag = $CmbHookProcess.Items[$idx].Tag
            if ($itemTag -and $itemTag.Id -eq $fgPid) {
                $Script:SuppressHookProcessSelection = $true
                $CmbHookProcess.SelectedIndex = $idx
                $Script:SuppressHookProcessSelection = $false
                break
            }
        }

        Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [LOCKED ONTO] " -Message "$pName (PID $fgPid)" -BadgeColor "Green"
        Invoke-HookMonitorStep -ForceLogSnapshot
    } catch {
        $errCtx = Write-DiagnosticError -Source "LIVEHOOK" -Context "Lock onto foreground process" -Target "PID=$fgPid" -ErrorRecord $_
        $TxtLiveHookStatus.Text = "LOCK FAILED - Could not inspect PID $fgPid"
        $TxtLiveHookStatus.Foreground = $BrushRed
        Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [LOCK FAILED] " -Message "PID $fgPid - $errCtx" -BadgeColor "Red"
    }
})

$BtnToggleLiveMonitor.Add_Click({
    if ($HookTimer.IsEnabled) {
        $HookTimer.Stop()
        $BtnToggleLiveMonitor.Content = "Start Real-Time Watch"
        $BtnToggleLiveMonitor.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#22A055")
        $TxtLiveHookStatus.Text = "WATCH PAUSED"
        $TxtLiveHookStatus.Foreground = $BrushYellow
        Write-DiagnosticLog -Level "INFO" -Source "LIVEHOOK" -Message "Real-time watch stopped."
    } else {
        $target = Get-SelectedHookTarget
        if (-not $target -and $Script:LiveHookTarget) {
            try {
                $pCheck = Get-Process -Id $Script:LiveHookTarget.Id -ErrorAction Stop
                $pCheck.Dispose()
                $target = $Script:LiveHookTarget
            } catch { $target = $null }
        }
        if (-not $target) {
            $TxtLiveHookStatus.Text = "SELECT A PROCESS FIRST - Choose a target or use Lock Foreground"
            $TxtLiveHookStatus.Foreground = $BrushRed
            Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [WATCH BLOCKED] " -Message "Select a valid target process first." -BadgeColor "Red"
            return
        }
        $Script:LiveHookTarget = $target
        $Script:SeenModuleKeys.Clear()
        $Script:PendingHookDetections.Clear()
        $secs = switch ($CmbPollInterval.SelectedIndex) { 0 { 1 } 1 { 2 } 2 { 3 } default { 5 } }
        $HookTimer.Interval = [TimeSpan]::FromSeconds($secs)
        $HookTimer.Start()
        $BtnToggleLiveMonitor.Content = "Stop Real-Time Watch"
        $BtnToggleLiveMonitor.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#DC2626")
        Write-DiagnosticLog -Level "INFO" -Source "LIVEHOOK" -Message "Real-time watch started on $($target.Name) (PID $($target.Id)) with interval=${secs}s."
        Invoke-HookMonitorStep -ForceLogSnapshot
    }
})

$BtnScanNowHooks.Add_Click({
    $target = Get-SelectedHookTarget
    if (-not $target -and $Script:LiveHookTarget) {
        try {
            $pCheck = Get-Process -Id $Script:LiveHookTarget.Id -ErrorAction Stop
            $pCheck.Dispose()
            $target = $Script:LiveHookTarget
        } catch { $target = $null }
    }
    if (-not $target) {
        $TxtLiveHookStatus.Text = "SELECT A PROCESS FIRST - Choose a target or use Lock Foreground"
        $TxtLiveHookStatus.Foreground = $BrushRed
        Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [SCAN SKIPPED] " -Message "No valid target process selected." -BadgeColor "Red"
        return
    }
    $Script:LiveHookTarget = $target
    Write-DiagnosticLog -Level "INFO" -Source "LIVEHOOK" -Message "Manual snapshot scan requested for $($target.Name) (PID $($target.Id))."
    Invoke-HookMonitorStep -ForceLogSnapshot
})

$BtnClearHookLog.Add_Click({
    $HookLogBox.Document.Blocks.Clear()
    $Script:PendingHookDetections.Clear()
    Write-DiagnosticLog -Level "DEBUG" -Source "LIVEHOOK" -Message "Cleared Live DLL Hooks log."
})

$CmbPollInterval.Add_SelectionChanged({
    $secs = switch ($CmbPollInterval.SelectedIndex) { 0 { 1 } 1 { 2 } 2 { 3 } default { 5 } }
    if ($HookTimer) { $HookTimer.Interval = [TimeSpan]::FromSeconds($secs) }
    Write-DiagnosticLog -Level "DEBUG" -Source "LIVEHOOK" -Message "Poll interval changed to ${secs}s."
})

$Window.Add_Closed({
    if ($HookTimer -and $HookTimer.IsEnabled) { $HookTimer.Stop() }
    Write-DiagnosticLog -Level "INFO" -Source "SESSION" -Message "ZeroHook window closed; session ended." -ForceTrim
})

$Window.Add_Loaded({
    $startupSw = [System.Diagnostics.Stopwatch]::StartNew()
    Refresh-HookProcessList -SelectFirstSilently
    Update-Dashboard -Filter "ALL"
    $startupSw.Stop()
    Write-DiagnosticLog -Level "DEBUG" -Source "SESSION" -Message "Initial dashboard & process list loaded in $($startupSw.ElapsedMilliseconds)ms."
})

$null = $Window.ShowDialog()