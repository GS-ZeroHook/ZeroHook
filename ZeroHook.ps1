param(
    [switch]$AutoBlock,
    [switch]$DebugLog
)

# Captured at script scope: inside a function $MyInvocation describes the function, not the script.
$Script:SelfPath        = $PSCommandPath
$Script:SelfScriptBlock = $MyInvocation.MyCommand.ScriptBlock

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
    "$env:ProgramFiles\GOG Galaxy",
    "$env:ProgramData\GOG.com\Galaxy\redists",
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
    "fakenvapi.dll"                            = "OptiScaler"
    "dlss-enabler-headless.dll"                = "OptiScaler"
    "f5low.dll"                                = "OptiScaler"
    "params_builder.dll"                       = "OptiScaler"

    "d3d12core.dll"                            = "D3D12Runtime"

    "amd_fidelityfx_dx12.dll"                  = "FSR"
    "amd_fidelityfx_vk.dll"                    = "FSR"
    "amd_fidelityfx_loader_dx12.dll"           = "FSR"
    "amd_fidelityfx_loader_vk.dll"             = "FSR"
    "amd_fidelityfx_upscaler_dx12.dll"         = "FSR"
    "amd_fidelityfx_upscaler_vk.dll"           = "FSR"
    "amd_fidelityfx_framegeneration_dx12.dll"  = "FSR"
    "amd_fidelityfx_framegeneration_vk.dll"    = "FSR"

    "libxess.dll"                              = "XeSS"
    "libxess_dx11.dll"                         = "XeSS"
    "libxess_fg.dll"                           = "XeSS"
    "libxell.dll"                              = "XeSS"

    "dlssg_to_fsr3.dll"                        = "FGBridge"
    "dlssg_to_fsr3_amd_is_better.dll"          = "FGBridge"

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
    "D3D12Runtime",
    "FSR",
    "XeSS",
    "FGBridge",
    "DXVK",
    "ProxyHook",
    "MFGUnlocker",
    "RTXEncore",
    "DLSSGMod",
    "LumaMod",
    "BFIMod",
    "LocalProxy",
    "Unrecognised"
)

$LiveHookDllDescriptions = @{
    "relimiter.addon32"                        = "a ReShade addon for frame pacing and FPS limiting on NVIDIA G-Sync / VRR displays"
    "relimiter.addon64"                        = "a ReShade addon for frame pacing and FPS limiting on NVIDIA G-Sync / VRR displays"
    "reshade64.dll"                            = "ReShade (64-bit) - installed under a proxy/custom name or loaded by another component"
    "reshade32.dll"                            = "ReShade (32-bit) - installed under a proxy/custom name or loaded by another component"
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
    "optiscaler.dll"                           = "OptiScaler core middleware DLL (often renamed to a proxy DLL)"
    "fakenvapi.dll"                            = "Spoofs NVIDIA NVAPI for AMD/Intel GPUs"
    "dlss-enabler-headless.dll"                = "Unlocks DLSS options on non-RTX cards (DLSS Enabler headless DLL)"
    "d3d12core.dll"                            = "Direct3D 12 Core Runtime / Agility SDK DLL (or OptiScaler D3D12_OptiScaler\D3D12Core.dll)"
    "f5low.dll"                                = "Internal helper library (OptiScaler F5 build plugin DLL)"
    "params_builder.dll"                       = "Configuration/parameter builder (OptiScaler DLSS NR build params_builder DLL)"
    "amd_fidelityfx_dx12.dll"                  = "AMD FidelityFX DirectX 12 DLL"
    "amd_fidelityfx_vk.dll"                    = "AMD FidelityFX Vulkan DLL"
    "amd_fidelityfx_loader_dx12.dll"           = "AMD FidelityFX DirectX 12 loader DLL"
    "amd_fidelityfx_loader_vk.dll"             = "AMD FidelityFX Vulkan loader DLL"
    "amd_fidelityfx_upscaler_dx12.dll"         = "AMD FidelityFX DirectX 12 upscaler DLL"
    "amd_fidelityfx_upscaler_vk.dll"           = "AMD FidelityFX Vulkan upscaler DLL"
    "amd_fidelityfx_framegeneration_dx12.dll"  = "AMD FidelityFX DirectX 12 frame generation DLL"
    "amd_fidelityfx_framegeneration_vk.dll"    = "AMD FidelityFX Vulkan frame generation DLL"
    "libxess.dll"                              = "Standard DX12/Vulkan upscaler (Intel XeSS upscaling DLL)"
    "libxess_dx11.dll"                         = "DirectX 11 upscaler (Intel XeSS DirectX 11 DLL)"
    "libxess_fg.dll"                           = "XeSS Frame Generation (Intel XeSS Frame Generation DLL)"
    "libxell.dll"                              = "Intel Xe Low Latency DLL"
    "dlssg_to_fsr3.dll"                        = "DLSSG-to-FSR3 frame generation bridge DLL"
    "dlssg_to_fsr3_amd_is_better.dll"          = "DLSSG-to-FSR3 variant frame generation bridge DLL"
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

# Short descriptions for the Live DLL Hooks log. The full text above (with mod and build notes)
# still goes to the diagnostic log and the bug report.
$LiveHookDllShortDescriptions = @{
    "relimiter.addon32"                        = "Frame pacing / FPS limiter for G-Sync and VRR"
    "relimiter.addon64"                        = "Frame pacing / FPS limiter for G-Sync and VRR"
    "nvngx_dlss.dll"                           = "DLSS Super Resolution"
    "nvngx_dlssd.dll"                          = "DLSS Ray Reconstruction"
    "nvngx_dlssg.dll"                          = "DLSS Frame Generation"
    "nvngx_dlssnr.dll"                         = "DLSS Neural Rendering"
    "nvngx_dlssnr_real.dll"                    = "DLSS Neural Rendering runtime"
    "nvngx.dll_dlssnr.dll"                     = "OptiScaler DLSS Neural Rendering"
    "nvngx_latewarp.dll"                       = "NVIDIA Latewarp (FrameWarp)"
    "sl.interposer.dll"                        = "Streamline loader"
    "sl.common.dll"                            = "Streamline common"
    "sl.dlss.dll"                              = "Streamline DLSS"
    "sl.dlss_d.dll"                            = "Streamline Ray Reconstruction"
    "sl.dlss_g.dll"                            = "Streamline Frame Generation"
    "sl.reflex.dll"                            = "Streamline Reflex"
    "sl.pcl.dll"                               = "Streamline latency stats"
    "sl.nis.dll"                               = "Streamline NIS sharpening"
    "sl.deepdvc.dll"                           = "Streamline RTX Dynamic Vibrance"
    "sl.directsr.dll"                          = "Streamline DirectSR"
    "sl.nvperf.dll"                            = "Streamline profiler"
    "d3d12core.dll"                            = "DirectX 12 runtime (Agility SDK)"
    "optiscaler.dll"                           = "OptiScaler"
    "fakenvapi.dll"                            = "Fakes NVIDIA NVAPI on AMD/Intel GPUs"
    "dlss-enabler-headless.dll"                = "DLSS Enabler (DLSS on non-RTX cards)"
    "f5low.dll"                                = "OptiScaler helper"
    "params_builder.dll"                       = "OptiScaler helper"
    "amd_fidelityfx_dx12.dll"                  = "FSR (DirectX 12)"
    "amd_fidelityfx_vk.dll"                    = "FSR (Vulkan)"
    "amd_fidelityfx_loader_dx12.dll"           = "FSR loader (DirectX 12)"
    "amd_fidelityfx_loader_vk.dll"             = "FSR loader (Vulkan)"
    "amd_fidelityfx_upscaler_dx12.dll"         = "FSR upscaling (DirectX 12)"
    "amd_fidelityfx_upscaler_vk.dll"           = "FSR upscaling (Vulkan)"
    "amd_fidelityfx_framegeneration_dx12.dll"  = "FSR Frame Generation (DirectX 12)"
    "amd_fidelityfx_framegeneration_vk.dll"    = "FSR Frame Generation (Vulkan)"
    "libxess.dll"                              = "XeSS upscaling"
    "libxess_dx11.dll"                         = "XeSS upscaling (DirectX 11)"
    "libxess_fg.dll"                           = "XeSS Frame Generation"
    "libxell.dll"                              = "XeLL low latency"
    "dlssg_to_fsr3.dll"                        = "Swaps DLSS Frame Gen for FSR Frame Gen"
    "dlssg_to_fsr3_amd_is_better.dll"          = "Swaps DLSS Frame Gen for FSR Frame Gen"
    "dxgi_dxvk.dll"                            = "DXVK (DirectX to Vulkan)"
    "mfgunlocker.dll"                          = "MFG Unlocker"
    "rtxmfg.dll"                               = "MFG Unlocker"
    "rtx40mfgcore.dll"                         = "MFG Unlocker (legacy)"
    "rtx-encore.dll"                           = "RTX Encore"
    "dxcompiler.dll"                           = "DirectX shader compiler"
    "dxil.dll"                                 = "DirectX shader validator"
    "sm86_backend.dll"                         = "DLSSG mod backend"
    "fg_kernels.dll"                           = "DLSSG mod frame gen kernels"
    "sr_kernels.dll"                           = "DLSSG mod upscaling kernels"
    "xefg_kernels.dll"                         = "DLSSG mod XeFG kernels"
    "bfipresentervk.dll"                       = "Black Frame Insertion (Vulkan, 64-bit)"
    "bfipresentervk32.dll"                     = "Black Frame Insertion (Vulkan, 32-bit)"
}

# Groups whose DLLs games ship themselves (upscalers, frame generation, the DirectX 12 runtime).
# Found inside the game folder and not in a mod folder, they are listed as game components.
$GameComponentHookCategories = @("DLSSStreamline", "FSR", "XeSS", "D3D12Runtime")
$ModFolderPattern = '(?i)[\\/]([^\\/]*(optiscaler|dlssg_sm|dlssg[-_]to[-_]fsr|dlss[-_ ]?enabler|reshade|mfgunlock|rtxmfg|hsf_|luma)[^\\/]*|mods?)[\\/]'

# Groups that are a specific mod, so a proxy file name (dxgi.dll, version.dll ...) in them is that mod
$NamedModHookCategories = @("ReShade", "ReLimiter", "OptiScaler", "DXVK", "MFGUnlocker", "DLSSGMod", "LumaMod", "FGBridge", "RTXEncore", "BFIMod")

function Get-LiveHookDllShortDescription {
    param([string]$ModuleName, [string]$FullDescription = "")
    $name = if ($ModuleName) { $ModuleName.ToLowerInvariant() } else { "" }
    if ($name -and $LiveHookDllShortDescriptions.ContainsKey($name)) { return $LiveHookDllShortDescriptions[$name] }
    if ([string]::IsNullOrWhiteSpace($FullDescription)) { return "" }
    # "Shared proxy name (ReShade, ASI Loader, or native/local library)" -> "Mod proxy or game file: ReShade, ..."
    if ($FullDescription -match '^Shared proxy(?: / [^(]+)? name \((.+)\)$') { return "Mod proxy or normal file - could be $($Matches[1])" }
    # Drop trailing build/mod notes such as "(or ...)" and "(also ...)"
    return ($FullDescription -replace '\s*\((or|also|kept|32-bit or|64-bit)\b[^)]*\)\s*$', '').Trim()
}

# Where a loaded DLL comes from: Overlay, Game (a component the game ships) or Mod (mods and other injected DLLs)
function Get-HookModuleOrigin {
    param([string]$CategoryId, [string]$Path, [string]$GameRoot)
    if ($CategoryId -eq "WindowsCapture" -or $OverlayHookCategories -contains $CategoryId) { return "Overlay" }
    if ($GameComponentHookCategories -contains $CategoryId -and $GameRoot -and $Path -and
        $Path.StartsWith($GameRoot.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
        $rel = $Path.Substring($GameRoot.TrimEnd('\').Length)
        if ($rel -notmatch $ModFolderPattern) { return "Game" }
    }
    return "Mod"
}

# A path inside the game folder is shown as <game>\..., anything else with the user name hidden
function Format-HookModuleFolder {
    param([string]$Path, [string]$GameRoot)
    if ([string]::IsNullOrWhiteSpace($Path)) { return "" }
    $dir = [IO.Path]::GetDirectoryName($Path)
    if ($GameRoot -and $dir) {
        $root = $GameRoot.TrimEnd('\')
        if ($dir -ieq $root) { return "<game>" }
        if ($dir.StartsWith($root + '\', [System.StringComparison]::OrdinalIgnoreCase)) { return "<game>" + $dir.Substring($root.Length) }
    }
    return (Hide-Username $dir)
}

function Test-LumaModContext {
    param(
        [string]$ModuleName,
        [string]$ModulePath
    )
    if ([string]::IsNullOrWhiteSpace($ModuleName)) { return $false }
    $name = $ModuleName.ToLowerInvariant()
    if ($name -match '^luma.*\.dll$') { return $true }

    if (-not [string]::IsNullOrWhiteSpace($ModulePath)) {
        if ($ModulePath -match '(?i)[\\/](Engine|ThirdParty|CEF3|Redist)[\\/]') {
            return $false
        }
        if ($ModulePath -match '(?i)\bluma\b') {
            return $true
        }
        try {
            $dir = [IO.Path]::GetDirectoryName($ModulePath)
            # Real-time watch asks this on every poll; list each folder only once per session
            if ($dir -and $Script:LumaDirCache.ContainsKey($dir)) { return $Script:LumaDirCache[$dir] }
            if ($dir -and (Test-Path -LiteralPath $dir)) {
                $lumaFiles = Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -match '(?i)^luma' } | Select-Object -First 1
                $Script:LumaDirCache[$dir] = [bool]$lumaFiles
                if ($lumaFiles) { return $true }
            }
        } catch { Write-DiagnosticSkip -Source "LIVEHOOK" -Context "Luma folder check" -Target $ModulePath -ErrorRecord $_ }
    }
    return $false
}

function Get-LiveHookDllDescription {
    param(
        [string]$ModuleName,
        [string]$ModulePath = ""
    )
    if ([string]::IsNullOrWhiteSpace($ModuleName)) { return "" }
    $name = $ModuleName.ToLowerInvariant()

    if ($name -eq "d3dcompiler_47.dll") {
        if (Test-LumaModContext -ModuleName $ModuleName -ModulePath $ModulePath) {
            return "HLSL shader compiler DLL shipped with a Luma mod"
        }
        return "Direct3D HLSL shader compiler runtime DLL"
    }

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
        Label   = "ReLimiter (ReShade add-on)"
        Off     = "Open ReLimiter in ReShade and disable the frame limiter for this title."
        Cost    = "Frame cap and pacing will change; verify game/driver limiters if needed."
        Restart = "Re-enable in ReLimiter to undo."
    }
    DLSSStreamline = @{
        Label   = "NVIDIA DLSS / Streamline"
        Off     = "Change upscaling, frame generation, or reflex/low-latency settings in-game or remove/restore mod DLLs in the game folder."
        Cost    = "Disables DLSS upscaling, frame generation, reflex, or neural rendering mods."
        Restart = "Restart the game after modifying game-folder files or settings."
    }
    OptiScaler = @{
        Label   = "OptiScaler"
        Off     = "Disable or remove OptiScaler middleware, spoofing, or helper DLLs from the game folder."
        Cost    = "Disables OptiScaler middleware, NVAPI spoofing, or helper/translation layers."
        Restart = "Restart the game after changing game-folder files."
    }
    D3D12Runtime = @{
        Label   = "DirectX 12 Runtime"
        Off     = "Check the module path; standard or Agility SDK D3D12Core.dll is part of Direct3D 12 rendering, while D3D12_OptiScaler\D3D12Core.dll belongs to OptiScaler."
        Cost    = "Removing or altering a game's expected D3D12Core.dll can prevent Direct3D 12 launch or break Agility SDK features."
        Restart = "Restart the game after changing files in the game or D3D12 subfolder."
    }
    FSR = @{
        Label   = "AMD FSR"
        Off     = "Disable or remove AMD FidelityFX upscaler / frame generation / loader DLLs from the game folder."
        Cost    = "Reverts AMD FidelityFX upscaling or frame generation back to native/other rendering."
        Restart = "Restart the game after changing game-folder files."
    }
    XeSS = @{
        Label   = "Intel XeSS"
        Off     = "Disable or remove Intel XeSS / XeLL DLLs from the game folder."
        Cost    = "Disables Intel XeSS upscaling, XeSS frame generation, or XeLL low latency."
        Restart = "Restart the game after changing game-folder files."
    }
    FGBridge = @{
        Label   = "DLSS-to-FSR Frame Gen Mod"
        Off     = "Disable or remove DLSSG-to-FSR3 bridge DLLs from the game folder."
        Cost    = "Disables DLSSG-to-FSR3 frame generation bridging."
        Restart = "Restart the game after changing game-folder files."
    }
    DXVK = @{
        Label   = "DXVK (DirectX to Vulkan)"
        Off     = "Remove or rename the DXVK DLL in the game folder to revert to native Direct3D."
        Cost    = "Changes Direct3D-to-Vulkan translation behavior and shader/performance profile."
        Restart = "Restart the game after changing game-folder files."
    }
    ProxyHook = @{
        Label   = "Mod Loader / Proxy DLL (ASI Loader etc.)"
        Off     = "Inspect the module path; if it is a mod proxy (ASI Loader, ReShade, OptiScaler, MFG Unlocker), remove/disable the mod in the game folder."
        Cost    = "May be required by mods or native game/Windows components depending on the file path."
        Restart = "Restart the game after changing game-folder files."
    }
    MFGUnlocker = @{
        Label   = "MFG Unlocker"
        Off     = "Remove or disable MFGUnlocker / RTXMFG files in the game or mod loader folder."
        Cost    = "Disables multi-frame-generation unlocker behavior."
        Restart = "Restart the game after changing files."
    }
    RTXEncore = @{
        Label   = "RTX Encore / RTX Hair"
        Off     = "Remove or disable RTX Encore files in the game or plugin folder."
        Cost    = "Disables RTX Encore or RTX Hair features."
        Restart = "Restart the game after changing files."
    }
    DLSSGMod = @{
        Label   = "DLSSG Frame Gen Mod"
        Off     = "Remove or disable the DLSSG mod folder/files in the game directory."
        Cost    = "Disables DLSSG frame generation replacement kernels."
        Restart = "Restart the game after changing files."
    }
    LumaMod = @{
        Label   = "Luma HDR / Shader Mod"
        Off     = "Remove or disable Luma mod files from the game folder."
        Cost    = "Disables Luma HDR / shader overrides."
        Restart = "Restart the game after changing files."
    }
    BFIMod = @{
        Label   = "BFI Presenter (Black Frame Insertion)"
        Off     = "Remove or disable BFIPresenterVK files or Vulkan layer entries."
        Cost    = "Disables Black Frame Insertion Vulkan presentation."
        Restart = "Restart the game after changing files."
    }
    GenericOverlay = @{
        Label   = "FPS Counter / Overlay"
        Off     = "Check the DLL path shown above and disable the overlay in its parent utility or block via ZeroHook."
        Cost    = "Disables that utility's on-screen display or overlay injection."
        Restart = "Restart the game after disabling."
    }
    ControllerHook = @{
        Label   = "Controller Software (DualSense)"
        Off     = "If unwanted, block via ZeroHook or disable controller companion software (keep allowed if using DualSense features)."
        Cost    = "Blocking may disable adaptive triggers, haptics, or controller remapping in some games."
        Restart = "Restart the game after changing."
    }
    LocalProxy = @{
        Label   = "Proxy DLL Next to Game (Mod or Game File)"
        Off     = "Check the DLL path and file details; if it is a mod proxy (ReShade, OptiScaler, DXVK, ASI Loader, MFG Unlocker, DLSSG 2.0-3.0), disable or remove it via your mod setup."
        Cost    = "Removing a native/local game DLL or a required mod proxy can prevent launch or disable mods/features."
        Restart = "Restart the game after changing game-folder files."
    }
    Unrecognised = @{
        Label   = "Other Third-Party DLLs"
        Off     = "Not on ZeroHook's list. Check the publisher and folder shown: antivirus, mouse/RGB software, screen recorders and mods often inject DLLs. Disable or uninstall the program that owns it if you do not want it in games."
        Cost    = "Depends on the program; some (antivirus, accessibility tools) are expected."
        Restart = "Restart the game after changing the owning program."
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

# Implicit layers can be registered per machine (HKLM) or per user (HKCU); both are loaded into Vulkan games
$VulkanKeys = @(
    "HKLM:\SOFTWARE\Khronos\Vulkan\ImplicitLayers",
    "HKLM:\SOFTWARE\WOW6432Node\Khronos\Vulkan\ImplicitLayers",
    "HKCU:\SOFTWARE\Khronos\Vulkan\ImplicitLayers"
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

# Short keywords must stand alone, otherwise "cam" also matches "Camera", "Camtasia" or a user named "Cameron".
$WholeWordStartupKeywords = @("cam", "gcc", "aura")
$StartupKeywordRegex = (@($StartupUtilityKeywords | ForEach-Object {
    $escaped = [regex]::Escape($_)
    if ($WholeWordStartupKeywords -contains $_) { "(?<![a-z])$escaped(?![a-z])" } else { $escaped }
}) -join "|")

$StartupLocations = @(
    @{ Run = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"; Approved = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" },
    @{ Run = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"; Approved = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" },
    @{ Run = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"; Approved = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32" }
)

function Get-EffectiveStartupLocations {
    $locs = [System.Collections.Generic.List[object]]::new()
    foreach ($l in $StartupLocations) { [void]$locs.Add($l) }
    $isSys = ($env:USERNAME -eq "SYSTEM") -or ([System.Security.Principal.WindowsIdentity]::GetCurrent().IsSystem)
    if ($isSys) {
        if (-not (Get-PSDrive -Name "HKU" -ErrorAction SilentlyContinue)) {
            try { New-PSDrive -Name "HKU" -PSProvider Registry -Root "HKEY_USERS" -ErrorAction SilentlyContinue | Out-Null } catch { Write-DiagnosticSkip -Source "STARTUP" -Context "Mount HKEY_USERS drive" -Target "HKU" -ErrorRecord $_ }
        }
        if (Get-PSDrive -Name "HKU" -ErrorAction SilentlyContinue) {
            foreach ($sidKey in (Get-ChildItem -Path "HKU:\" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^S-1-5-21-[\d-]+$' })) {
                $hive = "HKU:\$($sidKey.PSChildName)"
                [void]$locs.Add(@{
                    Run      = "$hive\Software\Microsoft\Windows\CurrentVersion\Run"
                    Approved = "$hive\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
                })
            }
        }
    }
    return $locs.ToArray()
}

$StartupFolderPaths = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
)
$StartupBackupDir       = "$env:ProgramData\ZeroHook_StartupBackup"
$LocalInstallDir        = "$env:ProgramData\ZeroHook"
$LocalScriptPath        = Join-Path $LocalInstallDir "ZeroHook.ps1"
$UserConfigDir          = Join-Path $env:LOCALAPPDATA "ZeroHook"
$ExclusionsFile         = Join-Path $UserConfigDir "exclusions.json"
$SharedExclusionsFile   = Join-Path $LocalInstallDir "exclusions.json"
$RoamingExclusionsFile  = Join-Path $env:APPDATA "ZeroHook\exclusions.json"
$LegacyExclusionsFile   = Join-Path $StartupBackupDir "exclusions.json"
# --- VERSION ---
# Single source for the version shown in the window, the log and bug reports
$AppVersion             = "1.1.0"
$AppBuildLabel          = "v.$AppVersion"

# --- DIAGNOSTIC LOGGING ---
$LogDir                 = Join-Path $env:LOCALAPPDATA "ZeroHook\Logs"
$GuiLogFile             = Join-Path $LogDir "zerohook-current.log"
# The scheduled run writes to its own file, so a later GUI session cannot push it out of the log
$AutoBlockLogFile       = Join-Path $LogDir "zerohook-autoblock.log"
$DiagLogFile            = if ($AutoBlock) { $AutoBlockLogFile } else { $GuiLogFile }
$DebugFlagFile          = Join-Path $UserConfigDir "debug.json"
$DebugModeHours         = 24
$MaxLogLinesNormal      = 2500
$MaxLogLinesDebug       = 10000
$Script:SessionId       = ([guid]::NewGuid().ToString("N").Substring(0, 8))
$Script:DiagWriteCount  = 0
$Script:SessionErrorCount = 0
$Script:SessionWarnCount  = 0
$Script:LogMutex        = $null
$Script:ExclusionsLoggedOnce = $false
$Script:DetectedStoreGames = @()
$Script:StoreScanCompleted = $false
$Script:StorePrefixEntries = @()
$Script:StorePathCache = @{}
$Script:ScanSkippedDirs = 0
$Script:LastModuleListKey = ""
$Script:LastSkippedDirsReported = -1
$Script:LastSnapshotErrorKey = ""
$Script:LumaDirCache = @{}
$Script:ModuleInfoCache = @{}
$Script:DiskStateCache = @{}
$Script:AntiCheatCache = @{}
$Script:BitnessCache = @{}
$Script:HookBaseline = $null
$Script:LastLiveHookSummary = $null
$Script:LiveExclusionsCache = $null

function Hide-Username {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return "" }
    $out = $Text
    if ($env:USERPROFILE) {
        $out = $out -ireplace [regex]::Escape($env:USERPROFILE), "C:\Users\%USERNAME%"
    }
    if ($env:USERNAME) {
        $userEsc = [regex]::Escape($env:USERNAME)
        $out = $out -ireplace ("(?i)(\\Users\\)" + $userEsc + "(\\|$)"), "`$1%USERNAME%`$2"
        # Account names such as DESKTOP-ABC\John or AzureAD\John
        $out = $out -ireplace ("(?i)(?<![\w%\\/:.-])[\w.-]+\\" + $userEsc + "(?![\w%])"), "%COMPUTERNAME%\%USERNAME%"
        # The bare name anywhere else (whole word only, so short names do not damage other words)
        if ($env:USERNAME.Length -ge 3) {
            $out = $out -ireplace ("(?i)(?<![\w%])" + $userEsc + "(?![\w%])"), "%USERNAME%"
        }
    }
    if ($env:COMPUTERNAME -and $env:COMPUTERNAME.Length -ge 3) {
        $out = $out -ireplace ("(?i)(?<![\w%])" + [regex]::Escape($env:COMPUTERNAME) + "(?![\w%])"), "%COMPUTERNAME%"
    }
    # Account SIDs identify the machine; keep only the well-known prefix and the RID
    $out = $out -replace 'S-1-5-21-\d+-\d+-\d+-(\d+)', 'S-1-5-21-x-x-x-$1'
    return $out
}

function Format-DiagnosticLine {
    param([string]$Text)
    $clean = Hide-Username ([string]$Text)
    return ($clean -replace "`r?`n", " | ")
}

# The GUI and the scheduled run can write at the same moment; a named mutex keeps lines from being lost
# while the file is trimmed. Returns $true when the lock is held.
function Enter-LogLock {
    try {
        if (-not $Script:LogMutex) {
            $Script:LogMutex = New-Object System.Threading.Mutex($false, "Local\ZeroHook_DiagnosticLog")
        }
        return $Script:LogMutex.WaitOne(1500)
    } catch [System.Threading.AbandonedMutexException] {
        # The previous holder exited without releasing it; the lock now belongs to this thread
        return $true
    } catch {
        return $false
    }
}

function Exit-LogLock {
    try { if ($Script:LogMutex) { $Script:LogMutex.ReleaseMutex() } } catch {}
}

function Get-MaxLogLines {
    if ($Script:DebugEnabled) { return $MaxLogLinesDebug }
    return $MaxLogLinesNormal
}

function Trim-DiagnosticLogFile {
    param([string]$Path = $DiagLogFile)
    $locked = Enter-LogLock
    try {
        if (Test-Path -LiteralPath $Path) {
            $max = Get-MaxLogLines
            $lines = @(Get-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop)
            if ($lines.Count -gt $max) {
                $lines | Select-Object -Last $max | Set-Content -LiteralPath $Path -Encoding UTF8 -Force -ErrorAction Stop
            }
        }
    } catch {
        # Cannot log a failure of the log itself; the next trim will try again
    } finally {
        if ($locked) { Exit-LogLock }
    }
}

function Write-DiagnosticLog {
    param(
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
        [string]$Level = "INFO",
        [string]$Source = "APP",
        [string]$Message = "",
        [switch]$ForceTrim
    )
    if ($Level -eq "DEBUG" -and -not $Script:DebugEnabled) { return }
    if ($Level -eq "ERROR") { $Script:SessionErrorCount++ } elseif ($Level -eq "WARN") { $Script:SessionWarnCount++ }
    $locked = $false
    try {
        $logFolder = if ($LogDir) { $LogDir } else { Join-Path $env:LOCALAPPDATA "ZeroHook\Logs" }
        $logPath = if ($DiagLogFile) { $DiagLogFile } else { Join-Path $logFolder "zerohook-current.log" }
        if (-not (Test-Path -LiteralPath $logFolder)) {
            New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
        }
        # The UTC offset makes reports from different time zones comparable
        $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fffzzz")
        $safeMsg = Format-DiagnosticLine -Text $Message
        $entry = "[$ts] [$Script:SessionId] [$Level] [$Source] $safeMsg"

        $locked = Enter-LogLock
        Add-Content -LiteralPath $logPath -Value $entry -Encoding UTF8 -ErrorAction SilentlyContinue

        $Script:DiagWriteCount++
        if ($ForceTrim -or (($Script:DiagWriteCount % 50) -eq 0)) {
            Trim-DiagnosticLogFile -Path $logPath
        }
    } catch {
    } finally {
        if ($locked) { Exit-LogLock }
    }
}

# --- DEBUG MODE ---
# Debug mode is stored in a small file with an expiry time, so it also reaches the scheduled
# Auto-Run task and later sessions, and switches itself off after $DebugModeHours hours.
function Get-DebugFlagState {
    $state = [PSCustomObject]@{ Enabled = $false; ExpiresUtc = $null; Expired = $false; Error = "" }
    if (-not (Test-Path -LiteralPath $DebugFlagFile)) { return $state }
    try {
        $obj = [System.IO.File]::ReadAllText($DebugFlagFile) | ConvertFrom-Json
        $exp = [DateTime]::new([int64]$obj.ExpiresUtcTicks, [DateTimeKind]::Utc)
        $state.ExpiresUtc = $exp
        if ($exp -gt [DateTime]::UtcNow) { $state.Enabled = $true } else { $state.Expired = $true }
    } catch {
        $state.Error = $_.Exception.Message
    }
    return $state
}

function Set-DebugFlag {
    param([switch]$Enable)
    if ($Enable) {
        $exp = [DateTime]::UtcNow.AddHours($DebugModeHours)
        if (-not (Test-Path -LiteralPath $UserConfigDir)) { [void][System.IO.Directory]::CreateDirectory($UserConfigDir) }
        $json = [PSCustomObject]@{
            ExpiresUtcTicks = $exp.Ticks
            ExpiresUtc      = $exp.ToString("yyyy-MM-dd HH:mm:ss") + "Z"
            EnabledUtc      = [DateTime]::UtcNow.ToString("yyyy-MM-dd HH:mm:ss") + "Z"
        } | ConvertTo-Json -Compress
        [System.IO.File]::WriteAllText($DebugFlagFile, $json, (New-Object System.Text.UTF8Encoding($false)))
        $Script:DebugEnabled = $true
        $Script:DebugExpiresUtc = $exp
        $Script:DebugSource = "flag"
    } else {
        if (Test-Path -LiteralPath $DebugFlagFile) { Remove-Item -LiteralPath $DebugFlagFile -Force -ErrorAction Stop }
        $Script:DebugExpiresUtc = $null
        # The -DebugLog switch keeps this session in debug mode even after the saved flag is removed
        $Script:DebugEnabled = [bool]$DebugLog
        $Script:DebugSource = if ($DebugLog) { "switch" } else { "off" }
    }
}

$Script:DebugFlagAtStart = Get-DebugFlagState
$Script:DebugEnabled     = [bool]$DebugLog -or $Script:DebugFlagAtStart.Enabled
$Script:DebugExpiresUtc  = if ($Script:DebugFlagAtStart.Enabled) { $Script:DebugFlagAtStart.ExpiresUtc } else { $null }
$Script:DebugSource      = if ($DebugLog) { "switch" } elseif ($Script:DebugFlagAtStart.Enabled) { "flag" } else { "off" }
if ($Script:DebugFlagAtStart.Expired) {
    try { Remove-Item -LiteralPath $DebugFlagFile -Force -ErrorAction Stop } catch {}
}

function Get-DebugStateText {
    if (-not $Script:DebugEnabled) { return "Off" }
    if ($Script:DebugSource -eq "switch") { return "On (-DebugLog switch)" }
    if ($Script:DebugExpiresUtc) { return "On (until $($Script:DebugExpiresUtc.ToLocalTime().ToString('yyyy-MM-dd HH:mm')))" }
    return "On"
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

# Records an error the code recovers from on purpose (a missing key, an unreadable folder, a bad
# manifest). Only written in debug mode, so normal logs stay short.
function Write-DiagnosticSkip {
    param(
        [string]$Source = "APP",
        [string]$Context = "",
        [string]$Target = "",
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    if (-not $Script:DebugEnabled) { return }
    $detail = Format-ErrorRecordDetail -ErrorRecord $ErrorRecord -Context $Context -Target $Target
    Write-DiagnosticLog -Level "DEBUG" -Source $Source -Message "Handled: $detail"
}

function Get-ScheduledTaskDiagInfo {
    try {
        $t = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if (-not $t) {
            return [PSCustomObject]@{
                State          = "NotRegistered"
                LastRunTime    = "N/A"
                LastTaskResult = "N/A"
                Execute        = "N/A"
                Arguments      = "N/A"
                WorkingDir     = "N/A"
            }
        }
        $info = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
        $act = $t.Actions | Select-Object -First 1
        return [PSCustomObject]@{
            State          = "$($t.State)"
            LastRunTime    = if ($info -and $info.LastRunTime) { "$($info.LastRunTime)" } else { "N/A" }
            LastTaskResult = if ($info) { "$($info.LastTaskResult)" } else { "N/A" }
            Execute        = if ($act) { Hide-Username ([string]$act.Execute) } else { "N/A" }
            Arguments      = if ($act) { Hide-Username ([string]$act.Arguments) } else { "N/A" }
            WorkingDir     = if ($act -and $act.WorkingDirectory) { Hide-Username ([string]$act.WorkingDirectory) } else { "N/A" }
        }
    } catch {
        Write-DiagnosticSkip -Source "TASK" -Context "Query scheduled task" -Target $TaskName -ErrorRecord $_
        return [PSCustomObject]@{
            State          = "QueryFailed ($($_.Exception.GetBaseException().Message))"
            LastRunTime    = "N/A"
            LastTaskResult = "N/A"
            Execute        = "N/A"
            Arguments      = "N/A"
            WorkingDir     = "N/A"
        }
    }
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
    } catch {
        Write-DiagnosticSkip -Source "ENV" -Context "Read current process info" -ErrorRecord $_
    } finally {
        if ($proc) { $proc.Dispose() }
    }

    $mode = if ($AutoBlock) { "-AutoBlock" } else { "GUI" }
    if ($Script:DebugEnabled) { $mode += " + Debug" }

    return [PSCustomObject]@{
        OsInfo       = $osInfo
        PsVer        = $psVer
        IsAdmin      = $isAdmin
        ExePath      = $exePath
        WorkingSet   = $wsMb
        Mode         = $mode
        ScriptPath   = if ($PSCommandPath) { Hide-Username $PSCommandPath } else { "Inline/Hosted" }
        Arch         = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
        Culture      = [System.Globalization.CultureInfo]::CurrentCulture.Name
        DebugState   = Get-DebugStateText
    }
}

Write-DiagnosticLog -Level "INFO" -Source "SESSION" -Message "Session started | Version=$AppVersion | SessionId=$Script:SessionId | PID=$PID | Mode=$(if ($AutoBlock) { '-AutoBlock' } else { 'GUI' }) | Debug=$(Get-DebugStateText)" -ForceTrim
if ($Script:DebugFlagAtStart.Expired) {
    Write-DiagnosticLog -Level "INFO" -Source "SESSION" -Message "Saved debug mode expired at $($Script:DebugFlagAtStart.ExpiresUtc.ToString('yyyy-MM-dd HH:mm'))Z and was switched off."
} elseif ($Script:DebugFlagAtStart.Error) {
    Write-DiagnosticLog -Level "WARN" -Source "SESSION" -Message "Could not read debug flag file $DebugFlagFile : $($Script:DebugFlagAtStart.Error)"
}
$initEnv = Get-EnvironmentSummary
Write-DiagnosticLog -Level "INFO" -Source "ENV" -Message "OS=$($initEnv.OsInfo) ($($initEnv.Arch)) | PS=$($initEnv.PsVer) | Culture=$($initEnv.Culture) | Admin=$($initEnv.IsAdmin) | Exe=$($initEnv.ExePath) | Script=$($initEnv.ScriptPath)" -ForceTrim

# --- ELEVATION CHECK ---
# Every block/restore action needs Administrator rights; without them most of them fail.
if (-not $initEnv.IsAdmin) {
    Write-DiagnosticLog -Level "WARN" -Source "APP" -Message "Not running as Administrator." -ForceTrim
    if ($AutoBlock) {
        Write-DiagnosticLog -Level "ERROR" -Source "AUTOBLOCK" -Message "Scheduled run stopped: it needs Administrator rights. Turn Auto-Run off and on again to re-create the task with highest privileges." -ForceTrim
        exit 1
    }
    try {
        $selfExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $extraArgs = @()
        if ($DebugLog) { $extraArgs += "-DebugLog" }
        if ($selfExe -notmatch '(?i)\\(powershell|pwsh|powershell_ise)\.exe$') {
            if ($extraArgs.Count -gt 0) { Start-Process -FilePath $selfExe -ArgumentList $extraArgs -Verb RunAs }
            else { Start-Process -FilePath $selfExe -Verb RunAs }
            return
        }
        if ($Script:SelfPath) {
            $argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$($Script:SelfPath)`"") + $extraArgs
            Start-Process -FilePath $selfExe -ArgumentList $argList -Verb RunAs
            return
        }
    } catch {
        [void](Write-DiagnosticError -Source "APP" -Context "Relaunch elevated" -Target "ZeroHook" -ErrorRecord $_)
    }
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show("ZeroHook needs to be run as Administrator.", "ZeroHook") | Out-Null
    return
}

# Folders under ProgramData are writable by standard users by default. The auto-run task executes a
# script from there with elevated rights, so only Administrators and SYSTEM may write to it.
function Protect-AdminDirectory {
    param([string]$Path, [switch]$Recurse)
    try {
        if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -ItemType Directory -Force -ErrorAction Stop | Out-Null }
        $icacls = Join-Path $env:SystemRoot "System32\icacls.exe"
        if ($Recurse) {
            & $icacls $Path /setowner "*S-1-5-32-544" /T /C /L /Q | Out-Null
            & $icacls $Path /reset /T /C /L /Q | Out-Null
        } else {
            & $icacls $Path /setowner "*S-1-5-32-544" /C /L /Q | Out-Null
        }
        & $icacls $Path /inheritance:r /grant:r "*S-1-5-32-544:(OI)(CI)F" "*S-1-5-18:(OI)(CI)F" "*S-1-5-32-545:(OI)(CI)RX" /C /L /Q | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-DiagnosticLog -Level "WARN" -Source "SECURITY" -Message "icacls returned $LASTEXITCODE for $Path"
        }
    } catch {
        [void](Write-DiagnosticError -Source "SECURITY" -Context "Protect directory" -Target $Path -ErrorRecord $_)
    }
}

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
    } catch { Write-DiagnosticSkip -Source "STORE" -Context "Resolve junction target" -Target $clean -ErrorRecord $_ }
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
    } catch { Write-DiagnosticSkip -Source "STORE" -Context "Read registry value" -Target "$Path ($($Names -join ','))" -ErrorRecord $_ }
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
    } catch { Write-DiagnosticSkip -Source "STORE" -Context "Read Steam libraryfolders.vdf" -Target $VdfFilePath -ErrorRecord $_ }
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
        $pos = -1
        # Let .NET find candidate positions; a PowerShell loop over every byte of this file takes minutes.
        while (($pos = [Array]::IndexOf($bytes, $idBytes[0], $pos + 1)) -ge 0 -and $pos -lt ($bytes.Length - 4)) {
            if ($bytes[$pos+1] -eq $idBytes[1] -and $bytes[$pos+2] -eq $idBytes[2] -and $bytes[$pos+3] -eq $idBytes[3]) {
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
        }
    } catch { Write-DiagnosticSkip -Source "STORE" -Context "Read Steam appinfo.vdf" -Target $appInfoPath -ErrorRecord $_ }
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
            } catch { Write-DiagnosticSkip -Source "STORE" -Context "Parse Steam app manifest" -Target $mf.FullName -ErrorRecord $_ }
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
            } catch { Write-DiagnosticSkip -Source "STORE" -Context "Parse Epic manifest" -Target $it.FullName -ErrorRecord $_ }
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
            } catch { Write-DiagnosticSkip -Source "STORE" -Context "Read Epic catalog cache" -Target $catalogCachePath -ErrorRecord $_ }
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
                } catch { Write-DiagnosticSkip -Source "STORE" -Context "Parse Epic installations.jsonl line" -Target "$eglv2Jsonl (line $i)" -ErrorRecord $_ }
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
        } catch { Write-DiagnosticSkip -Source "STORE" -Context "Read Epic installations.jsonl" -Target $eglv2Jsonl -ErrorRecord $_ }
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
            } catch { Write-DiagnosticSkip -Source "STORE" -Context "Parse EA installerdata.xml" -Target $xf.FullName -ErrorRecord $_ }
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
                $pathHits = [regex]::Matches($txt, '[A-Za-z]:[\\/][^\r\n"\'']+')
                foreach ($m in $pathHits) {
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
            } catch { Write-DiagnosticSkip -Source "STORE" -Context "Scan EA Desktop config file" -Target $cf.FullName -ErrorRecord $_ }
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
        } catch { Write-DiagnosticSkip -Source "STORE" -Context "Read Ubisoft settings.yml" -Target $settingsYml -ErrorRecord $_ }
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
        } catch { Write-DiagnosticSkip -Source "STORE" -Context "Read Battle.net config" -Target $bnetCfg -ErrorRecord $_ }
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
                } catch { Write-DiagnosticSkip -Source "STORE" -Context "Read Rockstar titles.dat" -Target $titlesDat -ErrorRecord $_ }
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
        } catch { Write-DiagnosticSkip -Source "STORE" -Context "Read Xbox GamingServices repository" -Target $repoRoot -ErrorRecord $_ }
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
                try { $rawPath = Normalize-StorePath ([string]$pkg.InstalledLocation.Path) } catch { Write-DiagnosticSkip -Source "STORE" -Context "Read Xbox package install location" -Target $fullName -ErrorRecord $_ }
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
                } catch { Write-DiagnosticSkip -Source "STORE" -Context "Read Xbox app list entries" -Target $fullName -ErrorRecord $_ }

                [void]$games.Add([PSCustomObject]@{
                    Store       = "Xbox"
                    Name        = $dispName
                    InstallPath = $finalPath
                    LaunchUri   = if ($aumid) { "shell:AppsFolder\$aumid" } else { "" }
                    Id          = $fullName
                })
            } catch { Write-DiagnosticSkip -Source "STORE" -Context "Read Xbox package" -Target $(try { [string]$pkg.Id.FullName } catch { "unknown package" }) -ErrorRecord $_ }
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

    $Script:StoreScanCompleted = $true
    $sw.Stop()

    Write-DiagnosticLog -Level "INFO" -Source "STORE" -Message "Store scan finished in $($sw.ElapsedMilliseconds)ms | TotalDeduped=$($Script:DetectedStoreGames.Count) | Breakdown: $($perStoreCounts -join ', ')"
    if ($Script:DebugEnabled) {
        foreach ($g in $Script:DetectedStoreGames) {
            Write-DiagnosticLog -Level "DEBUG" -Source "STORE" -Message "Game [$($g.Store)] $($g.Name) | Id=$($g.Id) | Path=$($g.InstallPath) | Exists=$(Test-Path -LiteralPath $g.InstallPath)"
        }
    }

    return $Script:DetectedStoreGames
}

function Update-SearchPaths {
    $paths = [System.Collections.Generic.List[string]]::new()
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $add = {
        param($p)
        $n = Normalize-StorePath $p
        if ($n -and $seen.Add($n)) { [void]$paths.Add($n) }
    }
    foreach ($p in $BaseSearchPaths) { & $add $p }

    # Custom Steam install and library folders
    $steamPath = Get-RegistryStringValue -Path "HKLM:\SOFTWARE\Valve\Steam" -Names @("SteamPath", "InstallPath")
    if (-not $steamPath) {
        $steamPath = Get-RegistryStringValue -Path "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -Names @("SteamPath", "InstallPath")
    }
    $steamRoot = Normalize-StorePath $steamPath
    if ($steamRoot -and (Test-Path -LiteralPath $steamRoot)) {
        $roots = @($steamRoot) + @(Get-VdfLibraryPaths -VdfFilePath (Join-Path $steamRoot "steamapps\libraryfolders.vdf"))
        foreach ($root in $roots) {
            & $add $root
            $bin = Join-Path $root "bin"
            if (Test-Path -LiteralPath $bin) { & $add $bin }
        }
    }
    # GOG Galaxy installed in a custom folder
    foreach ($key in @("HKLM:\SOFTWARE\WOW6432Node\GOG.com\GalaxyClient\paths", "HKLM:\SOFTWARE\GOG.com\GalaxyClient\paths")) {
        $galaxy = Get-RegistryStringValue -Path $key -Names @("client")
        if ($galaxy) { & $add $galaxy }
    }
    $Script:SearchPaths = $paths.ToArray()
    if ($Script:DebugEnabled) {
        $existing = @($Script:SearchPaths | Where-Object { Test-Path -LiteralPath $_ })
        Write-DiagnosticLog -Level "DEBUG" -Source "SCAN" -Message "Search paths: $($existing.Count) of $($Script:SearchPaths.Count) exist | SteamRoot=$(if ($steamRoot) { $steamRoot } else { 'not found' })"
    }
}

# Recursive search that never descends into excluded folders (game libraries hold hundreds of thousands of files).
function Find-TargetFiles {
    param(
        [string]$Root,
        [System.Collections.Generic.HashSet[string]]$Names,
        [int]$MaxDepth = 16
    )
    $stack = New-Object System.Collections.Stack
    $stack.Push(@((New-Object System.IO.DirectoryInfo($Root)), 0))
    while ($stack.Count -gt 0) {
        $dir, $depth = $stack.Pop()
        try {
            foreach ($file in $dir.EnumerateFiles()) {
                if ($Names.Contains($file.Name) -and ($file.FullName -notmatch $ExcludedPathRegex)) { $file }
            }
            if ($depth -ge $MaxDepth) {
                Write-DiagnosticLog -Level "DEBUG" -Source "SCAN" -Message "Depth limit ($MaxDepth) reached, not searching below: $($dir.FullName)"
                continue
            }
            foreach ($sub in $dir.EnumerateDirectories()) {
                # Do not follow junctions/symlinks: EA's "EA Desktop\EA Desktop" link points at the versioned
                # folder, which would list (and block/restore) the same DLL twice.
                if (($sub.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
                if (($sub.FullName + "\") -notmatch $ExcludedPathRegex) { $stack.Push(@($sub, ($depth + 1))) }
            }
        } catch {
            # Access denied or folder removed during the scan: skip it, but count it, because a skipped
            # folder is a common reason for "app folder exists but no DLL found"
            $Script:ScanSkippedDirs++
            Write-DiagnosticSkip -Source "SCAN" -Context "Enumerate folder (skipped)" -Target $dir.FullName -ErrorRecord $_
        }
    }
}

# True when any parent folder of the file is a junction or symlink
function Test-PathThroughLink {
    param([string]$Path)
    try {
        $dir = [System.IO.Path]::GetDirectoryName($Path)
        while ($dir -and [System.IO.Path]::GetDirectoryName($dir)) {
            if ([System.IO.Directory]::Exists($dir) -and
                (([System.IO.File]::GetAttributes($dir) -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)) { return $true }
            $dir = [System.IO.Path]::GetDirectoryName($dir)
        }
    } catch { Write-DiagnosticSkip -Source "SCAN" -Context "Check folder links" -Target $Path -ErrorRecord $_ }
    return $false
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
    if ($s -match "electronic arts|\bea\b|\\ea\\|eadesktop|eabackgroundservice|(?<![a-z])origin(?![a-z])|originwebhelper|originclient|igo32\.dll|igo64\.dll") { return "EA / ORIGIN" }
    if ($s -match "ubisoft|uplay|(?<![a-z])upc(?![a-z])") { return "UBISOFT" }
    if ($s -match "(?<![a-z])gog(?![a-z])|galaxy") { return "GOG GALAXY" }
    if ($s -match "overwolf|(?<![a-z])ow(client|explorer|utils|-)[a-z0-9_-]*\.dll") { return "OVERWOLF" }
    if ($s -match "(?<![a-z])obs(?![a-z])|streamlabs|graphics-hook") { return "OBS / STREAMLABS" }
    if ($s -match "rtss|rivatuner") { return "RTSS / RIVATUNER" }
    if ($s -match "nvidia|nvspcap") { return "NVIDIA" }
    if ($s -match "\\amd\\|amddvr") { return "AMD" }
    if ($s -match "razer|synapse|cortex") { return "RAZER" }
    if ($s -match "sony|dualsense|ps5controller") { return "SONY / DUALSENSE" }
    if ($s -match "(?<![a-z])msi(?![a-z])|msicenter|mystic|dragon center|lightkeeper|voicecontrolservice") { return "MSI" }
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

# Returns the last scheduled run as { Summary; Lines } from the Auto-Run log file
function Get-LastAutoBlockRun {
    param([int]$MaxLines = 200)
    $result = [PSCustomObject]@{ Summary = "No run recorded in $([IO.Path]::GetFileName($AutoBlockLogFile))"; Lines = @() }
    if (-not (Test-Path -LiteralPath $AutoBlockLogFile)) { return $result }
    try {
        $all = @(Get-Content -LiteralPath $AutoBlockLogFile -Encoding UTF8 -ErrorAction Stop)
        $startLine = $all | Where-Object { $_ -match 'Starting scheduled AutoBlock run' } | Select-Object -Last 1
        if (-not $startLine -or $startLine -notmatch '^\[[^\]]+\] \[([0-9a-f]{8})\]') { return $result }
        $sid = $matches[1]
        $runLines = @($all | Where-Object { $_.Contains("] [$sid] ") })
        $result.Lines = @($runLines | Select-Object -Last $MaxLines)
        $doneLine = $runLines | Where-Object { $_ -match 'Completed scheduled AutoBlock run' } | Select-Object -Last 1
        if ($doneLine -and $doneLine -match '^\[([^\]]+)\].*?(Completed scheduled AutoBlock run.*)$') {
            $result.Summary = "$($matches[1])  $($matches[2])"
        } elseif ($startLine -match '^\[([^\]]+)\]') {
            $result.Summary = "$($matches[1])  Started but no completion line (the run was interrupted or is still running)"
        }
    } catch {
        Write-DiagnosticSkip -Source "REPORT" -Context "Read Auto-Run log" -Target $AutoBlockLogFile -ErrorRecord $_
    }
    return $result
}

# Builds the full bug report text. Everything in it is masked with Hide-Username.
function Get-BugReportText {
    param(
        [string]$FallbackTitle = "ZeroHook Diagnostic Log",
        [int]$RecentLineCount = 600
    )
    Trim-DiagnosticLogFile -Path $GuiLogFile
    $envInfo = Get-EnvironmentSummary

    $exclList = try { @(Get-SavedExclusions) } catch { @() }
    $exclInfo = Get-ExclusionsDiagnosticSummary -ExcludedIds $exclList
    $exclCount = $exclInfo.Count
    $taskDiag = Get-ScheduledTaskDiagInfo
    $taskState = $taskDiag.State
    $lastRun = Get-LastAutoBlockRun

    $storeSummary = if ($Script:DetectedStoreGames -and $Script:DetectedStoreGames.Count -gt 0) {
        $grpParts = @($Script:DetectedStoreGames | Group-Object Store | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Count)" })
        "$($Script:DetectedStoreGames.Count) ($($grpParts -join ', '))"
    } else {
        "0"
    }

    $scanSummary = "No scan yet"
    if ($Script:ScanData -and $Script:ScanData.Count -gt 0) {
        $d = @($Script:ScanData.Dlls)
        $existingPaths = @($Script:SearchPaths | Where-Object { Test-Path -LiteralPath $_ }).Count
        $scanSummary = "DLLs=$(@($d | Where-Object { $_.IsBlocked }).Count)/$($d.Count) blocked | Vulkan layers=$(@($Script:ScanData.VulkanLayers).Count) | Services=$(@($Script:ScanData.Services).Count) | GameBarOff=$($Script:ScanData.GameBarOff) | UnreadableFolders=$($Script:ScanSkippedDirs) | SearchPaths=$existingPaths/$(@($Script:SearchPaths).Count) exist | ScannedAt=$($Script:ScanData.Time.ToString('HH:mm:ss'))Z"
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

    $allLines = if (Test-Path -LiteralPath $GuiLogFile) {
        @(Get-Content -LiteralPath $GuiLogFile -Encoding UTF8 -ErrorAction SilentlyContinue)
    } else {
        @()
    }
    $recentLines = @($allLines | Select-Object -Last $RecentLineCount)
    $sessionIssues = @($allLines | Where-Object { $_.Contains("] [$Script:SessionId] [ERROR]") -or $_.Contains("] [$Script:SessionId] [WARN]") } | Select-Object -Last 25)

    if ($recentLines.Count -eq 0 -and $LogBox) {
        $uiText = (New-Object System.Windows.Documents.TextRange($LogBox.Document.ContentStart, $LogBox.Document.ContentEnd)).Text
        $recentLines = @($uiText -split "`r?`n" | Where-Object { $_.Trim() -ne "" } | ForEach-Object { Format-DiagnosticLine $_ })
    }

    $now = Get-Date
    $report = @(
        "=== ZeroHook Bug Report ==="
        "App: ZeroHook (Made by: GS | Build: $AppBuildLabel)"
        "SessionId: $Script:SessionId | RunMode: $($envInfo.Mode) | Debug: $(Get-DebugStateText)"
        "Section: $FallbackTitle"
        "Timestamp: $($now.ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'))Z (local $($now.ToString('yyyy-MM-dd HH:mm:ss zzz')))"
        "OS: $($envInfo.OsInfo) ($($envInfo.Arch)) | Culture: $($envInfo.Culture)"
        "PowerShell: $($envInfo.PsVer) | Admin: $($envInfo.IsAdmin) | WorkingSet: $($envInfo.WorkingSet)"
        "Executable: $($envInfo.ExePath)"
        "Script: $($envInfo.ScriptPath)"
        "StartupTask: State=$($taskDiag.State) | LastRun=$($taskDiag.LastRunTime) | LastResult=$($taskDiag.LastTaskResult) | Exec=$($taskDiag.Execute) | Args=$($taskDiag.Arguments) | WorkDir=$($taskDiag.WorkingDir)"
        "LastAutoBlock: $($lastRun.Summary)"
        "ExclusionsSummary: $($exclInfo.Summary)"
        "ExclusionsIDs: $($exclInfo.IdsText)"
        "Scan: $scanSummary"
        "State: Task=$taskState | Exclusions=$exclCount | StoreGames=$storeSummary | CategoryFilter=$Script:CurrentCategoryFilter | AppFilter=$appFilterVal | LiveTarget=$liveTargetInfo | WatchActive=$watchEnabled | Poll=$pollVal"
        "SessionIssues: Errors=$Script:SessionErrorCount | Warnings=$Script:SessionWarnCount"
        "--- Live DLL Hooks ---"
        ((Get-LiveHookReportLines) -join "`r`n")
        "--- Errors & Warnings This Session ($($sessionIssues.Count) lines) ---"
        ($sessionIssues -join "`r`n")
        "--- Last Auto-Run ($($lastRun.Lines.Count) lines) ---"
        ($lastRun.Lines -join "`r`n")
        "--- Recent Log ($($recentLines.Count) lines) ---"
        ($recentLines -join "`r`n")
        "=== End Report ==="
    ) -join "`r`n"

    # Older log lines may predate the current masking rules; mask the whole report once more
    return (Hide-Username $report)
}

function Copy-BugReportToClipboard {
    param([string]$FallbackTitle = "ZeroHook Diagnostic Log")
    $report = Get-BugReportText -FallbackTitle $FallbackTitle
    # SetDataObject retries when another program is holding the clipboard
    [System.Windows.Clipboard]::SetDataObject($report, $true)
    Write-DiagnosticLog -Level "INFO" -Source "REPORT" -Message "Copied bug report to clipboard ($($report.Length) chars, section='$FallbackTitle')." -ForceTrim
    return $report.Length
}

# Chat apps cut long pastes (Discord allows about 2,000 characters), so the report can also be saved
# as a file the user attaches instead. Keeps the 10 newest reports.
function Save-BugReportToFile {
    param([string]$FallbackTitle = "ZeroHook Diagnostic Log")
    $report = Get-BugReportText -FallbackTitle $FallbackTitle
    if (-not (Test-Path -LiteralPath $LogDir)) { [void][System.IO.Directory]::CreateDirectory($LogDir) }
    $path = Join-Path $LogDir ("zerohook-report-{0}.txt" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    [System.IO.File]::WriteAllText($path, $report, (New-Object System.Text.UTF8Encoding($true)))
    Get-ChildItem -LiteralPath $LogDir -Filter "zerohook-report-*.txt" -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -Skip 10 |
        ForEach-Object {
            $oldReport = $_.FullName
            try { Remove-Item -LiteralPath $oldReport -Force -ErrorAction Stop }
            catch { Write-DiagnosticSkip -Source "REPORT" -Context "Remove old report" -Target $oldReport -ErrorRecord $_ }
        }
    Write-DiagnosticLog -Level "INFO" -Source "REPORT" -Message "Saved bug report to $path ($($report.Length) chars)." -ForceTrim
    try {
        Start-Process -FilePath "explorer.exe" -ArgumentList "/select,`"$path`"" | Out-Null
    } catch {
        Write-DiagnosticSkip -Source "REPORT" -Context "Open Explorer at report" -Target $path -ErrorRecord $_
    }
    return $path
}

function Open-LogsFolder {
    if (-not (Test-Path -LiteralPath $LogDir)) { [void][System.IO.Directory]::CreateDirectory($LogDir) }
    Start-Process -FilePath "explorer.exe" -ArgumentList "`"$LogDir`"" | Out-Null
    Write-DiagnosticLog -Level "DEBUG" -Source "UI" -Message "Opened logs folder."
}

function Get-HostRuntimeInfo {
    $exePath = ""
    try {
        $exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    } catch { Write-DiagnosticSkip -Source "APP" -Context "Read host executable path" -Target "CurrentProcess" -ErrorRecord $_ }

    $isHostShell = [string]::IsNullOrWhiteSpace($exePath) -or ($exePath -match '(?i)\\(powershell|pwsh|powershell_ise)\.exe$')
    $sourceScriptPath = $null

    if ($Script:SelfPath -and (Test-Path -LiteralPath $Script:SelfPath)) {
        $sourceScriptPath = $Script:SelfPath
    }

    return [PSCustomObject]@{
        ExePath          = $exePath
        IsPortableExe    = (-not $isHostShell)
        SourceScriptPath = $sourceScriptPath
    }
}

# Switches debug mode on (for $DebugModeHours hours) or off without restarting ZeroHook
function Invoke-ToggleDebugMode {
    try {
        if ($Script:DebugEnabled -and $Script:DebugSource -ne "switch") {
            Write-DiagnosticLog -Level "INFO" -Source "DEBUG" -Message "Debug mode switched off by user." -ForceTrim
            Set-DebugFlag
        } elseif ($Script:DebugEnabled) {
            [System.Windows.MessageBox]::Show("This session was started with -DebugLog, so debug logging stays on until ZeroHook is closed.", "ZeroHook") | Out-Null
            return
        } else {
            Set-DebugFlag -Enable
            $envNow = Get-EnvironmentSummary
            Write-DiagnosticLog -Level "INFO" -Source "DEBUG" -Message "Debug mode switched on by user: $(Get-DebugStateText). Applies to this session, new sessions and the Auto-Run task." -ForceTrim
            Write-DiagnosticLog -Level "DEBUG" -Source "ENV" -Message "OS=$($envNow.OsInfo) ($($envNow.Arch)) | PS=$($envNow.PsVer) | Culture=$($envNow.Culture) | Admin=$($envNow.IsAdmin) | Exe=$($envNow.ExePath) | Script=$($envNow.ScriptPath) | WorkingSet=$($envNow.WorkingSet)"
            # Collect the detailed scan output right away, so a report copied now already contains it
            Update-Dashboard -Filter "NONE" -RefreshStore
            Add-Log -Badge "[DEBUG MODE ON] " -Message "Detailed logging is on until $($Script:DebugExpiresUtc.ToLocalTime().ToString('yyyy-MM-dd HH:mm')). Reproduce the problem, then click Save Report." -BadgeColor "Yellow" -NoDiag
        }
        Update-DebugModeButton
    } catch {
        $errCtx = Write-DiagnosticError -Source "DEBUG" -Context "Toggle debug mode" -Target $DebugFlagFile -ErrorRecord $_ -ForceTrim
        [System.Windows.MessageBox]::Show("Could not change Debug Mode:`n$errCtx", "ZeroHook Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
}

function Update-DebugModeButton {
    if (-not $BtnDebugMode) { return }
    $conv = [System.Windows.Media.BrushConverter]::new()
    if ($Script:DebugEnabled) {
        $BtnDebugMode.Content = if ($Script:DebugSource -eq "switch") { "Debug: ON (-DebugLog)" } else { "Debug: ON until $($Script:DebugExpiresUtc.ToLocalTime().ToString('HH:mm'))" }
        $BtnDebugMode.Background = $conv.ConvertFromString("#2A2410")
        $BtnDebugMode.ToolTip = "Detailed logging is on for this session, new sessions and the Auto-Run task. Click to switch it off."
    } else {
        $BtnDebugMode.Content = "Debug Mode"
        $BtnDebugMode.Background = $conv.ConvertFromString("#202024")
        $BtnDebugMode.ToolTip = "Turn on detailed logging for $DebugModeHours hours (also used by the Auto-Run task). No restart needed."
    }
}

function Get-SavedExclusions {
    $targetDir = if ($UserConfigDir) { $UserConfigDir } else { Join-Path $env:LOCALAPPDATA "ZeroHook" }
    $targetPath = if ($ExclusionsFile) { $ExclusionsFile } else { Join-Path $targetDir "exclusions.json" }
    $sharedPath = if ($SharedExclusionsFile) { $SharedExclusionsFile } else { Join-Path "$env:ProgramData\ZeroHook" "exclusions.json" }
    $isSystemContext = ($env:USERNAME -eq "SYSTEM") -or ([System.Security.Principal.WindowsIdentity]::GetCurrent().IsSystem)

    $candidatePaths = [System.Collections.Generic.List[string]]::new()
    if ($AutoBlock -or $isSystemContext) {
        if ($sharedPath) { [void]$candidatePaths.Add($sharedPath) }
        if ($targetPath -and ($targetPath -ne $sharedPath)) { [void]$candidatePaths.Add($targetPath) }
    } else {
        if ($targetPath) { [void]$candidatePaths.Add($targetPath) }
        if ($sharedPath -and ($sharedPath -ne $targetPath)) { [void]$candidatePaths.Add($sharedPath) }
    }
    foreach ($legacyPath in @($RoamingExclusionsFile, $LegacyExclusionsFile)) {
        if ($legacyPath -and -not $candidatePaths.Contains($legacyPath)) {
            [void]$candidatePaths.Add($legacyPath)
        }
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    foreach ($candPath in $candidatePaths) {
        if (-not (Test-Path -LiteralPath $candPath)) { continue }
        try {
            $rawText = [System.IO.File]::ReadAllText($candPath, $utf8NoBom)
            if (-not [string]::IsNullOrWhiteSpace($rawText)) {
                $parsed = ConvertFrom-Json -InputObject $rawText
                $ids = @($parsed | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
                if (-not $isSystemContext) {
                    if ($candPath -ne $targetPath -and -not (Test-Path -LiteralPath $targetPath)) {
                        try {
                            if (-not (Test-Path -LiteralPath $targetDir)) { [System.IO.Directory]::CreateDirectory($targetDir) | Out-Null }
                            [System.IO.File]::WriteAllText($targetPath, $rawText, $utf8NoBom)
                        } catch { Write-DiagnosticSkip -Source "EXCLUSIONS" -Context "Copy exclusions to user folder" -Target $targetPath -ErrorRecord $_ }
                    }
                    if ($sharedPath -and -not (Test-Path -LiteralPath $sharedPath)) {
                        try {
                            $sharedDir = Split-Path -Parent $sharedPath
                            if (-not (Test-Path -LiteralPath $sharedDir)) { [System.IO.Directory]::CreateDirectory($sharedDir) | Out-Null }
                            [System.IO.File]::WriteAllText($sharedPath, $rawText, $utf8NoBom)
                        } catch { Write-DiagnosticSkip -Source "EXCLUSIONS" -Context "Mirror exclusions to ProgramData" -Target $sharedPath -ErrorRecord $_ }
                    }
                }
                Write-DiagnosticLog -Level "DEBUG" -Source "EXCLUSIONS" -Message "Loaded $($ids.Count) exclusion(s) from $(Hide-Username $candPath)."
                Log-ExclusionsOnce -ExcludedIds $ids
                return $ids
            }
        } catch {
            [void](Write-DiagnosticError -Source "EXCLUSIONS" -Context "Read exclusions.json" -Target $candPath -ErrorRecord $_ -ForceTrim)
        }
    }
    Log-ExclusionsOnce -ExcludedIds @()
    return @()
}

function Save-Exclusions {
    param([string[]]$Ids)
    $targetDir = if ($UserConfigDir) { $UserConfigDir } else { Join-Path $env:LOCALAPPDATA "ZeroHook" }
    $targetFile = if ($ExclusionsFile) { $ExclusionsFile } else { Join-Path $targetDir "exclusions.json" }
    $sharedFile = if ($SharedExclusionsFile) { $SharedExclusionsFile } else { Join-Path "$env:ProgramData\ZeroHook" "exclusions.json" }

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

        $sharedSynced = $false
        try {
            $sharedDir = Split-Path -Parent $sharedFile
            Protect-AdminDirectory -Path $sharedDir -Recurse
            [System.IO.File]::WriteAllText($sharedFile, $json, $utf8NoBom)
            $sharedSynced = $true
        } catch {
            [void](Write-DiagnosticError -Source "EXCLUSIONS" -Context "Mirror exclusions.json to ProgramData" -Target $sharedFile -ErrorRecord $_ -ForceTrim)
        }

        $exSummary = Get-ExclusionsDiagnosticSummary -ExcludedIds $cleanIds
        Write-DiagnosticLog -Level "INFO" -Source "EXCLUSIONS" -Message "Saved $($cleanIds.Count) exclusion(s) to $(Hide-Username $targetFile) (SharedSynced=$sharedSynced) | $($exSummary.Summary)." -ForceTrim
    } catch {
        [void](Write-DiagnosticError -Source "EXCLUSIONS" -Context "Save exclusions.json" -Target $targetFile -ErrorRecord $_ -ForceTrim)
        try {
            [System.Windows.MessageBox]::Show(
                "Could not save exclusions to:`n$targetFile`n`n$($_.Exception.Message)",
                "ZeroHook Error",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error
            ) | Out-Null
        } catch { Write-DiagnosticSkip -Source "EXCLUSIONS" -Context "Show save error dialog" -Target "MessageBox" -ErrorRecord $_ }
    }
}

# Exclusion IDs contain full paths, and several apps put their version number in the folder name.
# Comparing with those segments wildcarded keeps an exclusion valid after the app updates.
function Get-ExclusionKey {
    param([string]$Id)
    if ([string]::IsNullOrWhiteSpace($Id)) { return "" }
    $key = ($Id.Trim() -replace '/', '\').ToLowerInvariant()
    if ($key.StartsWith("dll|")) {
        $key = $key -replace '\\app-\d+(\.\d+)+\\', '\app-*\'
        $key = $key -replace '\\\d+(\.\d+){2,}(-\d+)?\\', '\*\'
        $key = $key -replace '\\discord_hook\\[0-9a-f]{8,}\\', '\discord_hook\*\'
    }
    return $key
}

function Test-ItemExcluded {
    param(
        [string]$Id,
        [string[]]$ExcludedIds
    )
    if ([string]::IsNullOrWhiteSpace($Id) -or -not $ExcludedIds) { return $false }
    $key = Get-ExclusionKey $Id
    foreach ($ex in $ExcludedIds) {
        if ((Get-ExclusionKey $ex) -eq $key) { return $true }
    }
    return $false
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
    return @(Get-Process -Name $LauncherProcesses -ErrorAction SilentlyContinue)
}

function Get-OverlayDLLs {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    Update-SearchPaths
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

    $Script:ScanSkippedDirs = 0
    foreach ($BasePath in $Script:SearchPaths) {
        $normBase = Normalize-StorePath $BasePath
        if (-not $normBase -or ($normBase -match '(?i)[\\/]WindowsApps([\\/]|$)')) { continue }
        if (-not (Test-Path -LiteralPath $normBase)) {
            Write-DiagnosticLog -Level "DEBUG" -Source "SCAN" -Message "Search path not present: $normBase"
            continue
        }
        $foundBefore = $Found.Count
        $skippedBefore = $Script:ScanSkippedDirs

        # System32 / SysWOW64 are never searched recursively: only check the known NVIDIA and AMD files
        if (($normBase -ieq $sys32Path) -or ($normBase -ieq $sysWow64Path)) {
            foreach ($name in @("nvspcap64.dll", "amddvr64.dll")) {
                $candidate = Join-Path $sys32Path $name
                if (Test-Path -LiteralPath $candidate) {
                    & $addFile (Get-Item -LiteralPath $candidate -ErrorAction SilentlyContinue)
                }
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
                foreach ($f in (Find-TargetFiles -Root $steamBin -Names $targetNameSet)) { & $addFile $f }
            }
        } else {
            foreach ($f in (Find-TargetFiles -Root $normBase -Names $targetNameSet)) { & $addFile $f }
        }
        Write-DiagnosticLog -Level "DEBUG" -Source "SCAN" -Message "Searched $normBase | NewDLLs=$($Found.Count - $foundBefore) | UnreadableFolders=$($Script:ScanSkippedDirs - $skippedBefore)"
    }

    $Results = [System.Collections.Generic.List[object]]::new()
    foreach ($F in $Found) {
        $IsBlocked = $false
        try {
            $Acl = Get-Acl -LiteralPath $F.FullName -ErrorAction Stop
            if ($Acl) {
                foreach ($R in $Acl.Access) {
                    if (Test-IsEveryoneDenyRule $R) { $IsBlocked = $true; break }
                }
            }
        } catch {
            [void](Write-DiagnosticError -Source "SCAN" -Context "Read DLL ACL" -Target $F.FullName -ErrorRecord $_)
        }
        [void]$Results.Add([PSCustomObject]@{ Name = $F.Name; FullName = $F.FullName; IsBlocked = $IsBlocked })
        Write-DiagnosticLog -Level "DEBUG" -Source "SCAN" -Message "DLL $($F.Name) | Blocked=$IsBlocked | Size=$($F.Length) | Modified=$($F.LastWriteTime.ToString('yyyy-MM-dd')) | $($F.FullName)"
    }
    $sw.Stop()
    Write-DiagnosticLog -Level "DEBUG" -Source "SCAN" -Message "Get-OverlayDLLs completed in $($sw.ElapsedMilliseconds)ms | Found=$($Results.Count) | UnreadableFolders=$($Script:ScanSkippedDirs)"
    # Reported once per change, not on every dashboard refresh
    if ($Script:ScanSkippedDirs -gt 0 -and $Script:ScanSkippedDirs -ne $Script:LastSkippedDirsReported) {
        $Script:LastSkippedDirsReported = $Script:ScanSkippedDirs
        Write-DiagnosticLog -Level "INFO" -Source "SCAN" -Message "$($Script:ScanSkippedDirs) folder(s) could not be read during the DLL search; overlay DLLs inside them would be missed. Turn on Debug Mode to log which folders."
    }
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
    foreach ($Loc in (Get-EffectiveStartupLocations)) {
        if (Test-Path $Loc.Run) {
            $Props = Get-ItemProperty -Path $Loc.Run
            foreach ($Prop in $Props.PSObject.Properties) {
                if ($Prop.Name -in @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider")) { continue }
                $EntryName = [string]$Prop.Name
                $EntryCmd = [string]$Prop.Value
                if ($EntryName -match "LEDKeeper2_Host" -or $EntryCmd -match "LEDKeeper2_Host") { continue }
                if ($EntryName -match $StartupKeywordRegex -or $EntryCmd -match $StartupKeywordRegex) {
                    $IsDisabled = $false
                    if (Test-Path $Loc.Approved) {
                        $AppVal = (Get-ItemProperty -Path $Loc.Approved -Name $EntryName -ErrorAction SilentlyContinue).$EntryName
                        if ($AppVal -is [byte[]] -and $AppVal.Length -ge 1 -and (($AppVal[0] -band 1) -eq 1)) { $IsDisabled = $true }
                    }
                    $Items += [PSCustomObject]@{
                        Name = $EntryName; Command = $EntryCmd; RunPath = $Loc.Run; ApprovedPath = $Loc.Approved; IsDisabled = $IsDisabled
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
                if ($File.Name -match $StartupKeywordRegex) {
                    $Found += [PSCustomObject]@{ Name = $File.Name; FullPath = $File.FullName; OrigFolder = $Dir; IsDisabled = $false }
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
        if ("$($Task.TaskPath)$($Task.TaskName)" -match $StartupKeywordRegex) { $Matched += $Task }
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

# Lists the modules of another process. Process.Modules (EnumProcessModules) only returns the 64-bit
# modules of a 32-bit process when called from 64-bit PowerShell, so 32-bit games would look clean.
# A Toolhelp snapshot with TH32CS_SNAPMODULE32 returns both the 32-bit and the 64-bit modules.
function Ensure-ModuleNativeWin32 {
    if (-not ("ZeroHook.ModuleNative" -as [type])) {
        Add-Type -ErrorAction Stop -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;

namespace ZeroHook {
    public class ModuleEntry {
        public string Name;
        public string Path;
    }

    public static class ModuleNative {
        const uint TH32CS_SNAPMODULE = 0x00000008;
        const uint TH32CS_SNAPMODULE32 = 0x00000010;
        const uint PROCESS_QUERY_LIMITED_INFORMATION = 0x1000;
        const int ERROR_BAD_LENGTH = 24;
        static readonly IntPtr INVALID_HANDLE_VALUE = new IntPtr(-1);
        static Dictionary<string, string> driveMap;

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        struct MODULEENTRY32W {
            public uint dwSize;
            public uint th32ModuleID;
            public uint th32ProcessID;
            public uint GlblcntUsage;
            public uint ProccntUsage;
            public IntPtr modBaseAddr;
            public uint modBaseSize;
            public IntPtr hModule;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)] public string szModule;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string szExePath;
        }

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern IntPtr CreateToolhelp32Snapshot(uint dwFlags, uint th32ProcessID);
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern bool Module32FirstW(IntPtr hSnapshot, ref MODULEENTRY32W lpme);
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern bool Module32NextW(IntPtr hSnapshot, ref MODULEENTRY32W lpme);
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool CloseHandle(IntPtr hObject);
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, uint dwProcessId);
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool IsWow64Process(IntPtr hProcess, out bool wow64Process);
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern uint QueryDosDeviceW(string lpDeviceName, StringBuilder lpTargetPath, uint ucchMax);

        public static List<ModuleEntry> GetModules(int pid) {
            IntPtr snap = INVALID_HANDLE_VALUE;
            int err = 0;
            // ERROR_BAD_LENGTH means the module list changed while it was being read; try again
            for (int i = 0; i < 5; i++) {
                snap = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, (uint)pid);
                if (snap != INVALID_HANDLE_VALUE) break;
                err = Marshal.GetLastWin32Error();
                if (err != ERROR_BAD_LENGTH) break;
                System.Threading.Thread.Sleep(25);
            }
            if (snap == INVALID_HANDLE_VALUE) throw new Win32Exception(err);

            List<ModuleEntry> list = new List<ModuleEntry>();
            HashSet<string> seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            try {
                MODULEENTRY32W entry = new MODULEENTRY32W();
                entry.dwSize = (uint)Marshal.SizeOf(typeof(MODULEENTRY32W));
                if (!Module32FirstW(snap, ref entry)) throw new Win32Exception(Marshal.GetLastWin32Error());
                do {
                    string path = entry.szExePath ?? "";
                    string key = path.Length > 0 ? path : (entry.szModule ?? "");
                    if (seen.Add(key)) {
                        ModuleEntry m = new ModuleEntry();
                        m.Name = entry.szModule ?? "";
                        m.Path = path;
                        list.Add(m);
                    }
                } while (Module32NextW(snap, ref entry));
            } finally {
                CloseHandle(snap);
            }
            return list;
        }

        // 32 = 32-bit process on 64-bit Windows, 64 = 64-bit process, 0 = could not tell
        public static int GetBitness(int pid) {
            if (!Environment.Is64BitOperatingSystem) return 32;
            IntPtr h = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, false, (uint)pid);
            if (h == IntPtr.Zero) return 0;
            try {
                bool wow64;
                if (!IsWow64Process(h, out wow64)) return 0;
                return wow64 ? 32 : 64;
            } finally {
                CloseHandle(h);
            }
        }

        public static void RefreshDriveMap() {
            Dictionary<string, string> map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (string drive in Environment.GetLogicalDrives()) {
                string letter = drive.Substring(0, 2);
                StringBuilder sb = new StringBuilder(1024);
                if (QueryDosDeviceW(letter, sb, (uint)sb.Capacity) > 0) map[sb.ToString()] = letter;
            }
            driveMap = map;
        }

        // Kernel events report \Device\HarddiskVolume3\... paths; turn them into C:\... paths
        public static string DevicePathToDosPath(string devicePath) {
            if (string.IsNullOrEmpty(devicePath)) return devicePath;
            if (devicePath.StartsWith(@"\SystemRoot\", StringComparison.OrdinalIgnoreCase)) {
                return Environment.GetEnvironmentVariable("SystemRoot") + devicePath.Substring(11);
            }
            if (!devicePath.StartsWith(@"\Device\", StringComparison.OrdinalIgnoreCase)) return devicePath;
            if (driveMap == null) RefreshDriveMap();
            foreach (KeyValuePair<string, string> kv in driveMap) {
                if (devicePath.StartsWith(kv.Key + @"\", StringComparison.OrdinalIgnoreCase)) {
                    return kv.Value + devicePath.Substring(kv.Key.Length);
                }
            }
            return devicePath;
        }
    }
}
"@
    }
}

# Returns @{ Modules = list of { Name; Path }; Method = "Toolhelp32" or ".NET" }
function Get-ProcessModuleList {
    param([int]$TargetPid)
    $nativeError = $null
    try {
        Ensure-ModuleNativeWin32
        $mods = @([ZeroHook.ModuleNative]::GetModules($TargetPid) | ForEach-Object { [PSCustomObject]@{ Name = [string]$_.Name; Path = [string]$_.Path } })
        if ($mods.Count -gt 0) { return [PSCustomObject]@{ Modules = $mods; Method = "Toolhelp32" } }
    } catch {
        $nativeError = $_
        Write-DiagnosticSkip -Source "LIVEHOOK" -Context "Toolhelp32 module list (falling back to Process.Modules)" -Target "PID=$TargetPid" -ErrorRecord $_
    }
    $proc = $null
    try {
        $proc = Get-Process -Id $TargetPid -ErrorAction Stop
        $mods = @($proc.Modules | ForEach-Object { [PSCustomObject]@{ Name = [string]$_.ModuleName; Path = [string]$_.FileName } })
        if ($mods.Count -gt 0) { return [PSCustomObject]@{ Modules = $mods; Method = ".NET" } }
    } catch {
        # The first error is the more useful one (usually "Access is denied" from a protected game)
        if ($nativeError) { throw $nativeError.Exception }
        throw
    } finally {
        if ($proc) { $proc.Dispose() }
    }
    if ($nativeError) { throw $nativeError.Exception }
    throw "Windows returned an empty or inaccessible module list."
}

function Get-ProcessBitnessText {
    param([int]$TargetPid)
    if ($Script:BitnessCache.ContainsKey($TargetPid)) { return $Script:BitnessCache[$TargetPid] }
    $text = "unknown"
    try {
        Ensure-ModuleNativeWin32
        $bits = [ZeroHook.ModuleNative]::GetBitness($TargetPid)
        if ($bits -gt 0) { $text = "$bits-bit" }
    } catch {
        Write-DiagnosticSkip -Source "LIVEHOOK" -Context "Read process bitness" -Target "PID=$TargetPid" -ErrorRecord $_
    }
    $Script:BitnessCache[$TargetPid] = $text
    return $text
}

# Version info and (optionally) the digital signature of a DLL, cached per path for the session
function Get-ModuleFileInfo {
    param([string]$Path, [switch]$IncludeSignature)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    $info = $Script:ModuleInfoCache[$Path]
    if (-not $info) {
        $info = [PSCustomObject]@{
            Company = ""; Product = ""; FileDescription = ""; OriginalFilename = ""
            SignatureChecked = $false; Signer = ""; SignatureStatus = ""; IsMicrosoft = $false
        }
        try {
            $ver = [Diagnostics.FileVersionInfo]::GetVersionInfo($Path)
            $info.Company = [string]$ver.CompanyName
            $info.Product = [string]$ver.ProductName
            $info.FileDescription = [string]$ver.FileDescription
            $info.OriginalFilename = [string]$ver.OriginalFilename
        } catch {
            Write-DiagnosticSkip -Source "LIVEHOOK" -Context "Read DLL version info" -Target $Path -ErrorRecord $_
        }
        $Script:ModuleInfoCache[$Path] = $info
    }
    if ($IncludeSignature -and -not $info.SignatureChecked) {
        $info.SignatureChecked = $true
        try {
            $sig = Get-AuthenticodeSignature -LiteralPath $Path -ErrorAction Stop
            $info.SignatureStatus = [string]$sig.Status
            if ($sig.SignerCertificate) {
                $subject = [string]$sig.SignerCertificate.Subject
                $info.Signer = if ($subject -match 'CN=("[^"]+"|[^,]+)') { $matches[1].Trim('"') } else { $subject }
                $info.IsMicrosoft = ($sig.Status -eq "Valid") -and ($subject -match 'O=Microsoft Corporation')
            }
        } catch {
            Write-DiagnosticSkip -Source "LIVEHOOK" -Context "Read DLL signature" -Target $Path -ErrorRecord $_
        }
    }
    return $info
}

function Format-ModuleFileInfo {
    param($Info, [string]$ModuleName)
    if (-not $Info) { return "" }
    $parts = @()
    if ($Info.Product) { $parts += $Info.Product } elseif ($Info.FileDescription) { $parts += $Info.FileDescription }
    if ($Info.Company) { $parts += "by $($Info.Company)" }
    if ($Info.SignatureChecked) {
        $parts += if ($Info.Signer -and $Info.SignatureStatus -eq "Valid") { "signed: $($Info.Signer)" } elseif ($Info.Signer) { "signature $($Info.SignatureStatus): $($Info.Signer)" } else { "not signed" }
    }
    if ($Info.OriginalFilename -and $ModuleName -and ($Info.OriginalFilename -replace '\.mui$', '') -ine $ModuleName) {
        $parts += "renamed, original name $($Info.OriginalFilename)"
    }
    return ($parts -join ", ")
}

# The game's install folder: the detected store folder if there is one, otherwise a best guess from the exe path
function Get-GameRootForPath {
    param([string]$GamePath)
    if ([string]::IsNullOrWhiteSpace($GamePath)) { return "" }
    $norm = Normalize-StorePath $GamePath
    foreach ($entry in $Script:StorePrefixEntries) {
        if ($norm.StartsWith($entry.Prefix, [System.StringComparison]::OrdinalIgnoreCase)) { return $entry.Exact }
    }
    $dir = [IO.Path]::GetDirectoryName($norm)
    # Unreal Engine games keep the exe in <Game>\Binaries\Win64 and DLLs in <Root>\Engine\Binaries
    $idx = $dir.IndexOf('\Binaries\', [System.StringComparison]::OrdinalIgnoreCase)
    if ($idx -gt 3) {
        $gameDir = $dir.Substring(0, $idx)
        $parent = [IO.Path]::GetDirectoryName($gameDir)
        if ($parent -and $parent.Length -gt 3) { return $parent }
        return $gameDir
    }
    return $dir
}

# Windows, .NET, WebView2 and Store framework folders: modules from here are never treated as injected
function Test-IsSystemModulePath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $true }
    foreach ($root in @($env:SystemRoot, "$env:ProgramFiles\WindowsApps", "$env:ProgramFiles\dotnet",
                        "${env:ProgramFiles(x86)}\Microsoft\EdgeWebView", "$env:ProgramFiles\Common Files\Microsoft Shared",
                        "${env:ProgramFiles(x86)}\Common Files\Microsoft Shared")) {
        if ($root -and $Path.StartsWith($root.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

# Steam client libraries are loaded into every Steam game through steam_api; they are not an overlay
$BenignInjectedModulePattern = '(?i)^(steamclient(64)?|tier0_s(64)?|vstdlib_s(64)?|GameOverlayRenderer(64)?)\.dll$'

# Modules that are not on ZeroHook's list but were loaded from outside the game and Windows folders
# and are not signed by Microsoft or by the game's own publisher
function Get-UnrecognisedModules {
    param([object[]]$Modules, [string]$GamePath, $MatchedKeys)
    $result = [System.Collections.Generic.List[object]]::new()
    if (-not $Modules -or [string]::IsNullOrWhiteSpace($GamePath)) { return $result.ToArray() }
    $gameRoot = Get-GameRootForPath -GamePath $GamePath
    $gameSigner = (Get-ModuleFileInfo -Path $GamePath -IncludeSignature).Signer
    foreach ($m in $Modules) {
        if ($MatchedKeys.Contains($m.Key)) { continue }
        if ($m.Path -ieq $GamePath) { continue }
        if (Test-IsSystemModulePath $m.Path) { continue }
        if ($gameRoot -and $m.Path.StartsWith($gameRoot.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase)) { continue }
        if ($m.Name -match $BenignInjectedModulePattern) { continue }
        $info = Get-ModuleFileInfo -Path $m.Path -IncludeSignature
        if ($info.IsMicrosoft) { continue }
        if ($gameSigner -and $info.Signer -and $info.Signer -eq $gameSigner -and $info.SignatureStatus -eq "Valid") { continue }
        $m.Description = Format-ModuleFileInfo -Info $info -ModuleName $m.Name
        [void]$result.Add($m)
    }
    return $result.ToArray()
}

# Anti-cheat drivers usually stop other programs from reading a game's module list. Finding the
# anti-cheat lets ZeroHook explain that instead of showing an unexplained error.
$AntiCheatServices = [ordered]@{
    "EasyAntiCheat"      = "Easy Anti-Cheat"
    "EasyAntiCheat_EOS"  = "Easy Anti-Cheat"
    "BEService"          = "BattlEye"
    "vgc"                = "Riot Vanguard"
    "FACEIT"             = "FACEIT Anti-Cheat"
    "EAAntiCheatService" = "EA Javelin Anti-Cheat"
    "PnkBstrA"           = "PunkBuster"
}

function Get-AntiCheatInfo {
    param([int]$TargetPid, [string]$GamePath, [string[]]$ModuleNames = @())
    $cacheKey = "$TargetPid|$GamePath"
    # Folder and service checks run once per target; only the cheap module-name check runs on every poll
    $base = $Script:AntiCheatCache[$cacheKey]
    if (-not $base) {
        $base = [ordered]@{}
        $gameRoot = Get-GameRootForPath -GamePath $GamePath
        try {
            if ($gameRoot -and (Test-Path -LiteralPath $gameRoot)) {
                # Two folder levels are enough: anti-cheat ships next to the exe or in a folder beside it
                $entries = @(Get-ChildItem -LiteralPath $gameRoot -ErrorAction SilentlyContinue)
                $entries += @($entries | Where-Object { $_.PSIsContainer } | ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -ErrorAction SilentlyContinue })
                if ($GamePath) { $entries += @(Get-ChildItem -LiteralPath ([IO.Path]::GetDirectoryName($GamePath)) -ErrorAction SilentlyContinue) }
                foreach ($e in $entries) {
                    if ($e.Name -match '(?i)^start_protected_game\.exe$') { $base["Easy Anti-Cheat"] = "start_protected_game.exe in game folder" }
                    elseif ($e.Name -match '(?i)^EasyAntiCheat') { $base["Easy Anti-Cheat"] = "files in game folder" }
                    elseif ($e.Name -match '(?i)^(BattlEye|BEClient|BEService)') { $base["BattlEye"] = "files in game folder" }
                    elseif ($e.Name -match '(?i)^EAAntiCheat') { $base["EA Javelin Anti-Cheat"] = "files in game folder" }
                }
            }
            if ($GamePath -match '(?i)\\Riot Games\\') {
                $vgc = Get-Service -Name "vgc" -ErrorAction SilentlyContinue
                if ($vgc) { $base["Riot Vanguard"] = "Riot game, vgc service $($vgc.Status)" }
            }
            # A running anti-cheat service is only a hint: it may belong to another game
            if ($base.Count -eq 0) {
                foreach ($svcName in $AntiCheatServices.Keys) {
                    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
                    if ($svc -and $svc.Status -eq "Running") { $base[$AntiCheatServices[$svcName]] = "service $svcName running, may belong to another game" }
                }
            }
        } catch {
            Write-DiagnosticSkip -Source "LIVEHOOK" -Context "Detect anti-cheat" -Target $GamePath -ErrorRecord $_
        }
        $Script:AntiCheatCache[$cacheKey] = $base
    }
    $found = [ordered]@{}
    foreach ($k in $base.Keys) { $found[$k] = $base[$k] }
    foreach ($n in $ModuleNames) {
        if ($n -match '(?i)^easyanticheat') { $found["Easy Anti-Cheat"] = "loaded in game" }
        elseif ($n -match '(?i)^beclient') { $found["BattlEye"] = "loaded in game" }
        elseif ($n -match '(?i)^eaanticheat') { $found["EA Javelin Anti-Cheat"] = "loaded in game" }
    }
    return @($found.Keys | ForEach-Object { [PSCustomObject]@{ Name = $_; Evidence = $found[$_] } })
}

function Format-AntiCheatText {
    param([object[]]$AntiCheat)
    if (-not $AntiCheat -or $AntiCheat.Count -eq 0) { return "" }
    return (@($AntiCheat | ForEach-Object { "$($_.Name) ($($_.Evidence))" }) -join "; ")
}

# Disk state of a loaded hook DLL, linking the Live tab to the Blocker:
#   BLOCKED   - blocked on disk, but the game loaded it before the block (restart the game)
#   ACTIVE    - on ZeroHook's list and not blocked (can be blocked from the Live tab)
#   EXCLUDED  - on the Exclusions List, kept on purpose
#   ""        - not a file ZeroHook blocks (mods, upscalers, game files)
function Get-HookDiskState {
    param([string]$Path, [string]$CategoryId)
    if ([string]::IsNullOrWhiteSpace($Path)) { return "" }
    if ($OverlayHookCategories -notcontains $CategoryId) { return "" }
    $name = [IO.Path]::GetFileName($Path)
    if (-not ($TargetDLLs | Where-Object { $_ -ieq $name })) { return "" }
    $cached = $Script:DiskStateCache[$Path]
    if ($cached -and ([DateTime]::UtcNow - $cached.Time).TotalSeconds -lt 10) { return $cached.State }
    $state = "ACTIVE"
    try {
        # Exclusions are read at most every 10 seconds here; the watch can ask many times per poll
        if (-not $Script:LiveExclusionsCache -or ([DateTime]::UtcNow - $Script:LiveExclusionsCache.Time).TotalSeconds -ge 10) {
            $Script:LiveExclusionsCache = [PSCustomObject]@{ Ids = @(Get-SavedExclusions); Time = [DateTime]::UtcNow }
        }
        if (Test-ItemExcluded -Id "DLL|$Path" -ExcludedIds $Script:LiveExclusionsCache.Ids) {
            $state = "EXCLUDED"
        } else {
            $acl = Get-Acl -LiteralPath $Path -ErrorAction Stop
            foreach ($rule in $acl.Access) { if (Test-IsEveryoneDenyRule $rule) { $state = "BLOCKED"; break } }
        }
    } catch {
        Write-DiagnosticSkip -Source "LIVEHOOK" -Context "Read hook DLL disk state" -Target $Path -ErrorRecord $_
        $state = ""
    }
    $Script:DiskStateCache[$Path] = [PSCustomObject]@{ State = $state; Time = [DateTime]::UtcNow }
    return $state
}

function Get-HookDiskStateDisplay {
    param([string]$State)
    switch ($State) {
        "BLOCKED"  { return [PSCustomObject]@{ Text = "  [BLOCKED ON DISK - restart game to unload]"; Color = "Yellow" } }
        "ACTIVE"   { return [PSCustomObject]@{ Text = "  [NOT BLOCKED]"; Color = "Red" } }
        "EXCLUDED" { return [PSCustomObject]@{ Text = "  [EXCLUDED - kept on purpose]"; Color = "Muted" } }
        default    { return $null }
    }
}

# Blocks one loaded hook DLL from the Live tab, through the same code as the Blocker buttons
function Invoke-BlockLiveHookDll {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [BLOCK FAILED] " -Message "File not found: $(Hide-Username $Path)" -BadgeColor "Red"
        return
    }
    $file = Get-Item -LiteralPath $Path -ErrorAction Stop
    $raw = [PSCustomObject]@{ Name = $file.Name; FullName = $file.FullName; IsBlocked = $false }
    $target = New-BlockTarget -Id "DLL|$($file.FullName)" -Kind "DLL" -App (Get-AppGroupName "$($file.Name) $($file.FullName)") `
        -DetailText "[Overlay DLL] $($file.Name)  ($(Hide-Username $file.FullName))" -LogName (Hide-Username $file.FullName) `
        -IsBlocked $false -RawObject $raw -ExcludedIds @(Get-SavedExclusions)
    if ($target.IsExcluded) {
        Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [EXCLUDED] " -Message "$($file.Name) is on the Exclusions List; remove it there first." -BadgeColor "Yellow"
        return
    }
    try {
        Set-TargetBlocked -Target $target
        $Script:DiskStateCache.Remove($file.FullName)
        Write-DiagnosticLog -Level "INFO" -Source "LIVEHOOK" -Message "Blocked from Live tab: $($file.FullName)" -ForceTrim
        Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [BLOCKED DLL] " -Message "$($file.Name) is blocked on disk. Restart the game to unload it." -BadgeColor "Green" -SkipDiagLog
    } catch {
        $errCtx = Write-DiagnosticError -Source "LIVEHOOK" -Context "Block DLL from Live tab" -Target $file.FullName -ErrorRecord $_ -ForceTrim
        Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [BLOCK FAILED] " -Message "$($file.Name) - $errCtx" -BadgeColor "Red" -MsgColor "Red" -SkipDiagLog
        return
    }
    if ($Script:LastHookSnapshot) { Render-HookLogFromState -ForceSnapshot }
    Update-Dashboard -Filter "NONE"
}

# Mods are often renamed to a system DLL name (dxgi.dll, version.dll ...). Their version info still names them.
function Get-ModFeatureFromVersionInfo {
    param([string]$Path)
    $info = Get-ModuleFileInfo -Path $Path
    if (-not $info) { return $null }
    $text = "$($info.Product) | $($info.OriginalFilename) | $($info.FileDescription)"
    if ($text -match '(?i)\bReShade\b') { return "ReShade" }
    if ($text -match '(?i)OptiScaler') { return "OptiScaler" }
    if ($text -match '(?i)\bDXVK\b') { return "DXVK" }
    if ($text -match '(?i)ASI Loader|Ultimate ASI|Special ?K') { return "ProxyHook" }
    return $null
}

function Get-LiveHookFeatureKey {
    param([string]$ModuleName, [string]$ModulePath, [string]$GamePath)
    if ([string]::IsNullOrWhiteSpace($ModuleName)) { return $null }
    $name = $ModuleName.ToLowerInvariant()

    # Ignore System32 / SysWOW64 modules except the NVIDIA and AMD capture DLLs
    if (-not [string]::IsNullOrWhiteSpace($ModulePath)) {
        $modDir = [IO.Path]::GetDirectoryName($ModulePath)
        $sys32  = Join-Path $env:SystemRoot "System32"
        $sysWow = Join-Path $env:SystemRoot "SysWOW64"
        if (($modDir -ieq $sys32 -or $modDir -ieq $sysWow) -and ($name -notin @("nvspcap.dll", "nvspcap64.dll", "amddvr64.dll"))) {
            return $null
        }
    }

    if ($name -eq "d3d12core.dll" -and -not [string]::IsNullOrWhiteSpace($ModulePath) -and ($ModulePath -match '(?i)[\\/]D3D12_OptiScaler[\\/]')) {
        return "OptiScaler"
    }

    if ($name -eq "d3dcompiler_47.dll") {
        if (Test-LumaModContext -ModuleName $ModuleName -ModulePath $ModulePath) {
            return "LumaMod"
        }
        return $null
    }

    if ($LiveHookMap.ContainsKey($name)) { return $LiveHookMap[$name] }
    if ($name -match '^luma.*\.dll$') { return "LumaMod" }
    if ($name -in @("igo32.dll", "igo64.dll") -and $ModulePath -match '(?i)[\\/](Electronic Arts|EA Desktop|Origin)[\\/]') { return "EA" }
    if ($name -in @("overlay32.dll", "overlay64.dll") -and $ModulePath -match '(?i)[\\/]Ubisoft Game Launcher[\\/]') { return "Ubisoft" }
    if ($name -in @("dxgi.dll", "d3d9.dll", "d3d11.dll", "d3d12.dll", "opengl32.dll", "dinput8.dll", "winmm.dll") -and
        $GamePath -and $ModulePath -and ([IO.Path]::GetDirectoryName($ModulePath) -ieq [IO.Path]::GetDirectoryName($GamePath))) {
        $modFeature = Get-ModFeatureFromVersionInfo -Path $ModulePath
        if ($modFeature) { return $modFeature }
        return "LocalProxy"
    }
    # Any other DLL next to the game exe whose version info names a known mod (renamed proxies)
    if ($GamePath -and $ModulePath -and ([IO.Path]::GetDirectoryName($ModulePath) -ieq [IO.Path]::GetDirectoryName($GamePath)) -and ($ModulePath -ine $GamePath)) {
        $modFeature = Get-ModFeatureFromVersionInfo -Path $ModulePath
        if ($modFeature) { return $modFeature }
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
    $moduleMethod = ""
    $bitness = Get-ProcessBitnessText -TargetPid $TargetPid

    try {
        $proc = Get-Process -Id $TargetPid -ErrorAction Stop
        if ($null -ne $ExpectedStartUtc) {
            $actualStart = $proc.StartTime.ToUniversalTime()
            if ([Math]::Abs(($actualStart - $ExpectedStartUtc).TotalSeconds) -gt 2) {
                throw "Process start time changed (PID reused or process restarted; expected=$($ExpectedStartUtc.ToString('o')), actual=$($actualStart.ToString('o')))."
            }
        }
        $listing = Get-ProcessModuleList -TargetPid $TargetPid
        $moduleMethod = $listing.Method
        foreach ($m in $listing.Modules) {
            $modPath = [string]$m.Path
            # The file name from the path, so keys match the live load events and the case on disk
            $modName = if ($modPath) { [IO.Path]::GetFileName($modPath) } else { [string]$m.Name }
            $storeTag = Get-StoreForPath -FilePath $modPath
            $baseDesc = Get-LiveHookDllDescription -ModuleName $modName -ModulePath $modPath
            $fullDesc = if ($baseDesc) { $baseDesc } elseif ($storeTag) { "Store game directory module" } else { "" }
            $item = [PSCustomObject]@{
                Name        = $modName
                Path        = $modPath
                Description = $fullDesc
                ShortDescription = (Get-LiveHookDllShortDescription -ModuleName $modName -FullDescription $fullDesc)
                Store       = $storeTag
                Key         = "$modName|$modPath"
            }
            [void]$allModules.Add($item)
            $feat = Get-LiveHookFeatureKey -ModuleName $item.Name -ModulePath $item.Path -GamePath $GamePath
            if ($feat -and $NamedModHookCategories -contains $feat -and $fullDesc -match '(?i)proxy' -and
                -not $LiveHookDllShortDescriptions.ContainsKey($modName.ToLowerInvariant())) {
                # A proxy file name (dxgi.dll, version.dll ...) already identified as a specific mod
                $item.ShortDescription = "$($LiveHookFeatures[$feat].Label) (loaded as $modName)"
            }
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
        # Real-time watch repeats this every poll; write the error once per target and message
        $errKey = "$TargetPid|$message"
        if ($Script:LastSnapshotErrorKey -ne $errKey) {
            $Script:LastSnapshotErrorKey = $errKey
            [void](Write-DiagnosticError -Source "LIVEHOOK" -Context "Get-ProcessHookSnapshot" -Target "PID=$TargetPid;Path=$GamePath" -ErrorRecord $_)
        }
    } finally {
        if ($proc) { $proc.Dispose() }
    }

    $antiCheat = @(Get-AntiCheatInfo -TargetPid $TargetPid -GamePath $GamePath -ModuleNames @($allModules | ForEach-Object { $_.Name }))

    if ($state -eq "PASS") {
        $matchedKeys = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($list in $byFeature.Values) { foreach ($item in $list) { [void]$matchedKeys.Add($item.Key) } }
        try {
            $unrecognised = @(Get-UnrecognisedModules -Modules $allModules.ToArray() -GamePath $GamePath -MatchedKeys $matchedKeys)
            if ($unrecognised.Count -gt 0) {
                $byFeature["Unrecognised"] = [System.Collections.Generic.List[object]]::new()
                foreach ($u in $unrecognised) {
                    # Get-UnrecognisedModules writes publisher and file details into Description
                    if ($u.PSObject.Properties['ShortDescription']) { $u.ShortDescription = $u.Description }
                    [void]$byFeature["Unrecognised"].Add($u)
                }
            }
        } catch {
            [void](Write-DiagnosticError -Source "LIVEHOOK" -Context "Find unrecognised modules" -Target "PID=$TargetPid" -ErrorRecord $_)
        }
    }

    $findings = @()
    $gameRoot = Get-GameRootForPath -GamePath $GamePath
    foreach ($k in $LiveHookFeatures.Keys) {
        if ($byFeature.ContainsKey($k)) {
            $mods = $byFeature[$k].ToArray()
            # A group counts as a game component only when every DLL in it is one
            $origins = @($mods | ForEach-Object { Get-HookModuleOrigin -CategoryId $k -Path $_.Path -GameRoot $gameRoot } | Select-Object -Unique)
            $origin = if ($origins.Count -eq 1) { $origins[0] } elseif ($origins -contains "Overlay") { "Overlay" } else { "Mod" }
            $findings += [PSCustomObject]@{ Id = $k; Label = $LiveHookFeatures[$k].Label; Modules = $mods; Scope = "Loaded in process"; Origin = $origin }
        }
    }

    $historicalCapture = "Unknown"
    try {
        $val = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "HistoricalCaptureEnabled" -ErrorAction Stop
        if ($null -ne $val.HistoricalCaptureEnabled) {
            if ([int]$val.HistoricalCaptureEnabled -eq 1) {
                $historicalCapture = "Enabled"
                $findings += [PSCustomObject]@{ Id = "WindowsCapture"; Label = $LiveHookFeatures["WindowsCapture"].Label; Modules = @(); Scope = "Record what happened is on"; Origin = "Overlay" }
            } else { $historicalCapture = "Off" }
        }
    } catch { Write-DiagnosticSkip -Source "LIVEHOOK" -Context "Read HistoricalCaptureEnabled" -Target "HKCU GameDVR" -ErrorRecord $_ }

    Write-DiagnosticLog -Level "DEBUG" -Source "LIVEHOOK" -Message "Snapshot PID=$TargetPid | State=$state | Bitness=$bitness | Method=$moduleMethod | Modules=$($allModules.Count) | HookGroups=$($findings.Count) | Capture=$historicalCapture | AntiCheat=$(Format-AntiCheatText $antiCheat)"

    # Full module list, written once per target and again whenever the count changes. This is what
    # answers "why is X not detected?" without asking the user for a module dump.
    if ($Script:DebugEnabled -and $state -eq "PASS") {
        $listKey = "$TargetPid|$($allModules.Count)"
        if ($Script:LastModuleListKey -ne $listKey) {
            $Script:LastModuleListKey = $listKey
            Write-DiagnosticLog -Level "DEBUG" -Source "MODULES" -Message "--- Module list for PID=$TargetPid ($($allModules.Count) modules) ---"
            foreach ($m in ($allModules | Sort-Object Name)) {
                $extra = @()
                if ($m.Store) { $extra += "Store=$($m.Store)" }
                if ($m.Description) { $extra += "Desc=$($m.Description)" }
                $extraText = if ($extra.Count -gt 0) { " | " + ($extra -join " | ") } else { "" }
                Write-DiagnosticLog -Level "DEBUG" -Source "MODULES" -Message "$($m.Name) -> $($m.Path)$extraText"
            }
        }
    }

    return [PSCustomObject]@{
        State = $state; Message = $message; Findings = $findings; GameRoot = $gameRoot; TotalModuleCount = $allModules.Count; HistoricalCapture = $historicalCapture
        Bitness = $bitness; ModuleMethod = $moduleMethod; AntiCheat = $antiCheat; ModuleKeys = @($allModules | ForEach-Object { $_.Key })
    }
}

# --- BLOCK / RESTORE ENGINE ---
# The GUI buttons, both dialogs and -AutoBlock all go through these functions, so an item is
# detected, identified, blocked and restored the same way everywhere.
$AllTargetKinds     = @("DLL", "VULKAN", "GAMEBAR", "SVC", "RUN", "SHORTCUT", "TASK")
$OverlayTargetKinds = @("DLL", "VULKAN", "GAMEBAR")
$BlockBadges   = @{ DLL = "BLOCKED DLL"; VULKAN = "DISABLED VULKAN"; GAMEBAR = "DISABLED"; SVC = "MANUAL"; RUN = "DISABLED RUN"; SHORTCUT = "MOVED SHORTCUT"; TASK = "DISABLED TASK" }
$RestoreBadges = @{ DLL = "RESTORED DLL"; VULKAN = "ENABLED VULKAN"; GAMEBAR = "ENABLED"; SVC = "AUTO / STARTED"; RUN = "ENABLED RUN"; SHORTCUT = "RESTORED SHORTCUT"; TASK = "ENABLED TASK" }

function New-BlockTarget {
    param($Id, $Kind, $App, $DetailText, $LogName, $IsBlocked, $RawObject, $ExcludedIds)
    $isExcluded = Test-ItemExcluded -Id $Id -ExcludedIds $ExcludedIds
    # Under SYSTEM, per-user Run keys appear as HKU\<SID>; exclusions are saved as HKCU
    if (-not $isExcluded -and $Kind -eq "RUN") {
        $isExcluded = Test-ItemExcluded -Id ($Id -replace 'HKU:\\S-1-5-21-[\d-]+\\', 'HKCU:\') -ExcludedIds $ExcludedIds
    }
    return [PSCustomObject]@{
        Id = $Id; Kind = $Kind; App = $App; DetailText = $DetailText; LogName = $LogName
        IsBlocked = [bool]$IsBlocked; IsExcluded = [bool]$isExcluded; RawObject = $RawObject
    }
}

function Get-BlockTargets {
    param(
        [string[]]$Kinds = $AllTargetKinds,
        [string[]]$ExcludedIds = @()
    )
    $list = [System.Collections.Generic.List[object]]::new()
    if ($Kinds -contains "DLL") {
        foreach ($f in @(Get-OverlayDLLs)) {
            [void]$list.Add((New-BlockTarget -Id "DLL|$($f.FullName)" -Kind "DLL" -App (Get-AppGroupName "$($f.Name) $($f.FullName)") `
                -DetailText "[Overlay DLL] $($f.Name)  ($(Hide-Username $f.FullName))" -LogName (Hide-Username $f.FullName) `
                -IsBlocked $f.IsBlocked -RawObject $f -ExcludedIds $ExcludedIds))
        }
    }
    if ($Kinds -contains "VULKAN") {
        foreach ($l in @(Get-VulkanLayersList)) {
            [void]$list.Add((New-BlockTarget -Id "VULKAN|$($l.Key)|$($l.Name)" -Kind "VULKAN" -App (Get-AppGroupName $l.Name) `
                -DetailText "[Vulkan Layer] $(Hide-Username $l.Name)" -LogName (Hide-Username $l.Name) `
                -IsBlocked $l.IsDisabled -RawObject $l -ExcludedIds $ExcludedIds))
        }
    }
    if ($Kinds -contains "GAMEBAR") {
        [void]$list.Add((New-BlockTarget -Id "GAMEBAR|XBOX" -Kind "GAMEBAR" -App "XBOX / GAME BAR" `
            -DetailText "[Game Bar] Xbox Game Bar / Game DVR Background Hooks" -LogName "Xbox Game Bar & Game DVR Registry Hooks" `
            -IsBlocked (Get-GameBarStatus) -RawObject $null -ExcludedIds $ExcludedIds))
    }
    if ($Kinds -contains "SVC") {
        foreach ($svc in @(Get-UtilityServices)) {
            [void]$list.Add((New-BlockTarget -Id "SVC|$($svc.Name)" -Kind "SVC" -App (Get-AppGroupName "$($svc.Name) $($svc.DisplayName)") `
                -DetailText "[Service] $($svc.DisplayName) ($($svc.Name)) [Start: $($svc.StartType)]" -LogName "$($svc.DisplayName) ($($svc.Name))" `
                -IsBlocked ($svc.StartType -eq "Manual" -or $svc.StartType -eq "Disabled") -RawObject $svc -ExcludedIds $ExcludedIds))
        }
    }
    if ($Kinds -contains "RUN") {
        foreach ($item in @(Get-UtilityStartupItems)) {
            [void]$list.Add((New-BlockTarget -Id "RUN|$($item.RunPath)|$($item.Name)" -Kind "RUN" -App (Get-AppGroupName "$($item.Name) $($item.Command)") `
                -DetailText "[Startup Run] $($item.Name)  ($(Hide-Username $item.RunPath))" -LogName $item.Name `
                -IsBlocked $item.IsDisabled -RawObject $item -ExcludedIds $ExcludedIds))
        }
    }
    if ($Kinds -contains "SHORTCUT") {
        foreach ($sc in @(Get-UtilityStartupShortcuts)) {
            [void]$list.Add((New-BlockTarget -Id "SHORTCUT|$($sc.OrigFolder)|$($sc.Name)" -Kind "SHORTCUT" -App (Get-AppGroupName "$($sc.Name) $($sc.FullPath)") `
                -DetailText "[Startup Shortcut] $($sc.Name) ($(Hide-Username $sc.OrigFolder))" -LogName $sc.Name `
                -IsBlocked $sc.IsDisabled -RawObject $sc -ExcludedIds $ExcludedIds))
        }
    }
    if ($Kinds -contains "TASK") {
        foreach ($task in @(Get-UtilityScheduledTasks)) {
            [void]$list.Add((New-BlockTarget -Id "TASK|$($task.TaskPath)$($task.TaskName)" -Kind "TASK" -App (Get-AppGroupName "$($task.TaskPath)$($task.TaskName)") `
                -DetailText "[Scheduled Task] $($task.TaskPath)$($task.TaskName) [$($task.State)]" -LogName "$($task.TaskPath)$($task.TaskName)" `
                -IsBlocked ($task.State -eq "Disabled") -RawObject $task -ExcludedIds $ExcludedIds))
        }
    }
    $summary = @($list | Group-Object Kind | Sort-Object Name | ForEach-Object {
        $b = @($_.Group | Where-Object { $_.IsBlocked }).Count
        $e = @($_.Group | Where-Object { $_.IsExcluded }).Count
        "$($_.Name)=$($_.Count) (blocked $b, excluded $e)"
    })
    Write-DiagnosticLog -Level "DEBUG" -Source "TARGETS" -Message "Targets found: $($summary -join ', ')"
    if ($Script:DebugEnabled) {
        foreach ($t in $list) {
            Write-DiagnosticLog -Level "DEBUG" -Source "TARGETS" -Message "$($t.Kind) | Blocked=$($t.IsBlocked) | Excluded=$($t.IsExcluded) | App=$($t.App) | $($t.Id)"
        }
    }
    return $list.ToArray()
}

function Get-UserHiveRoots {
    $isSystem = [System.Security.Principal.WindowsIdentity]::GetCurrent().IsSystem
    if ($isSystem) {
        if (-not (Get-PSDrive -Name "HKU" -ErrorAction SilentlyContinue)) {
            New-PSDrive -Name "HKU" -PSProvider Registry -Root "HKEY_USERS" -Scope Script -ErrorAction SilentlyContinue | Out-Null
        }
        $sids = @(Get-ChildItem -Path "HKU:\" -ErrorAction SilentlyContinue |
            Where-Object { $_.PSChildName -match '^S-1-5-21-[\d-]+$' } |
            ForEach-Object { "HKU:\$($_.PSChildName)" })
        if ($sids.Count -gt 0) { return $sids }
    }
    return "HKCU:"
}

# Applies the block for one target. Throws if it could not be applied.
function Set-TargetBlocked {
    param($Target)
    $ErrorActionPreference = "Stop"
    $o = $Target.RawObject
    switch ($Target.Kind) {
        "DLL" {
            $acl = Get-Acl -LiteralPath $o.FullName
            $acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($EveryoneSID, "ReadAndExecute", "Deny")))
            Set-Acl -LiteralPath $o.FullName -AclObject $acl
        }
        "VULKAN" {
            Set-ItemProperty -Path $o.Key -Name $o.Name -Value 1 -Type DWord
        }
        "GAMEBAR" {
            foreach ($hive in @(Get-UserHiveRoots)) {
                $dvr = "$hive\Software\Microsoft\Windows\CurrentVersion\GameDVR"
                $cfg = "$hive\System\GameConfigStore"
                # Create only when missing: New-Item -Force on an existing registry key wipes its contents.
                foreach ($key in @($dvr, $cfg)) {
                    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
                }
                Set-ItemProperty -Path $dvr -Name "AppCaptureEnabled" -Value 0 -Type DWord
                Set-ItemProperty -Path $cfg -Name "GameDVR_Enabled" -Value 0 -Type DWord
                Remove-ItemProperty -Path $cfg -Name "GameDVR_FSEBehaviorMode" -ErrorAction SilentlyContinue
            }
        }
        "SVC" {
            if ($o.StartType -ne "Manual" -and $o.StartType -ne "Disabled") { Set-Service -Name $o.Name -StartupType Manual }
            if ($o.Status -eq "Running") { Stop-Service -Name $o.Name -Force -ErrorAction SilentlyContinue }
        }
        "RUN" {
            $disabledBytes = [byte[]](0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
            if (-not (Test-Path $o.ApprovedPath)) { New-Item -Path $o.ApprovedPath -Force | Out-Null }
            Set-ItemProperty -Path $o.ApprovedPath -Name $o.Name -Value $disabledBytes -Type Binary
        }
        "SHORTCUT" {
            if (-not $o.IsDisabled) {
                $sub = if ($o.OrigFolder -eq $StartupFolderPaths[0]) { "User" } else { "Common" }
                $dest = Join-Path $StartupBackupDir $sub
                foreach ($dir in @($StartupBackupDir, $dest)) { Protect-AdminDirectory -Path $dir }
                Move-Item -LiteralPath $o.FullPath -Destination (Join-Path $dest $o.Name) -Force
            }
        }
        "TASK" {
            if ($o.State -ne "Disabled") { Disable-ScheduledTask -TaskName $o.TaskName -TaskPath $o.TaskPath | Out-Null }
        }
    }
}

# Restores one target to its default state. Returns $true if something was written. Throws on failure.
function Set-TargetRestored {
    param($Target)
    $ErrorActionPreference = "Stop"
    $o = $Target.RawObject
    switch ($Target.Kind) {
        "DLL" {
            $acl = Get-Acl -LiteralPath $o.FullName
            $removed = $false
            foreach ($rule in @($acl.Access)) {
                if (Test-IsEveryoneDenyRule $rule) { [void]$acl.RemoveAccessRule($rule); $removed = $true }
            }
            if ($removed) { Set-Acl -LiteralPath $o.FullName -AclObject $acl }
            return $removed
        }
        "VULKAN" {
            Set-ItemProperty -Path $o.Key -Name $o.Name -Value 0 -Type DWord
            return $true
        }
        "GAMEBAR" {
            $pairs = @(
                @("HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR", "AppCaptureEnabled"),
                @("HKCU:\System\GameConfigStore", "GameDVR_Enabled")
            )
            foreach ($pair in $pairs) {
                if (-not (Test-Path $pair[0])) { New-Item -Path $pair[0] -Force | Out-Null }
                Set-ItemProperty -Path $pair[0] -Name $pair[1] -Value 1 -Type DWord
            }
            return $true
        }
        "SVC" {
            if ($o.StartType -ne "Automatic") { Set-Service -Name $o.Name -StartupType Automatic }
            Start-Service -Name $o.Name -ErrorAction SilentlyContinue
            return $true
        }
        "RUN" {
            if (-not (Test-Path $o.ApprovedPath)) { return $false }
            $enabledBytes = [byte[]](0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
            Set-ItemProperty -Path $o.ApprovedPath -Name $o.Name -Value $enabledBytes -Type Binary
            return $true
        }
        "SHORTCUT" {
            if (-not $o.IsDisabled) { return $false }
            if (-not (Test-Path -LiteralPath $o.OrigFolder)) { New-Item -Path $o.OrigFolder -ItemType Directory -Force | Out-Null }
            Move-Item -LiteralPath $o.FullPath -Destination (Join-Path $o.OrigFolder $o.Name) -Force
            return $true
        }
        "TASK" {
            if ($o.State -ne "Disabled") { return $false }
            Enable-ScheduledTask -TaskName $o.TaskName -TaskPath $o.TaskPath | Out-Null
            return $true
        }
    }
    return $false
}

# Pre-load exclusions so the one-time snapshot is logged at startup
$null = Get-SavedExclusions

if ($AutoBlock) {
    # Exit codes shown as the task's Last Result: 0 = all applied, 2 = some items failed, 1 = the run itself failed
    $abSw = [System.Diagnostics.Stopwatch]::StartNew()
    $abExitCode = 0
    $errCount = 0
    $skippedCount = 0
    $newlyBlocked = 0
    $reapplied = 0
    $abStage = "start"
    Write-DiagnosticLog -Level "INFO" -Source "AUTOBLOCK" -Message "Starting scheduled AutoBlock run (respecting exclusions). User context: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" -ForceTrim
    try {
        $abStage = "load exclusions"
        $ExcludedIds = @(Get-SavedExclusions)
        $abStage = "find targets"
        $abTargets = @(Get-BlockTargets -ExcludedIds $ExcludedIds)
        Write-DiagnosticLog -Level "INFO" -Source "AUTOBLOCK" -Message "Found $($abTargets.Count) target(s); $(@($abTargets | Where-Object { $_.IsBlocked }).Count) already blocked, $(@($abTargets | Where-Object { $_.IsExcluded }).Count) excluded."

        $abStage = "apply blocks"
        foreach ($t in $abTargets) {
            if ($t.Kind -eq "SHORTCUT" -and $t.IsBlocked) { continue }
            if ($t.IsExcluded) {
                $skippedCount++
                Write-DiagnosticLog -Level "INFO" -Source "AUTOBLOCK" -Message "[SKIPPED - EXCLUDED] $($t.Kind) | $($t.LogName)"
                continue
            }
            try {
                Set-TargetBlocked -Target $t
                # "Was active" means something switched the item back on since the last block
                # (an app update, a launcher re-enabling its Vulkan layer, a reinstall)
                if ($t.IsBlocked) {
                    $reapplied++
                    Write-DiagnosticLog -Level "DEBUG" -Source "AUTOBLOCK" -Message "[RE-APPLIED] $($t.Kind) | $($t.LogName) (was already blocked)"
                } else {
                    $newlyBlocked++
                    Write-DiagnosticLog -Level "INFO" -Source "AUTOBLOCK" -Message "[BLOCKED] $($t.Kind) | $($t.App) | $($t.LogName) (was active)"
                }
            } catch {
                $errCount++
                [void](Write-DiagnosticError -Source "AUTOBLOCK" -Context "Block $($t.Kind)" -Target $t.Id -ErrorRecord $_)
            }
        }
        $abStage = "done"
        if ($errCount -gt 0) { $abExitCode = 2 }
    } catch {
        $abExitCode = 1
        [void](Write-DiagnosticError -Source "AUTOBLOCK" -Context "Scheduled run failed during '$abStage'" -Target "AutoBlock" -ErrorRecord $_ -ForceTrim)
    } finally {
        $abSw.Stop()
        $finalLevel = if ($abExitCode -eq 1) { "ERROR" } elseif ($errCount -gt 0) { "WARN" } else { "INFO" }
        $outcome = if ($abExitCode -eq 1) { "FAILED at '$abStage'" } else { "OK" }
        Write-DiagnosticLog -Level $finalLevel -Source "AUTOBLOCK" -Message "Completed scheduled AutoBlock run in $($abSw.ElapsedMilliseconds)ms (Result: $outcome, Newly blocked: $newlyBlocked, Re-applied: $reapplied, Excluded skipped: $skippedCount, Errors: $errCount, ExitCode: $abExitCode)." -ForceTrim
    }
    exit $abExitCode
}

# --- WPF GUI SETUP & LOGO LOADING ---
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

Write-DiagnosticLog -Level "INFO" -Source "APP" -Message "ZeroHook GUI started (Build: $AppBuildLabel)."

# App icon (multi-size .ico), embedded so no image file has to ship next to ZeroHook
$ZeroHookIconBase64 = @'
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
QRQpt3YAAAAASUVORK5CYII=
'@

# Window icons use the decoder frame, so Windows can pick the right size for the title bar and taskbar.
# The header image uses the largest frame.
$ZeroHookLogo = $null
$ZeroHookHeaderImage = $null
try {
    $iconStream = New-Object System.IO.MemoryStream(,[System.Convert]::FromBase64String($ZeroHookIconBase64))
    $iconDecoder = [System.Windows.Media.Imaging.BitmapDecoder]::Create($iconStream,
        [System.Windows.Media.Imaging.BitmapCreateOptions]::None,
        [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad)
    $ZeroHookLogo = $iconDecoder.Frames[0]
    $ZeroHookHeaderImage = $iconDecoder.Frames | Sort-Object PixelWidth | Select-Object -Last 1
} catch {
    [void](Write-DiagnosticError -Source "APP" -Context "Load app icon" -Target "Embedded icon" -ErrorRecord $_)
}

# --- SHARED DARK THEME (used by every window) ---
$ThemeResources = @'
        <SolidColorBrush x:Key="Surface" Color="#1C1C21"/>
        <SolidColorBrush x:Key="Control" Color="#26262C"/>
        <SolidColorBrush x:Key="Line" Color="#34343C"/>
        <SolidColorBrush x:Key="Muted" Color="#9CA3AF"/>
        <SolidColorBrush x:Key="Accent" Color="#38BDF8"/>

        <Style TargetType="TabItem">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border x:Name="Tab" Background="Transparent" BorderBrush="Transparent" BorderThickness="0,0,0,2" Padding="4,6" Margin="0,0,22,0" Cursor="Hand">
                            <ContentPresenter x:Name="Head" ContentSource="Header" TextElement.Foreground="#9CA3AF" TextElement.FontWeight="SemiBold" TextElement.FontSize="13"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Head" Property="TextElement.Foreground" Value="#E4E4E7"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Head" Property="TextElement.Foreground" Value="#FFFFFF"/>
                                <Setter TargetName="Tab" Property="BorderBrush" Value="#38BDF8"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="Button">
            <Setter Property="Background" Value="#26262C"/>
            <Setter Property="Foreground" Value="#F4F4F5"/>
            <Setter Property="BorderBrush" Value="#3A3A43"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,4"/>
            <Setter Property="Height" Value="30"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Grid>
                            <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                                    BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6"/>
                            <Border x:Name="Shade" Background="#FFFFFF" Opacity="0" CornerRadius="6"/>
                            <ContentPresenter Margin="{TemplateBinding Padding}" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Shade" Property="Opacity" Value="0.08"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Shade" Property="Opacity" Value="0.16"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Opacity" Value="0.45"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#1C1C21"/>
            <Setter Property="Foreground" Value="#F4F4F5"/>
            <Setter Property="CaretBrush" Value="#F4F4F5"/>
            <Setter Property="BorderBrush" Value="#3A3A43"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border x:Name="Frame" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="1" CornerRadius="6">
                            <ScrollViewer x:Name="PART_ContentHost" Margin="8,0" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsKeyboardFocused" Value="True">
                                <Setter TargetName="Frame" Property="BorderBrush" Value="#38BDF8"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#E4E4E7"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <Border x:Name="Row" Background="Transparent" CornerRadius="5" Padding="6,3">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Border x:Name="Box" Width="16" Height="16" CornerRadius="4" Background="#1C1C21"
                                        BorderBrush="#5B5B66" BorderThickness="1" VerticalAlignment="Center">
                                    <Grid>
                                        <Path x:Name="Tick" Data="M 3,7.5 L 6,10.5 L 11,4.5" Stroke="#0B1220" StrokeThickness="2" Visibility="Collapsed"/>
                                        <Rectangle x:Name="Dash" Width="8" Height="2" Fill="#0B1220" Visibility="Collapsed"/>
                                    </Grid>
                                </Border>
                                <ContentPresenter Grid.Column="1" Margin="9,0,0,0" VerticalAlignment="Center"/>
                            </Grid>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Row" Property="Background" Value="#1F1F26"/>
                            </Trigger>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="Box" Property="Background" Value="#38BDF8"/>
                                <Setter TargetName="Box" Property="BorderBrush" Value="#38BDF8"/>
                                <Setter TargetName="Tick" Property="Visibility" Value="Visible"/>
                            </Trigger>
                            <Trigger Property="IsChecked" Value="{x:Null}">
                                <Setter TargetName="Box" Property="Background" Value="#38BDF8"/>
                                <Setter TargetName="Box" Property="BorderBrush" Value="#38BDF8"/>
                                <Setter TargetName="Dash" Property="Visibility" Value="Visible"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ComboBoxItem">
            <Setter Property="Foreground" Value="#E4E4E7"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBoxItem">
                        <Border x:Name="Row" Background="Transparent" CornerRadius="4" Padding="8,4">
                            <ContentPresenter/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsHighlighted" Value="True">
                                <Setter TargetName="Row" Property="Background" Value="#34343F"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ComboBox">
            <Setter Property="Foreground" Value="#F4F4F5"/>
            <Setter Property="Height" Value="30"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="MaxDropDownHeight" Value="360"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton Focusable="False" ClickMode="Press" Cursor="Hand"
                                          IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
                                <ToggleButton.Template>
                                    <ControlTemplate TargetType="ToggleButton">
                                        <Border Background="#26262C" BorderBrush="#3A3A43" BorderThickness="1" CornerRadius="6">
                                            <Path Data="M 0,0 L 4,4 L 8,0" Stroke="#9CA3AF" StrokeThickness="1.5"
                                                  HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,10,0"/>
                                        </Border>
                                    </ControlTemplate>
                                </ToggleButton.Template>
                            </ToggleButton>
                            <ContentPresenter Content="{TemplateBinding SelectionBoxItem}"
                                              ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                              Margin="10,0,26,0" VerticalAlignment="Center" IsHitTestVisible="False"/>
                            <Popup x:Name="PART_Popup" IsOpen="{TemplateBinding IsDropDownOpen}" Placement="Bottom"
                                   AllowsTransparency="True" Focusable="False">
                                <Border Background="#1C1C21" BorderBrush="#3A3A43" BorderThickness="1" CornerRadius="6" Padding="3"
                                        MinWidth="{Binding ActualWidth, RelativeSource={RelativeSource TemplatedParent}}"
                                        MaxHeight="{TemplateBinding MaxDropDownHeight}">
                                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                                        <ItemsPresenter/>
                                    </ScrollViewer>
                                </Border>
                            </Popup>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ScrollThumb" TargetType="Thumb">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Thumb">
                        <Border Background="#4A4A55" CornerRadius="4" Margin="2"/>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ScrollBar">
            <Setter Property="Width" Value="11"/>
            <Setter Property="MinWidth" Value="11"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Border Background="Transparent">
                            <Track x:Name="PART_Track" IsDirectionReversed="True">
                                <Track.Thumb>
                                    <Thumb Style="{StaticResource ScrollThumb}"/>
                                </Track.Thumb>
                            </Track>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="Orientation" Value="Horizontal">
                    <Setter Property="Width" Value="Auto"/>
                    <Setter Property="MinWidth" Value="0"/>
                    <Setter Property="Height" Value="11"/>
                    <Setter Property="Template">
                        <Setter.Value>
                            <ControlTemplate TargetType="ScrollBar">
                                <Border Background="Transparent">
                                    <Track x:Name="PART_Track">
                                        <Track.Thumb>
                                            <Thumb Style="{StaticResource ScrollThumb}"/>
                                        </Track.Thumb>
                                    </Track>
                                </Border>
                            </ControlTemplate>
                        </Setter.Value>
                    </Setter>
                </Trigger>
            </Style.Triggers>
        </Style>
'@

# Windows draws the title bar; ask for its dark variant so it matches the window
function Enable-DarkTitleBar {
    param($TargetWindow)
    $TargetWindow.Add_SourceInitialized({
        param($win)
        try {
            if (-not ("ZeroHook.Dwm" -as [type])) {
                Add-Type -Namespace ZeroHook -Name Dwm -MemberDefinition '[DllImport("dwmapi.dll")] public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attribute, ref int value, int size);'
            }
            $hwnd = (New-Object System.Windows.Interop.WindowInteropHelper($win)).Handle
            $on = 1
            [void][ZeroHook.Dwm]::DwmSetWindowAttribute($hwnd, 20, [ref]$on, 4)
        } catch { Write-DiagnosticSkip -Source "UI" -Context "Enable dark title bar" -Target "Window" -ErrorRecord $_ }
    })
}

[xml]$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ZeroHook"
        Height="920" Width="1320" MinHeight="640" MinWidth="1040"
        WindowStartupLocation="CenterScreen"
        Background="#131316" Foreground="#E4E4E7"
        FontFamily="Segoe UI" UseLayoutRounding="True">

    <Window.Resources>
$ThemeResources
        <Style x:Key="CardButton" TargetType="Button">
            <Setter Property="Foreground" Value="#E4E4E7"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Frame" Background="#1C1C21" BorderBrush="#2C2C33" BorderThickness="1" CornerRadius="10" Padding="14,10">
                            <ContentPresenter/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Frame" Property="Background" Value="#23232A"/>
                                <Setter TargetName="Frame" Property="BorderBrush" Value="#38BDF8"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="18,14,18,18">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <DockPanel Grid.Row="0" Margin="0,0,0,12" LastChildFill="True">
            <StackPanel DockPanel.Dock="Right" Orientation="Horizontal" VerticalAlignment="Center">
                <Button x:Name="BtnSaveBugReport" Content="Save Report" Foreground="#4ADE80" Margin="0,0,8,0"
                        ToolTip="Save the bug report as a .txt file to attach in Discord or email (long pastes get cut off)"/>
                <Button x:Name="BtnCopyBugReport" Content="Copy Log for Dev" Foreground="#4ADE80" Margin="0,0,8,0"
                        ToolTip="Copy the bug report to the clipboard. For Discord, use Save Report and attach the file instead."/>
                <Button x:Name="BtnOpenLogs" Content="Open Logs" Margin="0,0,8,0" ToolTip="Open the ZeroHook logs folder"/>
                <Button x:Name="BtnDebugMode" Content="Debug Mode" Foreground="#FACC15" Margin="0,0,8,0"/>
                <Button x:Name="BtnAboutInfo" Content="Guide" Foreground="#38BDF8" Margin="0,0,8,0" ToolTip="How ZeroHook works and everything it can block"/>
                <Button x:Name="BtnRefresh" Content="Full Rescan" ToolTip="Re-scan installed store games, DLLs, services, startup entries, and running processes"/>
            </StackPanel>
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                <Image x:Name="ImgHeaderLogo" Width="36" Height="36" Margin="0,0,12,0" RenderOptions.BitmapScalingMode="HighQuality"/>
                <StackPanel>
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="ZeroHook" FontSize="20" FontWeight="Bold" Foreground="#FFFFFF"/>
                        <TextBlock Text="$AppBuildLabel  |  Made by GS" FontSize="11" Foreground="#6B7280" Margin="10,0,0,4" VerticalAlignment="Bottom"/>
                    </StackPanel>
                    <TextBlock Text="Bloat and overlay blocker with live game DLL hook detection" FontSize="11.5" Foreground="{StaticResource Muted}"/>
                </StackPanel>
            </StackPanel>
        </DockPanel>

        <TabControl x:Name="MainTabs" Grid.Row="1" Background="Transparent" BorderThickness="0" Padding="0">
            <TabItem Header="Bloat &amp; Overlay Blocker">
                <Grid Margin="0,12,0,0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <Grid Grid.Row="0">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="10"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="10"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="10"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Button x:Name="CardTask" Grid.Row="0" Grid.Column="0" Style="{StaticResource CardButton}">
                            <StackPanel>
                                <TextBlock Text="STARTUP AUTO-BLOCK" FontSize="10.5" FontWeight="SemiBold" Foreground="{StaticResource Muted}"/>
                                <TextBlock x:Name="TxtCardTaskStatus" Text="SCANNING..." FontSize="17" FontWeight="Bold" Foreground="#E4E4E7" Margin="0,3,0,2"/>
                                <TextBlock Text="Click for task details" FontSize="10.5" FontWeight="Normal" Foreground="#6B7280" TextTrimming="CharacterEllipsis"/>
                            </StackPanel>
                        </Button>
                        <Button x:Name="CardDlls" Grid.Row="0" Grid.Column="2" Style="{StaticResource CardButton}">
                            <StackPanel>
                                <TextBlock Text="OVERLAY &amp; HOOK DLLS" FontSize="10.5" FontWeight="SemiBold" Foreground="{StaticResource Muted}"/>
                                <TextBlock x:Name="TxtCardDllStatus" Text="SCANNING..." FontSize="17" FontWeight="Bold" Foreground="#E4E4E7" Margin="0,3,0,2"/>
                                <TextBlock Text="Steam, Discord, EA, Epic, OBS..." FontSize="10.5" FontWeight="Normal" Foreground="#6B7280" TextTrimming="CharacterEllipsis"/>
                            </StackPanel>
                        </Button>
                        <Button x:Name="CardVulkan" Grid.Row="0" Grid.Column="4" Style="{StaticResource CardButton}">
                            <StackPanel>
                                <TextBlock Text="VULKAN &amp; XBOX GAME BAR" FontSize="10.5" FontWeight="SemiBold" Foreground="{StaticResource Muted}"/>
                                <TextBlock x:Name="TxtCardVulkanStatus" Text="SCANNING..." FontSize="17" FontWeight="Bold" Foreground="#E4E4E7" Margin="0,3,0,2"/>
                                <TextBlock Text="Implicit layers and Game DVR" FontSize="10.5" FontWeight="Normal" Foreground="#6B7280" TextTrimming="CharacterEllipsis"/>
                            </StackPanel>
                        </Button>
                        <Button x:Name="CardServices" Grid.Row="2" Grid.Column="0" Style="{StaticResource CardButton}">
                            <StackPanel>
                                <TextBlock Text="RGB &amp; UTILITY SERVICES" FontSize="10.5" FontWeight="SemiBold" Foreground="{StaticResource Muted}"/>
                                <TextBlock x:Name="TxtCardSvcStatus" Text="SCANNING..." FontSize="17" FontWeight="Bold" Foreground="#E4E4E7" Margin="0,3,0,2"/>
                                <TextBlock Text="MSI, ASUS, Corsair, Razer, SignalRGB..." FontSize="10.5" FontWeight="Normal" Foreground="#6B7280" TextTrimming="CharacterEllipsis"/>
                            </StackPanel>
                        </Button>
                        <Button x:Name="CardStartup" Grid.Row="2" Grid.Column="2" Style="{StaticResource CardButton}">
                            <StackPanel>
                                <TextBlock Text="STARTUP APPS &amp; TASKS" FontSize="10.5" FontWeight="SemiBold" Foreground="{StaticResource Muted}"/>
                                <TextBlock x:Name="TxtCardStartupStatus" Text="SCANNING..." FontSize="17" FontWeight="Bold" Foreground="#E4E4E7" Margin="0,3,0,2"/>
                                <TextBlock Text="Run keys, shortcuts and tasks" FontSize="10.5" FontWeight="Normal" Foreground="#6B7280" TextTrimming="CharacterEllipsis"/>
                            </StackPanel>
                        </Button>
                        <Button x:Name="CardLaunchers" Grid.Row="2" Grid.Column="4" Style="{StaticResource CardButton}">
                            <StackPanel>
                                <TextBlock Text="BACKGROUND LAUNCHERS" FontSize="10.5" FontWeight="SemiBold" Foreground="{StaticResource Muted}"/>
                                <TextBlock x:Name="TxtCardLauncherStatus" Text="SCANNING..." FontSize="17" FontWeight="Bold" Foreground="#E4E4E7" Margin="0,3,0,2"/>
                                <TextBlock Text="Running overlay, RGB and cloud processes" FontSize="10.5" FontWeight="Normal" Foreground="#6B7280" TextTrimming="CharacterEllipsis"/>
                            </StackPanel>
                        </Button>
                    </Grid>

                    <DockPanel Grid.Row="1" Margin="0,12" LastChildFill="False">
                        <Button x:Name="BtnBlockAll" Content="Block Everything" Background="#15803D" BorderBrush="#16A34A" Height="36" Padding="20,4"
                                ToolTip="Block all overlay hooks, services, startup items and tasks (respects the Exclusions List)"/>
                        <Button x:Name="BtnBlockOverlaysOnly" Content="Block Overlay Hooks Only" Background="#1D4ED8" BorderBrush="#2563EB" Height="36" Margin="8,0,0,0"
                                ToolTip="Block only overlay DLLs, Vulkan layers and Game Bar/DVR (respects the Exclusions List)"/>
                        <Button x:Name="BtnCustomBlock" Content="Exclusions List..." Foreground="#FBBF24" Height="36" Margin="8,0,0,0"
                                ToolTip="Choose items that must never be blocked"/>
                        <Button x:Name="BtnRestoreAll" DockPanel.Dock="Right" Content="Restore Everything" Foreground="#F87171" BorderBrush="#7F1D1D" Height="36" Margin="8,0,0,0"
                                ToolTip="Restore everything to default auto-start and turn Auto-Run off"/>
                        <Button x:Name="BtnRestoreSelected" DockPanel.Dock="Right" Content="Restore Selected..." Height="36"
                                ToolTip="Choose specific blocked DLLs, Vulkan layers, services, startup items, or tasks to restore to default"/>
                    </DockPanel>

                    <Border Grid.Row="2" Background="#1C1C21" BorderBrush="#2C2C33" BorderThickness="1" CornerRadius="10" Padding="12">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <DockPanel Grid.Row="0" Margin="0,0,0,10">
                                <StackPanel DockPanel.Dock="Right" Orientation="Horizontal">
                                    <Button x:Name="BtnOverlayStatus" Content="Overlay DLL Status" Foreground="#38BDF8" Margin="0,0,8,0"
                                            ToolTip="See which overlay DLLs were found, blocked or not found for each app"/>
                                    <Button x:Name="BtnToggleTask" Content="Auto-Run: ?" Margin="0,0,14,0"
                                            ToolTip="Turn the ZeroHook_AutoBlock scheduled task on or off (runs 60s after logon)"/>
                                    <TextBlock Text="App filter" Foreground="{StaticResource Muted}" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                    <ComboBox x:Name="CmbAppFilter" Width="200"/>
                                    <Button x:Name="BtnQuickFilter" Content="Reset View" Margin="8,0,0,0" ToolTip="Reset category and app filters back to All, and collapse fully blocked apps again"/>
                                </StackPanel>
                                <TextBlock x:Name="TxtLogHeader" Text="ACTIVITY &amp; SCAN LOG - ALL APPS &amp; ITEMS" FontSize="11.5" FontWeight="Bold"
                                           Foreground="{StaticResource Muted}" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
                            </DockPanel>
                            <RichTextBox x:Name="LogBox" Grid.Row="1" Background="#101013" Foreground="#D4D4D8" BorderThickness="0"
                                         FontFamily="Consolas" FontSize="12.5" IsReadOnly="True"
                                         VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" Padding="8">
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
                <Grid Margin="0,12,0,0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <Border Grid.Row="0" Background="#1C1C21" BorderBrush="#2C2C33" BorderThickness="1" CornerRadius="10" Padding="12">
                        <StackPanel>
                            <DockPanel>
                                <TextBlock Text="Target process" Foreground="#FFFFFF" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,10,0"/>
                                <Button x:Name="BtnLockForeground" DockPanel.Dock="Right" Content="Lock Foreground (3s)" Background="#1D4ED8" BorderBrush="#2563EB" Margin="8,0,0,0"/>
                                <Button x:Name="BtnReloadProcs" DockPanel.Dock="Right" Content="Reload Processes" Margin="8,0,0,0"/>
                                <ComboBox x:Name="CmbHookProcess"/>
                            </DockPanel>
                            <DockPanel Margin="0,10,0,0">
                                <Button x:Name="BtnToggleLiveMonitor" Content="Start Real-Time Watch" Background="#15803D" BorderBrush="#16A34A"/>
                                <Button x:Name="BtnScanNowHooks" Content="Scan Snapshot Now" Margin="8,0,0,0"/>
                                <Button x:Name="BtnClearHookLog" Content="Clear Hook Log" Margin="8,0,0,0"/>
                                <CheckBox x:Name="ChkAutoAttach" Content="Auto-attach to games" VerticalAlignment="Center" Margin="12,0,0,0"
                                          ToolTip="Start the real-time watch automatically when a game from a detected store folder (Steam, Epic, GOG, EA, Ubisoft, Battle.net, Rockstar, Xbox) opens its window"/>
                                <TextBlock Text="Interval" Foreground="{StaticResource Muted}" VerticalAlignment="Center" Margin="16,0,8,0"/>
                                <ComboBox x:Name="CmbPollInterval" Width="80"/>
                                <TextBlock x:Name="TxtLiveHookStatus" Text="IDLE - Select a game process or lock onto foreground window" Margin="16,0,0,0"
                                           FontWeight="SemiBold" Foreground="#38BDF8" VerticalAlignment="Center" TextAlignment="Right" TextTrimming="CharacterEllipsis"/>
                            </DockPanel>
                        </StackPanel>
                    </Border>

                    <Grid Grid.Row="1" Margin="0,10">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="10"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="10"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Border Grid.Column="0" Background="#1C1C21" BorderBrush="#2C2C33" BorderThickness="1" CornerRadius="10" Padding="14,8">
                            <StackPanel>
                                <TextBlock Text="HOOK GROUPS TO REVIEW" FontSize="10.5" FontWeight="SemiBold" Foreground="{StaticResource Muted}"/>
                                <TextBlock x:Name="TxtHookGroupCount" Foreground="#FFFFFF" Text="0 GROUPS" FontSize="16" FontWeight="Bold"/>
                            </StackPanel>
                        </Border>
                        <Border Grid.Column="2" Background="#1C1C21" BorderBrush="#2C2C33" BorderThickness="1" CornerRadius="10" Padding="14,8">
                            <StackPanel>
                                <TextBlock Text="LOADED MODULES IN PROCESS" FontSize="10.5" FontWeight="SemiBold" Foreground="{StaticResource Muted}"/>
                                <TextBlock x:Name="TxtHookModuleTotal" Foreground="#FFFFFF" Text="0 MODULES" FontSize="16" FontWeight="Bold"/>
                            </StackPanel>
                        </Border>
                        <Border Grid.Column="4" Background="#1C1C21" BorderBrush="#2C2C33" BorderThickness="1" CornerRadius="10" Padding="14,8">
                            <StackPanel>
                                <TextBlock Text="WINDOWS HISTORICAL CAPTURE" FontSize="10.5" FontWeight="SemiBold" Foreground="{StaticResource Muted}"/>
                                <TextBlock x:Name="TxtHookCaptureState" Foreground="#FFFFFF" Text="UNKNOWN" FontSize="16" FontWeight="Bold"/>
                            </StackPanel>
                        </Border>
                    </Grid>

                    <Border Grid.Row="2" Background="#1C1C21" BorderBrush="#2C2C33" BorderThickness="1" CornerRadius="10" Padding="12">
                        <RichTextBox x:Name="HookLogBox" Background="#101013" Foreground="#D4D4D8" BorderThickness="0"
                                     FontFamily="Consolas" FontSize="12.5" IsReadOnly="True" IsDocumentEnabled="True"
                                     VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" Padding="8">
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
    # Keep the window inside the screen on small or scaled displays
    $Window.Height = [Math]::Min($Window.Height, [System.Windows.SystemParameters]::WorkArea.Height)
    $Window.Width = [Math]::Min($Window.Width, [System.Windows.SystemParameters]::WorkArea.Width)
    Enable-DarkTitleBar $Window
} catch {
    $innerErr = if ($_.Exception.InnerException) { $_.Exception.InnerException.Message } else { "" }
    $fullErr = if ($innerErr) { "$($_.Exception.Message)`n$innerErr" } else { $_.Exception.Message }
    [void](Write-DiagnosticError -Source "XAML" -Context "Load main GUI XAML" -Target "MainWindow" -ErrorRecord $_ -ForceTrim)
    [System.Windows.MessageBox]::Show("Failed to load GUI XAML:`n$fullErr", "ZeroHook Error") | Out-Null
    return
}

$ImgHeaderLogo        = $Window.FindName("ImgHeaderLogo")
$BtnCopyBugReport     = $Window.FindName("BtnCopyBugReport")
$BtnSaveBugReport     = $Window.FindName("BtnSaveBugReport")
$BtnOpenLogs          = $Window.FindName("BtnOpenLogs")
$BtnDebugMode         = $Window.FindName("BtnDebugMode")
$BtnAboutInfo         = $Window.FindName("BtnAboutInfo")
$BtnOverlayStatus     = $Window.FindName("BtnOverlayStatus")
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
$BtnRestoreSelected   = $Window.FindName("BtnRestoreSelected")
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
$ChkAutoAttach        = $Window.FindName("ChkAutoAttach")
$CmbPollInterval      = $Window.FindName("CmbPollInterval")
$TxtLiveHookStatus    = $Window.FindName("TxtLiveHookStatus")
$TxtHookGroupCount    = $Window.FindName("TxtHookGroupCount")
$TxtHookModuleTotal   = $Window.FindName("TxtHookModuleTotal")
$TxtHookCaptureState  = $Window.FindName("TxtHookCaptureState")
$HookLogBox           = $Window.FindName("HookLogBox")

if ($ZeroHookHeaderImage -and $ImgHeaderLogo) {
    $ImgHeaderLogo.Source = $ZeroHookHeaderImage
}

Update-DebugModeButton

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
$Script:SeenModuleKeys = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
$Script:CollapsedHookCategories = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($cat in $CollapsibleHookCategories) {
    [void]$Script:CollapsedHookCategories.Add($cat)
}
$Script:PendingHookDetections = @{}

function Update-AutoRunToggleButton {
    param($ExistingTask = $null)
    if (-not $BtnToggleTask) { return }
    $task = if ($null -ne $ExistingTask) { $ExistingTask } else { Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue }
    if ($task) {
        $BtnToggleTask.Content = "Auto-Run: ON"
        $BtnToggleTask.Foreground = $BrushGreen
        $BtnToggleTask.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#15803D")
    } else {
        $BtnToggleTask.Content = "Auto-Run: OFF"
        $BtnToggleTask.Foreground = $BrushGray
        $BtnToggleTask.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3F3F46")
    }
}

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
        if ([string]::IsNullOrWhiteSpace($hostInfo.ExePath) -or -not (Test-Path -LiteralPath $hostInfo.ExePath)) {
            throw "Portable executable path could not be resolved."
        }
        Write-DiagnosticLog -Level "INFO" -Source "TASK" -Message "Portable EXE detected ($(Hide-Username $hostInfo.ExePath)); using executable directly for scheduled task."
        return $hostInfo.ExePath
    }

    Protect-AdminDirectory -Path $LocalInstallDir -Recurse

    $utf8Reader = New-Object System.Text.UTF8Encoding($false)
    $utf8BomWriter = New-Object System.Text.UTF8Encoding($true)
    $scriptText = $null
    $sourceUsed = "none"

    if ($hostInfo.SourceScriptPath) {
        $scriptText = [System.IO.File]::ReadAllText($hostInfo.SourceScriptPath, $utf8Reader)
        $sourceUsed = "ScriptFile"
    } elseif ($Script:SelfScriptBlock) {
        $scriptText = $Script:SelfScriptBlock.ToString()
        $sourceUsed = "ScriptBlock"
    }

    if ([string]::IsNullOrWhiteSpace($scriptText) -or $scriptText.Length -lt 1000 -or ($scriptText -notmatch 'ZeroHook_AutoBlock')) {
        throw "Captured script source looks incomplete/empty (source=$sourceUsed, len=$(if ($scriptText) { $scriptText.Length } else { 0 })). Run ZeroHook from a .ps1 file to create the scheduled task."
    }

    [System.IO.File]::WriteAllText($LocalScriptPath, $scriptText, $utf8BomWriter)
    Write-DiagnosticLog -Level "INFO" -Source "TASK" -Message "Saved local script copy to $(Hide-Username $LocalScriptPath) via $sourceUsed (chars=$($scriptText.Length))."
    return $LocalScriptPath
}

# The auto-run task executes its own copy of the script; keep it in step with the version being run.
function Update-AutoRunScriptCopy {
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if (-not $task) { return }
        $hostInfo = Get-HostRuntimeInfo
        if ($hostInfo.IsPortableExe -or -not $hostInfo.SourceScriptPath) { return }
        $taskArgs = [string]($task.Actions | Select-Object -First 1).Arguments
        if (-not $taskArgs.Contains($LocalScriptPath)) { return }
        if ($hostInfo.SourceScriptPath -eq $LocalScriptPath) { return }
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        if ((Test-Path -LiteralPath $LocalScriptPath) -and
            ([System.IO.File]::ReadAllText($hostInfo.SourceScriptPath, $utf8) -ceq [System.IO.File]::ReadAllText($LocalScriptPath, $utf8))) { return }
        [void](Save-LocalScriptCopy)
        Write-DiagnosticLog -Level "INFO" -Source "TASK" -Message "Updated the auto-run script copy to match the running script." -ForceTrim
    } catch {
        [void](Write-DiagnosticError -Source "TASK" -Context "Update auto-run script copy" -Target $LocalScriptPath -ErrorRecord $_)
    }
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
        # Extra text after the message in the muted color (for example a folder)
        [string]$Detail = "",
        # Adds a [+]/[-] link that shows or hides this app's lines in the per-app summary
        [string]$ToggleApp = "",
        [switch]$ToggleExpanded,
        [switch]$NoScroll,
        [switch]$NoDiag
    )
    if (-not $NoDiag -and ($Badge -ne "" -or $Message -ne "")) {
        $lvl = if ($Badge -match "FAIL|ERROR") { "ERROR" } elseif ($Badge -match "WARN|IMPORTANT") { "WARN" } else { "INFO" }
        Write-DiagnosticLog -Level $lvl -Source "BLOCKER" -Message "$Badge$Message$Detail".Trim()
    }
    $Para = New-Object System.Windows.Documents.Paragraph
    if ($ToggleApp -ne "") {
        $Para.Inlines.Add((New-LogAppToggleLink -App $ToggleApp -Expanded:$ToggleExpanded))
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
    if ($Detail -ne "") {
        $RunDetail = New-Object System.Windows.Documents.Run($Detail)
        $RunDetail.Foreground = $BrushMuted
        $Para.Inlines.Add($RunDetail)
    }
    $LogBox.Document.Blocks.Add($Para)
    Limit-LogBlocks -Box $LogBox -MaxBlocks 3000
    if (-not $NoScroll) { $LogBox.ScrollToEnd() }
}

function Get-LogBrush {
    param([string]$Color)
    switch ($Color) {
        "Green"  { return $BrushGreen }
        "Red"    { return $BrushRed }
        "Yellow" { return $BrushYellow }
        "Cyan"   { return $BrushCyan }
        "Muted"  { return $BrushMuted }
        default  { return $BrushGray }
    }
}

# A [Block] link next to a loaded hook DLL that is not blocked yet
$Script:LastBlockLinkPath = ""
$Script:LastBlockLinkTime = [DateTime]::MinValue
function New-BlockDllLink {
    param([string]$Path)
    $link = New-Object System.Windows.Documents.Hyperlink
    $link.Tag = $Path
    $link.TextDecorations = $null
    $link.Foreground = $BrushCyan
    $link.FontWeight = [System.Windows.FontWeights]::Bold
    $link.Cursor = [System.Windows.Input.Cursors]::Hand
    $link.ToolTip = "Block this DLL now, the same way the Blocker tab does. The game keeps it loaded until you restart the game."
    [void]$link.Inlines.Add((New-Object System.Windows.Documents.Run(" [Block]")))
    $onClick = {
        param($linkSender, $e)
        $e.Handled = $true
        $blockPath = [string]$linkSender.Tag
        # Both events below can fire for one click; act once
        $now = [DateTime]::UtcNow
        if ($Script:LastBlockLinkPath -eq $blockPath -and ($now - $Script:LastBlockLinkTime).TotalMilliseconds -lt 800) { return }
        $Script:LastBlockLinkPath = $blockPath
        $Script:LastBlockLinkTime = $now
        Invoke-UiAction "Block DLL from Live tab" { Invoke-BlockLiveHookDll -Path $blockPath }
    }
    $link.Add_Click($onClick)
    $link.Add_MouseLeftButtonDown($onClick)
    return $link
}

function Add-HookLog {
    param(
        [string]$Badge = "",
        [string]$Message = "",
        [string]$BadgeColor = "Gray",
        [string]$MsgColor = "Gray",
        [string]$ToggleCategoryId = "",
        [string]$DiagMessage = "",
        # Extra text after the message in the muted color (for example the DLL's folder)
        [string]$Detail = "",
        # Disk state shown after the message, and the DLL a [Block] link should block
        [string]$StatusText = "",
        [string]$StatusColor = "Muted",
        [string]$BlockPath = "",
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
    if ($Detail -ne "") {
        $RunDetail = New-Object System.Windows.Documents.Run($Detail)
        $RunDetail.Foreground = $BrushMuted
        $Para.Inlines.Add($RunDetail)
    }
    if ($StatusText -ne "") {
        $RunStatus = New-Object System.Windows.Documents.Run($StatusText)
        $RunStatus.FontWeight = [System.Windows.FontWeights]::Bold
        $RunStatus.Foreground = Get-LogBrush $StatusColor
        $Para.Inlines.Add($RunStatus)
    }
    if ($BlockPath -ne "") {
        $Para.Inlines.Add((New-BlockDllLink -Path $BlockPath))
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
        $joined = if ($missing.Count -gt 1) { (($missing[0..($missing.Count - 2)]) -join ", ") + " or " + $missing[-1] } else { $missing[0] }
        if ($Timestamp) {
            # Real-time watch: report only when the result changes
            $stateKey = "$($Script:LastHookTargetInfo.Id)|$joined"
            if ($Script:LastMissingOverlayState -eq $stateKey) { return }
            $Script:LastMissingOverlayState = $stateKey
        }
        $tsPart = if (-not [string]::IsNullOrWhiteSpace($Timestamp)) { "[$Timestamp] " } else { "" }
        Add-HookLog -Badge "${Prefix}${tsPart}[OK] " `
            -Message "No $joined overlay loaded in the game." `
            -BadgeColor "Green" -MsgColor "Green" -SkipDiagLog -NoScroll:$NoScroll
    }
}

function Add-SteamClientTipToLog {
    param([switch]$NoScroll, [switch]$NoDiag)
    Add-Log -Badge "`n[STEAM CLIENT TIP] " -Message "For extra optimization, consider disabling these in your Steam client too (Settings > Interface > Advanced - requires a Steam restart):" -BadgeColor "Cyan" -MsgColor "Gray" -NoScroll:$NoScroll -NoDiag:$NoDiag
    Add-Log -Badge "  - " -Message "Enable smooth scrolling in web views" -BadgeColor "Cyan" -MsgColor "Gray" -NoScroll:$NoScroll -NoDiag:$NoDiag
    Add-Log -Badge "  - " -Message "Enable GPU accelerated rendering in web views" -BadgeColor "Cyan" -MsgColor "Gray" -NoScroll:$NoScroll -NoDiag:$NoDiag
    Add-Log -Badge "  - " -Message "Enable hardware video decoding, if supported" -BadgeColor "Cyan" -MsgColor "Gray" -NoScroll:$NoScroll -NoDiag:$NoDiag
    Add-Log -Badge "  - " -Message "Note: Steam re-enables its Vulkan layers on every launch. Keep Steam auto-startup enabled and use the Auto-Run task scheduler so they are disabled automatically 60s after Windows Startup & Logon." -BadgeColor "Yellow" -MsgColor "Yellow" -NoScroll:$NoScroll -NoDiag:$NoDiag
}

function Refresh-HookProcessList {
    param([switch]$SelectFirstSilently)

    $Script:SuppressHookProcessSelection = $true
    try {
        $previousId = if ($CmbHookProcess.SelectedItem -and $CmbHookProcess.SelectedItem.Tag) { $CmbHookProcess.SelectedItem.Tag.Id } else { $null }
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
            if ($p.Id -eq $previousId) { $CmbHookProcess.SelectedItem = $item }
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

# Sections of the Live DLL Hooks log, in display order
$HookLogSections = @(
    [PSCustomObject]@{ Origin = "Overlay"; Title = "OVERLAYS & CAPTURE"; Color = "Red";    Note = "hook into the game; you can usually turn these off" }
    [PSCustomObject]@{ Origin = "Mod";     Title = "MODS & THIRD-PARTY DLLS"; Color = "Yellow"; Note = "added by you or by another program" }
    [PSCustomObject]@{ Origin = "Game";    Title = "GAME COMPONENTS"; Color = "Green";  Note = "shipped with the game - normal, nothing to fix" }
)

function Get-HookFindingOrigin {
    param($Finding)
    if ($Finding -and $Finding.PSObject.Properties['Origin'] -and $Finding.Origin) { return [string]$Finding.Origin }
    if ($Finding -and ($Finding.Id -eq "WindowsCapture" -or $OverlayHookCategories -contains $Finding.Id)) { return "Overlay" }
    return "Mod"
}

function Get-HookOriginColor {
    param([string]$Origin)
    switch ($Origin) {
        "Overlay" { return "Red" }
        "Game"    { return "Gray" }
        default   { return "Yellow" }
    }
}

function Get-HookFindingBadgeColor {
    param($Finding)
    return (Get-HookOriginColor (Get-HookFindingOrigin $Finding))
}

# [OVERLAY DETECTED], [MOD LOADED], [GAME COMPONENT DETECTED] ...
function Get-HookOriginBadge {
    param([string]$Origin, [string]$Verb)
    $kind = switch ($Origin) { "Overlay" { "OVERLAY" } "Game" { "GAME COMPONENT" } default { "MOD" } }
    return "[$kind $Verb]"
}

# "7 groups: 2 mods, 5 game components" for the status line; counts for the summary card
function Get-HookGroupCounts {
    param($Snapshot)
    $c = [ordered]@{ Overlay = 0; Mod = 0; Game = 0 }
    foreach ($f in @($Snapshot.Findings)) { $c[(Get-HookFindingOrigin $f)]++ }
    return [PSCustomObject]$c
}

function Format-HookGroupSummary {
    param($Snapshot)
    $c = Get-HookGroupCounts $Snapshot
    $total = $c.Overlay + $c.Mod + $c.Game
    if ($total -eq 0) { return "no hooks found" }
    $parts = @()
    if ($c.Overlay -gt 0) { $parts += "$($c.Overlay) overlay$(if ($c.Overlay -ne 1) { 's' })" }
    if ($c.Mod -gt 0) { $parts += "$($c.Mod) mod$(if ($c.Mod -ne 1) { 's' })" }
    if ($c.Game -gt 0) { $parts += "$($c.Game) game component$(if ($c.Game -ne 1) { 's' })" }
    return "$total group$(if ($total -ne 1) { 's' }): $($parts -join ', ')"
}

function Render-HookLogFromState {
    param([switch]$ForceSnapshot)
    $snap = $Script:LastHookSnapshot
    $target = $Script:LastHookTargetInfo
    if (-not $snap -or -not $target) { return }

    $HookLogBox.Document.Blocks.Clear()
    $Script:PendingHookDetections.Clear()

    if ($ForceSnapshot) {
        Add-HookLog -Badge "`n=== $($target.Name) (PID $($target.Id)) ===" -BadgeColor "Cyan" -SkipDiagLog -NoScroll
        if ($target.Path) { Add-HookLog -Message "  Game: $(Hide-Username $target.Path)" -MsgColor "Muted" -SkipDiagLog -NoScroll }
        $acText = Format-AntiCheatText $snap.AntiCheat
        # Module read method and live load events are in the diagnostic log and bug report, not here
        Add-HookLog -Message "  $($snap.Bitness) | started $(Format-SinceStart -StartedUtc $target.StartedUtc) ago$(if ($acText) { " | Anti-cheat: $acText" })" -MsgColor "Muted" -SkipDiagLog -NoScroll
        Write-MissingCoreOverlaysHookLog -Snapshot $snap -Prefix "  " -NoScroll
        $loadedButBlocked = 0
        $notBlocked = 0
        $gameRoot = if ($snap.PSObject.Properties['GameRoot']) { $snap.GameRoot } else { Get-GameRootForPath -GamePath $target.Path }
        if ($snap.Findings.Count -eq 0) {
            Add-HookLog -Badge "  [CLEAN] " -Message "No overlays, mods or hook DLLs found in the game." -BadgeColor "Green" -SkipDiagLog -NoScroll
        } else {
            foreach ($sec in $HookLogSections) {
                $secFindings = @($snap.Findings | Where-Object { (Get-HookFindingOrigin $_) -eq $sec.Origin })
                if ($secFindings.Count -eq 0) { continue }
                Add-HookLog -Badge "`n  $($sec.Title) ($($secFindings.Count)) " -Message "- $($sec.Note)" -BadgeColor $sec.Color -MsgColor "Muted" -SkipDiagLog -NoScroll
                foreach ($f in $secFindings) {
                    $findingColor = Get-HookFindingBadgeColor $f
                    $isCollapsible = Test-IsCollapsibleCategory -CategoryId $f.Id
                    $isMin = Test-IsCategoryMinimized -CategoryId $f.Id
                    $countText = if ($f.Modules.Count -eq 0) { $f.Scope } elseif ($f.Modules.Count -eq 1) { "1 file" } else { "$($f.Modules.Count) files" }
                    if ($isCollapsible -and $isMin) {
                        $modDetails = @($f.Modules | ForEach-Object {
                            $d = if (-not [string]::IsNullOrWhiteSpace($_.Description)) { " ($($_.Description))" } else { "" }
                            "$($_.Name) -> $(Hide-Username $_.Path)$d"
                        }) -join " | "
                        Add-HookLog -Badge "    $($f.Label) " -Message "($countText - click [+] to show)" `
                            -BadgeColor $findingColor -MsgColor "Muted" -ToggleCategoryId $f.Id `
                            -DiagMessage "[$($f.Id)] $($f.Label) [$(Get-HookFindingOrigin $f)] ($($f.Modules.Count) module(s) - minimized in UI): $modDetails" -NoScroll
                    } else {
                        Add-HookLog -Badge "    $($f.Label) " -Message "($countText)" -BadgeColor $findingColor -MsgColor "Muted" -ToggleCategoryId $f.Id -SkipDiagLog -NoScroll
                        foreach ($m in $f.Modules) {
                            $short = if ($m.PSObject.Properties['ShortDescription']) { $m.ShortDescription } else { $m.Description }
                            $descPart = if (-not [string]::IsNullOrWhiteSpace($short)) { " - $short" } else { "" }
                            $lateSuffix = if (Test-LoadedAfterBaseline -Key $m.Key) { " (loaded after first scan)" } else { "" }
                            $folder = Format-HookModuleFolder -Path $m.Path -GameRoot $gameRoot
                            $diskState = Get-HookDiskState -Path $m.Path -CategoryId $f.Id
                            $disp = Get-HookDiskStateDisplay $diskState
                            if ($diskState -eq "BLOCKED") { $loadedButBlocked++ } elseif ($diskState -eq "ACTIVE") { $notBlocked++ }
                            Add-HookLog -Badge "       $($m.Name)" -Message $descPart -Detail "   $folder$lateSuffix" -BadgeColor "Gray" -MsgColor "Gray" -SkipDiagLog -NoScroll `
                                -StatusText $(if ($disp) { $disp.Text } else { "" }) -StatusColor $(if ($disp) { $disp.Color } else { "Muted" }) `
                                -BlockPath $(if ($diskState -eq "ACTIVE") { $m.Path } else { "" })
                        }
                    }
                }
            }
        }
        if ($loadedButBlocked -gt 0) {
            Add-HookLog -Badge "`n  [RESTART NEEDED] " -Message "$loadedButBlocked hook DLL(s) are blocked on disk but were loaded before the block. Restart the game to unload them." -BadgeColor "Yellow" -MsgColor "Yellow" -SkipDiagLog -NoScroll
        }
        if ($notBlocked -gt 0) {
            Add-HookLog -Badge "  [NOT BLOCKED] " -Message "$notBlocked hook DLL(s) are not blocked. Click [Block] next to one, or use Block Overlay Hooks Only on the first tab." -BadgeColor "Red" -MsgColor "Gray" -SkipDiagLog -NoScroll
        }
        $Script:LastLiveHookSummary = [PSCustomObject]@{ Target = "$($target.Name) (PID $($target.Id))"; Snapshot = $snap; LoadedButBlocked = $loadedButBlocked; NotBlocked = $notBlocked }
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
        $Script:HookBaseline = $null
        $Script:SeenModuleKeys.Clear()
        $Script:PendingHookDetections.Clear()
        Unregister-ModuleLoadEvents
        return
    } finally {
        if ($currentProc) { $currentProc.Dispose() }
    }

    # Real-time watch also listens for every DLL load, so a hook that loads and unloads between two
    # polls is still caught. Turned on only while the watch runs; polling keeps working without it.
    if ($HookTimer.IsEnabled) {
        Register-ModuleLoadEvents -TargetPid $target.Id
        foreach ($loadedPath in @(Read-ModuleLoadEvents -TargetPid $target.Id)) {
            $loadedName = [IO.Path]::GetFileName($loadedPath)
            $feat = Get-LiveHookFeatureKey -ModuleName $loadedName -ModulePath $loadedPath -GamePath $target.Path
            if (-not $feat) { continue }
            $key = "$loadedName|$loadedPath"
            if ($Script:SeenModuleKeys.Contains($key)) { continue }
            [void]$Script:SeenModuleKeys.Add($key)
            $diskState = Get-HookDiskState -Path $loadedPath -CategoryId $feat
            $disp = Get-HookDiskStateDisplay $diskState
            $liveOrigin = Get-HookModuleOrigin -CategoryId $feat -Path $loadedPath -GameRoot (Get-GameRootForPath -GamePath $target.Path)
            Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] $(Get-HookOriginBadge $liveOrigin 'LOADED') $($LiveHookFeatures[$feat].Label): " `
                -Message "$loadedName" -Detail "   $(Format-HookModuleFolder -Path $loadedPath -GameRoot (Get-GameRootForPath -GamePath $target.Path)) - $(Format-SinceStart -StartedUtc $target.StartedUtc) after game start" `
                -DiagMessage "[HOOK LOADED][$feat][$liveOrigin] $loadedName -> $(Hide-Username $loadedPath) (live event, $(Format-SinceStart -StartedUtc $target.StartedUtc) after game start)" `
                -BadgeColor (Get-HookOriginColor $liveOrigin) -MsgColor "Gray" -ToggleCategoryId $feat -NoScroll `
                -StatusText $(if ($disp) { $disp.Text } else { "" }) -StatusColor $(if ($disp) { $disp.Color } else { "Muted" }) `
                -BlockPath $(if ($diskState -eq "ACTIVE") { $loadedPath } else { "" })
        }
    }

    $snap = Get-ProcessHookSnapshot -TargetPid $target.Id -ExpectedStartUtc $target.StartedUtc -GamePath $target.Path
    $Script:LastHookSnapshot = $snap
    $Script:LastHookTargetInfo = $target

    # Overlays and mods are what the user may want to act on; game components are shown as a side count
    $grp = Get-HookGroupCounts $snap
    $review = $grp.Overlay + $grp.Mod
    $TxtHookGroupCount.Text = "$review GROUP$(if ($review -ne 1) { 'S' })$(if ($grp.Game -gt 0) { "  (+$($grp.Game) GAME)" })"
    $TxtHookGroupCount.Foreground = if ($grp.Overlay -gt 0) { $BrushRed } elseif ($grp.Mod -gt 0) { $BrushYellow } else { $BrushGreen }

    $TxtHookModuleTotal.Text = "$($snap.TotalModuleCount) MODULES"
    $TxtHookModuleTotal.Foreground = $BrushCyan

    $TxtHookCaptureState.Text = $snap.HistoricalCapture.ToUpper()
    $TxtHookCaptureState.Foreground = if ($snap.HistoricalCapture -eq "Enabled") { $BrushYellow } elseif ($snap.HistoricalCapture -eq "Off") { $BrushGreen } else { $BrushGray }

    if ($snap.State -eq "INCONCLUSIVE") {
        $acText = Format-AntiCheatText $snap.AntiCheat
        $Script:LastLiveHookSummary = [PSCustomObject]@{ Target = "$($target.Name) (PID $($target.Id))"; Snapshot = $snap; LoadedButBlocked = 0; NotBlocked = 0 }
        if ($acText -and $snap.Message -match '(?i)denied|partial|access') {
            # Expected with anti-cheat; say so instead of showing what looks like a ZeroHook error
            $acName = $snap.AntiCheat[0].Name
            $TxtLiveHookStatus.Text = "PROTECTED BY $($acName.ToUpper()): $($target.Name) (PID $($target.Id))"
            $TxtLiveHookStatus.Foreground = $BrushYellow
            if ($ForceLogSnapshot) {
                Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [PROTECTED] " -Message "$($target.Name) is protected by anti-cheat ($acText). Windows will not share its module list with other programs, so ZeroHook cannot list its DLLs. This is expected and not a ZeroHook error. Blocks set on the first tab still apply." -BadgeColor "Yellow" -MsgColor "Gray"
            }
        } else {
            $TxtLiveHookStatus.Text = "INCONCLUSIVE: $($target.Name) (PID $($target.Id))"
            $TxtLiveHookStatus.Foreground = $BrushRed
            if ($ForceLogSnapshot) {
                $acHint = if ($acText) { " Anti-cheat found: $acText." } else { "" }
                Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [INCONCLUSIVE] " -Message "Module list unavailable for $($target.Name) (PID $($target.Id)): $($snap.Message)$acHint" -BadgeColor "Red"
            }
        }
        return
    }

    # The first full scan of a game is its baseline; DLLs that appear later are marked with the time they loaded
    if (-not $Script:HookBaseline -or $Script:HookBaseline.Pid -ne $target.Id) {
        $baseKeys = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($k in $snap.ModuleKeys) { [void]$baseKeys.Add($k) }
        $Script:HookBaseline = [PSCustomObject]@{ Pid = $target.Id; Keys = $baseKeys; TakenUtc = [DateTime]::UtcNow; SinceStart = (Format-SinceStart -StartedUtc $target.StartedUtc) }
        Write-DiagnosticLog -Level "INFO" -Source "LIVEHOOK" -Message "Baseline for $($target.Name) (PID $($target.Id), $($snap.Bitness), $($snap.ModuleMethod)): $($snap.TotalModuleCount) modules, $(Format-HookGroupSummary $snap), taken $($Script:HookBaseline.SinceStart) after game start. Anti-cheat: $(Format-AntiCheatText $snap.AntiCheat)"
    }

    $liveEvents = if ($Script:ModuleEventPid -eq $target.Id) { " | live load events" } else { "" }
    $TxtLiveHookStatus.Text = "MONITORING: $($target.Name) (PID $($target.Id), $($snap.Bitness)) | $(Format-HookGroupSummary $snap)$liveEvents"
    $TxtLiveHookStatus.Foreground = $BrushGreen

    if (-not $ForceLogSnapshot) {
        Write-MissingCoreOverlaysHookLog -Snapshot $snap -Prefix "" -Timestamp (Get-Date -Format 'HH:mm:ss') -NoScroll
    }

    $currentHookKeys = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($f in $snap.Findings) {
        $findingColor = Get-HookFindingBadgeColor $f
        $findingBadge = Get-HookOriginBadge (Get-HookFindingOrigin $f) "DETECTED"
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
                Write-DiagnosticLog -Level "INFO" -Source "LIVEHOOK" -Message "[HOOK DETECTED][$($f.Id)][$(Get-HookFindingOrigin $f)]$minTag $($nm.Name) -> $(Hide-Username $nm.Path)$descPart"
            }

            if ($isCollapsible -and $isMin) {
                if (-not $Script:PendingHookDetections.ContainsKey($f.Id)) {
                    $Script:PendingHookDetections[$f.Id] = [System.Collections.Generic.List[object]]::new()
                }
                foreach ($nm in $newModsInGroup) { [void]$Script:PendingHookDetections[$f.Id].Add($nm) }
                $totalQueued = $Script:PendingHookDetections[$f.Id].Count
                Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] $findingBadge $($f.Label) " -Message "($totalQueued file$(if ($totalQueued -ne 1) { 's' }) - click [+] to show)" -BadgeColor $findingColor -MsgColor "Muted" -ToggleCategoryId $f.Id -SkipDiagLog -NoScroll
            } else {
                foreach ($nm in $newModsInGroup) {
                    $timing = if (Test-LoadedAfterBaseline -Key $nm.Key) { " - loaded $(Format-SinceStart -StartedUtc $target.StartedUtc) after game start" } else { "" }
                    $diskState = Get-HookDiskState -Path $nm.Path -CategoryId $f.Id
                    $disp = Get-HookDiskStateDisplay $diskState
                    $short = if ($nm.PSObject.Properties['ShortDescription']) { $nm.ShortDescription } else { $nm.Description }
                    $descPart = if (-not [string]::IsNullOrWhiteSpace($short)) { " - $short" } else { "" }
                    Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] $findingBadge $($f.Label): " -Message "$($nm.Name)$descPart" `
                        -Detail "   $(Format-HookModuleFolder -Path $nm.Path -GameRoot $snap.GameRoot)$timing" -BadgeColor $findingColor -MsgColor "Gray" -ToggleCategoryId $f.Id -SkipDiagLog -NoScroll `
                        -StatusText $(if ($disp) { $disp.Text } else { "" }) -StatusColor $(if ($disp) { $disp.Color } else { "Muted" }) `
                        -BlockPath $(if ($diskState -eq "ACTIVE") { $nm.Path } else { "" })
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
        # Keys are "name|path"; show the file name with its folder
        $rkParts = $rk.Split('|', 2)
        $rkPath = if ($rkParts.Count -gt 1) { $rkParts[1] } else { "" }
        Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [UNLOADED] " -Message $rkParts[0] -Detail "   $(Format-HookModuleFolder -Path $rkPath -GameRoot $snap.GameRoot)" `
            -DiagMessage "[HOOK UNLOADED] $(Hide-Username $rk)" -BadgeColor "Cyan" -MsgColor "Gray" -NoScroll
    }

    if ($ForceLogSnapshot) {
        Render-HookLogFromState -ForceSnapshot
    } else {
        $HookLogBox.ScrollToEnd()
    }
}

function Format-SinceStart {
    param($StartedUtc)
    if ($null -eq $StartedUtc) { return "unknown time" }
    $span = [DateTime]::UtcNow - $StartedUtc
    if ($span.TotalSeconds -lt 0) { return "0s" }
    if ($span.TotalHours -ge 1) { return ("{0}h {1:00}m" -f [int][Math]::Floor($span.TotalHours), $span.Minutes) }
    if ($span.TotalMinutes -ge 1) { return ("{0}m {1:00}s" -f [int][Math]::Floor($span.TotalMinutes), $span.Seconds) }
    return ("{0}s" -f [int]$span.TotalSeconds)
}

# True when a module was not loaded yet at the first full scan of the current game
function Test-LoadedAfterBaseline {
    param([string]$Key)
    $b = $Script:HookBaseline
    if (-not $b -or -not $Script:LastHookTargetInfo -or $b.Pid -ne $Script:LastHookTargetInfo.Id) { return $false }
    return (-not $b.Keys.Contains($Key))
}

# --- LIVE MODULE LOAD EVENTS ---
# Windows reports every DLL load through the Win32_ModuleLoadTrace kernel event (needs Administrator).
# Events queue up between polls and are read on each tick, so nothing runs on a background thread.
$ModuleEventSource = "ZeroHook.ModuleLoad"
$Script:ModuleEventPid = 0
$Script:ModuleEventFailedPid = 0

function Register-ModuleLoadEvents {
    param([int]$TargetPid)
    if ($Script:ModuleEventPid -eq $TargetPid -or $Script:ModuleEventFailedPid -eq $TargetPid) { return }
    Unregister-ModuleLoadEvents
    try {
        Ensure-ModuleNativeWin32
        [ZeroHook.ModuleNative]::RefreshDriveMap()
        $query = "SELECT * FROM Win32_ModuleLoadTrace WHERE ProcessID = $TargetPid"
        Register-CimIndicationEvent -Namespace "root/cimv2" -Query $query -SourceIdentifier $ModuleEventSource -ErrorAction Stop | Out-Null
        $Script:ModuleEventPid = $TargetPid
        Write-DiagnosticLog -Level "INFO" -Source "LIVEHOOK" -Message "Live module load events on for PID $TargetPid."
    } catch {
        $Script:ModuleEventFailedPid = $TargetPid
        Write-DiagnosticLog -Level "WARN" -Source "LIVEHOOK" -Message "Live module load events are not available for PID $TargetPid; using polling only. $($_.Exception.GetBaseException().Message)"
    }
}

function Unregister-ModuleLoadEvents {
    try { Get-EventSubscriber -SourceIdentifier $ModuleEventSource -ErrorAction SilentlyContinue | Unregister-Event -ErrorAction SilentlyContinue } catch {}
    try { Get-Event -SourceIdentifier $ModuleEventSource -ErrorAction SilentlyContinue | Remove-Event -ErrorAction SilentlyContinue } catch {}
    if ($Script:ModuleEventPid) {
        Write-DiagnosticLog -Level "DEBUG" -Source "LIVEHOOK" -Message "Live module load events off for PID $($Script:ModuleEventPid)."
    }
    $Script:ModuleEventPid = 0
}

# Returns the paths of DLLs the target loaded since the last call
function Read-ModuleLoadEvents {
    param([int]$TargetPid)
    $paths = [System.Collections.Generic.List[string]]::new()
    if ($Script:ModuleEventPid -ne $TargetPid) { return $paths.ToArray() }
    foreach ($ev in @(Get-Event -SourceIdentifier $ModuleEventSource -ErrorAction SilentlyContinue)) {
        try {
            $ne = $ev.SourceEventArgs.NewEvent
            $evPid = [int]$ne.CimInstanceProperties["ProcessID"].Value
            $fileName = [string]$ne.CimInstanceProperties["FileName"].Value
            if ($evPid -eq $TargetPid -and $fileName) {
                $dosPath = [ZeroHook.ModuleNative]::DevicePathToDosPath($fileName)
                if ($dosPath -and $dosPath -match '(?i)\.(dll|addon(32|64)?|asi)$') { [void]$paths.Add($dosPath) }
            }
        } catch {
            Write-DiagnosticSkip -Source "LIVEHOOK" -Context "Read module load event" -Target "PID=$TargetPid" -ErrorRecord $_
        } finally {
            Remove-Event -EventIdentifier $ev.EventIdentifier -ErrorAction SilentlyContinue
        }
    }
    if ($paths.Count -gt 0) {
        Write-DiagnosticLog -Level "DEBUG" -Source "LIVEHOOK" -Message "Load events for PID ${TargetPid}: $($paths.Count) DLL(s)"
    }
    return $paths.ToArray()
}

# --- AUTO-ATTACH ---
# Watches for a process started from a detected store game folder and starts the real-time watch on it
$AutoAttachSkipPattern = '(?i)(crash|report|launcher|setup|install|unins|redist|helper|updater|EasyAntiCheat|BEService|start_protected_game|dxsetup|vcredist|Battle\.net|Agent|webhelper|cefprocess|QtWebEngine)'
$Script:AutoAttachKnownPids = New-Object 'System.Collections.Generic.HashSet[int]'
$Script:AutoAttachPending = @{}

function Test-HookTargetAlive {
    param($Target)
    if (-not $Target) { return $false }
    $p = $null
    try {
        $p = Get-Process -Id $Target.Id -ErrorAction Stop
        if ($null -ne $Target.StartedUtc -and [Math]::Abs(($p.StartTime.ToUniversalTime() - $Target.StartedUtc).TotalSeconds) -gt 2) { return $false }
        return $true
    } catch {
        return $false
    } finally {
        if ($p) { $p.Dispose() }
    }
}

function Start-LiveHookWatchOn {
    param($TargetObj, [string]$Reason)
    $Script:LiveHookTarget = $TargetObj
    $Script:SeenModuleKeys.Clear()
    $Script:PendingHookDetections.Clear()
    $Script:HookBaseline = $null

    Refresh-HookProcessList -SelectFirstSilently
    $matchedItem = $null
    foreach ($item in $CmbHookProcess.Items) {
        if ($item.Tag -and $item.Tag.Id -eq $TargetObj.Id) { $matchedItem = $item; break }
    }
    if (-not $matchedItem) {
        $matchedItem = New-Object System.Windows.Controls.ComboBoxItem
        $matchedItem.Content = "$($TargetObj.Name) (PID $($TargetObj.Id)) [Auto]"
        $matchedItem.Tag = [PSCustomObject]@{ Id = $TargetObj.Id; Name = $TargetObj.Name; Path = $TargetObj.Path }
        [void]$CmbHookProcess.Items.Insert(0, $matchedItem)
    }
    $Script:SuppressHookProcessSelection = $true
    $CmbHookProcess.SelectedItem = $matchedItem
    $Script:SuppressHookProcessSelection = $false

    Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [AUTO-ATTACHED] " -Message "$($TargetObj.Name) (PID $($TargetObj.Id)) - $Reason" -BadgeColor "Green"
    if (-not $HookTimer.IsEnabled) {
        $HookTimer.Start()
        $BtnToggleLiveMonitor.Content = "Stop Real-Time Watch"
        $BtnToggleLiveMonitor.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#DC2626")
    }
    Invoke-HookMonitorStep -ForceLogSnapshot
}

function Invoke-AutoAttachStep {
    if ($Script:LiveHookTarget -and (Test-HookTargetAlive $Script:LiveHookTarget)) { return }
    if (-not $Script:StoreScanCompleted) { $null = Get-InstalledStoreGames }

    $alive = New-Object 'System.Collections.Generic.HashSet[int]'
    $attachTo = $null
    foreach ($p in @(Get-Process -ErrorAction SilentlyContinue)) {
        [void]$alive.Add($p.Id)
        if ($p.Id -eq $PID) { continue }
        if (-not $Script:AutoAttachKnownPids.Contains($p.Id)) {
            [void]$Script:AutoAttachKnownPids.Add($p.Id)
            if ($p.ProcessName -in $IgnoredForegroundProcesses -or $p.ProcessName -in $LauncherProcesses -or $p.ProcessName -match $AutoAttachSkipPattern) { continue }
            $path = try { [string]$p.Path } catch { "" }
            if (-not $path) { continue }
            $store = Get-StoreForPath -FilePath $path
            if (-not $store) { continue }
            $Script:AutoAttachPending[$p.Id] = [PSCustomObject]@{ Seen = [DateTime]::UtcNow; Path = $path; Store = $store }
            Write-DiagnosticLog -Level "DEBUG" -Source "AUTOATTACH" -Message "Candidate: $($p.ProcessName) (PID $($p.Id)) from $store folder $path"
        }
        if (-not $attachTo -and $Script:AutoAttachPending.ContainsKey($p.Id)) {
            $pend = $Script:AutoAttachPending[$p.Id]
            # Wait for a window: games often start a short-lived pre-launcher first
            if ($p.MainWindowHandle -ne 0) {
                $attachTo = [PSCustomObject]@{
                    Id = [int]$p.Id; Name = [string]$p.ProcessName; Path = $pend.Path; Store = $pend.Store
                    StartedUtc = $(try { $p.StartTime.ToUniversalTime() } catch { $null })
                }
                $Script:AutoAttachPending.Remove($p.Id)
            } elseif (([DateTime]::UtcNow - $pend.Seen).TotalSeconds -gt 180) {
                $Script:AutoAttachPending.Remove($p.Id)
            }
        }
    }
    foreach ($known in @($Script:AutoAttachKnownPids)) {
        if (-not $alive.Contains($known)) {
            [void]$Script:AutoAttachKnownPids.Remove($known)
            $Script:AutoAttachPending.Remove($known)
        }
    }
    if ($attachTo) {
        Write-DiagnosticLog -Level "INFO" -Source "AUTOATTACH" -Message "Attaching to $($attachTo.Name) (PID $($attachTo.Id)), $($attachTo.Store) game: $($attachTo.Path)"
        Start-LiveHookWatchOn -TargetObj $attachTo -Reason "$($attachTo.Store) game started"
    }
}

# Live DLL Hooks section of the bug report
function Get-LiveHookReportLines {
    $sum = $Script:LastLiveHookSummary
    if (-not $sum -or -not $sum.Snapshot) { return @("No Live DLL Hooks scan in this session.") }
    $snap = $sum.Snapshot
    $lines = [System.Collections.Generic.List[string]]::new()
    [void]$lines.Add("Target: $($sum.Target) | $($snap.Bitness) | Method: $($snap.ModuleMethod) | State: $($snap.State) | Modules: $($snap.TotalModuleCount) | Live events: $(if ($Script:ModuleEventPid) { 'on' } else { 'off' })")
    $ac = Format-AntiCheatText $snap.AntiCheat
    if ($ac) { [void]$lines.Add("Anti-cheat: $ac") }
    if ($snap.Message) { [void]$lines.Add("Message: $($snap.Message)") }
    if ($Script:HookBaseline) { [void]$lines.Add("Baseline taken $($Script:HookBaseline.SinceStart) after game start") }
    [void]$lines.Add("Loaded but blocked on disk: $($sum.LoadedButBlocked) | Loaded and not blocked: $($sum.NotBlocked)")
    foreach ($f in $snap.Findings) {
        [void]$lines.Add("[$($f.Id)] $($f.Label) [$(Get-HookFindingOrigin $f)] ($($f.Modules.Count))")
        foreach ($m in $f.Modules) {
            $state = Get-HookDiskState -Path $m.Path -CategoryId $f.Id
            $late = if (Test-LoadedAfterBaseline -Key $m.Key) { " [after baseline]" } else { "" }
            $desc = if ($m.Description) { " - $($m.Description)" } else { "" }
            [void]$lines.Add("    $($m.Path)$(if ($state) { " [$state]" })$late$desc")
        }
    }
    return $lines.ToArray()
}

$HookTimer = New-Object System.Windows.Threading.DispatcherTimer
$HookTimer.Interval = [TimeSpan]::FromSeconds(5)
$HookTimer.Add_Tick({ Invoke-UiAction "Real-time hook watch" -Quiet { Invoke-HookMonitorStep } })

# --- GUIDE AND OVERLAY STATUS WINDOWS ---
$OverlayApps = @(
    @{ Name = "Steam"; Files = @("GameOverlayRenderer.dll", "GameOverlayRenderer64.dll", "SteamOverlayVulkanLayer.dll", "SteamOverlayVulkanLayer64.dll", "SteamFossilizeVulkanLayer.dll", "SteamFossilizeVulkanLayer64.dll")
       Folders = @("${env:ProgramFiles(x86)}\Steam", "$env:ProgramFiles\Steam") },
    @{ Name = "Discord"; Files = @("DiscordHook.dll", "DiscordHook32.dll", "DiscordHook64.dll", "DiscordOverlay.dll")
       Folders = @("$env:LOCALAPPDATA\Discord", "$env:LOCALAPPDATA\DiscordCanary", "$env:LOCALAPPDATA\DiscordPTB") },
    @{ Name = "Epic / EOS"; Files = @("EOSOVH-Win32-Shipping.dll", "EOSOVH-Win64-Shipping.dll")
       Folders = @("${env:ProgramFiles(x86)}\Epic Games\Launcher", "${env:ProgramFiles(x86)}\Epic Games\Epic Online Services", "$env:ProgramFiles\Epic Games\Launcher", "$env:ProgramFiles\Epic Games\Epic Online Services") },
    @{ Name = "EA / Origin"; Files = @("IGO32.dll", "IGO64.dll")
       Folders = @("$env:ProgramFiles\Electronic Arts", "${env:ProgramFiles(x86)}\Origin") },
    @{ Name = "Ubisoft Connect"; Files = @("overlay.dll", "overlay32.dll", "overlay64.dll"); PathMatch = '\\Ubisoft'
       Folders = @("${env:ProgramFiles(x86)}\Ubisoft\Ubisoft Game Launcher") },
    @{ Name = "GOG Galaxy"; Files = @("GalaxyOverlay.dll", "OverlayInjector.dll"); Generic = @("overlay.dll", "overlay32.dll", "overlay64.dll"); PathMatch = '\\GOG Galaxy|\\GOG\.com\\Galaxy'
       Folders = @("${env:ProgramFiles(x86)}\GOG Galaxy", "$env:ProgramFiles\GOG Galaxy", "$env:ProgramData\GOG.com\Galaxy\redists") },
    @{ Name = "Overwolf"; Files = @("OWClient.dll", "OWExplorer.dll", "OWUtils.dll", "ow-graphics-hook.dll", "ow-graphics-hook32.dll", "ow-graphics-hook64.dll", "ow-graphics-vulkan.dll", "ow-vulkan-overlay32.dll", "ow-vulkan-overlay64.dll", "ow-obs-vulkan32.dll", "ow-obs-vulkan64.dll")
       Folders = @("${env:ProgramFiles(x86)}\Overwolf", "$env:ProgramFiles\Overwolf", "$env:LOCALAPPDATA\Overwolf") },
    @{ Name = "OBS / Streamlabs"; Files = @("graphics-hook32.dll", "graphics-hook64.dll", "obs-vulkan32.dll", "obs-vulkan64.dll")
       Folders = @("$env:ProgramFiles\obs-studio", "$env:ProgramFiles\Streamlabs OBS", "$env:ProgramData\obs-studio-hook") },
    @{ Name = "RTSS / RivaTuner"; Files = @("RTSSHooks.dll", "RTSSHooks64.dll", "RTSSVkLayer32.dll", "RTSSVkLayer64.dll")
       Folders = @("${env:ProgramFiles(x86)}\RivaTuner Statistics Server") },
    @{ Name = "NVIDIA"; Files = @("nvspcap.dll", "nvspcap64.dll")
       Folders = @("$env:ProgramFiles\NVIDIA Corporation") },
    @{ Name = "AMD"; Files = @("amddvr64.dll")
       Folders = @("$env:ProgramFiles\AMD") }
)

function New-UiText {
    param([string]$Text, [object]$Color = "#D4D4D8", [double]$Size = 12.5, [switch]$Bold, [switch]$Mono, [string]$Margin = "0")
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $Text
    $tb.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $tb.FontSize = $Size
    $tb.Margin = [System.Windows.ThicknessConverter]::new().ConvertFromString($Margin)
    $tb.Foreground = if ($Color -is [string]) { [System.Windows.Media.BrushConverter]::new().ConvertFromString($Color) } else { $Color }
    if ($Bold) { $tb.FontWeight = [System.Windows.FontWeights]::Bold }
    if ($Mono) { $tb.FontFamily = New-Object System.Windows.Media.FontFamily("Consolas") }
    return $tb
}

function New-UiPill {
    param([string]$Text, [string]$Background, [object]$Foreground, [double]$Width = 120)
    $pill = New-Object System.Windows.Controls.Border
    $pill.CornerRadius = New-Object System.Windows.CornerRadius(4)
    $pill.Padding = New-Object System.Windows.Thickness(0, 2, 0, 2)
    $pill.Width = $Width
    $pill.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
    $pill.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Background)
    # Not "$text": variable names ignore case, so it would be the [string]$Text parameter
    $label = New-UiText -Text $Text -Color $Foreground -Size 10 -Bold
    $label.TextAlignment = [System.Windows.TextAlignment]::Center
    $pill.Child = $label
    return $pill
}

# Adds a titled card to a panel and returns the card's content panel
function Add-UiCard {
    param($Panel, [string]$Title, [object]$Pill = $null)
    $card = New-Object System.Windows.Controls.Border
    $card.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1C1C21")
    $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2C2C33")
    $card.BorderThickness = New-Object System.Windows.Thickness(1)
    $card.CornerRadius = New-Object System.Windows.CornerRadius(10)
    $card.Padding = New-Object System.Windows.Thickness(14, 10, 14, 12)
    $card.Margin = New-Object System.Windows.Thickness(0, 0, 6, 10)
    $body = New-Object System.Windows.Controls.StackPanel
    $head = New-Object System.Windows.Controls.DockPanel
    $head.Margin = New-Object System.Windows.Thickness(0, 0, 0, 4)
    if ($Pill) {
        [System.Windows.Controls.DockPanel]::SetDock($Pill, [System.Windows.Controls.Dock]::Right)
        [void]$head.Children.Add($Pill)
    }
    [void]$head.Children.Add((New-UiText -Text $Title -Color "#FFFFFF" -Size 13.5 -Bold))
    [void]$body.Children.Add($head)
    $card.Child = $body
    [void]$Panel.Children.Add($card)
    return $body
}

function Add-GuideCard {
    param($Panel, [string]$Title, [string[]]$Lines, [string]$Detail = "")
    $body = Add-UiCard -Panel $Panel -Title $Title
    foreach ($line in $Lines) { [void]$body.Children.Add((New-UiText -Text $line -Margin "0,3,0,0")) }
    if ($Detail) { [void]$body.Children.Add((New-UiText -Text $Detail -Color "#9CA3AF" -Size 11.5 -Mono -Margin "0,8,0,0")) }
}

function Show-AboutInfoWindow {
    [xml]$InfoXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Guide - ZeroHook"
        Height="720" Width="940" MinHeight="480" MinWidth="700"
        WindowStartupLocation="CenterOwner"
        Background="#131316" Foreground="#E4E4E7"
        FontFamily="Segoe UI" UseLayoutRounding="True">
    <Window.Resources>
$ThemeResources
    </Window.Resources>
    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <TabControl Grid.Row="0" Background="Transparent" BorderThickness="0" Padding="0">
            <TabItem Header="How it works">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="0,12,0,0">
                    <StackPanel x:Name="HowPanel"/>
                </ScrollViewer>
            </TabItem>
            <TabItem Header="What gets blocked">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="0,12,0,0">
                    <StackPanel x:Name="BlockPanel"/>
                </ScrollViewer>
            </TabItem>
            <TabItem Header="Tips &amp; files">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="0,12,0,0">
                    <StackPanel x:Name="TipsPanel"/>
                </ScrollViewer>
            </TabItem>
        </TabControl>
        <Button x:Name="BtnCloseInfo" Grid.Row="1" Content="Close" HorizontalAlignment="Right" Margin="0,10,0,0" Padding="22,4"/>
    </Grid>
</Window>
"@
    $InfoWin = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $InfoXaml))
    $InfoWin.Owner = $Window
    Enable-DarkTitleBar $InfoWin
    if ($ZeroHookLogo) { $InfoWin.Icon = $ZeroHookLogo }

    $how = $InfoWin.FindName("HowPanel")
    Add-GuideCard $how "Quick start" @(
        "1. Optional: open Exclusions List and check anything you want to keep, for example your RGB or controller software.",
        "2. Click Block Overlay Hooks Only (overlays, Vulkan layers, Game Bar) or Block Everything (also services, startup apps and tasks).",
        "3. Turn Auto-Run on to repeat your blocks 60 seconds after each logon. App updates and Steam launches can undo them."
    )
    Add-GuideCard $how "The buttons" @(
        "Block Everything - blocks every matched item that is not excluded.",
        "Block Overlay Hooks Only - leaves services, startup apps and tasks alone.",
        "Exclusions List - items that are never blocked. Saving also restores newly excluded items.",
        "Restore Selected - restores only the items you check. Auto-Run blocks them again unless you exclude them.",
        "Restore Everything - restores all matched items and turns Auto-Run off.",
        "Overlay DLL Status - shows, per app, which overlay DLLs were found, blocked or not found."
    )
    Add-GuideCard $how "What blocking changes" @(
        "Overlay DLLs: adds a Deny (Read and Execute) permission for Everyone. No file is deleted or edited.",
        "Vulkan layers: marks the layer as disabled in the registry.",
        "Xbox Game Bar / DVR: turns off background capture. Windows Game Mode is not touched.",
        "Services: switches them to Manual start and stops them.",
        "Startup entries: disables them the same way Task Manager does. Startup shortcuts are moved to a backup folder.",
        "Scheduled tasks: disables matching non-Microsoft tasks."
    )
    Add-GuideCard $how "Before you restore" @(
        "Restoring puts items back to enabled: services return to Automatic start, and startup entries and tasks are switched on, even if they were already off before you used ZeroHook."
    )
    Add-GuideCard $how "Live DLL Hooks tab" @(
        "Pick a running game, lock onto the foreground window, or tick Auto-attach to games, to see which overlay and hook DLLs are loaded in it. Works for 32-bit and 64-bit games.",
        "Each hook DLL shows its state on disk: NOT BLOCKED (click [Block] to block it now), BLOCKED ON DISK (it was loaded before the block; restart the game) or EXCLUDED.",
        "The log sorts what it finds into three parts: Overlays & Capture (red), Mods & Third-Party DLLs (yellow), and Game Components - upscalers like DLSS, FSR and XeSS and the DirectX 12 runtime that the game itself ships. Game components are normal and need no action.",
        "Paths inside the game's install folder are shown as <game>\...; the full paths are in Save Report and Copy Log for Dev.",
        "Other Third-Party DLLs lists DLLs that come from outside the game and Windows folders and are not signed by Microsoft or the game's publisher, such as antivirus or recording tools.",
        "Real-Time Watch also catches DLLs that load and unload between checks, and marks DLLs that loaded after the game started.",
        "Games protected by anti-cheat (Easy Anti-Cheat, BattlEye, Vanguard...) usually hide their DLL list. ZeroHook says so; blocks from the first tab still apply."
    )

    $block = $InfoWin.FindName("BlockPanel")
    $overlayLines = @($OverlayApps | ForEach-Object { "$($_.Name):  $($_.Files -join ', ')" })
    Add-GuideCard $block "Overlay and hook DLLs ($($TargetDLLs.Count) file names)" $overlayLines
    $listed = @($OverlayApps | ForEach-Object { $_.Files })
    $others = @($TargetDLLs | Where-Object { $listed -notcontains $_ })
    if ($others.Count -gt 0) { Add-GuideCard $block "Other hook DLLs" @($others -join ", ") }
    Add-GuideCard $block "Vulkan implicit layers" @("Layers whose name contains: $($BlockedLayerKeywords -join ', ')") -Detail ($VulkanKeys -join "`n")
    Add-GuideCard $block "Services ($($TargetServicePatterns.Count) name patterns)" @(($TargetServicePatterns -join ", "), "LEDKeeper2_Host is always skipped.")
    Add-GuideCard $block "Startup entries, shortcuts and tasks" @("Names containing: $($StartupUtilityKeywords -join ', ')", "Short words ($($WholeWordStartupKeywords -join ', ')) only match as whole words.")
    Add-GuideCard $block "Background processes (listed only, never closed)" @($LauncherProcesses -join ", ")

    $tips = $InfoWin.FindName("TipsPanel")
    Add-GuideCard $tips "Steam client settings worth turning off" @(
        "Settings > Interface > Advanced (needs a Steam restart):",
        "- Enable smooth scrolling in web views",
        "- Enable GPU accelerated rendering in web views",
        "- Enable hardware video decoding, if supported",
        "Steam re-enables its Vulkan layers on every launch. Keep Steam auto-start and ZeroHook Auto-Run on so they are disabled again after logon."
    )
    Add-GuideCard $tips "Logs and bug reports" @(
        "Save Report writes a bug report file for GS with user and computer names masked. Attach it in Discord or email; a pasted report is usually too long for one message.",
        "Copy Log for Dev copies the same report to the clipboard.",
        "Debug Mode adds detailed logging for $DebugModeHours hours, including the Auto-Run task at the next logon, then switches itself off. Turn it on, reproduce the problem, then click Save Report."
    ) -Detail "%LOCALAPPDATA%\ZeroHook\Logs\zerohook-current.log`n%LOCALAPPDATA%\ZeroHook\Logs\zerohook-autoblock.log`n%LOCALAPPDATA%\ZeroHook\Logs\zerohook-report-*.txt`n%LOCALAPPDATA%\ZeroHook\exclusions.json"
    Update-SearchPaths
    Add-GuideCard $tips "Folders searched for DLLs" @("Steam libraries are detected automatically. Apps installed in other custom folders may be missed.") `
        -Detail (($Script:SearchPaths | ForEach-Object { Hide-Username $_ }) -join "`n")

    $InfoWin.FindName("BtnCloseInfo").Add_Click({ $InfoWin.Close() })
    $InfoWin.ShowDialog() | Out-Null
}

# Fills the overlay status list from the last scan
function Update-OverlayStatusPanel {
    param($Panel, $Summary)
    $Panel.Children.Clear()
    Update-SearchPaths
    $dlls = @($Script:ScanData.Dlls)
    $excludedIds = @(Get-SavedExclusions)

    $rows = foreach ($app in $OverlayApps) {
        $found = @($dlls | Where-Object {
            $byName = $app.Files -contains $_.Name
            $generic = $app.Generic -and ($app.Generic -contains $_.Name)
            # overlay*.dll is a common name: it only counts for the app whose folder it is in
            if ($app.PathMatch -and ($_.Name -like "overlay*.dll")) { ($byName -or $generic) -and ($_.FullName -match $app.PathMatch) }
            else { $byName }
        })
        $folders = @($app.Folders)
        if ($app.Name -eq "Steam") { $folders += @($Script:SearchPaths | Where-Object { $_ -match 'steam' }) }
        if ($app.Name -eq "GOG Galaxy") { $folders += @($Script:SearchPaths | Where-Object { $_ -match 'GOG' }) }
        $installed = @($folders | Where-Object { Test-Path -LiteralPath $_ }).Count -gt 0
        $rank = if ($found.Count -gt 0) { 0 } elseif ($installed) { 1 } else { 2 }
        [PSCustomObject]@{ App = $app; Found = $found; Installed = $installed; Rank = $rank }
    }

    foreach ($row in @($rows | Sort-Object Rank, { $_.App.Name })) {
        $files = @($row.Found | Sort-Object FullName | ForEach-Object {
            $state = if ($_.IsBlocked) { "BLOCKED" } elseif (Test-ItemExcluded -Id "DLL|$($_.FullName)" -ExcludedIds $excludedIds) { "EXCLUDED" } else { "ACTIVE" }
            [PSCustomObject]@{ State = $state; Path = (Hide-Username $_.FullName) }
        })
        $blocked = @($files | Where-Object { $_.State -eq "BLOCKED" }).Count
        $active = @($files | Where-Object { $_.State -eq "ACTIVE" }).Count

        if ($files.Count -eq 0 -and $row.Installed) { $pill = New-UiPill "NO DLL FOUND" "#3A3115" $BrushYellow }
        elseif ($files.Count -eq 0)                 { $pill = New-UiPill "APP NOT FOUND" "#2A2A30" "#9CA3AF" }
        elseif ($blocked -eq $files.Count)          { $pill = New-UiPill "BLOCKED $blocked/$($files.Count)" "#14351F" $BrushGreen }
        elseif ($active -gt 0 -and $blocked -gt 0)  { $pill = New-UiPill "BLOCKED $blocked/$($files.Count)" "#3A3115" $BrushYellow }
        elseif ($active -gt 0)                      { $pill = New-UiPill "ACTIVE" "#3A1D1D" $BrushRed }
        else                                        { $pill = New-UiPill "KEPT (EXCLUDED)" "#3A3115" $BrushYellow }

        $body = Add-UiCard -Panel $Panel -Title $row.App.Name -Pill $pill
        foreach ($f in $files) {
            $color = switch ($f.State) { "BLOCKED" { $BrushGreen } "EXCLUDED" { $BrushYellow } default { $BrushRed } }
            $line = New-Object System.Windows.Controls.DockPanel
            $line.Margin = New-Object System.Windows.Thickness(0, 3, 0, 0)
            $tag = New-UiText -Text $f.State -Color $color -Size 11 -Bold -Mono
            $tag.Width = 72
            [void]$line.Children.Add($tag)
            [void]$line.Children.Add((New-UiText -Text $f.Path -Size 11.5 -Mono))
            [void]$body.Children.Add($line)
        }

        if ($files.Count -eq 0) {
            $why = if ($row.Installed) { "The app folder exists, but none of these files were found: " } else { "Nothing found in the folders ZeroHook searches. Looks for: " }
            [void]$body.Children.Add((New-UiText -Text ($why + ($row.App.Files -join ", ")) -Color "#9CA3AF" -Size 11.5 -Margin "0,2,0,0"))
        } else {
            $foundNames = @($row.Found | ForEach-Object { $_.Name })
            $missing = @($row.App.Files | Where-Object { $foundNames -notcontains $_ })
            if ($missing.Count -gt 0) {
                [void]$body.Children.Add((New-UiText -Text "Not found: $($missing -join ', ')" -Color "#9CA3AF" -Size 11.5 -Margin "0,6,0,0"))
            }
        }
    }

    $withDlls = @($rows | Where-Object { $_.Found.Count -gt 0 }).Count
    $noDll = @($rows | Where-Object { $_.Rank -eq 1 } | ForEach-Object { $_.App.Name })
    $text = "Overlay DLLs found for $withDlls of $($OverlayApps.Count) apps."
    if ($noDll.Count -gt 0) { $text += " Installed but no DLL found: $($noDll -join ', ')." }
    $Summary.Text = $text
    Write-DiagnosticLog -Level "INFO" -Source "UI" -Message "Overlay DLL status: $text"
}

function Show-OverlayStatusWindow {
    [xml]$StatusXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Overlay DLL Status - ZeroHook"
        Height="720" Width="900" MinHeight="460" MinWidth="680"
        WindowStartupLocation="CenterOwner"
        Background="#131316" Foreground="#E4E4E7"
        FontFamily="Segoe UI" UseLayoutRounding="True">
    <Window.Resources>
$ThemeResources
    </Window.Resources>
    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,12">
            <TextBlock Text="Overlay DLL status" FontSize="17" FontWeight="Bold" Foreground="#FFFFFF"/>
            <TextBlock x:Name="TxtStatusSummary" FontSize="12" Foreground="{StaticResource Muted}" Margin="0,3,0,0" TextWrapping="Wrap"/>
        </StackPanel>
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel x:Name="StatusPanel"/>
        </ScrollViewer>
        <DockPanel Grid.Row="2" Margin="0,10,0,0">
            <Button x:Name="BtnStatusClose" DockPanel.Dock="Right" Content="Close" Padding="22,4"/>
            <Button x:Name="BtnStatusRescan" DockPanel.Dock="Right" Content="Rescan" Margin="0,0,8,0" Padding="18,4"/>
            <TextBlock Text="Apps usually ship only some of the listed names, so a few 'Not found' files are normal." FontSize="11.5"
                       Foreground="{StaticResource Muted}" VerticalAlignment="Center" TextWrapping="Wrap" Margin="0,0,12,0"/>
        </DockPanel>
    </Grid>
</Window>
"@
    $win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $StatusXaml))
    $win.Owner = $Window
    Enable-DarkTitleBar $win
    if ($ZeroHookLogo) { $win.Icon = $ZeroHookLogo }
    $statusPanel = $win.FindName("StatusPanel")
    $statusSummary = $win.FindName("TxtStatusSummary")

    if ($Script:ScanData.Count -eq 0 -or ([DateTime]::UtcNow - $Script:ScanData.Time).TotalSeconds -gt 30) {
        Update-Dashboard -Filter "NONE"
    }
    Update-OverlayStatusPanel -Panel $statusPanel -Summary $statusSummary

    $win.FindName("BtnStatusRescan").Add_Click({
        Update-Dashboard -Filter "NONE"
        Update-OverlayStatusPanel -Panel $statusPanel -Summary $statusSummary
    })
    $win.FindName("BtnStatusClose").Add_Click({ $win.Close() })
    $win.ShowDialog() | Out-Null
}

function Invoke-RestoreTargets {
    param([object[]]$Targets, [string]$FailBadge = "FAILED RESTORE")
    foreach ($t in $Targets) {
        try {
            if (Set-TargetRestored -Target $t) {
                Add-Log -Badge "[$($RestoreBadges[$t.Kind])][$($t.App)] " -Message $t.LogName -BadgeColor "Green" -NoScroll
            } else {
                Add-Log -Badge "[ALREADY DEFAULT][$($t.App)] " -Message $t.LogName -BadgeColor "Cyan" -NoScroll
            }
        } catch {
            $errCtx = Write-DiagnosticError -Source "RESTORE" -Context "Restore $($t.Kind)" -Target $t.DetailText -ErrorRecord $_
            Add-Log -Badge "[$FailBadge][$($t.App)] " -Message "$($t.LogName) - $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoScroll -NoDiag
        }
    }
}

# Shared checklist window for "Restore Selected" and "Exclusions List".
# Returns $null when cancelled, otherwise the checked items (possibly an empty array).
function Show-ItemPicker {
    param(
        [object[]]$Candidates,
        [string]$Title,
        [string]$Heading,
        [string]$Description,
        [string]$ConfirmLabel,
        [string]$ConfirmColor,
        [string]$CheckedWord,
        [object[]]$Presets,
        [switch]$PrecheckExcluded
    )
    [xml]$PickerXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Height="760" Width="1040" MinHeight="500" MinWidth="760"
        WindowStartupLocation="CenterOwner"
        Background="#131316" Foreground="#E4E4E7"
        FontFamily="Segoe UI" UseLayoutRounding="True">
    <Window.Resources>
$ThemeResources
    </Window.Resources>
    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,12">
            <TextBlock x:Name="TxtHeading" FontSize="17" FontWeight="Bold" Foreground="#FFFFFF"/>
            <TextBlock x:Name="TxtDescription" FontSize="12" Foreground="{StaticResource Muted}" Margin="0,3,0,0" TextWrapping="Wrap"/>
        </StackPanel>
        <DockPanel Grid.Row="1" Margin="0,0,0,8">
            <Button x:Name="BtnUncheckVisible" DockPanel.Dock="Right" Content="Uncheck Visible" Margin="8,0,0,0"/>
            <Button x:Name="BtnCheckVisible" DockPanel.Dock="Right" Content="Check Visible" Margin="8,0,0,0"/>
            <TextBlock Text="Search" Foreground="{StaticResource Muted}" VerticalAlignment="Center" Margin="0,0,8,0"/>
            <TextBox x:Name="TxtFilterBox" Height="30" FontSize="12"/>
        </DockPanel>
        <WrapPanel x:Name="PresetPanel" Grid.Row="2" Margin="0,0,0,10">
            <TextBlock Text="Quick select" Foreground="{StaticResource Muted}" VerticalAlignment="Center" Margin="0,0,8,0"/>
        </WrapPanel>
        <Border Grid.Row="3" Background="#1C1C21" BorderBrush="#2C2C33" BorderThickness="1" CornerRadius="10" Padding="8">
            <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                <StackPanel x:Name="ItemsPanel"/>
            </ScrollViewer>
        </Border>
        <DockPanel Grid.Row="4" Margin="0,12,0,0">
            <Button x:Name="BtnCancel" DockPanel.Dock="Right" Content="Cancel" Height="34" Padding="18,4"/>
            <Button x:Name="BtnConfirm" DockPanel.Dock="Right" Height="34" Padding="18,4" Margin="0,0,8,0"/>
            <TextBlock x:Name="TxtPickCount" Foreground="{StaticResource Muted}" VerticalAlignment="Center"/>
        </DockPanel>
    </Grid>
</Window>
"@
    $picker = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $PickerXaml))
    $picker.Owner = $Window
    $picker.Title = $Title
    if ($ZeroHookLogo) { $picker.Icon = $ZeroHookLogo }
    Enable-DarkTitleBar $picker

    $picker.FindName("TxtHeading").Text = $Heading
    $picker.FindName("TxtDescription").Text = $Description
    $filterBox    = $picker.FindName("TxtFilterBox")
    $presetPanel  = $picker.FindName("PresetPanel")
    $itemsPanel   = $picker.FindName("ItemsPanel")
    $countText    = $picker.FindName("TxtPickCount")
    $btnConfirm   = $picker.FindName("BtnConfirm")
    $btnConfirm.Content = $ConfirmLabel
    $btnConfirm.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($ConfirmColor)

    $entries = [System.Collections.Generic.List[object]]::new()
    $groups  = [System.Collections.Generic.List[object]]::new()

    $updateState = {
        $checked = @($entries | Where-Object { $_.CheckBox.IsChecked }).Count
        $blocked = @($entries | Where-Object { $_.Candidate.IsBlocked }).Count
        $countText.Text = "$checked $CheckedWord  |  $blocked currently blocked  |  $($entries.Count) total"
        foreach ($g in $groups) {
            $on = @($g.Entries | Where-Object { $_.CheckBox.IsChecked }).Count
            $g.Toggle.IsChecked = if ($on -eq 0) { $false } elseif ($on -eq $g.Entries.Count) { $true } else { $null }
        }
    }

    foreach ($group in @($Candidates | Group-Object App | Sort-Object Name)) {
        $toggle = New-Object System.Windows.Controls.CheckBox
        $toggle.Margin = New-Object System.Windows.Thickness(0, 8, 0, 2)
        $header = New-Object System.Windows.Controls.TextBlock
        $header.Text = "$($group.Name)  ($($group.Count))"
        $header.Foreground = $BrushCyan
        $header.FontWeight = [System.Windows.FontWeights]::Bold
        $header.FontSize = 12.5
        $toggle.Content = $header
        [void]$itemsPanel.Children.Add($toggle)

        $groupEntries = [System.Collections.Generic.List[object]]::new()
        foreach ($c in $group.Group) {
            $row = New-Object System.Windows.Controls.DockPanel

            $pill = New-Object System.Windows.Controls.Border
            $pill.CornerRadius = New-Object System.Windows.CornerRadius(4)
            $pill.Padding = New-Object System.Windows.Thickness(0, 1, 0, 1)
            $pill.Margin = New-Object System.Windows.Thickness(0, 0, 10, 0)
            $pill.Width = 68
            $pill.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $pill.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($(if ($c.IsBlocked) { "#14351F" } else { "#3A1D1D" }))
            $pillText = New-Object System.Windows.Controls.TextBlock
            $pillText.Text = if ($c.IsBlocked) { "BLOCKED" } else { "ACTIVE" }
            $pillText.Foreground = if ($c.IsBlocked) { $BrushGreen } else { $BrushRed }
            $pillText.FontSize = 10
            $pillText.FontWeight = [System.Windows.FontWeights]::Bold
            $pillText.TextAlignment = [System.Windows.TextAlignment]::Center
            $pill.Child = $pillText
            [System.Windows.Controls.DockPanel]::SetDock($pill, [System.Windows.Controls.Dock]::Left)
            [void]$row.Children.Add($pill)

            $detail = New-Object System.Windows.Controls.TextBlock
            $detail.Text = $c.DetailText
            $detail.TextWrapping = [System.Windows.TextWrapping]::Wrap
            $detail.FontFamily = New-Object System.Windows.Media.FontFamily("Consolas")
            $detail.FontSize = 12
            $detail.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            [void]$row.Children.Add($detail)

            $box = New-Object System.Windows.Controls.CheckBox
            $box.Content = $row
            $box.Margin = New-Object System.Windows.Thickness(22, 0, 0, 0)
            $box.IsChecked = [bool]($PrecheckExcluded -and $c.IsExcluded)
            [void]$itemsPanel.Children.Add($box)

            $state = if ($c.IsBlocked) { "blocked" } else { "active" }
            $entry = [PSCustomObject]@{ CheckBox = $box; Candidate = $c; SearchText = "$($group.Name) $($c.DetailText) $state".ToLowerInvariant() }
            [void]$entries.Add($entry)
            [void]$groupEntries.Add($entry)
            $box.Add_Click({ & $updateState })
        }

        $groupInfo = [PSCustomObject]@{ Toggle = $toggle; Entries = $groupEntries }
        [void]$groups.Add($groupInfo)
        $toggle.Tag = $groupInfo
        # Group box: check all visible items, or uncheck them if they are all checked already
        $toggle.Add_Click({
            param($clicked)
            $visible = @($clicked.Tag.Entries | Where-Object { $_.CheckBox.Visibility -eq [System.Windows.Visibility]::Visible })
            $target = @($visible | Where-Object { -not $_.CheckBox.IsChecked }).Count -gt 0
            foreach ($entry in $visible) { $entry.CheckBox.IsChecked = $target }
            & $updateState
        })
    }

    # Applies a check state to every visible item matching the filter
    $setVisible = {
        param([bool]$Value, [scriptblock]$Match)
        foreach ($entry in $entries) {
            if ($entry.CheckBox.Visibility -ne [System.Windows.Visibility]::Visible) { continue }
            if ($Match -and -not (& $Match $entry.Candidate)) { continue }
            $entry.CheckBox.IsChecked = $Value
        }
        & $updateState
    }

    foreach ($preset in $Presets) {
        $button = New-Object System.Windows.Controls.Button
        $button.Content = $preset.Label
        $button.Tag = $preset.Match
        $button.Margin = New-Object System.Windows.Thickness(0, 0, 8, 0)
        $button.Add_Click({ param($clicked) & $setVisible $true $clicked.Tag })
        [void]$presetPanel.Children.Add($button)
    }

    $picker.FindName("BtnCheckVisible").Add_Click({ & $setVisible $true $null })
    $picker.FindName("BtnUncheckVisible").Add_Click({ & $setVisible $false $null })
    $filterBox.Add_TextChanged({
        $query = ([string]$filterBox.Text).Trim().ToLowerInvariant()
        foreach ($g in $groups) {
            $any = $false
            foreach ($entry in $g.Entries) {
                $match = (-not $query) -or $entry.SearchText.Contains($query)
                $entry.CheckBox.Visibility = if ($match) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
                if ($match) { $any = $true }
            }
            $g.Toggle.Visibility = if ($any) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
        }
    })
    $btnConfirm.Add_Click({ $picker.DialogResult = $true })
    $picker.FindName("BtnCancel").Add_Click({ $picker.DialogResult = $false })

    & $updateState
    if ($picker.ShowDialog() -ne $true) { return $null }
    $result = @($entries | Where-Object { $_.CheckBox.IsChecked } | ForEach-Object { $_.Candidate })
    return , $result
}

function Show-SelectiveRestoreDialog {
    $presets = @(
        @{ Label = "Currently blocked";           Match = { param($c) $c.IsBlocked } },
        @{ Label = "DLL hooks, Vulkan, Game Bar"; Match = { param($c) $c.Kind -in @("DLL", "VULKAN", "GAMEBAR") } },
        @{ Label = "Services, startup, tasks";    Match = { param($c) $c.Kind -in @("SVC", "RUN", "SHORTCUT", "TASK") } }
    )
    $selected = Show-ItemPicker -Candidates @(Get-BlockTargets) -Presets $presets `
        -Title "Restore Selected - ZeroHook" -Heading "Restore selected items" `
        -Description "Check the items you want to return to their default state, then click Restore Selected." `
        -ConfirmLabel "Restore Selected" -ConfirmColor "#B91C1C" -CheckedWord "selected to restore"

    if ($null -eq $selected) {
        Write-DiagnosticLog -Level "DEBUG" -Source "RESTORE" -Message "Selective restore dialog cancelled without changes."
        return
    }
    if ($selected.Count -eq 0) {
        Write-DiagnosticLog -Level "INFO" -Source "RESTORE" -Message "Selective restore confirmed with 0 items selected."
        return
    }

    Write-DiagnosticLog -Level "INFO" -Source "RESTORE" -Message "Restoring $($selected.Count) selected item(s) to default state." -ForceTrim
    Clear-Log "ACTIVITY LOG - RESTORING SELECTED ITEMS"
    Add-Log -Badge "[SELECTIVE RESTORE] " -Message "Restoring $($selected.Count) selected item(s) to default state..." -BadgeColor "Cyan" -NoScroll
    Invoke-RestoreTargets -Targets $selected
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Add-Log -Badge "`n[IMPORTANT] " -Message "Auto-Run is ON: restored items are blocked again at next logon unless you also add them to the Exclusions List." -BadgeColor "Yellow" -MsgColor "Yellow" -NoScroll
    }
    Add-Log -Badge "`n=== SELECTIVE RESTORE COMPLETE ===" -BadgeColor "Cyan"
    Update-Dashboard -Filter "NONE"
}

function Show-ExclusionsDialog {
    $previousIds = @(Get-SavedExclusions)
    $candidates = @(Get-BlockTargets -ExcludedIds $previousIds)
    $rgbApps = @("MSI", "ASUS", "CORSAIR", "GIGABYTE", "ASROCK", "NZXT", "LOGITECH", "KINGSTON", "STEELSERIES", "OPENRGB / SIGNALRGB", "RAZER")
    $presets = @(
        @{ Label = "RGB control";          Match = { param($c) $c.App -in $rgbApps } },
        @{ Label = "Controller / gamepad"; Match = { param($c) $c.App -eq "SONY / DUALSENSE" } }
    )
    $excluded = Show-ItemPicker -Candidates $candidates -Presets $presets -PrecheckExcluded `
        -Title "Exclusions List - ZeroHook" -Heading "Exclusions list" `
        -Description "Checked items are never blocked. Saving restores any newly checked item that is currently blocked. Unchecked items are blocked again the next time you run a Block action." `
        -ConfirmLabel "Save Exclusions" -ConfirmColor "#15803D" -CheckedWord "excluded"

    if ($null -eq $excluded) {
        Write-DiagnosticLog -Level "DEBUG" -Source "EXCLUSIONS" -Message "Exclusions dialog cancelled without changes."
        return
    }

    # Keep exclusions for items that are not present right now (app being updated or uninstalled), but drop
    # old DLL entries that were recorded through a folder link: they duplicate the real file.
    $listedKeys = @($candidates | ForEach-Object { Get-ExclusionKey $_.Id })
    $unlistedIds = @($previousIds | Where-Object {
        ($listedKeys -notcontains (Get-ExclusionKey $_)) -and
        -not ($_ -like "DLL|*" -and (Test-PathThroughLink $_.Substring(4)))
    })
    $excludedIds = @($excluded | ForEach-Object { [string]$_.Id })
    Save-Exclusions -Ids (@($excludedIds) + @($unlistedIds))

    # Restore newly excluded items that are blocked. A blocked DLL is always ZeroHook's doing, so an
    # excluded DLL is restored even if it was already on the list.
    $toRestore = @($excluded | Where-Object { $_.IsBlocked -and ((-not $_.IsExcluded) -or $_.Kind -eq "DLL") })
    $released = @($candidates | Where-Object { $_.IsExcluded -and ($excludedIds -notcontains $_.Id) -and -not $_.IsBlocked })

    Clear-Log "ACTIVITY LOG - SAVING EXCLUSIONS LIST"
    Add-Log -Badge "[EXCLUSIONS SAVED] " -Message "$($excludedIds.Count) item(s) are excluded from blocking." -BadgeColor "Green" -NoScroll
    Invoke-RestoreTargets -Targets $toRestore -FailBadge "FAILED UNEXCLUDE"
    foreach ($t in $released) {
        Add-Log -Badge "[NO LONGER EXCLUDED][$($t.App)] " -Message "$($t.LogName) - still active; it is blocked on the next Block action." -BadgeColor "Yellow" -NoScroll
    }
    if ($toRestore.Count -eq 0 -and $released.Count -eq 0) {
        Add-Log -Message "No system changes were needed." -MsgColor "Muted" -NoScroll
    }
    Add-Log -Badge "`n=== EXCLUSIONS UPDATED ===" -BadgeColor "Cyan"
    Update-Dashboard -Filter "NONE"
}

# Details shown when the Startup Auto-Block card is clicked
function Show-TaskStatus {
    Clear-Log "STARTUP AUTO-BLOCK - SCHEDULED TASK STATUS"
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Update-AutoRunToggleButton -ExistingTask $task
    $line = {
        param([string]$Label, [string]$Value, [string]$Color = "Gray")
        Add-Log -Badge ("  " + $Label.PadRight(18)) -Message $Value -BadgeColor "Muted" -MsgColor $Color -NoScroll -NoDiag
    }
    Write-DiagnosticLog -Level "INFO" -Source "UI" -Message "Showing scheduled task status."

    if (-not $task) {
        $TxtCardTaskStatus.Text = "NOT SET"
        $TxtCardTaskStatus.Foreground = $BrushYellow
        & $line "Task" "$TaskName is not registered." "Yellow"
        & $line "How to enable" "Click 'Auto-Run: OFF' above to run your blocks 60s after logon."
        return
    }
    $TxtCardTaskStatus.Text = "ENABLED ($($task.State))"
    $TxtCardTaskStatus.Foreground = $BrushGreen

    try {
        $info = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction Stop
        $trigger = $task.Triggers | Select-Object -First 1
        $action = $task.Actions | Select-Object -First 1
        $neverRun = (-not $info.LastRunTime) -or $info.LastRunTime.Year -lt 2000
        $result = [int64]$info.LastTaskResult
        $resultText = switch ($result) {
            0          { "Success (0)" }
            267009     { "Currently running" }
            267011     { "Has not run yet" }
            267014     { "Stopped by user" }
            1          { "Run failed (see Last AutoBlock below / zerohook-autoblock.log)" }
            2          { "Finished, but some items could not be blocked (see zerohook-autoblock.log)" }
            2147942402 { "Program file not found" }
            default    { "Error code 0x{0:X}" -f $result }
        }
        $resultColor = if ($result -eq 0) { "Green" } elseif ($result -in @(267009, 267011)) { "Gray" } else { "Red" }

        & $line "Task" $TaskName
        & $line "State" "$($task.State)" $(if ("$($task.State)" -eq "Disabled") { "Red" } else { "Green" })
        & $line "Last run" $(if ($neverRun) { "Never" } else { $info.LastRunTime.ToString("yyyy-MM-dd HH:mm:ss") })
        & $line "Last result" $resultText $resultColor
        & $line "Trigger" "At logon$(if ($trigger.UserId) { " of $($trigger.UserId -replace '^.*\\', '' -replace [regex]::Escape($env:USERNAME), '%USERNAME%')" }), delay $(if ($trigger.Delay -eq 'PT60S' -or $trigger.Delay -eq 'PT1M') { '60 seconds' } else { $trigger.Delay })"
        & $line "Run level" "$($task.Principal.RunLevel) privileges"
        & $line "Program" (Hide-Username ([string]$action.Execute))
        & $line "Arguments" (Hide-Username ([string]$action.Arguments))

        $targetFile = if ([string]$action.Arguments -match '-File\s+"([^"]+)"') { $matches[1] } else { ([string]$action.Execute).Trim('"') }
        $targetExists = Test-Path -LiteralPath $targetFile
        & $line "Target file" $(if ($targetExists) { "Found" } else { "MISSING - turn Auto-Run off and on again" }) $(if ($targetExists) { "Green" } else { "Red" })
    } catch {
        $errCtx = Write-DiagnosticError -Source "TASK" -Context "Read task details" -Target $TaskName -ErrorRecord $_
        & $line "Error" $errCtx "Red"
    }

    & $line "Exclusions" "$(@(Get-SavedExclusions).Count) item(s) skipped by the task"
    & $line "Last AutoBlock" (Get-LastAutoBlockRun -MaxLines 1).Summary
    & $line "Run log" (Hide-Username $AutoBlockLogFile)
    & $line "Debug mode" (Get-DebugStateText)
    $LogBox.ScrollToHome()
}

# Per-app summary: which apps were shown expanded or collapsed by the user ([+]/[-] in the app header)
$Script:LogAppExpanded = New-Object 'System.Collections.Hashtable' ([System.StringComparer]::OrdinalIgnoreCase)
$Script:LastPerAppRender = $null
$Script:LastLogToggleApp = ""
$Script:LastLogToggleTime = [DateTime]::MinValue

function New-LogAppToggleLink {
    param([string]$App, [switch]$Expanded)
    $link = New-Object System.Windows.Documents.Hyperlink
    $link.Tag = $App
    $link.TextDecorations = $null
    $link.Foreground = $BrushCyan
    $link.FontWeight = [System.Windows.FontWeights]::Bold
    $link.Cursor = [System.Windows.Input.Cursors]::Hand
    [void]$link.Inlines.Add((New-Object System.Windows.Documents.Run($(if ($Expanded) { "[-] " } else { "[+] " }))))
    $onClick = {
        param($linkSender, $e)
        $e.Handled = $true
        $app = [string]$linkSender.Tag
        # Both events below can fire for one click; act once
        $now = [DateTime]::UtcNow
        if ($Script:LastLogToggleApp -eq $app -and ($now - $Script:LastLogToggleTime).TotalMilliseconds -lt 400) { return }
        $Script:LastLogToggleApp = $app
        $Script:LastLogToggleTime = $now
        Invoke-UiAction "Toggle app in log" { Invoke-ToggleLogApp -App $app }
    }
    $link.Add_Click($onClick)
    $link.Add_MouseLeftButtonDown($onClick)
    return $link
}

function Invoke-ToggleLogApp {
    param([string]$App)
    $r = $Script:LastPerAppRender
    if (-not $r -or [string]::IsNullOrWhiteSpace($App)) { return }
    $current = if ($r.Expanded.ContainsKey($App)) { [bool]$r.Expanded[$App] } else { $true }
    $Script:LogAppExpanded[$App] = -not $current
    # Keep the scroll position so the log does not jump to the end after a click
    $box = $LogBox
    $offset = $LogBox.VerticalOffset
    Render-PerAppSummary -AppFilter $r.AppFilter -CategoryFilter $r.CategoryFilter -KeepScroll
    # Runs after the new lines are laid out; the closure keeps $box and $offset
    $null = $box.Dispatcher.BeginInvoke([Action]({ $box.ScrollToVerticalOffset($offset) }.GetNewClosure()), [System.Windows.Threading.DispatcherPriority]::Background)
}

# "GameOverlayRenderer.dll, GameOverlayRenderer64.dll" -> "GameOverlayRenderer(64).dll"
function Join-CompactFileNames {
    param([string[]]$Names)
    $groups = [ordered]@{}
    foreach ($n in $Names) {
        $ext = [IO.Path]::GetExtension($n)
        $stem = $n.Substring(0, $n.Length - $ext.Length)
        $suffix = ""
        if ($stem -match '^(.+?)(32|64)$') { $stem = $Matches[1]; $suffix = $Matches[2] }
        $key = "$stem|$ext"
        if (-not $groups.Contains($key)) { $groups[$key] = [System.Collections.Generic.List[string]]::new() }
        [void]$groups[$key].Add($suffix)
    }
    $out = foreach ($key in $groups.Keys) {
        $parts = $key.Split('|', 2)
        $sfx = @($groups[$key] | Sort-Object -Unique)
        if ($sfx.Count -eq 1) { "$($parts[0])$($sfx[0])$($parts[1])" }
        else { "$($parts[0])($((@($sfx | Where-Object { $_ })) -join '/'))$($parts[1])" }
    }
    return (@($out) -join ", ")
}

# Kind order and labels for the per-app summary lines
$LogKindInfo = [ordered]@{
    DLL      = @{ One = "DLL";              Many = "DLLs" }
    VULKAN   = @{ One = "Vulkan layer";     Many = "Vulkan layers" }
    GAMEBAR  = @{ One = "Game Bar";         Many = "Game Bar" }
    SERVICE  = @{ One = "Service";          Many = "Services" }
    RUN      = @{ One = "Startup entry";    Many = "Startup entries" }
    SHORTCUT = @{ One = "Startup shortcut"; Many = "Startup shortcuts" }
    TASK     = @{ One = "Scheduled task";   Many = "Scheduled tasks" }
    PROCESS  = @{ One = "Process";          Many = "Processes" }
}

function Render-PerAppSummary {
    param([string]$AppFilter = "ALL APPS", [string]$CategoryFilter = "ALL", [switch]$ShowSteamTip, [switch]$KeepScroll)
    $D = $Script:ScanData
    if (-not $D -or $D.Count -eq 0) { return }
    $Entries = @()
    # One entry per item. State is the tag shown in the log; Level is Blocked, Active (still on) or Info (running process).
    $newEntry = {
        param($App, $Kind, $Name, $Folder, $State, $Level, $Diag)
        [PSCustomObject]@{ App = $App; Kind = $Kind; Name = $Name; Folder = $Folder; State = $State; Level = $Level; Diag = $Diag }
    }

    if ($CategoryFilter -in @("ALL", "DLLS")) {
        foreach ($File in $D.Dlls) {
            $b = [bool]$File.IsBlocked
            $Entries += & $newEntry (Get-AppGroupName "$($File.Name) $($File.FullName)") "DLL" $File.Name (Hide-Username ([IO.Path]::GetDirectoryName($File.FullName))) `
                $(if ($b) { "BLOCKED" } else { "NOT BLOCKED" }) $(if ($b) { "Blocked" } else { "Active" }) (Hide-Username $File.FullName)
        }
    }
    if ($CategoryFilter -in @("ALL", "VULKAN")) {
        foreach ($Layer in $D.VulkanLayers) {
            $b = [bool]$Layer.IsDisabled
            $Entries += & $newEntry (Get-AppGroupName $Layer.Name) "VULKAN" ([IO.Path]::GetFileName([string]$Layer.Name)) (Hide-Username ([IO.Path]::GetDirectoryName([string]$Layer.Name))) `
                $(if ($b) { "DISABLED" } else { "ENABLED" }) $(if ($b) { "Blocked" } else { "Active" }) (Hide-Username $Layer.Name)
        }
        $b = [bool]$D.GameBarOff
        $Entries += & $newEntry "XBOX / GAME BAR" "GAMEBAR" "Xbox Game Bar & Game DVR" "" `
            $(if ($b) { "DISABLED" } else { "ENABLED" }) $(if ($b) { "Blocked" } else { "Active" }) "Xbox Game Bar & Game DVR"
    }
    if ($CategoryFilter -in @("ALL", "SERVICES")) {
        foreach ($Svc in $D.Services) {
            $b = ($Svc.StartType -eq "Manual" -or $Svc.StartType -eq "Disabled")
            $svcName = if ($Svc.DisplayName -and $Svc.DisplayName -ne $Svc.Name) { "$($Svc.DisplayName) ($($Svc.Name))" } else { [string]$Svc.Name }
            if ("$($Svc.Status)" -eq "Running") { $svcName += " - running" }
            $Entries += & $newEntry (Get-AppGroupName "$($Svc.Name) $($Svc.DisplayName)") "SERVICE" $svcName "" `
                ("$($Svc.StartType)".ToUpper()) $(if ($b) { "Blocked" } else { "Active" }) "$($Svc.DisplayName) ($($Svc.Name)) $($Svc.StartType) ($($Svc.Status))"
        }
    }
    if ($CategoryFilter -in @("ALL", "STARTUP")) {
        foreach ($Item in $D.StartupItems) {
            $b = [bool]$Item.IsDisabled
            $Entries += & $newEntry (Get-AppGroupName "$($Item.Name) $($Item.Command)") "RUN" $Item.Name "" `
                $(if ($b) { "DISABLED" } else { "ENABLED" }) $(if ($b) { "Blocked" } else { "Active" }) "$($Item.Name) ($(Hide-Username $Item.Command))"
        }
        foreach ($Sc in $D.Shortcuts) {
            $b = [bool]$Sc.IsDisabled
            $Entries += & $newEntry (Get-AppGroupName "$($Sc.Name) $($Sc.FullPath)") "SHORTCUT" $Sc.Name (Hide-Username $Sc.OrigFolder) `
                $(if ($b) { "DISABLED" } else { "ENABLED" }) $(if ($b) { "Blocked" } else { "Active" }) "$($Sc.Name) ($(Hide-Username $Sc.OrigFolder))"
        }
        foreach ($Task in $D.VendorTasks) {
            $b = ($Task.State -eq "Disabled")
            $Entries += & $newEntry (Get-AppGroupName "$($Task.TaskPath)$($Task.TaskName)") "TASK" ("$($Task.TaskPath)$($Task.TaskName)".TrimStart('\')) "" `
                $(if ($b) { "DISABLED" } else { "ENABLED" }) $(if ($b) { "Blocked" } else { "Active" }) "$($Task.TaskPath)$($Task.TaskName) [$($Task.State)]"
        }
    }
    if ($CategoryFilter -in @("ALL", "LAUNCHERS")) {
        foreach ($Proc in $D.RunningProcs) {
            $Entries += & $newEntry (Get-AppGroupName $Proc.ProcessName) "PROCESS" $Proc.ProcessName "" "RUNNING" "Info" "$($Proc.ProcessName) (PID $($Proc.Id))"
        }
    }

    if ($AppFilter -ne "ALL APPS") { $Entries = @($Entries | Where-Object { $_.App -eq $AppFilter }) }

    $CatLabel = switch ($CategoryFilter) {
        "DLLS"      { "OVERLAY & HOOK DLLS" }
        "VULKAN"    { "VULKAN & XBOX GAME BAR" }
        "SERVICES"  { "RGB & UTILITY SERVICES" }
        "STARTUP"   { "STARTUP APPS & TASKS" }
        "LAUNCHERS" { "BACKGROUND LAUNCHERS" }
        default     { "ALL ITEMS" }
    }
    $HeaderTitle = "ACTIVITY & SCAN LOG - $AppFilter  [$CatLabel]"
    $TxtLogHeader.Text = $HeaderTitle
    $LogBox.Document.Blocks.Clear()
    $render = [PSCustomObject]@{ AppFilter = $AppFilter; CategoryFilter = $CategoryFilter; Expanded = @{} }
    $Script:LastPerAppRender = $render

    if ($CategoryFilter -eq "ALL" -and $AppFilter -eq "ALL APPS") {
        $TaskStatus = if ($D.Task) { "REGISTERED ($($D.Task.State))" } else { "NOT REGISTERED" }
        Add-Log -Badge "[TASK] " -Message "$TaskName -> $TaskStatus" -BadgeColor $(if ($D.Task) { "Green" } else { "Yellow" }) -NoScroll -NoDiag
        Add-Log -Badge "[STORE GAMES] " -Message "Detected $($D.StoreGamesCount) game folder(s) across Steam, Epic, GOG, EA, Ubisoft, Battle.net, Rockstar & Xbox." -BadgeColor "Cyan" -NoScroll -NoDiag
    }

    if ($Entries.Count -eq 0) {
        Add-Log -Message "`nNo matching items found for '$AppFilter' in [$CatLabel]." -MsgColor "Yellow" -NoScroll -NoDiag
        if ($ShowSteamTip -or ($AppFilter -eq "STEAM")) { Add-SteamClientTipToLog -NoScroll -NoDiag }
        if (-not $KeepScroll) { $LogBox.ScrollToEnd() }
        return
    }

    # Apps with something still active come first, then the rest by name
    $Grouped = @($Entries | Group-Object App | Sort-Object @{ Expression = { @($_.Group | Where-Object { $_.Level -eq "Active" }).Count -eq 0 } }, Name)
    $kindKeys = @($LogKindInfo.Keys)
    foreach ($Grp in $Grouped) {
        $items = @($Grp.Group)
        $blockable = @($items | Where-Object { $_.Level -ne "Info" })
        $active = @($blockable | Where-Object { $_.Level -eq "Active" })
        $procs = @($items | Where-Object { $_.Level -eq "Info" })

        $statusText = ""; $statusColor = "Gray"
        if ($blockable.Count -gt 0) {
            if ($active.Count -eq 0) { $statusText = "- all blocked"; $statusColor = "Green" }
            else { $statusText = "- $($active.Count) of $($blockable.Count) still active"; $statusColor = "Red" }
        }
        $procText = ""
        if ($procs.Count -gt 0) {
            $procText = "$($procs.Count) process$(if ($procs.Count -ne 1) { 'es' }) running (not touched)"
            if ($statusText) { $procText = " | $procText" } else { $statusText = "- $procText"; $statusColor = "Yellow"; $procText = "" }
        }

        # Fully blocked apps start collapsed; a click on [+]/[-] is remembered for the session
        $canToggle = ($AppFilter -eq "ALL APPS" -and $blockable.Count -gt 0)
        $expanded = if (-not $canToggle) { $true } elseif ($Script:LogAppExpanded.ContainsKey($Grp.Name)) { [bool]$Script:LogAppExpanded[$Grp.Name] } else { $active.Count -gt 0 }
        $render.Expanded[$Grp.Name] = $expanded
        $hint = if ($expanded) { "" } else { "  ($($items.Count) item$(if ($items.Count -ne 1) { 's' }) - click [+] to show)" }

        Add-Log -Badge " " -NoScroll -NoDiag
        Add-Log -Badge "=== $($Grp.Name) " -Message $statusText -Detail "$procText$hint" -BadgeColor "Cyan" -MsgColor $statusColor `
            -ToggleApp $(if ($canToggle) { $Grp.Name } else { "" }) -ToggleExpanded:$expanded -NoScroll -NoDiag
        if ($Script:DebugEnabled) {
            foreach ($it in $items) { Write-DiagnosticLog -Level "DEBUG" -Source "UI" -Message "[$($Grp.Name)] [$($it.State)] [$($it.Kind)] $($it.Diag)" }
        }
        if (-not $expanded) { continue }

        # One line per state, kind and folder: still active first, then blocked, then running processes
        $lineGroups = @($items | Group-Object State, Kind, Folder | Sort-Object `
            @{ Expression = { switch ($_.Group[0].Level) { "Active" { 0 } "Blocked" { 1 } default { 2 } } } },
            @{ Expression = { [array]::IndexOf($kindKeys, $_.Group[0].Kind) } })
        foreach ($lg in $lineGroups) {
            $first = $lg.Group[0]
            $kindLabel = if ($lg.Count -gt 1) { $LogKindInfo[$first.Kind].Many } else { $LogKindInfo[$first.Kind].One }
            $names = if ($first.Kind -in @("DLL", "VULKAN")) {
                Join-CompactFileNames -Names @($lg.Group | ForEach-Object { $_.Name } | Sort-Object)
            } elseif ($first.Kind -eq "PROCESS") {
                $kindLabel = $LogKindInfo["PROCESS"].Many
                (@($lg.Group | Group-Object Name | Sort-Object Name | ForEach-Object { if ($_.Count -gt 1) { "$($_.Name) x$($_.Count)" } else { $_.Name } }) -join ", ")
            } else {
                (@($lg.Group | ForEach-Object { $_.Name } | Sort-Object) -join ", ")
            }
            $col = switch ($first.Level) { "Blocked" { "Green" } "Active" { "Red" } default { "Yellow" } }
            $folderText = if ($first.Folder) { "   in $($first.Folder)" } else { "" }
            if ($first.Kind -eq "GAMEBAR") { $line = $names } else { $line = "${kindLabel}: $names" }
            Add-Log -Badge "  [$($first.State)] " -Message $line -Detail $folderText -BadgeColor $col -MsgColor "Gray" -NoScroll -NoDiag
        }
    }
    if ($ShowSteamTip -or ($AppFilter -eq "STEAM")) { Add-SteamClientTipToLog -NoScroll -NoDiag }
    if (-not $KeepScroll) { $LogBox.ScrollToEnd() }
    Write-DiagnosticLog -Level "DEBUG" -Source "UI" -Message "Rendered log -> AppFilter='$AppFilter', CategoryFilter='$CategoryFilter', Entries=$($Entries.Count)"
}

function Update-Dashboard {
    param([string]$Filter = "ALL", [switch]$ShowSteamTip, [switch]$RefreshStore)
    if ($RefreshStore -or (-not $Script:StoreScanCompleted)) {
        $null = Get-InstalledStoreGames -Refresh
    }

    $scanSw = [System.Diagnostics.Stopwatch]::StartNew()
    $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Update-AutoRunToggleButton -ExistingTask $Task
    $AllServices = @(Get-Service -ErrorAction SilentlyContinue)
    $AllTasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue)
    $Dlls = @(Get-OverlayDLLs)
    $VulkanLayers = @(Get-VulkanLayersList)
    $GameBarOff = Get-GameBarStatus
    $Services = @(Get-UtilityServices -AllServices $AllServices)
    $StartupItems = @(Get-UtilityStartupItems)
    $Shortcuts = @(Get-UtilityStartupShortcuts)
    $VendorTasks = @(Get-UtilityScheduledTasks -AllTasks $AllTasks)
    $RunningProcs = @(Get-RunningLaunchers)
    $scanSw.Stop()

    $Script:ScanData = @{
        Task = $Task; Dlls = $Dlls; VulkanLayers = $VulkanLayers; GameBarOff = $GameBarOff
        Services = $Services; StartupItems = $StartupItems; Shortcuts = $Shortcuts
        VendorTasks = $VendorTasks; RunningProcs = $RunningProcs
        StoreGamesCount = @($Script:DetectedStoreGames).Count
        Time = [DateTime]::UtcNow
    }

    $BlockedDlls = @($Dlls | Where-Object { $_.IsBlocked }).Count
    $TotalDlls = $Dlls.Count
    $DisabledLayers = @($VulkanLayers | Where-Object { $_.IsDisabled }).Count
    $TotalLayers = $VulkanLayers.Count
    $ManualSvcs = @($Services | Where-Object { $_.StartType -eq "Manual" -or $_.StartType -eq "Disabled" }).Count
    $TotalSvcs = $Services.Count
    $DisabledRun = @($StartupItems | Where-Object { $_.IsDisabled }).Count
    $DisabledSc = @($Shortcuts | Where-Object { $_.IsDisabled }).Count
    $DisabledTasks = @($VendorTasks | Where-Object { $_.State -eq "Disabled" }).Count
    $TotalStartup = $StartupItems.Count + $Shortcuts.Count + $VendorTasks.Count
    $TotalDisabledStartup = $DisabledRun + $DisabledSc + $DisabledTasks
    $RunCount = $RunningProcs.Count
    # One app (Steam, Discord ...) usually runs several helper processes; the card counts apps
    $RunApps = @($RunningProcs | ForEach-Object { Get-AppGroupName $_.ProcessName } | Sort-Object -Unique).Count

    Write-DiagnosticLog -Level "INFO" -Source "SCAN" -Message "Dashboard scan completed in $($scanSw.ElapsedMilliseconds)ms | Task=$(if ($Task) { 'ON' } else { 'OFF' }) | DLLs=$BlockedDlls/$TotalDlls blocked | Vulkan=$DisabledLayers/$TotalLayers disabled, GameBarOff=$GameBarOff | Svcs=$ManualSvcs/$TotalSvcs manual/disabled | Startup=$TotalDisabledStartup/$TotalStartup disabled | Launchers=$RunApps app(s), $RunCount process(es) | StoreGames=$(@($Script:DetectedStoreGames).Count)" -ForceTrim

    if ($Task) { $TxtCardTaskStatus.Text = "ENABLED ($($Task.State))"; $TxtCardTaskStatus.Foreground = $BrushGreen }
    else { $TxtCardTaskStatus.Text = "NOT SET"; $TxtCardTaskStatus.Foreground = $BrushYellow }

    if ($TotalDlls -eq 0) { $TxtCardDllStatus.Text = "NONE FOUND"; $TxtCardDllStatus.Foreground = $BrushYellow }
    elseif ($BlockedDlls -eq $TotalDlls) { $TxtCardDllStatus.Text = "$BlockedDlls / $TotalDlls BLOCKED"; $TxtCardDllStatus.Foreground = $BrushGreen }
    else { $TxtCardDllStatus.Text = "$BlockedDlls / $TotalDlls BLOCKED"; $TxtCardDllStatus.Foreground = $BrushRed }

    $LayersAllOff = ($TotalLayers -eq 0 -or $DisabledLayers -eq $TotalLayers)
    if ($LayersAllOff -and $GameBarOff) { $TxtCardVulkanStatus.Text = "$DisabledLayers/$TotalLayers OFF + DVR OFF"; $TxtCardVulkanStatus.Foreground = $BrushGreen }
    else { $TxtCardVulkanStatus.Text = "$DisabledLayers/$TotalLayers OFF | DVR:$(if ($GameBarOff) {'OFF'} else {'ON'})"; $TxtCardVulkanStatus.Foreground = $BrushYellow }

    if ($TotalSvcs -eq 0) { $TxtCardSvcStatus.Text = "NONE FOUND"; $TxtCardSvcStatus.Foreground = $BrushGreen }
    elseif ($ManualSvcs -eq $TotalSvcs) { $TxtCardSvcStatus.Text = "$ManualSvcs / $TotalSvcs MANUAL"; $TxtCardSvcStatus.Foreground = $BrushGreen }
    else { $TxtCardSvcStatus.Text = "$ManualSvcs / $TotalSvcs MANUAL"; $TxtCardSvcStatus.Foreground = $BrushYellow }

    if ($TotalStartup -eq 0) { $TxtCardStartupStatus.Text = "NONE FOUND"; $TxtCardStartupStatus.Foreground = $BrushGreen }
    elseif ($TotalDisabledStartup -eq $TotalStartup) { $TxtCardStartupStatus.Text = "$TotalDisabledStartup / $TotalStartup OFF"; $TxtCardStartupStatus.Foreground = $BrushGreen }
    else { $TxtCardStartupStatus.Text = "$TotalDisabledStartup / $TotalStartup OFF"; $TxtCardStartupStatus.Foreground = $BrushYellow }

    if ($RunCount -eq 0) { $TxtCardLauncherStatus.Text = "0 RUNNING"; $TxtCardLauncherStatus.Foreground = $BrushGreen }
    else { $TxtCardLauncherStatus.Text = "$RunApps RUNNING ($RunCount PROCESSES)"; $TxtCardLauncherStatus.Foreground = $BrushYellow }

    if ($Filter -ne "NONE") {
        $Script:CurrentCategoryFilter = $Filter
        $SelectedApp = if ($CmbAppFilter.SelectedItem) { [string]$CmbAppFilter.SelectedItem } else { "ALL APPS" }
        Render-PerAppSummary -AppFilter $SelectedApp -CategoryFilter $Script:CurrentCategoryFilter -ShowSteamTip:$ShowSteamTip
    }
}

function Invoke-BlockTargets {
    param([string[]]$Kinds)
    $ExcludedIds = @(Get-SavedExclusions)
    foreach ($t in @(Get-BlockTargets -Kinds $Kinds -ExcludedIds $ExcludedIds)) {
        if ($t.Kind -eq "SHORTCUT" -and $t.IsBlocked) { continue }
        if ($t.IsExcluded) {
            Add-Log -Badge "[EXCLUDED / KEPT SAFE] " -Message $t.LogName -BadgeColor "Yellow" -NoScroll
            continue
        }
        try {
            Set-TargetBlocked -Target $t
            Add-Log -Badge "[$($BlockBadges[$t.Kind])] " -Message $t.LogName -BadgeColor "Green" -NoScroll
        } catch {
            $errCtx = Write-DiagnosticError -Source "BLOCK" -Context "Block $($t.Kind)" -Target $t.Id -ErrorRecord $_
            Add-Log -Badge "[FAILED $($t.Kind)] " -Message "$($t.LogName) - $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoScroll -NoDiag
        }
    }
}

function Invoke-BlockOverlaysOnly {
    Clear-Log "ACTIVITY LOG - BLOCKING OVERLAY HOOKS ONLY"
    Add-Log -Badge "[OVERLAYS ONLY] " -Message "Blocking overlay/hook DLLs, Vulkan layers, and Game Bar/DVR (respecting exclusions)..." -BadgeColor "Cyan" -NoScroll
    Invoke-BlockTargets -Kinds $OverlayTargetKinds
    Add-SteamClientTipToLog -NoScroll
    Add-Log -Badge "`n=== OVERLAY HOOKS BLOCK COMPLETE ===" -BadgeColor "Cyan"
    Update-Dashboard -Filter "NONE"
}

function Invoke-BlockEverything {
    Clear-Log "ACTIVITY LOG - BLOCKING EVERYTHING"
    Add-Log -Badge "[BLOCK ALL] " -Message "Applying full overlay, Vulkan, Game Bar, service, and startup blocks (respecting exclusions)..." -BadgeColor "Green" -NoScroll
    Invoke-BlockTargets -Kinds $AllTargetKinds
    Add-SteamClientTipToLog -NoScroll
    Add-Log -Badge "`n=== BLOCK COMPLETE ===" -BadgeColor "Cyan"
    Update-Dashboard -Filter "NONE"
}

function Invoke-RestoreEverything {
    $Confirm = [System.Windows.MessageBox]::Show(
        "Restore ALL blocked overlay DLLs, Vulkan layers, Game Bar/DVR settings, services, startup items, and scheduled tasks back to default auto-start?`n`nThis also turns Auto-Run OFF.",
        "Confirm Restore Everything", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question
    )
    if ($Confirm -ne [System.Windows.MessageBoxResult]::Yes) {
        Write-DiagnosticLog -Level "DEBUG" -Source "RESTORE" -Message "Restore Everything cancelled by user."
        return
    }

    Write-DiagnosticLog -Level "INFO" -Source "RESTORE" -Message "User confirmed Restore Everything." -ForceTrim
    Clear-Log "ACTIVITY LOG - RESTORING EVERYTHING"
    Add-Log -Badge "[RESTORE ALL] " -Message "Restoring DLLs, Vulkan layers, Game Bar/DVR, services, and startup items..." -BadgeColor "Yellow" -NoScroll

    # Remove the auto-run task first, otherwise everything is blocked again at the next logon
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        try {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
            Add-Log -Badge "[REMOVED] " -Message "Scheduled task '$TaskName' deleted." -BadgeColor "Green" -NoScroll
        } catch {
            $errCtx = Write-DiagnosticError -Source "RESTORE" -Context "Remove scheduled task" -Target $TaskName -ErrorRecord $_
            Add-Log -Badge "[FAILED TASK] " -Message "Could not remove '$TaskName': $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoScroll -NoDiag
        }
    }

    # Restore what is currently blocked; Game Bar is written even if only one of its two values is off
    Invoke-RestoreTargets -Targets @(Get-BlockTargets | Where-Object { $_.IsBlocked -or $_.Kind -eq "GAMEBAR" })

    Add-Log -Badge "`n=== RESTORE COMPLETE ===" -BadgeColor "Cyan"
    Update-Dashboard -Filter "NONE"
}

function Invoke-ToggleTask {
    $Existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($Existing) {
        try {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
            Update-AutoRunToggleButton -ExistingTask $null
            Write-DiagnosticLog -Level "INFO" -Source "TASK" -Message "Removed scheduled task '$TaskName'." -ForceTrim
            Clear-Log "ACTIVITY LOG - STARTUP TASK REMOVED"
            Add-Log -Badge "[REMOVED] " -Message "Scheduled task '$TaskName' deleted." -BadgeColor "Yellow"
        } catch {
            $errCtx = Write-DiagnosticError -Source "TASK" -Context "Remove scheduled task" -Target $TaskName -ErrorRecord $_ -ForceTrim
            Update-AutoRunToggleButton
            Clear-Log "ACTIVITY LOG - STARTUP TASK ERROR"
            Add-Log -Badge "[ERROR] " -Message "Could not remove scheduled task '$TaskName': $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoDiag
        }
    } else {
        try {
            $targetPath = Save-LocalScriptCopy
            $hostInfo = Get-HostRuntimeInfo
            if ($hostInfo.IsPortableExe) {
                $Action = New-ScheduledTaskAction -Execute $targetPath -Argument "-AutoBlock" -WorkingDirectory ([System.IO.Path]::GetDirectoryName($targetPath))
            } else {
                $psExe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
                $Action = New-ScheduledTaskAction -Execute $psExe -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$targetPath`" -AutoBlock" -WorkingDirectory $LocalInstallDir
            }
            $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            $Trigger = New-ScheduledTaskTrigger -AtLogOn -User $CurrentUser
            $Trigger.Delay = "PT60S"
            $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
            $Principal = New-ScheduledTaskPrincipal -UserId $CurrentUser -LogonType Interactive -RunLevel Highest
            Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Force -ErrorAction Stop | Out-Null
            Update-AutoRunToggleButton
            Write-DiagnosticLog -Level "INFO" -Source "TASK" -Message "Registered scheduled task '$TaskName' (User=$CurrentUser, Target=$(Hide-Username $targetPath), Delay=60s)." -ForceTrim
            Clear-Log "ACTIVITY LOG - STARTUP TASK CREATED"
            Add-Log -Badge "[CREATED] " -Message "Scheduled task '$TaskName' will run 60s after logon (respects Exclusions List)." -BadgeColor "Green"
            Add-Log -Badge "[TARGET] " -Message (Hide-Username $targetPath) -BadgeColor "Cyan"
        } catch {
            $errCtx = Write-DiagnosticError -Source "TASK" -Context "Register scheduled task" -Target $TaskName -ErrorRecord $_ -ForceTrim
            Update-AutoRunToggleButton
            Clear-Log "ACTIVITY LOG - STARTUP TASK ERROR"
            Add-Log -Badge "[ERROR] " -Message "Could not create scheduled task '$TaskName': $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoDiag
        }
    }
    Update-Dashboard -Filter "NONE"
}

function Invoke-ResetLogAndFilters {
    $Script:SuppressFilterEvent = $true
    try {
        $Script:CurrentCategoryFilter = "ALL"
        $CmbAppFilter.SelectedIndex = 0
        # Also forget which apps were expanded or collapsed by hand
        $Script:LogAppExpanded.Clear()
    } finally {
        $Script:SuppressFilterEvent = $false
    }
    Write-DiagnosticLog -Level "DEBUG" -Source "UI" -Message "Reset log & filters to ALL APPS / ALL."
    Render-PerAppSummary -AppFilter "ALL APPS" -CategoryFilter "ALL"
}

# Runs a button or timer action and logs any failure with the action's name. PowerShell does not
# reliably pass errors thrown inside WPF event handlers on to the window, so each handler catches its own.
$Script:LastUiErrorKey = ""
function Invoke-UiAction {
    param(
        [string]$Name,
        [scriptblock]$Action,
        # For timers: no dialog, and a repeating error is written only once
        [switch]$Quiet
    )
    if (-not $Quiet) { Write-DiagnosticLog -Level "DEBUG" -Source "UI" -Message "Action: $Name" }
    try {
        & $Action
    } catch {
        $errKey = "$Name|$($_.Exception.GetBaseException().Message)"
        if ($Quiet -and $Script:LastUiErrorKey -eq $errKey) { return }
        $Script:LastUiErrorKey = $errKey
        $errCtx = Write-DiagnosticError -Source "UI" -Context $Name -Target "UI action" -ErrorRecord $_ -ForceTrim
        try { Add-Log -Badge "[ERROR] " -Message "$Name failed: $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoDiag } catch {}
        if (-not $Quiet) {
            try {
                [System.Windows.MessageBox]::Show("$Name failed:`n$errCtx`n`nClick 'Save Report' and send the file to GS.", "ZeroHook Error",
                    [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
            } catch {}
        }
    }
}

# Last line of defence for errors that still reach the window: log them and keep ZeroHook running
$Window.Dispatcher.Add_UnhandledException({
    param($dispatcherSender, $e)
    try {
        $ex = $e.Exception.GetBaseException()
        $stack = ([string]$ex.StackTrace -replace '\s+', ' ')
        if ($stack.Length -gt 600) { $stack = $stack.Substring(0, 600) + "..." }
        Write-DiagnosticLog -Level "ERROR" -Source "UI" -Message "Unhandled UI exception: $($ex.GetType().FullName): $($ex.Message) | Stack: $stack" -ForceTrim
    } catch {}
    $e.Handled = $true
})

$CopyLabelTimer = New-Object System.Windows.Threading.DispatcherTimer
$CopyLabelTimer.Interval = [TimeSpan]::FromMilliseconds(1500)
$CopyLabelTimer.Add_Tick({
    $CopyLabelTimer.Stop()
    $BtnCopyBugReport.Content = "Copy Log for Dev"
})

$BtnCopyBugReport.Add_Click({
    try {
        $chars = Copy-BugReportToClipboard -FallbackTitle $TxtLogHeader.Text
        $BtnCopyBugReport.Content = "Copied!"
        $CopyLabelTimer.Start()
        Add-Log -Badge "[COPIED] " -Message "Bug report & recent diagnostics copied to clipboard for GS ($chars characters)." -BadgeColor "Green" -NoDiag
        if ($chars -gt 2000) {
            Add-Log -Badge "[TIP] " -Message "This report is too long for a single Discord message. Use 'Save Report' and attach the file instead." -BadgeColor "Yellow" -NoDiag
        }
    } catch {
        $errCtx = Write-DiagnosticError -Source "REPORT" -Context "Copy bug report" -Target "Clipboard" -ErrorRecord $_ -ForceTrim
        [System.Windows.MessageBox]::Show("Could not copy bug report:`n$errCtx`n`nTry 'Save Report' instead.", "ZeroHook Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})
$BtnSaveBugReport.Add_Click({
    try {
        $reportPath = Save-BugReportToFile -FallbackTitle $TxtLogHeader.Text
        Add-Log -Badge "[SAVED] " -Message "Bug report saved to $(Hide-Username $reportPath). Attach this file when you contact GS." -BadgeColor "Green" -NoDiag
    } catch {
        $errCtx = Write-DiagnosticError -Source "REPORT" -Context "Save bug report" -Target $LogDir -ErrorRecord $_ -ForceTrim
        [System.Windows.MessageBox]::Show("Could not save bug report:`n$errCtx", "ZeroHook Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})
$BtnOpenLogs.Add_Click({ Invoke-UiAction "Open logs folder" { Open-LogsFolder } })
$BtnDebugMode.Add_Click({ Invoke-UiAction "Toggle debug mode" { Invoke-ToggleDebugMode } })
$BtnAboutInfo.Add_Click({ Invoke-UiAction "Open guide" { Show-AboutInfoWindow } })
$BtnOverlayStatus.Add_Click({ Invoke-UiAction "Open overlay DLL status" { Show-OverlayStatusWindow } })
$BtnRefresh.Add_Click({
    Invoke-UiAction "Full rescan" {
        Write-DiagnosticLog -Level "INFO" -Source "UI" -Message "Manual Full Rescan triggered." -ForceTrim
        Update-Dashboard -Filter $Script:CurrentCategoryFilter -RefreshStore
        Refresh-HookProcessList -SelectFirstSilently
    }
})

# Card clicks only filter the view; reuse a recent scan instead of rescanning the system each time
function Show-DashboardCategory {
    param([string]$Filter)
    if ($Script:ScanData.Count -eq 0 -or ([DateTime]::UtcNow - $Script:ScanData.Time).TotalSeconds -gt 30) {
        Update-Dashboard -Filter $Filter
        return
    }
    $Script:CurrentCategoryFilter = $Filter
    $app = if ($CmbAppFilter.SelectedItem) { [string]$CmbAppFilter.SelectedItem } else { "ALL APPS" }
    Render-PerAppSummary -AppFilter $app -CategoryFilter $Filter
}

$CardTask.Add_Click({ Invoke-UiAction "Show task status" { Show-TaskStatus } })
$CardDlls.Add_Click({ Invoke-UiAction "Show DLLs" { Show-DashboardCategory -Filter "DLLS" } })
$CardVulkan.Add_Click({ Invoke-UiAction "Show Vulkan and Game Bar" { Show-DashboardCategory -Filter "VULKAN" } })
$CardServices.Add_Click({ Invoke-UiAction "Show services" { Show-DashboardCategory -Filter "SERVICES" } })
$CardStartup.Add_Click({ Invoke-UiAction "Show startup items" { Show-DashboardCategory -Filter "STARTUP" } })
$CardLaunchers.Add_Click({ Invoke-UiAction "Show launchers" { Show-DashboardCategory -Filter "LAUNCHERS" } })

$BtnBlockAll.Add_Click({ Invoke-UiAction "Block Everything" { Invoke-BlockEverything } })
$BtnCustomBlock.Add_Click({ Invoke-UiAction "Exclusions List" { Show-ExclusionsDialog } })
$BtnRestoreAll.Add_Click({ Invoke-UiAction "Restore Everything" { Invoke-RestoreEverything } })
$BtnBlockOverlaysOnly.Add_Click({ Invoke-UiAction "Block Overlay Hooks Only" { Invoke-BlockOverlaysOnly } })
$BtnRestoreSelected.Add_Click({ Invoke-UiAction "Restore Selected" { Show-SelectiveRestoreDialog } })
$BtnToggleTask.Add_Click({ Invoke-UiAction "Toggle Auto-Run" { Invoke-ToggleTask } })
$BtnQuickFilter.Add_Click({ Invoke-UiAction "Reset view" { Invoke-ResetLogAndFilters } })

$CmbAppFilter.Add_SelectionChanged({
    if ($Script:SuppressFilterEvent) { return }
    $SelectedApp = if ($CmbAppFilter.SelectedItem) { [string]$CmbAppFilter.SelectedItem } else { "ALL APPS" }
    Render-PerAppSummary -AppFilter $SelectedApp -CategoryFilter $Script:CurrentCategoryFilter
})

$BtnReloadProcs.Add_Click({
    Refresh-HookProcessList
    Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [PROCS] " -Message "Refreshed window process list ($($CmbHookProcess.Items.Count) found)." -BadgeColor "Cyan"
})

$CmbHookProcess.Add_SelectionChanged({
    if ($Script:SuppressHookProcessSelection) { return }
    $target = Get-SelectedHookTarget
    if ($target) {
        $Script:LiveHookTarget = $target
        $Script:SeenModuleKeys.Clear()
        $Script:PendingHookDetections.Clear()
        $TxtLiveHookStatus.Text = "SELECTED: $($target.Name) (PID $($target.Id))"
        $TxtLiveHookStatus.Foreground = $BrushCyan
        Write-DiagnosticLog -Level "INFO" -Source "LIVEHOOK" -Message "Selected target process: $($target.Name) (PID $($target.Id))."
    }
})

$LockCountdownTimer = New-Object System.Windows.Threading.DispatcherTimer
$LockCountdownTimer.Interval = [TimeSpan]::FromMilliseconds(250)
$Script:LockDeadline = [DateTime]::MinValue

$LockCountdownTimer.Add_Tick({
    $rem = ($Script:LockDeadline - [DateTime]::Now).TotalSeconds
    if ($rem -gt 0) {
        $TxtLiveHookStatus.Text = ("SWITCH TO GAME WINDOW NOW... {0:N1}s" -f $rem)
        $TxtLiveHookStatus.Foreground = $BrushYellow
        return
    }

    $LockCountdownTimer.Stop()
    $BtnLockForeground.IsEnabled = $true

    try {
        Ensure-ForegroundWin32
        $fgPid = [ZeroHook.Win32Foreground]::GetForegroundPid()
        if ($fgPid -le 0 -or $fgPid -eq $PID) {
            $TxtLiveHookStatus.Text = "LOCK FAILED - No external foreground window detected"
            $TxtLiveHookStatus.Foreground = $BrushRed
            Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [LOCK FAILED] " -Message "Could not capture an external foreground window PID." -BadgeColor "Red"
            return
        }

        $p = Get-Process -Id $fgPid -ErrorAction Stop
        if ($p.ProcessName -in $IgnoredForegroundProcesses) {
            $pName = $p.ProcessName
            $p.Dispose()
            $TxtLiveHookStatus.Text = "IGNORED FOREGROUND: $pName (PID $fgPid)"
            $TxtLiveHookStatus.Foreground = $BrushYellow
            Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [LOCK SKIPPED] " -Message "Foreground process '$pName' (PID $fgPid) is in the ignored utility list." -BadgeColor "Yellow"
            return
        }

        $targetObj = [PSCustomObject]@{
            Id         = [int]$p.Id
            Name       = [string]$p.ProcessName
            Path       = $(try { [string]$p.Path } catch { "" })
            StartedUtc = $(try { $p.StartTime.ToUniversalTime() } catch { $null })
        }
        $p.Dispose()

        $Script:LiveHookTarget = $targetObj
        $Script:SeenModuleKeys.Clear()
        $Script:PendingHookDetections.Clear()

        Refresh-HookProcessList -SelectFirstSilently
        $matchedItem = $null
        foreach ($item in $CmbHookProcess.Items) {
            if ($item.Tag -and $item.Tag.Id -eq $targetObj.Id) { $matchedItem = $item; break }
        }
        if (-not $matchedItem) {
            $matchedItem = New-Object System.Windows.Controls.ComboBoxItem
            $matchedItem.Content = "$($targetObj.Name) (PID $($targetObj.Id)) [Locked]"
            $matchedItem.Tag = [PSCustomObject]@{ Id = $targetObj.Id; Name = $targetObj.Name; Path = $targetObj.Path }
            [void]$CmbHookProcess.Items.Insert(0, $matchedItem)
        }
        $Script:SuppressHookProcessSelection = $true
        $CmbHookProcess.SelectedItem = $matchedItem
        $Script:SuppressHookProcessSelection = $false

        Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [LOCKED] " -Message "Locked onto $($targetObj.Name) (PID $($targetObj.Id))." -BadgeColor "Green"
        Invoke-HookMonitorStep -ForceLogSnapshot
    } catch {
        $errCtx = Write-DiagnosticError -Source "LIVEHOOK" -Context "Lock foreground process" -Target "ForegroundWindow" -ErrorRecord $_
        $TxtLiveHookStatus.Text = "LOCK ERROR - Could not inspect foreground process"
        $TxtLiveHookStatus.Foreground = $BrushRed
        Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [LOCK ERROR] " -Message $errCtx -BadgeColor "Red" -SkipDiagLog
    }
})

$BtnLockForeground.Add_Click({
    if ($LockCountdownTimer.IsEnabled) { return }
    $BtnLockForeground.IsEnabled = $false
    $Script:LockDeadline = [DateTime]::Now.AddSeconds(3)
    $TxtLiveHookStatus.Text = "SWITCH TO GAME WINDOW NOW... 3.0s"
    $TxtLiveHookStatus.Foreground = $BrushYellow
    $LockCountdownTimer.Start()
})

$CmbPollInterval.Add_SelectionChanged({
    if ($CmbPollInterval.SelectedItem) {
        $txt = [string]$CmbPollInterval.SelectedItem
        if ($txt -match '^(\d+)s$') {
            $secs = [int]$matches[1]
            $HookTimer.Interval = [TimeSpan]::FromSeconds($secs)
            Write-DiagnosticLog -Level "DEBUG" -Source "LIVEHOOK" -Message "Updated poll interval to ${secs}s."
        }
    }
})

$BtnToggleLiveMonitor.Add_Click({
    if ($HookTimer.IsEnabled) {
        $HookTimer.Stop()
        $BtnToggleLiveMonitor.Content = "Start Real-Time Watch"
        $BtnToggleLiveMonitor.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#22A055")
        if ($Script:LiveHookTarget) {
            $TxtLiveHookStatus.Text = "PAUSED: $($Script:LiveHookTarget.Name) (PID $($Script:LiveHookTarget.Id))"
            $TxtLiveHookStatus.Foreground = $BrushYellow
        } else {
            $TxtLiveHookStatus.Text = "STOPPED"
            $TxtLiveHookStatus.Foreground = $BrushGray
        }
        Unregister-ModuleLoadEvents
        Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [WATCH] " -Message "Real-time hook monitoring paused." -BadgeColor "Yellow"
    } else {
        $target = Get-SelectedHookTarget
        if (-not $target) {
            $TxtLiveHookStatus.Text = "SELECT A PROCESS FIRST - Or click Lock Foreground (3s)"
            $TxtLiveHookStatus.Foreground = $BrushRed
            Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [WATCH] " -Message "No valid target process selected." -BadgeColor "Red"
            return
        }
        if (-not $Script:LiveHookTarget -or $Script:LiveHookTarget.Id -ne $target.Id) {
            $Script:LiveHookTarget = $target
            $Script:SeenModuleKeys.Clear()
            $Script:PendingHookDetections.Clear()
        }
        $HookTimer.Start()
        $BtnToggleLiveMonitor.Content = "Stop Real-Time Watch"
        $BtnToggleLiveMonitor.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#DC2626")
        Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [WATCH] " -Message "Started real-time hook monitoring on $($target.Name) (PID $($target.Id))." -BadgeColor "Green"
        Invoke-HookMonitorStep -ForceLogSnapshot
    }
})

$BtnScanNowHooks.Add_Click({ Invoke-UiAction "Scan snapshot" {
    $target = Get-SelectedHookTarget
    if (-not $target) {
        $TxtLiveHookStatus.Text = "SELECT A PROCESS FIRST - Or click Lock Foreground (3s)"
        $TxtLiveHookStatus.Foreground = $BrushRed
        Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [SNAPSHOT] " -Message "No valid target process selected." -BadgeColor "Red"
        return
    }
    if (-not $Script:LiveHookTarget -or $Script:LiveHookTarget.Id -ne $target.Id) {
        $Script:LiveHookTarget = $target
        $Script:SeenModuleKeys.Clear()
        $Script:PendingHookDetections.Clear()
    }
    Invoke-HookMonitorStep -ForceLogSnapshot
} })

$AutoAttachTimer = New-Object System.Windows.Threading.DispatcherTimer
$AutoAttachTimer.Interval = [TimeSpan]::FromSeconds(2)
$AutoAttachTimer.Add_Tick({ Invoke-UiAction "Auto-attach" -Quiet { Invoke-AutoAttachStep } })

$ChkAutoAttach.Add_Click({
    Invoke-UiAction "Toggle auto-attach" {
        if ($ChkAutoAttach.IsChecked) {
            if (-not $Script:StoreScanCompleted) { $null = Get-InstalledStoreGames }
            $Script:AutoAttachKnownPids.Clear()
            $Script:AutoAttachPending.Clear()
            $gameCount = @($Script:DetectedStoreGames).Count
            Write-DiagnosticLog -Level "INFO" -Source "AUTOATTACH" -Message "Auto-attach on ($gameCount detected game folders)."
            Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [AUTO-ATTACH ON] " -Message "Waiting for a game from $gameCount detected game folder(s) to open its window. A game that is already running is picked up now." -BadgeColor "Cyan" -SkipDiagLog
            $AutoAttachTimer.Start()
            Invoke-AutoAttachStep
        } else {
            $AutoAttachTimer.Stop()
            Write-DiagnosticLog -Level "INFO" -Source "AUTOATTACH" -Message "Auto-attach off."
            Add-HookLog -Badge "[$(Get-Date -Format 'HH:mm:ss')] [AUTO-ATTACH OFF] " -Message "The current watch keeps running until you stop it." -BadgeColor "Muted" -SkipDiagLog
        }
    }
})

$BtnClearHookLog.Add_Click({
    $HookLogBox.Document.Blocks.Clear()
    $Script:PendingHookDetections.Clear()
    Write-DiagnosticLog -Level "DEBUG" -Source "UI" -Message "Cleared Live DLL Hook log."
})

$Window.Add_Closed({
    try { $HookTimer.Stop() } catch {}
    try { $LockCountdownTimer.Stop() } catch {}
    try { $AutoAttachTimer.Stop() } catch {}
    try { Unregister-ModuleLoadEvents } catch {}
    Write-DiagnosticLog -Level "INFO" -Source "SESSION" -Message "Session closing | SessionId=$Script:SessionId" -ForceTrim
})

# Show the window first, then run the initial scan so startup does not look frozen
$Script:InitialScanDone = $false
$Window.Add_ContentRendered({
    if ($Script:InitialScanDone) { return }
    $Script:InitialScanDone = $true
    try {
        Update-AutoRunScriptCopy
        Refresh-HookProcessList -SelectFirstSilently
        Update-Dashboard -Filter "ALL"
        Add-HookLog -Badge "[READY] " -Message "Select a game process from the dropdown or click 'Lock Foreground (3s)', then click 'Start Real-Time Watch' or 'Scan Snapshot Now'." -BadgeColor "Cyan"
    } catch {
        $errCtx = Write-DiagnosticError -Source "APP" -Context "Initial scan" -Target "Dashboard" -ErrorRecord $_ -ForceTrim
        Add-Log -Badge "[ERROR] " -Message "Initial scan failed: $errCtx" -BadgeColor "Red" -MsgColor "Red" -NoDiag
    }
})

[void]$Window.ShowDialog()
